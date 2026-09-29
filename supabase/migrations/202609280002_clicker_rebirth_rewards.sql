alter table public.album_progress
  add column if not exists clicker_rebirths integer not null default 0
  check (clicker_rebirths >= 0);

create or replace function public.claim_clicker_rebirth(p_rebirth_count integer)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  claimed_count integer;
  coin_balance integer;
  reward_amount integer := 0;
begin
  if uid is null then raise exception 'Faça login no Álbum Pedro Victor para receber a recompensa'; end if;
  if p_rebirth_count is null or p_rebirth_count < 1 or p_rebirth_count > 1000000 then
    raise exception 'Contagem de renascimentos inválida';
  end if;

  select clicker_rebirths, coins into claimed_count, coin_balance
  from public.album_progress where user_id = uid for update;
  if not found then raise exception 'Álbum do usuário não encontrado'; end if;

  if p_rebirth_count <= claimed_count then
    return jsonb_build_object('reward', 0, 'coins', coin_balance, 'rebirths', claimed_count, 'already_claimed', true);
  end if;

  -- Na primeira conexão, a contagem atual vira o ponto de partida. Depois disso,
  -- apenas o próximo renascimento pode ser resgatado, impedindo saltos de contagem.
  if claimed_count > 0 and p_rebirth_count <> claimed_count + 1 then
    raise exception 'Sincronize o próximo renascimento pelo clicker conectado ao álbum';
  end if;

  reward_amount := 10;
  coin_balance := coin_balance + reward_amount;
  update public.album_progress
  set clicker_rebirths = p_rebirth_count, coins = coin_balance, updated_at = now()
  where user_id = uid;

  return jsonb_build_object('reward', reward_amount, 'coins', coin_balance, 'rebirths', p_rebirth_count, 'already_claimed', false);
end;
$$;

revoke all on function public.claim_clicker_rebirth(integer) from public, anon;
grant execute on function public.claim_clicker_rebirth(integer) to authenticated;
