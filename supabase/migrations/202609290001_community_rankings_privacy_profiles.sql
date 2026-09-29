create or replace function public.album_count_owned(p_owned jsonb, p_max_card integer)
returns smallint
language sql
immutable
parallel safe
set search_path = ''
as $$
  select count(*)::smallint
  from jsonb_each_text(coalesce(p_owned, '{}'::jsonb)) as item(card_id, quantity)
  where item.card_id ~ '^[0-9]+$'
    and item.card_id::integer between 1 and p_max_card
    and item.quantity ~ '^[0-9]+$'
    and item.quantity::integer > 0
$$;

alter table public.album_progress
  add column if not exists album_unique_stickers smallint
    generated always as (public.album_count_owned(owned, 110)) stored,
  add column if not exists total_unique_stickers smallint
    generated always as (public.album_count_owned(owned, 111)) stored;

create index if not exists album_progress_album_rank_idx
  on public.album_progress (album_unique_stickers desc, updated_at asc);
create index if not exists album_progress_total_rank_idx
  on public.album_progress (total_unique_stickers desc, updated_at asc);

alter table public.social_profiles
  add column if not exists bio text not null default '',
  add column if not exists accent_color text not null default '#b277ff',
  add column if not exists avatar_card integer,
  add column if not exists collection_visibility text not null default 'public',
  add column if not exists show_in_rankings boolean not null default true;

alter table public.social_profiles
  drop constraint if exists social_profiles_bio_check,
  add constraint social_profiles_bio_check check (char_length(bio) <= 160),
  drop constraint if exists social_profiles_accent_color_check,
  add constraint social_profiles_accent_color_check check (accent_color ~ '^#[0-9a-fA-F]{6}$'),
  drop constraint if exists social_profiles_avatar_card_check,
  add constraint social_profiles_avatar_card_check check (avatar_card between 1 and 111),
  drop constraint if exists social_profiles_collection_visibility_check,
  add constraint social_profiles_collection_visibility_check check (collection_visibility in ('public', 'friends', 'private'));

create index if not exists social_profiles_handle_search_idx
  on public.social_profiles (lower(handle) text_pattern_ops);
create index if not exists social_profiles_name_search_idx
  on public.social_profiles (lower(display_name) text_pattern_ops);

