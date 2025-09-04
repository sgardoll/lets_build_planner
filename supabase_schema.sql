-- Updated Supabase schema with content type and outline fields
-- Run these SQL commands in your Supabase SQL editor

-- OPTION 1: If starting fresh (new database)
-- Create the content_items table with all required fields
CREATE TABLE IF NOT EXISTS content_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  url TEXT DEFAULT '',
  attachments TEXT[] DEFAULT '{}',
  date_scheduled TIMESTAMP WITH TIME ZONE,
  date_published TIMESTAMP WITH TIME ZONE,
  video_link TEXT DEFAULT '',
  is_private BOOLEAN DEFAULT false,
  content_type TEXT DEFAULT 'featureCentricTutorial' CHECK (content_type IN (
    'featureCentricTutorial',
    'comparative',
    'conceptualRedefinition',
    'blueprintSeries',
    'debugForensics'
  )),
  outline TEXT DEFAULT '',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- OPTION 2: If you have an existing content_items table (run these migration commands)
-- Add the new columns if they don't exist
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS content_type TEXT DEFAULT 'featureCentricTutorial';
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS outline TEXT DEFAULT '';

-- Add the constraint for content_type values
ALTER TABLE content_items ADD CONSTRAINT content_type_check 
CHECK (content_type IN (
  'featureCentricTutorial',
  'comparative',
  'conceptualRedefinition',
  'blueprintSeries',
  'debugForensics'
));

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS content_items_user_id_idx ON content_items(user_id);
CREATE INDEX IF NOT EXISTS content_items_date_scheduled_idx ON content_items(date_scheduled);
CREATE INDEX IF NOT EXISTS content_items_date_published_idx ON content_items(date_published);
CREATE INDEX IF NOT EXISTS content_items_content_type_idx ON content_items(content_type);
CREATE INDEX IF NOT EXISTS content_items_created_at_idx ON content_items(created_at);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a trigger to automatically update updated_at on row updates
CREATE TRIGGER update_content_items_updated_at 
  BEFORE UPDATE ON content_items 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE content_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own content items
CREATE POLICY "Users can view own content items" ON content_items
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own content items
CREATE POLICY "Users can insert own content items" ON content_items
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own content items
CREATE POLICY "Users can update own content items" ON content_items
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can only delete their own content items
CREATE POLICY "Users can delete own content items" ON content_items
  FOR DELETE USING (auth.uid() = user_id);

-- Allow public read access to non-private content items for sharing
CREATE POLICY "Public can view non-private content items" ON content_items
  FOR SELECT USING (is_private = false);

-- Grant necessary permissions
GRANT ALL ON content_items TO authenticated;
GRANT SELECT ON content_items TO anon;