alter table pv_economy.rounds drop constraint if exists rounds_game_check;
alter table pv_economy.rounds add constraint rounds_game_check check (game in ('mines','crash','double','slots','coinflip'));
alter table pv_economy.rounds add column if not exists game_result jsonb;

create or replace function pv_economy.round_view(rid uuid) returns jsonb
language plpgsql stable set search_path='' as $$
declare r pv_economy.rounds;
begin
  select * into r from pv_economy.rounds where id=rid;
  return jsonb_build_object(
    'id',r.id,'game',r.game,'stake',r.stake,'status',r.status,'opened',r.opened,
    'mine_count',r.mine_count,'multiplier',r.multiplier,'started_at',r.started_at,
    'server_time',clock_timestamp(),'win',r.win,'color',r.color,
    'result_number',case when r.status<>'active' then r.result_number end,
    'mines',case when r.status<>'active' then to_jsonb(r.mines) end,
    'game_result',case when r.status<>'active' then r.game_result end
  );
end $$;

create or replace function pv_economy.rebase_principal_after_deposit() returns trigger
language plpgsql security invoker set search_path='' as $$
begin
  if new.balance > old.balance and new.principal > old.principal then
    new.principal := new.balance;
  end if;
  return new;
end $$;

drop trigger if exists wallet_rebase_principal_after_deposit on pv_economy.wallets;
create trigger wallet_rebase_principal_after_deposit
before update on pv_economy.wallets
for each row execute function pv_economy.rebase_principal_after_deposit();

create or replace function pv_economy.instant_game(p_request uuid,p_game text,p_stake bigint,p_choice text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  uid uuid:=auth.uid();
  w pv_economy.wallets;
  existing pv_economy.rounds;
  lots jsonb;
  r1 integer;
  r2 integer;
  r3 integer;
  s1 text;
  s2 text;
  s3 text;
  result_side text;
  mult numeric:=0;
  won bigint:=0;
  details jsonb;
begin
  if uid is null then raise exception 'Entre com sua conta do álbum'; end if;
  if p_request is null then raise exception 'Identificador da rodada ausente'; end if;
  if p_game not in ('slots','coinflip') then raise exception 'Jogo instantâneo inválido'; end if;
  if p_stake is null or p_stake<1 or p_stake>1000000 then raise exception 'Use uma aposta inteira entre 1 e 1.000.000'; end if;
  if p_game='coinflip' and p_choice not in ('heads','tails') then raise exception 'Escolha Pedro ou Caju'; end if;

  select * into existing from pv_economy.rounds where id=p_request;
  if found then
    if existing.user_id<>uid then raise exception 'Rodada inválida'; end if;
    return jsonb_build_object('round',pv_economy.round_view(existing.id),'snapshot',pv_economy.snapshot(uid));
  end if;

  insert into pv_economy.wallets(user_id) values(uid) on conflict do nothing;
  select * into w from pv_economy.wallets where user_id=uid for update;
  if exists(select 1 from pv_economy.rounds where user_id=uid and status='active') then raise exception 'Finalize sua rodada atual primeiro'; end if;
  if p_stake>w.balance then raise exception 'Feijões insuficientes'; end if;

  lots:=pv_economy.take_lots(uid,p_stake);
  update pv_economy.wallets set balance=balance-p_stake,revision=revision+1 where user_id=uid returning * into w;
  insert into pv_economy.ledger(id,user_id,kind,bean_delta,balance_after,details)
  values(gen_random_uuid(),uid,'game',-p_stake,w.balance,jsonb_build_object('game',p_game,'stake',p_stake));

  if p_game='slots' then
    r1:=pv_economy.rng(100);r2:=pv_economy.rng(100);r3:=pv_economy.rng(100);
    s1:=case when r1<35 then '🧃' when r1<60 then '🍊' when r1<80 then '⭐' when r1<94 then '👑' else '🐯' end;
    s2:=case when r2<35 then '🧃' when r2<60 then '🍊' when r2<80 then '⭐' when r2<94 then '👑' else '🐯' end;
    s3:=case when r3<35 then '🧃' when r3<60 then '🍊' when r3<80 then '⭐' when r3<94 then '👑' else '🐯' end;
    if s1=s2 and s2=s3 then
      mult:=case s1 when '🧃' then 2.5 when '🍊' then 4 when '⭐' then 7 when '👑' then 12 else 50 end;
      details:=jsonb_build_object('symbols',jsonb_build_array(s1,s2,s3),'label','Trinca');
    elsif s1=s2 or s1=s3 or s2=s3 then
      mult:=1.3;
      details:=jsonb_build_object('symbols',jsonb_build_array(s1,s2,s3),'label','Par');
    else
      details:=jsonb_build_object('symbols',jsonb_build_array(s1,s2,s3),'label','Sem prêmio');
    end if;
  else
    result_side:=case when pv_economy.rng(2)=0 then 'heads' else 'tails' end;
    if result_side=p_choice then mult:=1.9; end if;
    details:=jsonb_build_object('result',result_side,'choice',p_choice,'label',case when mult>0 then 'Acertou' else 'Errou' end);
  end if;

  won:=floor(p_stake*mult)::bigint;
  insert into pv_economy.rounds(id,user_id,game,stake,stake_lots,multiplier,status,game_result)
  values(p_request,uid,p_game,p_stake,lots,mult,'active',details);
  perform pv_economy.finish_round(p_request,won,mult);
  return jsonb_build_object('round',pv_economy.round_view(p_request),'snapshot',pv_economy.snapshot(uid));
end $$;

revoke all on function pv_economy.rebase_principal_after_deposit() from public,anon,authenticated;
revoke all on function pv_economy.instant_game(uuid,text,bigint,text) from public,anon,authenticated;
grant execute on function pv_economy.instant_game(uuid,text,bigint,text) to authenticated;

create or replace function public.bean_instant_game(p_request uuid,p_game text,p_stake bigint,p_choice text default null)
returns jsonb language sql security invoker set search_path='' as $$
  select pv_economy.instant_game(p_request,p_game,p_stake,p_choice)
$$;
revoke all on function public.bean_instant_game(uuid,text,bigint,text) from public,anon;
grant execute on function public.bean_instant_game(uuid,text,bigint,text) to authenticated;
