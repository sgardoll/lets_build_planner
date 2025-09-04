-- StoryFlow Content Calendar Security Policies
-- This file defines Row Level Security (RLS) policies for all tables

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;

-- Users table policies
-- Allow users to be created during signup
CREATE POLICY "Users can be created during signup" ON public.users
    FOR INSERT WITH CHECK (true);

-- Allow users to view their own profile
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Allow users to delete their own profile
CREATE POLICY "Users can delete own profile" ON public.users
    FOR DELETE USING (auth.uid() = id);

-- Content items policies
-- Allow users to create their own content items
DROP POLICY IF EXISTS "Users can create own content items" ON public.content_items;
CREATE POLICY "Users can create own content items" ON public.content_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to view their own content items AND public content items from other users
DROP POLICY IF EXISTS "Users can view own content items" ON public.content_items;
CREATE POLICY "Users can view content items" ON public.content_items
    FOR SELECT USING (
        auth.uid() = user_id OR  -- Own content
        (is_private = false)     -- Public content from others
    );

-- Allow users to update their own content items only
DROP POLICY IF EXISTS "Users can update own content items" ON public.content_items;
CREATE POLICY "Users can update own content items" ON public.content_items
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Allow users to delete their own content items only
DROP POLICY IF EXISTS "Users can delete own content items" ON public.content_items;
CREATE POLICY "Users can delete own content items" ON public.content_items
    FOR DELETE USING (auth.uid() = user_id);

-- Allow anonymous users to view public content items (for shared views)
CREATE POLICY "Anonymous users can view public content items" ON public.content_items
    FOR SELECT USING (is_private = false);

-- Allow anonymous users to view user profiles (needed for shared views)
CREATE POLICY "Anonymous users can view user profiles" ON public.users
    FOR SELECT USING (true);