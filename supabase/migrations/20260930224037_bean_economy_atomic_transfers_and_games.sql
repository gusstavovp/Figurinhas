create schema if not exists pv_economy;
revoke all on schema pv_economy from public, anon;
grant usage on schema pv_economy to authenticated;
create table pv_economy.wallets(user_id uuid primary key references public.profiles(id) on delete cascade,balance bigint not null default 0 check(balance>=0),principal bigint not null default 0 check(principal>=0),cycle bigint not null default 1,revision bigint not null default 0);
create table pv_economy.lots(id bigint generated always as identity primary key,user_id uuid not null references pv_economy.wallets(user_id),source text not null check(source in('clicker','sticker','casino')),remaining bigint not null check(remaining>=0),rate numeric(30,0) not null check(rate>=1000000000),created_at timestamptz not null default now());
create index bean_lots_user on pv_economy.lots(user_id,id) where remaining>0;
create table pv_economy.market(id boolean primary key default true check(id),rate numeric(30,0) not null default 1000000000 check(rate between 1000000000 and 100000000000),version bigint not null default 1,baseline numeric,current_index numeric,last_adjustment timestamptz not null default now(),participants integer not null default 0);
insert into pv_economy.market(id) values(true);
create table pv_economy.market_history(id bigint generated always as identity primary key,rate numeric not null,wealth_index numeric,participants integer,created_at timestamptz not null default now());
insert into pv_economy.market_history(rate) values(1000000000);
create table pv_economy.quotes(id uuid primary key default gen_random_uuid(),user_id uuid not null references pv_economy.wallets(user_id),kind text not null,amount bigint not null check(amount>0),options jsonb not null,wallet_revision bigint not null,clicker_revision bigint,market_version bigint not null,preview jsonb not null,expires_at timestamptz not null default now()+interval '2 minutes',result jsonb);
create index bean_quotes_user on pv_economy.quotes(user_id,expires_at);
create table pv_economy.ledger(id uuid primary key,user_id uuid not null references pv_economy.wallets(user_id),kind text not null,bean_delta bigint not null,balance_after bigint not null check(balance_after>=0),details jsonb not null,created_at timestamptz not null default now());
create index bean_ledger_user on pv_economy.ledger(user_id,created_at desc);
create table pv_economy.rounds(id uuid primary key default gen_random_uuid(),user_id uuid not null references pv_economy.wallets(user_id),game text not null check(game in('mines','crash','double')),stake bigint not null check(stake>0),stake_lots jsonb not null,mines integer[],opened integer[] not null default '{}',mine_count integer,crash_point numeric,color text,result_number integer,multiplier numeric not null default 1,status text not null default 'active' check(status in('active','won','lost')),started_at timestamptz not null default clock_timestamp(),finished_at timestamptz,win bigint not null default 0);
create unique index bean_one_active_round on pv_economy.rounds(user_id) where status='active';
create table pv_economy.actions(id uuid primary key,user_id uuid not null references pv_economy.wallets(user_id),round_id uuid not null references pv_economy.rounds(id),action text not null,cell integer,result jsonb not null);
do $$ declare t text;begin foreach t in array array['wallets','lots','market','market_history','quotes','ledger','rounds','actions'] loop execute format('alter table pv_economy.%I enable row level security',t);execute format('revoke all on pv_economy.%I from public, anon, authenticated',t);end loop;end $$;

