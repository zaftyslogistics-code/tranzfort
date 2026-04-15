-- Smoke Test: Reviews & Trust Score System
-- Run this after migration to verify all components work

-- Test 1: Check tables exist
SELECT 'reviews table exists' as test, COUNT(*) > 0 as passed
FROM information_schema.tables 
WHERE table_name = 'reviews';

SELECT 'profile_trust_scores table exists' as test, COUNT(*) > 0 as passed
FROM information_schema.tables 
WHERE table_name = 'profile_trust_scores';

-- Test 2: Check RPC functions exist
SELECT 'submit_review rpc exists' as test, COUNT(*) > 0 as passed
FROM information_schema.routines 
WHERE routine_name = 'submit_review';

SELECT 'add_reply_to_review rpc exists' as test, COUNT(*) > 0 as passed
FROM information_schema.routines 
WHERE routine_name = 'add_reply_to_review';

SELECT 'get_profile_reviews rpc exists' as test, COUNT(*) > 0 as passed
FROM information_schema.routines 
WHERE routine_name = 'get_profile_reviews';

SELECT 'can_review_user rpc exists' as test, COUNT(*) > 0 as passed
FROM information_schema.routines 
WHERE routine_name = 'can_review_user';

SELECT 'get_public_profile rpc exists' as test, COUNT(*) > 0 as passed
FROM information_schema.routines 
WHERE routine_name = 'get_public_profile';

-- Test 3: Check trigger exists
SELECT 'trigger exists' as test, COUNT(*) > 0 as passed
FROM information_schema.triggers 
WHERE trigger_name = 'trg_update_trust_score';

-- Test 4: Check RLS policies exist
SELECT 'reviews rls policies exist' as test, COUNT(*) >= 3 as passed
FROM pg_policies 
WHERE tablename = 'reviews';

SELECT 'profile_trust_scores rls policies exist' as test, COUNT(*) >= 1 as passed
FROM pg_policies 
WHERE tablename = 'profile_trust_scores';

-- Test 5: Verify table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'reviews' 
ORDER BY ordinal_position;

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profile_trust_scores' 
ORDER BY ordinal_position;

-- Test 6: Check constraints on reviews table
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'reviews';
