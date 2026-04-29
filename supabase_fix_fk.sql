-- Migration: Fix foreign key constraints on users and customers tables
-- The FK must reference auth.users(id), NOT public.users(id) or public.customers(id)
-- Run this in the Supabase SQL Editor.

-- ============================================================
-- 1. Fix the `users` (admin/staff) table
-- ============================================================

-- Drop the incorrect FK constraint
ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_id_fkey;

-- Add the correct FK pointing to auth.users(id)
ALTER TABLE public.users
  ADD CONSTRAINT users_id_fkey
  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- ============================================================
-- 2. Fix the `customers` table
-- ============================================================

-- Drop the incorrect FK constraint
ALTER TABLE public.customers
  DROP CONSTRAINT IF EXISTS customers_id_fkey;

-- Add the correct FK pointing to auth.users(id)
ALTER TABLE public.customers
  ADD CONSTRAINT customers_id_fkey
  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
