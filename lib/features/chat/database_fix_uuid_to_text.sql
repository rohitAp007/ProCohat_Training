-- ============================================================================
-- CRITICAL FIX: Change UUID to TEXT for Chat & Message IDs
-- ============================================================================
-- INSTRUCTIONS: Run this ENTIRE script in your Supabase SQL Editor
-- This fixes the "invalid input syntax for type uuid" error
-- ============================================================================

-- STEP 1: Drop foreign key constraints that reference these columns
-- ============================================================================

-- Drop constraints in messages table
ALTER TABLE IF EXISTS messages 
  DROP CONSTRAINT IF EXISTS messages_chat_id_fkey CASCADE;

-- Drop constraints in broadcast_deliveries table (if exists)
ALTER TABLE IF EXISTS broadcast_deliveries
  DROP CONSTRAINT IF EXISTS broadcast_deliveries_chat_id_fkey CASCADE,
  DROP CONSTRAINT IF EXISTS broadcast_deliveries_message_id_fkey CASCADE;

-- ============================================================================
-- STEP 2: Change column types from UUID to TEXT
-- ============================================================================

-- Fix chats table - change id from UUID to TEXT
ALTER TABLE IF EXISTS chats 
  ALTER COLUMN id TYPE TEXT USING id::TEXT;

-- Fix messages table - change id and chat_id from UUID to TEXT  
ALTER TABLE IF EXISTS messages 
  ALTER COLUMN id TYPE TEXT USING id::TEXT,
  ALTER COLUMN chat_id TYPE TEXT USING chat_id::TEXT;

-- ============================================================================
-- STEP 3: Recreate foreign key constraints
-- ============================================================================

-- Add back foreign key for messages.chat_id -> chats.id
ALTER TABLE IF EXISTS messages
  ADD CONSTRAINT messages_chat_id_fkey 
  FOREIGN KEY (chat_id) 
  REFERENCES chats(id) 
  ON DELETE CASCADE;

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
