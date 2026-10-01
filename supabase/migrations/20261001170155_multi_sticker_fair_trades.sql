create or replace function public.trade_card_value(p_card_id integer)
returns integer
language sql
immutable
strict
set search_path = ''
as $$
  select case
    when p_card_id = 111 then 40
    when p_card_id = any (array[5,12,110]) then 25
    when p_card_id = any (array[4,67,102,109]) then 17
    when p_card_id = any (array[13,38,54,69,95,96,97]) then 11
    when p_card_id = any (array[1,11,17,18,19,24,26,27,49,60,61,84,85,88]) then 7
    when p_card_id = any (array[10,20,21,22,23,41,43,48,53,62,63,64,70,71,72,73,74,76,86,87,94]) then 4
    when p_card_id = any (array[7,9,16,25,28,31,32,33,34,36,37,39,40,42,47,55,58,66,68,75,77,78,79,80,81,83]) then 2
    when p_card_id between 1 and 110 then 1
    else 0
  end
$$;

create or replace function public.trade_cards_valid(p_cards integer[])
returns boolean
language sql
immutable
set search_path = ''
as $$
  select p_cards is not null
    and cardinality(p_cards) between 1 and 5
    and cardinality(p_cards) = (select count(distinct card_id) from unnest(p_cards) card_id)
    and not exists (select 1 from unnest(p_cards) card_id where card_id not between 1 and 111)
$$;

create or replace function public.trade_bundle_value(p_cards integer[])
returns integer
language sql
immutable
set search_path = ''
as $$
  select coalesce(sum(public.trade_card_value(card_id)), 0)::integer
  from unnest(p_cards) card_id
$$;

create or replace function public.trade_bundle_is_fair(p_offered integer[], p_requested integer[])
returns boolean
language sql
immutable
set search_path = ''
as $$
  select public.trade_cards_valid(p_offered)
    and public.trade_cards_valid(p_requested)
    and not (p_offered && p_requested)
    and least(public.trade_bundle_value(p_offered), public.trade_bundle_value(p_requested)) * 100
      >= greatest(public.trade_bundle_value(p_offered), public.trade_bundle_value(p_requested)) * 65
$$;

alter table public.sticker_trades
  add column if not exists offered_card_ids integer[],
  add column if not exists requested_card_ids integer[];

update public.sticker_trades
set offered_card_ids = array[offered_card_id],
    requested_card_ids = array[requested_card_id]
where offered_card_ids is null or requested_card_ids is null;

alter table public.sticker_trades
  alter column offered_card_ids set not null,
  alter column requested_card_ids set not null,
  alter column offered_card_id drop not null,
  alter column requested_card_id drop not null;

alter table public.sticker_trades
  drop constraint if exists sticker_trades_bundle_shape_check,
  add constraint sticker_trades_bundle_shape_check check (
    public.trade_cards_valid(offered_card_ids)
    and public.trade_cards_valid(requested_card_ids)
  ),
  drop constraint if exists sticker_trades_bundle_fairness_check,
  add constraint sticker_trades_bundle_fairness_check check (
    public.trade_bundle_is_fair(offered_card_ids, requested_card_ids)
  ) not valid;

create or replace function public.propose_sticker_trade(
  p_friend uuid,
  p_offered_cards integer[],
  p_requested_cards integer[]
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  proposer_owned jsonb;
  recipient_owned jsonb;
  card_id integer;
  new_id bigint;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  if p_friend is null or p_friend = uid then raise exception 'Escolha um amigo válido'; end if;
  if not public.trade_cards_valid(p_offered_cards) or not public.trade_cards_valid(p_requested_cards) then
    raise exception 'Escolha de 1 a 5 figurinhas diferentes em cada lado';
  end if;
  if p_offered_cards && p_requested_cards then
    raise exception 'A mesma figurinha não pode aparecer nos dois lados';
  end if;
  if not public.trade_bundle_is_fair(p_offered_cards, p_requested_cards) then
    raise exception 'Troca desequilibrada: o menor lado precisa valer pelo menos 65%% do maior';
  end if;
  if not exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester_id = uid and f.addressee_id = p_friend)
        or (f.addressee_id = uid and f.requester_id = p_friend))
  ) then
    raise exception 'As trocas só podem ser feitas entre amigos';
  end if;
  if not public.can_view_album(p_friend, uid) then
    raise exception 'Este amigo não permitiu acesso à coleção dele';
  end if;

  select p.owned into proposer_owned from public.album_progress p where p.user_id = uid;
  select p.owned into recipient_owned from public.album_progress p where p.user_id = p_friend;
  foreach card_id in array p_offered_cards loop
    if coalesce((proposer_owned ->> card_id::text)::integer, 0) < 1 then
      raise exception 'Você não possui uma das figurinhas oferecidas';
    end if;
  end loop;
  foreach card_id in array p_requested_cards loop
    if coalesce((recipient_owned ->> card_id::text)::integer, 0) < 1 then
      raise exception 'Seu amigo não possui uma das figurinhas pedidas';
    end if;
  end loop;

  insert into public.sticker_trades (
    proposer_id, recipient_id, offered_card_id, requested_card_id, offered_card_ids, requested_card_ids
  ) values (
    uid, p_friend, null, null, p_offered_cards, p_requested_cards
  ) returning id into new_id;
  return new_id;
