-- Sapling Supabase (PostgreSQL) schema
-- Run in Supabase Dashboard → SQL Editor
-- Ensures app data is per-user and secured with RLS

-- Enable UUID extension if not already
create extension if not exists "uuid-ossp";

-- =============================================================================
-- APP SETTINGS (one row per user)
-- =============================================================================
create table public.app_settings (
  id text not null default 'singleton',
  user_id uuid primary key references auth.users(id) on delete cascade,
  base_currency text not null default 'cad',
  rollover_reset_type text not null default 'monthly',
  spending_baseline_days int not null default 30,
  allowance_default_mode text not null default 'paycheck',
  primary_goal_id text,
  payday_anchor_recurring_income_id text,
  default_payday_behavior text not null default 'confirm_actual_on_payday',
  payday_enabled boolean not null default true,
  bills_enabled boolean not null default true,
  overspend_enabled boolean not null default true,
  cycle_reset_enabled boolean not null default false,
  nightly_closeout_enabled boolean not null default true,
  nightly_closeout_time text not null default '21:00',
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =============================================================================
-- CATEGORIES (user_id nullable = system categories shared by all)
-- =============================================================================
create table public.categories (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  name text not null unique,
  default_label text not null default 'green',
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =============================================================================
-- TRANSACTIONS
-- =============================================================================
create table public.transactions (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  amount real not null,
  date timestamptz not null,
  category_id text references public.categories(id),
  label text,
  note text,
  linked_bill_id text,
  linked_recurring_income_id text,
  linked_split_entry_id text,
  income_posting_type text,
  source text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_transactions_user_date on public.transactions(user_id, date);
create index idx_transactions_user_type_date on public.transactions(user_id, type, date);
create index idx_transactions_linked_bill on public.transactions(linked_bill_id) where linked_bill_id is not null;

-- =============================================================================
-- GOALS
-- =============================================================================
create table public.goals (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  target_amount real not null,
  target_date timestamptz not null,
  saving_style text not null default 'natural',
  priority_order int not null default 0,
  is_archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =============================================================================
-- RECURRING INCOMES
-- =============================================================================
create table public.recurring_incomes (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  frequency text not null default 'monthly',
  next_payday_date timestamptz not null,
  expected_amount real,
  payday_behavior text not null default 'confirm_actual_on_payday',
  is_payday_anchor_eligible boolean not null default true,
  is_payday_anchor boolean not null default false,
  reminder_enabled boolean not null default false,
  reminder_time text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_recurring_incomes_user_next on public.recurring_incomes(user_id, next_payday_date);

-- =============================================================================
-- BILLS
-- =============================================================================
create table public.bills (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  amount real not null,
  frequency text not null default 'monthly',
  next_due_date timestamptz not null,
  category_id text not null,
  default_label text not null default 'green',
  autopay boolean not null default false,
  reminder_enabled boolean not null default true,
  reminder_lead_time_days int not null default 3,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_bills_user_next_due on public.bills(user_id, next_due_date);

-- =============================================================================
-- PERSONS (for splits / friends)
-- =============================================================================
create table public.persons (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  handle text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =============================================================================
-- SPLIT ENTRIES
-- =============================================================================
create table public.split_entries (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date timestamptz not null,
  description text not null,
  total_amount real not null,
  paid_by text not null references public.persons(id),
  link_to_expense_transaction_id text,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =============================================================================
-- SPLIT SHARES
-- =============================================================================
create table public.split_shares (
  id text primary key,
  split_entry_id text not null references public.split_entries(id) on delete cascade,
  person_id text not null references public.persons(id) on delete cascade,
  share_amount real not null
);

create index idx_split_shares_entry on public.split_shares(split_entry_id);

-- =============================================================================
-- DAILY CLOSEOUTS
-- =============================================================================
create table public.daily_closeouts (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null,
  result text not null,
  created_at timestamptz not null default now(),
  unique(user_id, date)
);

create index idx_daily_closeouts_user_date on public.daily_closeouts(user_id, date);

-- =============================================================================
-- RECOVERY PLANS
-- =============================================================================
create table public.recovery_plans (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  trigger_transaction_id text not null,
  overspend_amount real not null,
  plan_type text not null,
  parameters text not null default '{}',
  status text not null default 'active'
);

-- =============================================================================
-- SCHEDULER METADATA (key-value per user)
-- =============================================================================
create table public.scheduler_metadata (
  key text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  value text not null,
  primary key (key, user_id)
);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================
alter table public.app_settings enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.goals enable row level security;
alter table public.recurring_incomes enable row level security;
alter table public.bills enable row level security;
alter table public.persons enable row level security;
alter table public.split_entries enable row level security;
alter table public.split_shares enable row level security;
alter table public.daily_closeouts enable row level security;
alter table public.recovery_plans enable row level security;
alter table public.scheduler_metadata enable row level security;

-- Policies: users can only access their own rows (user_id = auth.uid())
-- split_shares: allow via split_entry ownership

create policy "app_settings_select" on public.app_settings for select using (auth.uid() = user_id);
create policy "app_settings_insert" on public.app_settings for insert with check (auth.uid() = user_id);
create policy "app_settings_update" on public.app_settings for update using (auth.uid() = user_id);

create policy "categories_select" on public.categories for select using (
  auth.uid() = user_id or is_system = true
);
create policy "categories_insert" on public.categories for insert with check (auth.uid() = user_id);
create policy "categories_update" on public.categories for update using (auth.uid() = user_id);

create policy "transactions_all" on public.transactions for all using (auth.uid() = user_id);

create policy "goals_all" on public.goals for all using (auth.uid() = user_id);
create policy "recurring_incomes_all" on public.recurring_incomes for all using (auth.uid() = user_id);
create policy "bills_all" on public.bills for all using (auth.uid() = user_id);
create policy "persons_all" on public.persons for all using (auth.uid() = user_id);
create policy "split_entries_all" on public.split_entries for all using (auth.uid() = user_id);

create policy "split_shares_select" on public.split_shares for select using (
  exists (select 1 from public.split_entries e where e.id = split_entry_id and e.user_id = auth.uid())
);
create policy "split_shares_insert" on public.split_shares for insert with check (
  exists (select 1 from public.split_entries e where e.id = split_entry_id and e.user_id = auth.uid())
);
create policy "split_shares_update" on public.split_shares for update using (
  exists (select 1 from public.split_entries e where e.id = split_entry_id and e.user_id = auth.uid())
);
create policy "split_shares_delete" on public.split_shares for delete using (
  exists (select 1 from public.split_entries e where e.id = split_entry_id and e.user_id = auth.uid())
);

create policy "daily_closeouts_all" on public.daily_closeouts for all using (auth.uid() = user_id);
create policy "recovery_plans_all" on public.recovery_plans for all using (auth.uid() = user_id);
create policy "scheduler_metadata_all" on public.scheduler_metadata for all using (auth.uid() = user_id);

-- Optional: trigger to set updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Apply to tables with updated_at
create trigger app_settings_updated before update on public.app_settings for each row execute function public.set_updated_at();
create trigger categories_updated before update on public.categories for each row execute function public.set_updated_at();
create trigger transactions_updated before update on public.transactions for each row execute function public.set_updated_at();
create trigger goals_updated before update on public.goals for each row execute function public.set_updated_at();
create trigger recurring_incomes_updated before update on public.recurring_incomes for each row execute function public.set_updated_at();
create trigger bills_updated before update on public.bills for each row execute function public.set_updated_at();
create trigger persons_updated before update on public.persons for each row execute function public.set_updated_at();
create trigger split_entries_updated before update on public.split_entries for each row execute function public.set_updated_at();

-- =============================================================================
-- SEED: System categories (run once; user_id null = shared)
-- =============================================================================
insert into public.categories (id, user_id, name, default_label, is_system) values
  ('cat_groceries', null, 'Groceries', 'green', true),
  ('cat_rent', null, 'Rent / Mortgage', 'green', true),
  ('cat_utilities', null, 'Utilities', 'green', true),
  ('cat_transport', null, 'Transportation', 'green', true),
  ('cat_dining', null, 'Dining Out', 'orange', true),
  ('cat_entertainment', null, 'Entertainment', 'orange', true),
  ('cat_shopping', null, 'Shopping', 'red', true),
  ('cat_subscriptions', null, 'Subscriptions', 'orange', true),
  ('cat_health', null, 'Health & Medical', 'green', true),
  ('cat_personal', null, 'Personal Care', 'orange', true),
  ('cat_other', null, 'Other', 'red', true)
on conflict (id) do nothing;
