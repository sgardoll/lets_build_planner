-- StoryFlow Content Calendar Database Schema
-- This file defines the database structure for the content planning application

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table to store user profiles
CREATE TABLE IF NOT EXISTS public.users (
    id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    display_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    PRIMARY KEY (id)
);

-- Content items table for storing all content calendar items
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

-- Create indexes for better query performance
-- Note: These will only be created if the table exists and has the columns
DO $$
BEGIN
    -- Check if content_items table exists before creating indexes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'content_items' AND table_schema = 'public') THEN
        CREATE INDEX IF NOT EXISTS idx_content_items_user_id ON public.content_items(user_id);
        CREATE INDEX IF NOT EXISTS idx_content_items_date_scheduled ON public.content_items(date_scheduled);
        CREATE INDEX IF NOT EXISTS idx_content_items_date_published ON public.content_items(date_published);
        CREATE INDEX IF NOT EXISTS idx_content_items_created_at ON public.content_items(created_at);
        
        -- Only create is_private index if the column exists
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'content_items' AND column_name = 'is_private' AND table_schema = 'public') THEN
            CREATE INDEX IF NOT EXISTS idx_content_items_is_private ON public.content_items(is_private);
        END IF;
    END IF;
END $$;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update updated_at timestamps
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS update_content_items_updated_at ON public.content_items;
CREATE TRIGGER update_content_items_updated_at
    BEFORE UPDATE ON public.content_items
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();