create table if not exists public.profile_blocks (
  blocker_id uuid not null references public.social_profiles(user_id) on delete cascade,
  blocked_id uuid not null references public.social_profiles(user_id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create index if not exists profile_blocks_blocked_idx on public.profile_blocks (blocked_id, blocker_id);
alter table public.profile_blocks enable row level security;

drop policy if exists "Users manage own blocks" on public.profile_blocks;
create policy "Users manage own blocks" on public.profile_blocks
for all to authenticated
using (auth.uid() = blocker_id)
with check (auth.uid() = blocker_id);

revoke all on table public.profile_blocks from anon, authenticated;
grant select, insert, delete on table public.profile_blocks to authenticated;

drop policy if exists "Users update own social profile" on public.social_profiles;
drop policy if exists "Users read friend albums" on public.album_progress;

create or replace function public.can_view_album(p_owner uuid, p_viewer uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_viewer is null then false
    when p_owner = p_viewer then true
    when exists (
      select 1 from public.profile_blocks b
      where (b.blocker_id = p_owner and b.blocked_id = p_viewer)
         or (b.blocker_id = p_viewer and b.blocked_id = p_owner)
    ) then false
    when coalesce((select s.collection_visibility from public.social_profiles s where s.user_id = p_owner), 'private') = 'public' then true
    when coalesce((select s.collection_visibility from public.social_profiles s where s.user_id = p_owner), 'private') = 'friends' then exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and ((f.requester_id = p_owner and f.addressee_id = p_viewer)
          or (f.addressee_id = p_owner and f.requester_id = p_viewer))
    )
    else false
  end
$$;

create or replace function public.album_leaderboard(p_sort text default 'stickers', p_limit integer default 50)
returns table (
  rank_position bigint,
  user_id uuid,
  handle text,
  display_name text,
  bio text,
  accent_color text,
  avatar_card integer,
  featured_card integer,
  sticker_count smallint,
  album_stickers smallint,
  completion_percent numeric,
  can_view_collection boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with ranked as (
    select
      s.user_id,
      s.handle,
      s.display_name,
      s.bio,
      s.accent_color,
      s.avatar_card,
      s.featured_card,
      p.total_unique_stickers as sticker_count,
      p.album_unique_stickers as album_stickers,
      round((p.album_unique_stickers::numeric / 110) * 100, 1) as completion_percent,
      public.can_view_album(s.user_id, auth.uid()) as can_view_collection
    from public.social_profiles s
    join public.album_progress p on p.user_id = s.user_id
    where s.show_in_rankings
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = s.user_id and b.blocked_id = auth.uid())
           or (b.blocker_id = auth.uid() and b.blocked_id = s.user_id)
      )
  )
  select
    row_number() over (
      order by
        case when p_sort = 'completion' then album_stickers else sticker_count end desc,
        case when p_sort = 'completion' then sticker_count else album_stickers end desc,
        lower(display_name), user_id
    ),
    ranked.*
  from ranked
  order by
    case when p_sort = 'completion' then album_stickers else sticker_count end desc,
    case when p_sort = 'completion' then sticker_count else album_stickers end desc,
    lower(display_name), user_id
  limit least(greatest(coalesce(p_limit, 50), 1), 100)
$$;

create or replace function public.search_album_users(p_query text, p_limit integer default 20)
returns table (
  user_id uuid,
  handle text,
  display_name text,
  bio text,
  accent_color text,
  avatar_card integer,
  featured_card integer,
  sticker_count smallint,
  completion_percent numeric,
  can_view_collection boolean,
  is_friend boolean,
  is_blocked_by_me boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with normalized as (
    select lower(trim(leading '@' from trim(coalesce(p_query, '')))) as term
  )
  select
    s.user_id,
    s.handle,
    s.display_name,
    s.bio,
    s.accent_color,
    s.avatar_card,
    s.featured_card,
    p.total_unique_stickers,
    round((p.album_unique_stickers::numeric / 110) * 100, 1),
    public.can_view_album(s.user_id, auth.uid()),
    exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and ((f.requester_id = auth.uid() and f.addressee_id = s.user_id)
          or (f.addressee_id = auth.uid() and f.requester_id = s.user_id))
    ),
    exists (
      select 1 from public.profile_blocks b
      where b.blocker_id = auth.uid() and b.blocked_id = s.user_id
    )
  from public.social_profiles s
  join public.album_progress p on p.user_id = s.user_id
  cross join normalized n
  where auth.uid() is not null
    and s.user_id <> auth.uid()
    and n.term <> ''
    and (lower(s.handle) like n.term || '%' or lower(s.display_name) like n.term || '%')
    and not exists (
      select 1 from public.profile_blocks b
      where b.blocker_id = s.user_id and b.blocked_id = auth.uid()
    )
  order by
    case when lower(s.handle) = n.term then 0 else 1 end,
    lower(s.handle), lower(s.display_name)
  limit least(greatest(coalesce(p_limit, 20), 1), 50)
$$;

create or replace function public.get_album_profile(p_user uuid)
returns table (
  user_id uuid,
  handle text,
  display_name text,
  bio text,
  accent_color text,
  avatar_card integer,
  featured_card integer,
  collection_visibility text,
  sticker_count smallint,
  album_stickers smallint,
  completion_percent numeric,
  can_view_collection boolean,
  is_friend boolean,
  is_blocked_by_me boolean,
  owned jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.user_id,
    s.handle,
    s.display_name,
    s.bio,
    s.accent_color,
    s.avatar_card,
    s.featured_card,
    s.collection_visibility,
    p.total_unique_stickers,
    p.album_unique_stickers,
    round((p.album_unique_stickers::numeric / 110) * 100, 1),
    allowed.can_view,
    exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and ((f.requester_id = auth.uid() and f.addressee_id = s.user_id)
          or (f.addressee_id = auth.uid() and f.requester_id = s.user_id))
    ),
    exists (
      select 1 from public.profile_blocks b
      where b.blocker_id = auth.uid() and b.blocked_id = s.user_id
    ),
    case when allowed.can_view then p.owned else null end
  from public.social_profiles s
  join public.album_progress p on p.user_id = s.user_id
  cross join lateral (select public.can_view_album(s.user_id, auth.uid()) as can_view) allowed
  where s.user_id = p_user
    and auth.uid() is not null
    and not exists (
      select 1 from public.profile_blocks b
      where b.blocker_id = s.user_id and b.blocked_id = auth.uid()
    )
  limit 1
$$;

create or replace function public.update_my_community_profile(
  p_handle text,
  p_display_name text,
  p_bio text,
  p_accent_color text,
  p_visibility text,
  p_show_in_rankings boolean,
  p_avatar_card integer default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  normalized_handle text := lower(trim(coalesce(p_handle, '')));
  clean_name text := trim(coalesce(p_display_name, ''));
  clean_bio text := trim(coalesce(p_bio, ''));
  owned_count integer;
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  if normalized_handle !~ '^[a-z0-9_]{3,24}$' then raise exception 'Use de 3 a 24 letras minúsculas, números ou _'; end if;
  if char_length(clean_name) not between 1 and 80 then raise exception 'O nome deve ter entre 1 e 80 caracteres'; end if;
  if char_length(clean_bio) > 160 then raise exception 'A bio pode ter no máximo 160 caracteres'; end if;
  if coalesce(p_accent_color, '') !~ '^#[0-9a-fA-F]{6}$' then raise exception 'Escolha uma cor válida'; end if;
  if p_visibility not in ('public', 'friends', 'private') then raise exception 'Privacidade inválida'; end if;
  if p_avatar_card is not null then
    select coalesce((owned ->> p_avatar_card::text)::integer, 0)
    into owned_count from public.album_progress where user_id = uid;
    if owned_count < 1 then raise exception 'Você só pode usar uma figurinha que possui como avatar'; end if;
  end if;

  update public.social_profiles
  set handle = normalized_handle,
      display_name = clean_name,
      bio = clean_bio,
      accent_color = lower(p_accent_color),
      collection_visibility = p_visibility,
      show_in_rankings = coalesce(p_show_in_rankings, true),
      avatar_card = p_avatar_card,
      updated_at = now()
  where user_id = uid;
  if not found then raise exception 'Perfil social não encontrado'; end if;

  update public.profiles set name = clean_name, updated_at = now() where id = uid;
exception
  when unique_violation then raise exception 'Este ID já está em uso. Escolha outro.';
end;
$$;

create or replace function public.set_profile_block(p_target uuid, p_block boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then raise exception 'Faça login para continuar'; end if;
  if p_target is null or p_target = uid then raise exception 'Usuário inválido'; end if;
  if not exists (select 1 from public.social_profiles where user_id = p_target) then raise exception 'Usuário não encontrado'; end if;

  if coalesce(p_block, false) then
    insert into public.profile_blocks (blocker_id, blocked_id)
    values (uid, p_target) on conflict do nothing;
    delete from public.friendships
    where (requester_id = uid and addressee_id = p_target)
       or (requester_id = p_target and addressee_id = uid);
    update public.sticker_trades
    set status = 'cancelled', resolved_at = now()
    where status = 'pending'
      and ((proposer_id = uid and recipient_id = p_target)
        or (proposer_id = p_target and recipient_id = uid));
  else
    delete from public.profile_blocks where blocker_id = uid and blocked_id = p_target;
  end if;
end;
$$;

revoke all on function public.album_count_owned(jsonb, integer) from public, anon, authenticated;
revoke all on function public.can_view_album(uuid, uuid) from public, anon, authenticated;
revoke all on function public.album_leaderboard(text, integer) from public, anon, authenticated;
revoke all on function public.search_album_users(text, integer) from public, anon, authenticated;
revoke all on function public.get_album_profile(uuid) from public, anon, authenticated;
revoke all on function public.update_my_community_profile(text, text, text, text, text, boolean, integer) from public, anon, authenticated;
revoke all on function public.set_profile_block(uuid, boolean) from public, anon, authenticated;

grant execute on function public.album_leaderboard(text, integer) to authenticated;
grant execute on function public.search_album_users(text, integer) to authenticated;
grant execute on function public.get_album_profile(uuid) to authenticated;
grant execute on function public.update_my_community_profile(text, text, text, text, text, boolean, integer) to authenticated;
grant execute on function public.set_profile_block(uuid, boolean) to authenticated;
