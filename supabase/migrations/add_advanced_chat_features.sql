-- ============================================================================
-- ADVANCED CHAT FEATURES - DATABASE SCHEMA
-- ============================================================================
-- Adds support for:
-- - Message delivery & read status
-- - Online/offline presence
-- - Multimedia attachments (images, videos, files)
-- - Unread message counts
-- ============================================================================

-- ============================================================================
-- STEP 1: Extend messages table for status & media
-- ============================================================================

-- Add message status tracking
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read')),
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- Add media attachment support
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS media_url TEXT,
  ADD COLUMN IF NOT EXISTS media_type TEXT CHECK (media_type IN ('image', 'video', 'file', 'audio', NULL)),
  ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
  ADD COLUMN IF NOT EXISTS file_name TEXT,
  ADD COLUMN IF NOT EXISTS file_size BIGINT;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_media_type ON messages(media_type) WHERE media_type IS NOT NULL;

-- ============================================================================
-- STEP 2: Extend profiles table for online presence
-- ============================================================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add index for online users
CREATE INDEX IF NOT EXISTS idx_profiles_online ON profiles(is_online) WHERE is_online = true;

-- ============================================================================
-- STEP 3: Create chat_metadata table for unread counts
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_metadata (
  chat_id TEXT PRIMARY KEY REFERENCES chats(id) ON DELETE CASCADE,
  user1_unread_count INT DEFAULT 0,
  user2_unread_count INT DEFAULT 0,
  user1_last_read TIMESTAMPTZ,
  user2_last_read TIMESTAMPTZ,
  last_message_id TEXT REFERENCES messages(id) ON DELETE SET NULL,
  last_message_preview TEXT,
  last_message_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add index for querying
CREATE INDEX IF NOT EXISTS idx_chat_metadata_last_message_time ON chat_metadata(last_message_time DESC);

-- Enable RLS
ALTER TABLE chat_metadata ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 4: Create RLS policies for chat_metadata
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their chat metadata" ON chat_metadata;
DROP POLICY IF EXISTS "Users can update their chat metadata" ON chat_metadata;
DROP POLICY IF EXISTS "Users can create chat metadata" ON chat_metadata;

-- Users can view metadata for their chats
CREATE POLICY "Users can view their chat metadata"
  ON chat_metadata FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chats
      WHERE chats.id = chat_metadata.chat_id
        AND (chats.user1_id = auth.uid() OR chats.user2_id = auth.uid())
    )
  );

-- Users can update metadata for their chats
CREATE POLICY "Users can update their chat metadata"
  ON chat_metadata FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chats
      WHERE chats.id = chat_metadata.chat_id
        AND (chats.user1_id = auth.uid() OR chats.user2_id = auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chats
      WHERE chats.id = chat_metadata.chat_id
        AND (chats.user1_id = auth.uid() OR chats.user2_id = auth.uid())
    )
  );

-- Users can insert metadata for their chats
CREATE POLICY "Users can create chat metadata"
  ON chat_metadata FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM chats
      WHERE chats.id = chat_metadata.chat_id
        AND (chats.user1_id = auth.uid() OR chats.user2_id = auth.uid())
    )
  );

-- ============================================================================
-- STEP 5: Create function to auto-update chat metadata
-- ============================================================================

CREATE OR REPLACE FUNCTION update_chat_metadata()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_chat_id TEXT;
  v_other_user_id UUID;
BEGIN
  -- Get chat_id from the message
  v_chat_id := NEW.chat_id;
  
  -- Determine the other user (receiver)
  v_other_user_id := NEW.receiver_id;
  
  -- Insert or update chat metadata
  INSERT INTO chat_metadata (
    chat_id,
    last_message_id,
    last_message_preview,
    last_message_time,
    user1_unread_count,
    user2_unread_count,
    updated_at
  )
  SELECT
    v_chat_id,
    NEW.id,
    CASE
      WHEN NEW.media_type IS NOT NULL THEN '📎 ' || COALESCE(NEW.file_name, 'Attachment')
      ELSE LEFT(NEW.message, 50)
    END,
    NEW.created_at,
    CASE WHEN c.user1_id = v_other_user_id THEN COALESCE(cm.user1_unread_count, 0) + 1 ELSE COALESCE(cm.user1_unread_count, 0) END,
    CASE WHEN c.user2_id = v_other_user_id THEN COALESCE(cm.user2_unread_count, 0) + 1 ELSE COALESCE(cm.user2_unread_count, 0) END,
    NOW()
  FROM chats c
  LEFT JOIN chat_metadata cm ON cm.chat_id = c.id
  WHERE c.id = v_chat_id
  ON CONFLICT (chat_id) DO UPDATE SET
    last_message_id = EXCLUDED.last_message_id,
    last_message_preview = EXCLUDED.last_message_preview,
    last_message_time = EXCLUDED.last_message_time,
    user1_unread_count = EXCLUDED.user1_unread_count,
    user2_unread_count = EXCLUDED.user2_unread_count,
    updated_at = EXCLUDED.updated_at;
  
  RETURN NEW;
END;
$$;

-- Create trigger to auto-update metadata on new message
DROP TRIGGER IF EXISTS on_message_created ON messages;

CREATE TRIGGER on_message_created
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_chat_metadata();

-- ============================================================================
-- STEP 6: Create function to mark messages as read
-- ============================================================================

CREATE OR REPLACE FUNCTION mark_messages_as_read(p_chat_id TEXT, p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update all unread messages in the chat
  UPDATE messages
  SET status = 'read',
      read_at = NOW()
  WHERE chat_id = p_chat_id
    AND receiver_id = p_user_id
    AND status != 'read';
  
  -- Reset unread count
  UPDATE chat_metadata cm
  SET 
    user1_unread_count = CASE WHEN c.user1_id = p_user_id THEN 0 ELSE cm.user1_unread_count END,
    user2_unread_count = CASE WHEN c.user2_id = p_user_id THEN 0 ELSE cm.user2_unread_count END,
    user1_last_read = CASE WHEN c.user1_id = p_user_id THEN NOW() ELSE cm.user1_last_read END,
    user2_last_read = CASE WHEN c.user2_id = p_user_id THEN NOW() ELSE cm.user2_last_read END,
    updated_at = NOW()
  FROM chats c
  WHERE cm.chat_id = p_chat_id
    AND c.id = p_chat_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION mark_messages_as_read(TEXT, UUID) TO authenticated;

-- ============================================================================
-- STEP 7: Verification queries
-- ============================================================================

-- Check new columns in messages table
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'messages'
  AND column_name IN ('status', 'delivered_at', 'read_at', 'media_url', 'media_type', 'file_name')
ORDER BY ordinal_position;

-- Check new columns in profiles table
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'profiles'
  AND column_name IN ('is_online', 'last_seen', 'fcm_token')
ORDER BY ordinal_position;

-- Check chat_metadata table was created
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'chat_metadata'
ORDER BY ordinal_position;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
-- ✅ Database schema extended successfully!
-- ✅ Message status tracking enabled
-- ✅ Online presence system ready
-- ✅ Multimedia support added
-- ✅ Unread count tracking configured
-- 
-- Next steps:
-- 1. Update Dart models to include new fields
-- 2. Implement read receipt UI
-- 3. Add online status indicators
-- 4. Integrate media upload/download
-- ============================================================================
