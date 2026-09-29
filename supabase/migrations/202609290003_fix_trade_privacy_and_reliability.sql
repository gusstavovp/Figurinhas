create or replace function public.propose_sticker_trade(
  p_friend uuid,
  p_offered integer,
  p_requested integer
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  offered_count integer;
  requested_count integer;
  new_id bigint;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  if p_friend is null or p_friend = uid then raise exception 'Escolha um amigo válido'; end if;
  if p_offered not between 1 and 111 or p_requested not between 1 and 111 then
    raise exception 'Figurinha inválida';
  end if;
  if p_offered = p_requested then raise exception 'Escolha duas figurinhas diferentes'; end if;

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

  select coalesce((p.owned ->> p_offered::text)::integer, 0)
  into offered_count
  from public.album_progress p
  where p.user_id = uid;

  select coalesce((p.owned ->> p_requested::text)::integer, 0)
  into requested_count
  from public.album_progress p
  where p.user_id = p_friend;

  if offered_count < 1 then raise exception 'Você não possui a figurinha oferecida'; end if;
  if requested_count < 1 then raise exception 'Seu amigo não possui a figurinha pedida'; end if;

  insert into public.sticker_trades (
    proposer_id, recipient_id, offered_card_id, requested_card_id
  ) values (
    uid, p_friend, p_offered, p_requested
  ) returning id into new_id;

  return new_id;
end;
$$;

revoke all on function public.propose_sticker_trade(uuid, integer, integer) from public, anon, authenticated;
grant execute on function public.propose_sticker_trade(uuid, integer, integer) to authenticated;
