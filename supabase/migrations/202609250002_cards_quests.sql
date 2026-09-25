alter table public.album_progress
  add column if not exists daily_activities jsonb not null default '{}'::jsonb,
  add column if not exists daily_activity_date date;

create or replace function public.album_card_rarity(p_card integer)
returns text
language sql immutable
as $$
  select case
    when p_card = any(array[5,12,110]) then 'secret'
    when p_card = any(array[4,102]) then 'legendary'
    when p_card = any(array[13,67,96,97]) then 'mythic'
    when p_card = any(array[1,11,17,18,19,24,26,38,95]) then 'epic'
    when p_card = any(array[10,20,21,22,23,27,49,54,60,61,69,71,72,73,74]) then 'rare'
    when p_card = any(array[7,9,16,25,28,31,32,33,34,36,37,39,40,41,42,43,47,48,53,55,58,62,63,64,70,75,76]) then 'uncommon'
    when p_card between 1 and 110 then 'common'
    else null
  end;
$$;

create or replace function public.random_album_card(p_rarity text)
returns integer
language sql volatile
as $$
  select card_id
  from generate_series(1,110) as card_id
  where public.album_card_rarity(card_id) = p_rarity
  order by random()
  limit 1;
$$;

create or replace function public.album_card_reward(p_card integer)
returns integer
language sql immutable
as $$
  select case public.album_card_rarity(p_card)
    when 'common' then 2
    when 'uncommon' then 4
    when 'rare' then 7
    when 'epic' then 12
    when 'mythic' then 20
    when 'legendary' then 35
    when 'secret' then 60
    else 0
  end;
$$;

create or replace function public.complete_daily_activity(p_activity text, p_score integer)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  today_local date := (now() at time zone 'America/Fortaleza')::date;
  activities jsonb;
  activity_date date;
  coin_balance integer;
  reward integer;
  minimum_score integer;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  if p_activity not in ('memory','quiz','caju') then raise exception 'Missão inválida'; end if;

  reward := case p_activity when 'memory' then 8 when 'quiz' then 6 else 10 end;
  minimum_score := case p_activity when 'memory' then 4 when 'quiz' then 1 else 5 end;
  if p_score < minimum_score then raise exception 'Complete o desafio antes de resgatar a recompensa'; end if;

  select daily_activities, daily_activity_date, coins
  into activities, activity_date, coin_balance
  from public.album_progress
  where user_id = uid
  for update;
  if not found then raise exception 'Álbum do usuário não encontrado'; end if;

  if activity_date is distinct from today_local then
    activities := '{}'::jsonb;
    activity_date := today_local;
  end if;
  if coalesce((activities ->> p_activity)::boolean, false) then
    raise exception 'Esta missão já foi concluída hoje';
  end if;

  activities := jsonb_set(activities, array[p_activity], 'true'::jsonb, true);
  coin_balance := coin_balance + reward;
  update public.album_progress
  set daily_activities = activities, daily_activity_date = activity_date,
      coins = coin_balance, updated_at = now()
  where user_id = uid;

  return jsonb_build_object(
    'activity', p_activity,
    'reward', reward,
    'coins', coin_balance,
    'activities', activities,
    'activity_date', activity_date
  );
end;
$$;

revoke all on function public.complete_daily_activity(text,integer) from public, anon;
grant execute on function public.complete_daily_activity(text,integer) to authenticated;
revoke all on function public.album_card_rarity(integer) from public, anon, authenticated;
revoke all on function public.random_album_card(text) from public, anon, authenticated;
revoke all on function public.album_card_reward(integer) from public, anon, authenticated;
