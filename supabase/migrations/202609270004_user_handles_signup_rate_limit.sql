create or replace function public.is_social_handle_available(p_handle text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select lower(trim(coalesce(p_handle, ''))) ~ '^[a-z0-9_]{3,24}$'
    and not exists (
      select 1 from public.social_profiles
      where handle = lower(trim(p_handle))
    )
$$;

create or replace function public.create_social_profile_for_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  requested_handle text;
begin
  select lower(trim(u.raw_user_meta_data ->> 'handle'))
  into requested_handle
  from auth.users u
  where u.id = new.id;

  if requested_handle is null or requested_handle !~ '^[a-z0-9_]{3,24}$' then
    requested_handle := public.safe_social_handle(new.name, new.id);
  end if;

  insert into public.social_profiles (user_id, handle, display_name)
  values (new.id, requested_handle, new.name);
  return new;
exception
  when unique_violation then
    raise exception 'Este ID já está em uso. Escolha outro.';
end;
$$;

create or replace function public.update_my_handle(p_handle text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  normalized text := lower(trim(coalesce(p_handle, '')));
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  if normalized !~ '^[a-z0-9_]{3,24}$' then
    raise exception 'Use de 3 a 24 letras minúsculas, números ou _';
  end if;

  update public.social_profiles
  set handle = normalized, updated_at = now()
  where user_id = uid;
  if not found then raise exception 'Perfil social não encontrado'; end if;
  return normalized;
exception
  when unique_violation then
    raise exception 'Este ID já está em uso. Escolha outro.';
end;
$$;

revoke all on function public.is_social_handle_available(text) from public, anon, authenticated;
grant execute on function public.is_social_handle_available(text) to anon, authenticated;
revoke all on function public.update_my_handle(text) from public, anon;
grant execute on function public.update_my_handle(text) to authenticated;
