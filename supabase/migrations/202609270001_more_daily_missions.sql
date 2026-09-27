create or replace function public.complete_daily_activity(p_activity text, p_score integer)
returns jsonb
language plpgsql
security definer
set search_path = public
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
  if uid is null then
    raise exception 'Faça login para continuar';
  end if;

  reward := case p_activity
    when 'memory' then 8
    when 'quiz' then 6
    when 'caju' then 10
    when 'rarity' then 7
    when 'sequence' then 9
    when 'order' then 11
    else 0
  end;
  minimum_score := case p_activity
    when 'memory' then 6
    when 'quiz' then 3
    when 'caju' then 10
    when 'rarity' then 4
    when 'sequence' then 5
    when 'order' then 8
    else 999
  end;

  if reward = 0 then
    raise exception 'Missão inválida';
  end if;
  if p_score < minimum_score then
    raise exception 'Complete o desafio antes de resgatar a recompensa';
  end if;

  select daily_activities, daily_activity_date, coins
  into activities, activity_date, coin_balance
  from public.album_progress
  where user_id = uid
  for update;

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
  set daily_activities = activities,
      daily_activity_date = activity_date,
      coins = coin_balance,
      updated_at = now()
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

revoke all on function public.complete_daily_activity(text, integer) from public, anon;
grant execute on function public.complete_daily_activity(text, integer) to authenticated;
