-- ============================================================================
-- DATABASE SCHEMA FIX FOR BROADCAST FEATURE
-- ============================================================================
-- ISSUE: Foreign key type mismatch in broadcast_deliveries table
-- The chat_id and message_id columns are TEXT in chats/messages tables
-- but the foreign key constraints were created with UUID assumption
-- 
-- RUN THIS IN YOUR SUPABASE SQL EDITOR TO FIX THE ISSUE
-- ============================================================================

-- Step 1: Drop the existing foreign key constraints
ALTER TABLE broadcast_deliveries 
DROP CONSTRAINT IF EXISTS broadcast_deliveries_chat_id_fkey;

ALTER TABLE broadcast_deliveries 
DROP CONSTRAINT IF EXISTS broadcast_deliveries_message_id_fkey;

-- Step 2: Alter column types to TEXT
ALTER TABLE broadcast_deliveries 
ALTER COLUMN chat_id TYPE TEXT;

ALTER TABLE broadcast_deliveries 
ALTER COLUMN message_id TYPE TEXT;

-- Step 3: Recreate the foreign key constraints with correct types
ALTER TABLE broadcast_deliveries
ADD CONSTRAINT broadcast_deliveries_chat_id_fkey
FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE;

ALTER TABLE broadcast_deliveries
ADD CONSTRAINT broadcast_deliveries_message_id_fkey
FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE;

-- Verify the fix
SELECT 
    column_name, 
    data_type 
FROM information_schema.columns 
WHERE table_name = 'broadcast_deliveries' 
AND column_name IN ('chat_id', 'message_id');

-- Expected output:
-- chat_id    | text
-- message_id | text
