-- =============================================================================
-- PLANT STATES (one row per user — streak-based plant growth system)
-- =============================================================================
-- Run in Supabase Dashboard → SQL Editor

create table if not exists public.plant_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  growth_points int not null default 0,
  health_score int not null default 100,
  longest_streak int not null default 0,
  days_at_zero int not null default 0,
  last_evaluated_date date not null default current_date,
  plant_species text not null default 'default',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.plant_states enable row level security;

create policy "plant_states_all" on public.plant_states
  for all using (auth.uid() = user_id);

-- Auto-update timestamp
create trigger plant_states_updated
  before update on public.plant_states
  for each row execute function public.set_updated_at();
