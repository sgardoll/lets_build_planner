-- Content Calendar Database Setup with RLS
-- Run these commands in your Supabase SQL editor

-- Enable RLS on content_items table
ALTER TABLE content_items ENABLE ROW LEVEL SECURITY;

-- Policy for authenticated users to see their own content
CREATE POLICY "Users can view own content" ON content_items
  FOR SELECT USING (auth.uid()::text = user_id);

-- Policy for authenticated users to insert their own content
CREATE POLICY "Users can insert own content" ON content_items
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- Policy for authenticated users to update their own content
CREATE POLICY "Users can update own content" ON content_items
  FOR UPDATE USING (auth.uid()::text = user_id) WITH CHECK (auth.uid()::text = user_id);

-- Policy for authenticated users to delete their own content
CREATE POLICY "Users can delete own content" ON content_items
  FOR DELETE USING (auth.uid()::text = user_id);

-- Policy for public viewing - allows everyone to see public (non-private) content
CREATE POLICY "Everyone can view public content" ON content_items
  FOR SELECT USING (is_private = false);

-- Create users table for user profiles (optional)
CREATE TABLE IF NOT EXISTS users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy for users to view their own profile
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Policy for users to update their own profile
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Policy to allow everyone to view user display names (for sharing features)
CREATE POLICY "Everyone can view user display names" ON users
  FOR SELECT USING (true);

-- Content items table structure (for reference)
-- Make sure your content_items table has these columns:
/*
CREATE TABLE content_items (
  id TEXT PRIMARY KEY,
  user_id TEXT REFERENCES auth.users(id) NOT NULL,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  url TEXT DEFAULT '',
  attachments JSONB DEFAULT '[]',
  date_scheduled TIMESTAMP WITH TIME ZONE,
  date_published TIMESTAMP WITH TIME ZONE,
  video_link TEXT DEFAULT '',
  is_private BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
*/

-- Add is_private column if it doesn't exist
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS update_content_items_updated_at ON content_items;
CREATE TRIGGER update_content_items_updated_at
    BEFORE UPDATE ON content_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();