create function pv_economy.rng(n integer) returns integer language plpgsql volatile set search_path='' as $$
declare b bytea;x bigint;lim bigint;begin if n<1 then raise exception 'Intervalo inválido';end if;lim:=floor(4294967296::numeric/n)*n;loop b:=extensions.gen_random_bytes(4);x:=get_byte(b,0)::bigint*16777216+get_byte(b,1)::bigint*65536+get_byte(b,2)::bigint*256+get_byte(b,3);exit when x<lim;end loop;return (x%n)::integer;end $$;
create function pv_economy.card_value(card integer) returns integer language sql stable set search_path='' as $$ select case public.album_card_rarity(card) when 'common' then 5 when 'uncommon' then 10 when 'rare' then 20 when 'epic' then 35 when 'mythic' then 60 when 'legendary' then 100 when 'secret' then 150 when 'supersecret' then 200 else 0 end $$;
create function pv_economy.adjust_market() returns void language plpgsql set search_path='' as $$
declare m pv_economy.market;idx numeric;cnt integer;target numeric;next_rate numeric;
begin select * into m from pv_economy.market where id=true for update;
if clock_timestamp()<m.last_adjustment+interval '24 hours' then return;end if;
-- Median of capped log wealth: one account cannot dominate the index.
select count(*),exp(percentile_cont(.5) within group(order by ln(1+least(1000000000000000::numeric,greatest(0,coalesce((c.state->>'juice')::numeric,0))))))-1 into cnt,idx
from public.clicker_progress c join public.profiles p on p.id=c.user_id where p.created_at<now()-interval '7 days' and c.updated_at>now()-interval '30 days';
if cnt<5 then update pv_economy.market set last_adjustment=clock_timestamp(),participants=cnt where id=true;return;end if;
if m.baseline is null then update pv_economy.market set baseline=greatest(idx,1000000000),current_index=idx,participants=cnt,last_adjustment=clock_timestamp() where id=true;return;end if;
target:=least(100000000000,greatest(1000000000,1000000000*sqrt(greatest(1,idx)/m.baseline)));
next_rate:=round(greatest(m.rate*.95,least(m.rate*1.05,m.rate*.9+target*.1)));
update pv_economy.market set rate=next_rate,version=version+1,current_index=idx,participants=cnt,last_adjustment=clock_timestamp() where id=true;
insert into pv_economy.market_history(rate,wealth_index,participants) values(next_rate,idx,cnt);
end $$;
create function pv_economy.take_lots(uid uuid,qty bigint) returns jsonb language plpgsql set search_path='' as $$
declare l pv_economy.lots;t bigint;left_qty bigint:=qty;out_lots jsonb:='[]';begin
for l in select * from pv_economy.lots where user_id=uid and remaining>0 order by id for update loop
t:=least(left_qty,l.remaining);out_lots:=out_lots||jsonb_build_array(jsonb_build_object('lot',l.id,'quantity',t,'rate',l.rate::text,'source',l.source));update pv_economy.lots set remaining=remaining-t where id=l.id;left_qty:=left_qty-t;exit when left_qty=0;end loop;
if left_qty<>0 then raise exception 'Saldo de lotes insuficiente';end if;return out_lots;end $$;
create function pv_economy.lot_preview(uid uuid,qty bigint) returns jsonb language plpgsql stable set search_path='' as $$
declare l pv_economy.lots;t bigint;left_qty bigint:=qty;total numeric:=0;out_lots jsonb:='[]';begin
for l in select * from pv_economy.lots where user_id=uid and remaining>0 order by id loop t:=least(left_qty,l.remaining);total:=total+t*l.rate;out_lots:=out_lots||jsonb_build_array(jsonb_build_object('quantity',t,'rate',l.rate::text,'source',l.source));left_qty:=left_qty-t;exit when left_qty=0;end loop;
if left_qty<>0 then raise exception 'Feijões insuficientes';end if;return jsonb_build_object('coins',total::text,'lots',out_lots);end $$;
create function pv_economy.finish_round(rid uuid,won bigint,mult numeric) returns void language plpgsql set search_path='' as $$
declare r pv_economy.rounds;l jsonb;t bigint;left_qty bigint;profit bigint;w pv_economy.wallets;
begin select * into r from pv_economy.rounds where id=rid for update;if r.status<>'active' then return;end if;
left_qty:=least(won,r.stake);for l in select value from jsonb_array_elements(r.stake_lots) loop exit when left_qty=0;t:=least(left_qty,(l->>'quantity')::bigint);insert into pv_economy.lots(user_id,source,remaining,rate) values(r.user_id,l->>'source',t,(l->>'rate')::numeric);left_qty:=left_qty-t;end loop;
profit:=greatest(0,won-r.stake);if profit>0 then insert into pv_economy.lots(user_id,source,remaining,rate) values(r.user_id,'casino',profit,1000000000);end if;
update pv_economy.wallets set balance=balance+won,revision=revision+1 where user_id=r.user_id returning * into w;
if w.balance=0 then update pv_economy.wallets set principal=0,cycle=cycle+1 where user_id=r.user_id;end if;
update pv_economy.rounds set status=case when won>0 then 'won' else 'lost' end,win=won,multiplier=mult,finished_at=clock_timestamp() where id=rid;
insert into pv_economy.ledger(id,user_id,kind,bean_delta,balance_after,details) values(rid,r.user_id,'game_result',won,w.balance,jsonb_build_object('game',r.game,'stake',r.stake,'win',won,'multiplier',mult));end $$;
create function pv_economy.round_view(rid uuid) returns jsonb language plpgsql stable set search_path='' as $$ declare r pv_economy.rounds;begin select * into r from pv_economy.rounds where id=rid;return jsonb_build_object('id',r.id,'game',r.game,'stake',r.stake,'status',r.status,'opened',r.opened,'mine_count',r.mine_count,'multiplier',r.multiplier,'started_at',r.started_at,'server_time',clock_timestamp(),'win',r.win,'color',r.color,'result_number',case when r.status<>'active' then r.result_number end,'mines',case when r.status<>'active' then to_jsonb(r.mines) end);end $$;
create function pv_economy.snapshot(uid uuid) returns jsonb language plpgsql set search_path='' as $$
declare w pv_economy.wallets;m pv_economy.market;r pv_economy.rounds;lots jsonb;hist jsonb;rates jsonb;
begin select * into w from pv_economy.wallets where user_id=uid;select * into m from pv_economy.market where id=true;
select * into r from pv_economy.rounds where user_id=uid and status='active';
if found and r.game='crash' and exp(extract(epoch from clock_timestamp()-r.started_at)*.14)>=r.crash_point then perform pv_economy.finish_round(r.id,0,r.crash_point);select * into w from pv_economy.wallets where user_id=uid;end if;
select coalesce(jsonb_agg(x),'[]') into lots from (select id,source,remaining,rate::text rate,created_at from pv_economy.lots where user_id=uid and remaining>0 order by id limit 100) x;
select coalesce(jsonb_agg(x),'[]') into hist from (select kind,bean_delta,balance_after,details,created_at from pv_economy.ledger where user_id=uid order by created_at desc,id limit 30) x;
select coalesce(jsonb_agg(x),'[]') into rates from (select rate::text rate,wealth_index::text wealth_index,participants,created_at from pv_economy.market_history order by id desc limit 14) x;
return jsonb_build_object('balance',w.balance,'principal',w.principal,'cycle',w.cycle,'revision',w.revision,'required',ceil(w.principal*1.35),'missing',greatest(0,ceil(w.principal*1.35)-w.balance),'album_unlocked',w.principal>0 and w.balance>=ceil(w.principal*1.35),'rate',m.rate::text,'market_version',m.version,'market',jsonb_build_object('baseline',m.baseline::text,'wealth_index',m.current_index::text,'participants',m.participants,'last_adjustment',m.last_adjustment,'history',rates),'lots',lots,'history',hist,'round',case when r.id is not null then pv_economy.round_view(r.id) else null end,'album_coins',(select coins from public.album_progress where user_id=uid),'clicker_coins',(select (state->>'juice') from public.clicker_progress where user_id=uid));end $$;
create function pv_economy.gateway(p_action text,p_payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();w pv_economy.wallets;m pv_economy.market;q pv_economy.quotes;amount bigint;kind text;opts jsonb;prev jsonb;lp jsonb;outcome jsonb;ap public.album_progress;cp public.clicker_progress;val bigint;beans bigint;cost numeric;needed numeric;lots jsonb;r pv_economy.rounds;rid uuid;cells integer[];i integer;j integer;temp integer;game text;mult numeric;result_int integer;
begin
if uid is null then raise exception 'Entre com sua conta do álbum';end if;
insert into pv_economy.wallets(user_id) values(uid) on conflict do nothing;
select * into w from pv_economy.wallets where user_id=uid for update;
if p_action='status' then perform pv_economy.adjust_market();return pv_economy.snapshot(uid);end if;
if p_action='quote' then
 if exists(select 1 from pv_economy.rounds where user_id=uid and status='active') then raise exception 'Finalize sua rodada antes de transferir';end if;
 amount:=(p_payload->>'amount')::bigint;kind:=p_payload->>'kind';opts:=coalesce(p_payload->'options','{}');
 if amount is null or amount<1 or amount>1000000 then raise exception 'Use uma quantidade inteira entre 1 e 1.000.000';end if;
 perform pv_economy.adjust_market();select * into m from pv_economy.market where id=true;
 select * into ap from public.album_progress where user_id=uid;select * into cp from public.clicker_progress where user_id=uid;
 needed:=ceil(w.principal*1.35);
 if kind='sticker' then
  i:=(opts->>'card')::integer;if i is null or i not between 1 and 111 then raise exception 'Figurinha inválida';end if;
  val:=pv_economy.card_value(i);if val=0 or coalesce((ap.owned->>i::text)::bigint,0)<amount then raise exception 'Você não possui essa quantidade de figurinhas';end if;
  beans:=amount*val;prev:=jsonb_build_object('remove_card',i,'copies',amount,'owned',ap.owned->i::text,'rarity',public.album_card_rarity(i),'beans',beans,'unit_value',val,'rate','1000000000');
 elsif kind='buy_clicker' then
  cost:=amount*m.rate;if cp.user_id is null or coalesce((cp.state->>'juice')::numeric,0)<cost then raise exception 'Moedas do Clicker insuficientes. Salve a partida e atualize';end if;
  beans:=amount;prev:=jsonb_build_object('beans',beans,'coins',cost::text,'rate',m.rate::text);
 elsif kind in('withdraw_album','withdraw_clicker') then
  if amount>w.balance then raise exception 'Feijões insuficientes';end if;
  if kind='withdraw_album' then
   if amount%10<>0 then raise exception 'O saque para o álbum deve ser múltiplo de 10 feijões';end if;
   if w.principal=0 or w.balance<needed then raise exception 'Atinja % feijões para liberar o saque do álbum',needed;end if;
   prev:=jsonb_build_object('beans',amount,'juice',amount/10,'rate','10 feijões = 1 suco','required',needed,'remaining',w.balance-amount,'next_required',ceil((w.balance-amount)*1.35));
  else if cp.user_id is null then raise exception 'Abra o Clicker e salve sua partida antes de converter';end if;lp:=pv_economy.lot_preview(uid,amount);prev:=lp||jsonb_build_object('beans',amount,'remaining',w.balance-amount,'next_required',ceil((w.balance-amount)*1.35));end if;
 elsif kind='game' then
  if amount>w.balance then raise exception 'Feijões insuficientes';end if;game:=opts->>'game';
  if game is null or game not in('mines','crash','double') then raise exception 'Jogo inválido';end if;
  if game='mines' and (opts->>'mines' is null or (opts->>'mines')::integer not in(3,5,10,20)) then raise exception 'Quantidade de minas inválida';end if;
  if game='double' and (opts->>'color' is null or opts->>'color' not in('red','white','black')) then raise exception 'Cor inválida';end if;
  prev:=jsonb_build_object('beans',amount,'game',game,'remaining',w.balance-amount);
 else raise exception 'Operação inválida';end if;
 if beans is not null and (beans>100000000 or w.balance+beans>100000000) then raise exception 'Limite de 100 milhões de feijões por carteira';end if;
 insert into pv_economy.quotes(user_id,kind,amount,options,wallet_revision,clicker_revision,market_version,preview) values(uid,kind,amount,opts,w.revision,cp.revision,m.version,prev) returning * into q;
 return jsonb_build_object('quote_id',q.id,'kind',kind,'preview',prev,'expires_at',q.expires_at,'snapshot',pv_economy.snapshot(uid));
elsif p_action='confirm' then
 select * into q from pv_economy.quotes where id=(p_payload->>'quote_id')::uuid and user_id=uid for update;
 if not found then raise exception 'Prévia não encontrada';end if;
 if q.result is not null then return q.result;end if;
 if q.expires_at<clock_timestamp() or q.wallet_revision<>w.revision then raise exception 'A prévia expirou ou o saldo mudou. Gere uma nova prévia';end if;
 if exists(select 1 from pv_economy.rounds where user_id=uid and status='active') then raise exception 'Finalize a rodada primeiro';end if;
 kind:=q.kind;amount:=q.amount;opts:=q.options;prev:=q.preview;
 if kind='sticker' then
  i:=(opts->>'card')::integer;select * into ap from public.album_progress where user_id=uid for update;
  val:=coalesce((ap.owned->>i::text)::bigint,0);if val<amount then raise exception 'Essa figurinha não está mais disponível';end if;
  update public.album_progress set owned=jsonb_set(owned,array[i::text],to_jsonb(val-amount)),updated_at=now() where user_id=uid;
  beans:=(prev->>'beans')::bigint;insert into pv_economy.lots(user_id,source,remaining,rate) values(uid,'sticker',beans,1000000000);
  update pv_economy.wallets set balance=balance+beans,principal=principal+beans,revision=revision+1 where user_id=uid;
 elsif kind='buy_clicker' then
  select * into cp from public.clicker_progress where user_id=uid for update;
  if cp.revision is distinct from q.clicker_revision then raise exception 'A partida do Clicker mudou. Atualize a prévia';end if;
  cost:=(prev->>'coins')::numeric;if (cp.state->>'juice')::numeric<cost then raise exception 'Moedas insuficientes';end if;
  update public.clicker_progress set state=jsonb_set(jsonb_set(state,'{juice}',to_jsonb((state->>'juice')::numeric-cost)),'{savedAt}',to_jsonb(floor(extract(epoch from clock_timestamp())*1000))),revision=revision+1,updated_at=now() where user_id=uid;
  beans:=amount;insert into pv_economy.lots(user_id,source,remaining,rate) values(uid,'clicker',beans,(prev->>'rate')::numeric);
  update pv_economy.wallets set balance=balance+beans,principal=principal+beans,revision=revision+1 where user_id=uid;
 elsif kind in('withdraw_album','withdraw_clicker') then
  if amount>w.balance then raise exception 'Feijões insuficientes';end if;
  if kind='withdraw_album' then
   if w.principal=0 or w.balance<ceil(w.principal*1.35) then raise exception 'Meta de 35%% ainda não atingida';end if;
   select * into ap from public.album_progress where user_id=uid for update;
   update public.album_progress set coins=coins+(amount/10)::integer,updated_at=now() where user_id=uid;
  else
   select * into cp from public.clicker_progress where user_id=uid for update;
   if cp.revision is distinct from q.clicker_revision then raise exception 'A partida mudou. Atualize a prévia';end if;
   cost:=(prev->>'coins')::numeric;
   update public.clicker_progress set state=jsonb_set(jsonb_set(state,'{juice}',to_jsonb((state->>'juice')::numeric+cost)),'{savedAt}',to_jsonb(floor(extract(epoch from clock_timestamp())*1000))),revision=revision+1,updated_at=now() where user_id=uid;
  end if;
  lots:=pv_economy.take_lots(uid,amount);beans:=-amount;
  update pv_economy.wallets set balance=balance-amount,principal=balance-amount,cycle=cycle+1,revision=revision+1 where user_id=uid;
 elsif kind='game' then
  lots:=pv_economy.take_lots(uid,amount);beans:=-amount;
  update pv_economy.wallets set balance=balance-amount,revision=revision+1 where user_id=uid;
  game:=opts->>'game';cells:=array(select generate_series(0,24));
  if game='mines' then for i in reverse 25..2 loop j:=pv_economy.rng(i)+1;temp:=cells[i];cells[i]:=cells[j];cells[j]:=temp;end loop;end if;
  mult:=least(100,greatest(1,floor((.97/(1-(pv_economy.rng(1000000)+1)::numeric/1000001))*100)/100));
  result_int:=pv_economy.rng(15);
  insert into pv_economy.rounds(user_id,game,stake,stake_lots,mines,mine_count,crash_point,color,result_number) values(uid,game,amount,lots,case when game='mines' then cells[1:(opts->>'mines')::integer] end,(opts->>'mines')::integer,mult,opts->>'color',result_int) returning id into rid;
 end if;
 select * into w from pv_economy.wallets where user_id=uid;
 insert into pv_economy.ledger(id,user_id,kind,bean_delta,balance_after,details) values(q.id,uid,kind,beans,w.balance,prev||jsonb_build_object('lots',lots,'round_id',rid,'cycle',w.cycle));
 if kind='game' and game='double' then
  if (case when result_int=0 then 'white' when result_int<=7 then 'red' else 'black' end)=opts->>'color' then mult:=case when result_int=0 then 14 else 2 end;else mult:=0;end if;
  perform pv_economy.finish_round(rid,floor(amount*mult)::bigint,mult);
 end if;
 outcome:=jsonb_build_object('completed',true,'kind',kind,'preview',prev,'round',case when rid is not null then pv_economy.round_view(rid) else null end,'snapshot',pv_economy.snapshot(uid));
 update pv_economy.quotes set result=outcome where id=q.id;return outcome;
end if;
raise exception 'Ação inválida';end $$;

create function pv_economy.game_action(p_request uuid,p_round uuid,p_action text,p_cell integer) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();w pv_economy.wallets;r pv_economy.rounds;a pv_economy.actions;outcome jsonb;m numeric:=1;i integer;won bigint;
begin if uid is null then raise exception 'Faça login';end if;if p_request is null then raise exception 'Identificador obrigatório';end if;
select * into w from pv_economy.wallets where user_id=uid for update;
select * into a from pv_economy.actions where id=p_request;
if found then if a.user_id<>uid or a.round_id<>p_round or a.action<>p_action or a.cell is distinct from p_cell then raise exception 'Identificador já utilizado';end if;return a.result;end if;
select * into r from pv_economy.rounds where id=p_round and user_id=uid for update;if not found then raise exception 'Rodada não encontrada';end if;
if r.status='active' then
 if r.game='crash' then
  m:=exp(extract(epoch from clock_timestamp()-r.started_at)*.14);
  if m>=r.crash_point then perform pv_economy.finish_round(r.id,0,r.crash_point);
  elsif p_action='cashout' then m:=floor(m*100)/100;perform pv_economy.finish_round(r.id,floor(r.stake*m)::bigint,m);
  elsif p_action<>'poll' then raise exception 'Ação inválida';end if;
 elsif r.game='mines' then
  if p_action='open' then
   if p_cell is null or p_cell not between 0 and 24 then raise exception 'Casa inválida';end if;
   if not p_cell=any(r.opened) then
    if p_cell=any(r.mines) then perform pv_economy.finish_round(r.id,0,0);
    else
     r.opened:=array_append(r.opened,p_cell);for i in 0..cardinality(r.opened)-1 loop m:=m*(25-i)::numeric/(25-r.mine_count-i);end loop;m:=floor(m*.97*100)/100;
     update pv_economy.rounds set opened=r.opened,multiplier=m where id=r.id;
     if cardinality(r.opened)=25-r.mine_count then perform pv_economy.finish_round(r.id,floor(r.stake*m)::bigint,m);end if;
    end if;
   end if;
  elsif p_action='cashout' then if cardinality(r.opened)=0 then raise exception 'Encontre pelo menos um caju';end if;perform pv_economy.finish_round(r.id,floor(r.stake*r.multiplier)::bigint,r.multiplier);
  else raise exception 'Ação inválida';end if;
 end if;
end if;
outcome:=jsonb_build_object('round',pv_economy.round_view(r.id),'snapshot',pv_economy.snapshot(uid));
insert into pv_economy.actions(id,user_id,round_id,action,cell,result) values(p_request,uid,p_round,p_action,p_cell,outcome);return outcome;end $$;

-- Exposed wrappers run as the caller; only authenticated, ownership-checking
-- entrypoints can call the privileged private operations.
revoke all on all functions in schema pv_economy from public,anon,authenticated;
grant execute on function pv_economy.gateway(text,jsonb),pv_economy.game_action(uuid,uuid,text,integer) to authenticated;
create function public.bean_economy(p_action text,p_payload jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$select pv_economy.gateway(p_action,p_payload)$$;
create function public.bean_game_action(p_request uuid,p_round uuid,p_action text,p_cell integer default null) returns jsonb language sql security invoker set search_path='' as $$select pv_economy.game_action(p_request,p_round,p_action,p_cell)$$;
revoke all on function public.bean_economy(text,jsonb),public.bean_game_action(uuid,uuid,text,integer) from public,anon;
grant execute on function public.bean_economy(text,jsonb),public.bean_game_action(uuid,uuid,text,integer) to authenticated;
notify pgrst,'reload schema';
