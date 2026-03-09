# Database Status & Supabase Schema

## Current status

- **Supabase** is used **only for authentication**:
  - Email/password sign up and sign in
  - Google OAuth
  - Session and redirect URL config in the dashboard

- **App data** (transactions, bills, goals, settings, etc.) is stored in a **local SQLite database** on the device, using **Drift**:
  - File: `sapling.sqlite` in the app’s documents directory
  - No cloud sync; data is device-only
  - All tables and repositories in the app read/write this local DB

So: **Supabase = auth + cloud data** when signed in; **Drift = local fallback** when signed out. All 12 repositories use Supabase when signed in.

---

## Supabase schema (for when you add a backend)

Below is a **PostgreSQL schema** you can run in the Supabase SQL Editor. It mirrors the app’s functionality and is designed for **multi-user, per-user data** with Row Level Security (RLS).

### Design choices

- Every user-scoped table has a `user_id` column referencing `auth.users(id)`.
- RLS policies ensure users only see and modify their own rows.
- Column types and names match the app’s Drift tables so you can later sync or migrate.
- Use the accompanying `supabase_schema.sql` (or the SQL block below) in **Supabase Dashboard → SQL Editor** to create tables and RLS.

### Tables

| Table | Purpose |
|-------|--------|
| `app_settings` | Single row per user: currency, payday/closeout options, onboarding flag |
| `categories` | Spending categories (system + user); optional user_id for user-created |
| `transactions` | Income and expense entries with date, amount, category, links to bills/splits |
| `goals` | Savings goals with target amount and date |
| `recurring_incomes` | Paychecks / recurring income and payday anchor |
| `bills` | Recurring bills with amount, frequency, next due, category |
| `persons` | People for “split with friends” |
| `split_entries` | A single split event (who paid, total, link to expense) |
| `split_shares` | Per-person share of a split |
| `daily_closeouts` | Daily budget closeout result (in/over budget) |
| `recovery_plans` | Overspend recovery plans |
| `scheduler_metadata` | Key-value store for scheduler state |

Run the SQL in **`docs/supabase_schema.sql`** in the Supabase Dashboard → SQL Editor to create these tables and enable RLS.

### Next steps (when you want cloud data)

1. Run `supabase_schema.sql` in your project’s SQL Editor.
2. Seed system categories (same IDs/names as in the app’s `_seedSystemCategories`) if you want them in Postgres.
3. In the Flutter app, add a data layer that uses the Supabase client (`supabase.from('transactions').select()`, etc.) with `user_id = auth.uid()` (or rely on RLS and omit `user_id` in queries).
4. Optionally keep Drift for offline-first and sync to Supabase when online (more work).
