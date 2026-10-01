create or replace function public.bean_crash_status(p_round uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  r pv_economy.rounds;
  current_multiplier numeric;
begin
  if uid is null then
    raise exception 'Faça login';
  end if;

  select * into r
  from pv_economy.rounds
  where id = p_round
    and user_id = uid
    and game = 'crash'
  for update;

  if not found then
    raise exception 'Rodada não encontrada';
  end if;

  if r.status = 'active' then
    current_multiplier := exp(extract(epoch from clock_timestamp() - r.started_at) * .14);
    if current_multiplier >= r.crash_point then
      perform pv_economy.finish_round(r.id, 0, r.crash_point);
    end if;
  end if;

  return pv_economy.round_view(r.id);
end;
$$;

revoke all on function public.bean_crash_status(uuid) from public, anon;
grant execute on function public.bean_crash_status(uuid) to authenticated;
