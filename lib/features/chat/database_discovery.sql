-- ============================================================================
-- STEP 1: DISCOVERY - Find ALL RLS Policies on Affected Tables
-- ============================================================================
-- INSTRUCTIONS: 
-- 1. Open Supabase Dashboard → SQL Editor
-- 2. Run this ENTIRE script
-- 3. Save/screenshot the results - we'll need them!
-- ============================================================================

-- ============================================================================
-- Query 1: List all RLS policies on affected tables
-- ============================================================================
SELECT 
    schemaname AS schema,
    tablename AS table_name,
    policyname AS policy_name,
    permissive AS is_permissive,
    roles,
    cmd AS command_type,
    qual AS using_expression,
    with_check AS with_check_expression
FROM pg_policies
WHERE tablename IN ('chats', 'messages', 'chat_typing', 'broadcast_deliveries')
ORDER BY tablename, policyname;

-- ============================================================================
-- Query 2: Get detailed policy definitions (for exact recreation)
-- ============================================================================
SELECT 
    tablename,
    policyname,
    'CREATE POLICY "' || policyname || '" ON ' || schemaname || '.' || tablename ||
    ' FOR ' || cmd ||
    ' TO ' || COALESCE(roles::text, 'PUBLIC') ||
    CASE 
        WHEN qual IS NOT NULL THEN ' USING (' || qual || ')'
        ELSE ''
    END ||
    CASE 
        WHEN with_check IS NOT NULL THEN ' WITH CHECK (' || with_check || ')'
        ELSE ''
    END || ';' AS policy_definition
FROM pg_policies
WHERE tablename IN ('chats', 'messages', 'chat_typing', 'broadcast_deliveries')
ORDER BY tablename, policyname;

-- ============================================================================
-- Query 3: Check if RLS is enabled on tables
-- ============================================================================
SELECT 
    schemaname,
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE tablename IN ('chats', 'messages', 'chat_typing', 'broadcast_deliveries')
ORDER BY tablename;

-- ============================================================================
-- Query 4: Find foreign key constraints
-- ============================================================================
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name IN ('chats', 'messages', 'chat_typing', 'broadcast_deliveries')
ORDER BY tc.table_name, tc.constraint_name;

-- ============================================================================
-- Query 5: Check current column types
-- ============================================================================
SELECT 
    table_name,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_name IN ('chats', 'messages', 'chat_typing', 'broadcast_deliveries')
    AND column_name LIKE '%id%'
ORDER BY table_name, ordinal_position;

-- ============================================================================
-- Query 6: Count existing data (to know what we're migrating)
-- ============================================================================
SELECT 
    'chats' AS table_name,
    COUNT(*) AS row_count
FROM chats
UNION ALL
SELECT 
    'messages' AS table_name,
    COUNT(*) AS row_count
FROM messages
UNION ALL
SELECT 
    'chat_typing' AS table_name,
    COUNT(*) AS row_count
FROM chat_typing
UNION ALL
SELECT 
    'broadcast_deliveries' AS table_name,
    COUNT(*) AS row_count
FROM broadcast_deliveries;

-- ============================================================================
-- SUCCESS MESSAGE
-- ============================================================================
-- Copy ALL results from the queries above!
-- We need this information to create a safe migration script.
-- ============================================================================

-- NEXT STEPS:
-- 1. Save/screenshot ALL query results
-- 2. Share the policy definitions with me
-- 3. I'll create a comprehensive migration script that:
--    - Saves all policies
--    - Drops them safely
--    - Changes column types
--    - Recreates policies
--    - Recreates foreign keys
--    - Verifies everything
-- ============================================================================
