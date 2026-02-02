-- ============================================================================
-- SUPABASE DATABASE SCHEMA FOR BROADCAST FEATURE
-- ============================================================================
-- INSTRUCTIONS: Run this SQL in your Supabase SQL Editor
-- ============================================================================

-- Table 1: broadcast_lists
CREATE TABLE IF NOT EXISTS broadcast_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  recipient_count INTEGER DEFAULT 0,
  last_broadcast_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_broadcast_lists_owner_id 
ON broadcast_lists(owner_id);

CREATE INDEX IF NOT EXISTS idx_broadcast_lists_updated_at 
ON broadcast_lists(updated_at DESC);

-- Table 2: broadcast_recipients
CREATE TABLE IF NOT EXISTS broadcast_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broadcast_list_id UUID NOT NULL REFERENCES broadcast_lists(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipient_name TEXT,
  recipient_avatar TEXT,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(broadcast_list_id, recipient_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_broadcast_recipients_list_id 
ON broadcast_recipients(broadcast_list_id);

CREATE INDEX IF NOT EXISTS idx_broadcast_recipients_recipient_id 
ON broadcast_recipients(recipient_id);

-- Table 3: broadcast_messages
CREATE TABLE IF NOT EXISTS broadcast_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broadcast_list_id UUID NOT NULL REFERENCES broadcast_lists(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT,
  media_url TEXT,
  total_recipients INTEGER NOT NULL DEFAULT 0,
  delivered_count INTEGER DEFAULT 0,
  read_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_broadcast_messages_list_id 
ON broadcast_messages(broadcast_list_id);

CREATE INDEX IF NOT EXISTS idx_broadcast_messages_created_at 
ON broadcast_messages(created_at DESC);

-- Table 4: broadcast_deliveries
-- NOTE: chat_id and message_id are TEXT (not UUID) to match chats and messages tables
-- We don't add foreign key constraints here because chats/messages tables use TEXT IDs
CREATE TABLE IF NOT EXISTS broadcast_deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broadcast_message_id UUID NOT NULL REFERENCES broadcast_messages(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chat_id TEXT NOT NULL,
  message_id TEXT NOT NULL,
  delivered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(broadcast_message_id, recipient_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_broadcast_deliveries_message_id 
ON broadcast_deliveries(broadcast_message_id);

CREATE INDEX IF NOT EXISTS idx_broadcast_deliveries_recipient_id 
ON broadcast_deliveries(recipient_id);

CREATE INDEX IF NOT EXISTS idx_broadcast_deliveries_chat_id 
ON broadcast_deliveries(chat_id);

-- Enable Row Level Security (RLS)
ALTER TABLE broadcast_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE broadcast_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE broadcast_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE broadcast_deliveries ENABLE ROW LEVEL SECURITY;

-- RLS Policies for broadcast_lists
CREATE POLICY "Users can view their own broadcast lists"
  ON broadcast_lists FOR SELECT
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can create their own broadcast lists"
  ON broadcast_lists FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own broadcast lists"
  ON broadcast_lists FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own broadcast lists"
  ON broadcast_lists FOR DELETE
  USING (auth.uid() = owner_id);

-- RLS Policies for broadcast_recipients
CREATE POLICY "Users can view recipients of their lists"
  ON broadcast_recipients FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM broadcast_lists
      WHERE broadcast_lists.id = broadcast_recipients.broadcast_list_id
      AND broadcast_lists.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can add recipients to their lists"
  ON broadcast_recipients FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM broadcast_lists
      WHERE broadcast_lists.id = broadcast_recipients.broadcast_list_id
      AND broadcast_lists.owner_id = auth.uid()
    )
  );

CREATE POLICY "Users can remove recipients from their lists"
  ON broadcast_recipients FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM broadcast_lists
      WHERE broadcast_lists.id = broadcast_recipients.broadcast_list_id
      AND broadcast_lists.owner_id = auth.uid()
    )
  );

-- RLS Policies for broadcast_messages
CREATE POLICY "Users can view their own broadcast messages"
  ON broadcast_messages FOR SELECT
  USING (auth.uid() = sender_id);

CREATE POLICY "Users can create broadcast messages"
  ON broadcast_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- RLS Policies for broadcast_deliveries
CREATE POLICY "Users can view deliveries for their messages"
  ON broadcast_deliveries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM broadcast_messages
      WHERE broadcast_messages.id = broadcast_deliveries.broadcast_message_id
      AND broadcast_messages.sender_id = auth.uid()
    )
    OR auth.uid() = recipient_id
  );

CREATE POLICY "System can create delivery records"
  ON broadcast_deliveries FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update delivery records"
  ON broadcast_deliveries FOR UPDATE
  USING (true);
