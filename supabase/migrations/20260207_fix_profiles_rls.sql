-- Fix RLS: Allow users to insert their own profile
-- This is technically required for 'upsert' to work, as upsert is an INSERT ... ON CONFLICT
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;

CREATE POLICY "Users can insert their own profile" 
ON public.profiles FOR INSERT 
WITH CHECK (auth.uid() = id);

-- Ensure users can update their own fcm_token
-- The existing update policy should cover this, but we ensure it's there
-- Existing: create policy "Users can update their own profile." on public.profiles for update using (auth.uid() = id);
