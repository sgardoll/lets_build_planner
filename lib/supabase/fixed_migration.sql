-- Fixed Supabase Migration
-- This file combines and fixes all schema and policy issues
-- Run this as a single migration to avoid conflicts

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own content" ON public.content_items;
DROP POLICY IF EXISTS "Users can insert own content" ON public.content_items;
DROP POLICY IF EXISTS "Users can update own content" ON public.content_items;
DROP POLICY IF EXISTS "Users can delete own content" ON public.content_items;
DROP POLICY IF EXISTS "Everyone can view public content" ON public.content_items;
DROP POLICY IF EXISTS "Users can create own content items" ON public.content_items;
DROP POLICY IF EXISTS "Users can view content items" ON public.content_items;
DROP POLICY IF EXISTS "Users can update own content items" ON public.content_items;
DROP POLICY IF EXISTS "Users can delete own content items" ON public.content_items;
DROP POLICY IF EXISTS "Anonymous users can view public content items" ON public.content_items;
DROP POLICY IF EXISTS "Users can view own content items" ON public.content_items;
DROP POLICY IF EXISTS "Users can be created during signup" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
DROP POLICY IF EXISTS "Anonymous users can view user profiles" ON public.users;
DROP POLICY IF EXISTS "Everyone can view user display names" ON public.users;

-- Drop existing triggers to avoid conflicts
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_content_items_updated_at ON public.content_items;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop existing functions to avoid conflicts
DROP FUNCTION IF EXISTS public.handle_updated_at();
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.create_missing_user_profiles();

-- Create tables if they don't exist
CREATE TABLE IF NOT EXISTS public.users (
    id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.content_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    url TEXT DEFAULT '',
    attachments TEXT[] DEFAULT '{}',
    date_scheduled TIMESTAMP WITH TIME ZONE,
    date_published TIMESTAMP WITH TIME ZONE,
    video_link TEXT DEFAULT '',
    is_private BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add is_private column if it doesn't exist (for existing databases)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'content_items' 
                   AND column_name = 'is_private' 
                   AND table_schema = 'public') THEN
        ALTER TABLE public.content_items ADD COLUMN is_private BOOLEAN DEFAULT false NOT NULL;
    END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_content_items_user_id ON public.content_items(user_id);
CREATE INDEX IF NOT EXISTS idx_content_items_date_scheduled ON public.content_items(date_scheduled);
CREATE INDEX IF NOT EXISTS idx_content_items_date_published ON public.content_items(date_published);
CREATE INDEX IF NOT EXISTS idx_content_items_created_at ON public.content_items(created_at);
CREATE INDEX IF NOT EXISTS idx_content_items_is_private ON public.content_items(is_private);

-- Create or replace trigger function for updating timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER update_content_items_updated_at
    BEFORE UPDATE ON public.content_items
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Enable RLS on tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can be created during signup" ON public.users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON public.users
    FOR DELETE USING (auth.uid() = id);

CREATE POLICY "Anonymous users can view user profiles" ON public.users
    FOR SELECT USING (true);

-- Content items policies
CREATE POLICY "Users can create own content items" ON public.content_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view content items" ON public.content_items
    FOR SELECT USING (
        auth.uid() = user_id OR  -- Own content
        (is_private = false)     -- Public content from others
    );

CREATE POLICY "Users can update own content items" ON public.content_items
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own content items" ON public.content_items
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Anonymous users can view public content items" ON public.content_items
    FOR SELECT USING (is_private = false);

-- Create function to handle automatic user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, display_name, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(COALESCE(NEW.email, ''), '@', 1), 'User'),
        COALESCE(NEW.created_at, NOW()),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = COALESCE(EXCLUDED.email, public.users.email),
        display_name = COALESCE(EXCLUDED.display_name, public.users.display_name),
        updated_at = NOW();
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth process
        RAISE WARNING 'Error creating user profile for %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user profile when user signs up
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Function to create missing user profiles for existing auth users
CREATE OR REPLACE FUNCTION public.create_missing_user_profiles()
RETURNS INTEGER AS $$
DECLARE
    created_count INTEGER := 0;
    auth_user RECORD;
BEGIN
    -- Loop through all auth users that don't have a public.users profile
    FOR auth_user IN 
        SELECT au.id, au.email, au.raw_user_meta_data, au.created_at
        FROM auth.users au
        LEFT JOIN public.users pu ON au.id = pu.id
        WHERE pu.id IS NULL
        AND au.id IS NOT NULL
    LOOP
        BEGIN
            INSERT INTO public.users (id, email, display_name, created_at, updated_at)
            VALUES (
                auth_user.id,
                COALESCE(auth_user.email, ''),
                COALESCE(auth_user.raw_user_meta_data->>'display_name', split_part(COALESCE(auth_user.email, ''), '@', 1), 'User'),
                COALESCE(auth_user.created_at, NOW()),
                NOW()
            )
            ON CONFLICT (id) DO NOTHING;
            created_count := created_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Failed to create profile for user %: %', auth_user.id, SQLERRM;
        END;
    END LOOP;
    
    RETURN created_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create missing profiles for any existing users
SELECT public.create_missing_user_profiles() AS profiles_created;