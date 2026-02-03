-- ============================================================================
-- CRITICAL FIX: Change UUID to TEXT for Chat & Message IDs
-- ============================================================================
-- INSTRUCTIONS: Run this ENTIRE script in your Supabase SQL Editor
-- This fixes the "invalid input syntax for type uuid" error
-- ============================================================================

-- STEP 1: Drop ALL RLS policies that might block the type change
-- ============================================================================

-- Drop all policies on chats table
DROP POLICY IF EXISTS "Users can view their chats" ON chats;
DROP POLICY IF EXISTS "Users can create chats" ON chats;
DROP POLICY IF EXISTS "Users can view typing in their chats" ON chat_typing;
DROP POLICY IF EXISTS "Users can update typing status" ON chat_typing;

-- Drop all policies on messages table
DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;

-- ============================================================================
-- STEP 2: Drop foreign key constraints
-- ============================================================================

-- Drop constraints in messages table
ALTER TABLE IF EXISTS messages 
  DROP CONSTRAINT IF EXISTS messages_chat_id_fkey CASCADE;

-- Drop constraints in chat_typing table
ALTER TABLE IF EXISTS chat_typing
  DROP CONSTRAINT IF EXISTS chat_typing_chat_id_fkey CASCADE;

-- Drop constraints in broadcast_deliveries table (if exists)
ALTER TABLE IF EXISTS broadcast_deliveries
  DROP CONSTRAINT IF EXISTS broadcast_deliveries_chat_id_fkey CASCADE,
  DROP CONSTRAINT IF EXISTS broadcast_deliveries_message_id_fkey CASCADE;

-- ============================================================================
-- STEP 3: Change column types from UUID to TEXT
-- ============================================================================

-- Fix chats table - change id from UUID to TEXT
ALTER TABLE IF EXISTS chats 
  ALTER COLUMN id TYPE TEXT USING id::TEXT;

-- Fix messages table - change id and chat_id from UUID to TEXT  
ALTER TABLE IF EXISTS messages 
  ALTER COLUMN id TYPE TEXT USING id::TEXT,
  ALTER COLUMN chat_id TYPE TEXT USING chat_id::TEXT;

-- Fix chat_typing table - change chat_id from UUID to TEXT
ALTER TABLE IF EXISTS chat_typing
  ALTER COLUMN chat_id TYPE TEXT USING chat_id::TEXT;

-- ============================================================================
-- STEP 4: Recreate foreign key constraints
-- ============================================================================

-- Add back foreign key for messages.chat_id -> chats.id
ALTER TABLE IF EXISTS messages
  ADD CONSTRAINT messages_chat_id_fkey 
  FOREIGN KEY (chat_id) 
  REFERENCES chats(id) 
  ON DELETE CASCADE;

-- Add back foreign key for chat_typing.chat_id -> chats.id
ALTER TABLE IF EXISTS chat_typing
  ADD CONSTRAINT chat_typing_chat_id_fkey
  FOREIGN KEY (chat_id)
  REFERENCES chats(id)
  ON DELETE CASCADE;

-- ============================================================================
-- STEP 5: Recreate RLS policies
-- ============================================================================

-- Chats table policies
CREATE POLICY "Users can view their chats"
  ON chats FOR SELECT TO authenticated
  USING (user1_id = auth.uid() OR user2_id = auth.uid());

CREATE POLICY "Users can create chats"
  ON chats FOR INSERT TO authenticated
  WITH CHECK (user1_id = auth.uid() OR user2_id = auth.uid());

-- Messages table policies
CREATE POLICY "Users can view messages in their chats"
  ON messages FOR SELECT TO authenticated
  USING (
    sender_id = auth.uid() OR 
    receiver_id = auth.uid()
  );

CREATE POLICY "Users can send messages"
  ON messages FOR INSERT TO authenticated
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can update their own messages"
  ON messages FOR UPDATE TO authenticated
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Users can delete their own messages"
  ON messages FOR DELETE TO authenticated
  USING (sender_id = auth.uid());

-- ============================================================================
-- STEP 4: Verify the changes
-- ============================================================================

-- Check chats table schema
SELECT 
  column_name, 
  data_type,
  character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'chats' 
  AND column_name IN ('id', 'user1_id', 'user2_id')
ORDER BY ordinal_position;

-- Check messages table schema
SELECT 
  column_name, 
  data_type,
  character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'messages' 
  AND column_name IN ('id', 'chat_id', 'sender_id', 'receiver_id')
ORDER BY ordinal_position;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
-- If you see TEXT for id and chat_id columns above, the fix was successful!
-- You can now use the messaging feature in your app.
-- ============================================================================