end;
$$;

create or replace function public.propose_sticker_trade(p_friend uuid, p_offered integer, p_requested integer)
returns bigint
language sql
security invoker
set search_path = ''
as $$
  select public.propose_sticker_trade(p_friend, array[p_offered], array[p_requested])
$$;

create or replace function public.respond_sticker_trade(p_trade_id bigint, p_accept boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  trade_record public.sticker_trades%rowtype;
  proposer_owned jsonb;
  recipient_owned jsonb;
  card_id integer;
  card_count integer;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  select * into trade_record
  from public.sticker_trades
  where id = p_trade_id and recipient_id = uid and status = 'pending'
  for update;
  if not found then raise exception 'Troca não encontrada'; end if;
  if not p_accept then
    update public.sticker_trades set status = 'rejected', resolved_at = now() where id = trade_record.id;
    return;
  end if;
  if not public.trade_bundle_is_fair(trade_record.offered_card_ids, trade_record.requested_card_ids) then
    raise exception 'Esta troca não atende mais às regras de equilíbrio';
  end if;

  perform 1 from public.album_progress
  where user_id in (trade_record.proposer_id, trade_record.recipient_id)
  order by user_id for update;
  select owned into proposer_owned from public.album_progress where user_id = trade_record.proposer_id;
  select owned into recipient_owned from public.album_progress where user_id = trade_record.recipient_id;

  foreach card_id in array trade_record.offered_card_ids loop
    card_count := coalesce((proposer_owned ->> card_id::text)::integer, 0);
    if card_count < 1 then raise exception 'Uma figurinha oferecida não está mais disponível'; end if;
    proposer_owned := jsonb_set(proposer_owned, array[card_id::text], to_jsonb(card_count - 1), true);
    recipient_owned := jsonb_set(recipient_owned, array[card_id::text], to_jsonb(coalesce((recipient_owned ->> card_id::text)::integer, 0) + 1), true);
  end loop;
  foreach card_id in array trade_record.requested_card_ids loop
    card_count := coalesce((recipient_owned ->> card_id::text)::integer, 0);
    if card_count < 1 then raise exception 'Uma figurinha pedida não está mais disponível'; end if;
    recipient_owned := jsonb_set(recipient_owned, array[card_id::text], to_jsonb(card_count - 1), true);
    proposer_owned := jsonb_set(proposer_owned, array[card_id::text], to_jsonb(coalesce((proposer_owned ->> card_id::text)::integer, 0) + 1), true);
  end loop;

  update public.album_progress set owned = proposer_owned, updated_at = now() where user_id = trade_record.proposer_id;
  update public.album_progress set owned = recipient_owned, updated_at = now() where user_id = trade_record.recipient_id;
  update public.sticker_trades set status = 'accepted', resolved_at = now() where id = trade_record.id;
end;
$$;

revoke all on function public.trade_card_value(integer) from public, anon, authenticated;
revoke all on function public.trade_cards_valid(integer[]) from public, anon, authenticated;
revoke all on function public.trade_bundle_value(integer[]) from public, anon, authenticated;
revoke all on function public.trade_bundle_is_fair(integer[], integer[]) from public, anon, authenticated;
revoke all on function public.propose_sticker_trade(uuid, integer[], integer[]) from public, anon, authenticated;
revoke all on function public.propose_sticker_trade(uuid, integer, integer) from public, anon, authenticated;
revoke all on function public.respond_sticker_trade(bigint, boolean) from public, anon, authenticated;
grant execute on function public.propose_sticker_trade(uuid, integer[], integer[]) to authenticated;
grant execute on function public.propose_sticker_trade(uuid, integer, integer) to authenticated;
grant execute on function public.respond_sticker_trade(bigint, boolean) to authenticated;
