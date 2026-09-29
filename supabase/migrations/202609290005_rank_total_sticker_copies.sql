create or replace function public.album_count_copies(p_owned jsonb, p_max_card integer)
returns bigint
language sql
immutable
parallel safe
set search_path = ''
as $$
  select coalesce(sum(item.quantity::bigint), 0)::bigint
  from jsonb_each_text(coalesce(p_owned, '{}'::jsonb)) as item(card_id, quantity)
  where item.card_id ~ '^[0-9]+$'
    and item.card_id::integer between 1 and p_max_card
    and item.quantity ~ '^[0-9]{1,18}$'
    and item.quantity::bigint > 0
$$;

alter table public.album_progress
  add column if not exists total_sticker_copies bigint
    generated always as (public.album_count_copies(owned, 111)) stored;

create index if not exists album_progress_total_copies_rank_idx
  on public.album_progress (total_sticker_copies desc, album_unique_stickers desc, updated_at asc);

drop function if exists public.album_leaderboard(text, integer);

create function public.album_leaderboard(p_sort text default 'stickers', p_limit integer default 50)
returns table (
  rank_position bigint,
  user_id uuid,
  handle text,
  display_name text,
  bio text,
  accent_color text,
  avatar_card integer,
  featured_card integer,
  sticker_count bigint,
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
      p.total_sticker_copies as sticker_count,
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
        case when p_sort = 'completion' then album_stickers::bigint else sticker_count end desc,
        case when p_sort = 'completion' then sticker_count else album_stickers::bigint end desc,
        lower(display_name), user_id
    ),
    ranked.*
  from ranked
  order by
    case when p_sort = 'completion' then album_stickers::bigint else sticker_count end desc,
    case when p_sort = 'completion' then sticker_count else album_stickers::bigint end desc,
    lower(display_name), user_id
  limit least(greatest(coalesce(p_limit, 50), 1), 100)
$$;

revoke all on function public.album_count_copies(jsonb, integer) from public, anon, authenticated;
revoke all on function public.album_leaderboard(text, integer) from public, anon, authenticated;
grant execute on function public.album_leaderboard(text, integer) to authenticated;
