create or replace function public.save_clicker_progress(
  p_state jsonb,
  p_expected_revision bigint
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  current_revision bigint;
  new_revision bigint;
begin
  if uid is null then
    raise exception 'Faça login para salvar o clicker';
  end if;

  if jsonb_typeof(p_state) is distinct from 'object'
     or pg_column_size(p_state) > 32768 then
    raise exception 'Progresso inválido ou grande demais';
  end if;

  if p_expected_revision is null or p_expected_revision < 0 then
    raise exception 'Revisão inválida';
  end if;

  -- Uma segunda aba do mesmo usuário não pode ocupar uma conexão aguardando
  -- a primeira terminar. O cliente mantém o progresso local e tenta novamente.
  select revision into current_revision
  from public.clicker_progress
  where user_id = uid
  for update nowait;

  if not found then
    if p_expected_revision <> 0 then
      raise exception 'Progresso alterado em outra sessão' using errcode = '40001';
    end if;

    insert into public.clicker_progress (user_id, state, revision)
    values (uid, p_state, 1);
    new_revision := 1;
  else
    if current_revision <> p_expected_revision then
      raise exception 'Progresso alterado em outra sessão' using errcode = '40001';
    end if;

    new_revision := current_revision + 1;
    update public.clicker_progress
    set state = p_state,
        revision = new_revision,
        updated_at = now()
    where user_id = uid;
  end if;

  return jsonb_build_object('revision', new_revision);
end;
$$;

revoke all on function public.save_clicker_progress(jsonb, bigint) from public;
grant execute on function public.save_clicker_progress(jsonb, bigint) to authenticated;
