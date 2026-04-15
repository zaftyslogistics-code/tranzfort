-- Fix submit_review RPC to use correct column name from profiles table
-- Issue: RPC was using 'role' column but profiles table uses 'user_role_type'
-- Fix: Changed select role to select user_role_type

CREATE OR REPLACE FUNCTION submit_review(
    p_reviewed_user_id uuid,
    p_context_type text,
    p_context_id uuid,
    p_rating int,
    p_comment text default null
)
RETURNS jsonb AS $$
DECLARE
    v_reviewer_id uuid;
    v_reviewer_role text;
    v_review_id uuid;
    v_existing_review_id uuid;
BEGIN
    -- Get current user info
    v_reviewer_id := auth.uid();
    if v_reviewer_id is null then
        return jsonb_build_object('success', false, 'error', 'Authentication required');
    end if;
    
    -- Cannot review yourself
    if v_reviewer_id = p_reviewed_user_id then
        return jsonb_build_object('success', false, 'error', 'Cannot review yourself');
    end if;
    
    -- Validate rating 1-5
    if p_rating is null or p_rating < 1 or p_rating > 5 then
        return jsonb_build_object('success', false, 'error', 'Rating must be between 1 and 5');
    end if;
    
    -- Validate context_type
    if p_context_type not in ('chat', 'load_closed', 'trip_completed') then
        return jsonb_build_object('success', false, 'error', 'Invalid context type');
    end if;
    
    -- Get reviewer role from profiles (FIXED: use user_role_type instead of role)
    select user_role_type into v_reviewer_role from profiles where id = v_reviewer_id;
    if v_reviewer_role is null then
        return jsonb_build_object('success', false, 'error', 'Reviewer profile not found');
    end if;
    
    -- Check if review already exists (one review per reviewer per reviewed user)
    select id into v_existing_review_id from reviews 
    where reviewed_user_id = p_reviewed_user_id and reviewer_id = v_reviewer_id;
    
    if v_existing_review_id is not null then
        return jsonb_build_object('success', false, 'error', 'You have already reviewed this user');
    end if;
    
    -- Insert the review
    insert into reviews (
        reviewed_user_id,
        reviewer_id,
        reviewer_role,
        context_type,
        context_id,
        rating,
        comment
    ) values (
        p_reviewed_user_id,
        v_reviewer_id,
        v_reviewer_role,
        p_context_type,
        p_context_id,
        p_rating,
        p_comment
    )
    returning id into v_review_id;
    
    return jsonb_build_object('success', true, 'review_id', v_review_id);
    
exception when unique_violation then
    return jsonb_build_object('success', false, 'error', 'You have already reviewed this user');
when others then
    return jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
