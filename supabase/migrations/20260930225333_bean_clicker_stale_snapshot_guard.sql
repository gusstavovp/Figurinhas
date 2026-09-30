alter table public.clicker_progress add column bean_epoch bigint not null default 0;
alter table public.clicker_progress add constraint clicker_nonnegative_juice check(jsonb_typeof(state->'juice')='number' and (state->>'juice')::numeric>=0);
create function pv_economy.validate_clicker_transfer_epoch() returns trigger language plpgsql security invoker set search_path='' as $$
begin if coalesce((new.state->>'beanEpoch')::bigint,0)<>new.bean_epoch then raise exception 'O saldo foi alterado por uma transferência. Sincronize a partida' using errcode='40001';end if;return new;end $$;
revoke all on function pv_economy.validate_clicker_transfer_epoch() from public,anon,authenticated;
create trigger clicker_transfer_epoch before insert or update on public.clicker_progress for each row execute function pv_economy.validate_clicker_transfer_epoch();
create or replace function pv_economy.gateway(p_action text,p_payload jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
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
  update public.clicker_progress set state=jsonb_set(jsonb_set(jsonb_set(state,'{juice}',to_jsonb((state->>'juice')::numeric-cost)),'{savedAt}',to_jsonb(floor(extract(epoch from clock_timestamp())*1000))),'{beanEpoch}',to_jsonb(bean_epoch+1)),bean_epoch=bean_epoch+1,revision=revision+1,updated_at=now() where user_id=uid;
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
   update public.clicker_progress set state=jsonb_set(jsonb_set(jsonb_set(state,'{juice}',to_jsonb((state->>'juice')::numeric+cost)),'{savedAt}',to_jsonb(floor(extract(epoch from clock_timestamp())*1000))),'{beanEpoch}',to_jsonb(bean_epoch+1)),bean_epoch=bean_epoch+1,revision=revision+1,updated_at=now() where user_id=uid;
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
