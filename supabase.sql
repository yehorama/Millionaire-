-- Supabase setup for the shared millionaire leaderboard
-- Create the table:
create table if not exists public.leaders (
  name text primary key,
  wins integer not null default 0 check (wins >= 0)
);

-- Public read access for the top-five leaderboard:
alter table public.leaders enable row level security;

create policy "public can read leaders"
on public.leaders for select
to anon
using (true);

-- Server-side increment function. The browser calls this instead of directly editing wins.
create or replace function public.record_million_win(player_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  player_name := trim(player_name);
  if length(player_name) < 2 or length(player_name) > 24 then
    raise exception 'Invalid name';
  end if;

  insert into public.leaders(name, wins)
  values (player_name, 1)
  on conflict (name)
  do update set wins = public.leaders.wins + 1;
end;
$$;

grant execute on function public.record_million_win(text) to anon;
