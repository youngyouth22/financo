-- ============================================================================
-- 1. TABLE DEFINITION
-- ============================================================================
-- This table stores extended user information. 
-- The 'id' links directly to Supabase Auth (auth.users).
create table public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  full_name text,
  avatar_url text,
  fcm_token text,                 -- Used for Firebase Push Notifications
  plan_type text default 'free',  -- Used for RevenueCat subscription status (free/pro)
  updated_at timestamp with time zone default timezone('utc'::text, now()),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- ============================================================================
-- 2. ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Secure the table: users can only see and edit their own data.
alter table public.profiles enable row level security;

create policy "Users can view their own profile." 
  on public.profiles for select 
  using (auth.uid() = id);

create policy "Users can update their own profile." 
  on public.profiles for update 
  using (auth.uid() = id);

-- ============================================================================
-- 3. AUTOMATION: GMAIL METADATA EXTRACTION
-- ============================================================================
-- This function extracts 'name', 'avatar_url', and 'email' from the 
-- JSON metadata provided by Google (Gmail) or other OAuth providers.
create or replace function public.handle_new_user()
returns trigger as $$
declare
  raw_meta jsonb := new.raw_user_meta_data;
begin
  insert into public.profiles (id, full_name, avatar_url, email)
  values (
    new.id,
    coalesce(raw_meta->>'full_name', raw_meta->>'name', 'New User'), -- Tries Google Full Name
    coalesce(raw_meta->>'avatar_url', raw_meta->>'picture', ''),      -- Tries Google Profile Picture
    new.email
  );
  return new;
end;
$$ language plpgsql security definer;

-- ============================================================================
-- 4. TRIGGER
-- ============================================================================
-- Fires automatically every time a new user signs up in auth.users
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();