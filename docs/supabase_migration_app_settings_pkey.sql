-- Migration: Fix app_settings primary key for multi-user support
-- Run this in Supabase Dashboard → SQL Editor if you get:
-- "duplicate key value violates unique constraint app_settings_pkey"
--
-- This changes the primary key from id to user_id so each user can have one row.

alter table public.app_settings drop constraint if exists app_settings_pkey;
alter table public.app_settings add primary key (user_id);
