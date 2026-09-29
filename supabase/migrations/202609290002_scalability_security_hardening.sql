create index if not exists feed_posts_user_id_idx on public.feed_posts (user_id, created_at desc);
create index if not exists friendships_addressee_id_idx on public.friendships (addressee_id, status);
create index if not exists sticker_trades_proposer_id_idx on public.sticker_trades (proposer_id, status, created_at desc);
create index if not exists sticker_trades_recipient_id_idx on public.sticker_trades (recipient_id, status, created_at desc);

drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile" on public.profiles
for select to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists "Users update own profile" on public.profiles;
create policy "Users update own profile" on public.profiles
for update to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = id)
with check ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists "Users read own album" on public.album_progress;
create policy "Users read own album" on public.album_progress
for select to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

drop policy if exists "Users read own friendships" on public.friendships;
create policy "Users read own friendships" on public.friendships
for select to authenticated
using ((select auth.uid()) = requester_id or (select auth.uid()) = addressee_id);

drop policy if exists "Friends read feed posts" on public.feed_posts;
create policy "Friends read feed posts" on public.feed_posts
for select to authenticated
using (
  user_id = (select auth.uid()) or exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester_id = (select auth.uid()) and f.addressee_id = feed_posts.user_id)
        or (f.addressee_id = (select auth.uid()) and f.requester_id = feed_posts.user_id))
  )
);

drop policy if exists "Users delete own feed posts" on public.feed_posts;
create policy "Users delete own feed posts" on public.feed_posts
for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "Users read own trades" on public.sticker_trades;
create policy "Users read own trades" on public.sticker_trades
for select to authenticated
using ((select auth.uid()) = proposer_id or (select auth.uid()) = recipient_id);

drop policy if exists "Users manage own blocks" on public.profile_blocks;
create policy "Users manage own blocks" on public.profile_blocks
for all to authenticated
using ((select auth.uid()) = blocker_id)
with check ((select auth.uid()) = blocker_id);

alter function public.random_album_card(text) set search_path = public;
alter function public.choose_album_pack_tier() set search_path = public;
alter function public.album_card_rarity(integer) set search_path = public;
alter function public.album_card_reward(integer) set search_path = public;
alter function public.safe_social_handle(text, uuid) set search_path = public;
alter function public.album_theme_cards(text) set search_path = public;
alter function public.random_themed_album_card(text, text) set search_path = public;

revoke all on function public.create_social_profile_for_user() from public, anon, authenticated;
revoke all on function public.handle_new_album_user() from public, anon, authenticated;
revoke all on function public.rls_auto_enable() from public, anon, authenticated;
