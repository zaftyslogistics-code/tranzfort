-- Fix type mismatch in get_all_user_feedback RPC
-- Issue: ratings.reviewer_role is user_role enum, reviews.reviewer_role is text
-- Fix: Cast reviewer_role to text in trip_ratings CTE for UNION compatibility
-- Also: Ensure all columns have matching types between CTEs

CREATE OR REPLACE FUNCTION get_all_user_feedback(
    p_user_id uuid,
    p_limit int default 10,
    p_offset int default 0
)
RETURNS jsonb AS $$
DECLARE
    v_feedback jsonb;
    v_trip_count int;
    v_review_count int;
BEGIN
    -- Debug: Count records in each source
    SELECT count(*) INTO v_trip_count
    FROM ratings r
    WHERE r.reviewee_id = p_user_id;
    
    SELECT count(*) INTO v_review_count
    FROM reviews r
    WHERE r.reviewed_user_id = p_user_id;
    
    RAISE NOTICE 'Trip ratings count: %, Reviews count: %', v_trip_count, v_review_count;
    
    -- Combine ratings (trip completions) and reviews (general feedback)
    -- Normalize column names and add context labels
    -- All columns must have matching types for UNION
    WITH trip_ratings AS (
        SELECT
            r.id::text as id,
            r.reviewee_id::text as reviewed_user_id,
            r.reviewer_id::text as reviewer_id,
            r.reviewer_role::text as reviewer_role,
            'trip_completed'::text as context_type,
            r.trip_id::text as context_id,
            r.score::text as rating,
            r.comment::text as comment,
            NULL::text as reply,
            NULL::text as reply_at,
            r.created_at::text as created_at,
            'Trip Completed'::text as context_label,
            l.origin_city::text as origin_city,
            l.destination_city::text as destination_city
        FROM ratings r
        LEFT JOIN loads l ON l.id = r.load_id
        WHERE r.reviewee_id = p_user_id
    ),
    general_reviews AS (
        SELECT
            r.id::text,
            r.reviewed_user_id::text,
            r.reviewer_id::text,
            r.reviewer_role::text,
            r.context_type::text,
            r.context_id::text,
            r.rating::text,
            r.comment::text,
            r.reply::text,
            r.reply_at::text,
            r.created_at::text,
            CASE
                WHEN r.context_type = 'chat' THEN 'Chat Interaction'::text
                WHEN r.context_type = 'load_closed' THEN 'Load Closed'::text
                WHEN r.context_type = 'trip_completed' THEN 'Trip Completed'::text
                ELSE r.context_type::text
            END as context_label,
            NULL::text as origin_city,
            NULL::text as destination_city
        FROM reviews r
        WHERE r.reviewed_user_id = p_user_id
    ),
    combined_feedback AS (
        SELECT * FROM trip_ratings
        UNION ALL
        SELECT * FROM general_reviews
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', cf.id,
            'reviewed_user_id', cf.reviewed_user_id,
            'reviewer_id', cf.reviewer_id,
            'reviewer_name', p.full_name,
            'reviewer_role', cf.reviewer_role,
            'reviewer_avg_rating', coalesce(pts.avg_rating, 0),
            'reviewer_review_count', coalesce(pts.review_count, 0),
            'reviewer_avatar_url', coalesce(p.avatar_url, p.profile_photo_document_path),
            'context_type', cf.context_type,
            'context_id', cf.context_id,
            'context_label', cf.context_label,
            'rating', cf.rating::int,
            'comment', cf.comment,
            'reply', cf.reply,
            'reply_at', cf.reply_at,
            'created_at', cf.created_at,
            'origin_city', cf.origin_city,
            'destination_city', cf.destination_city
        )
    ) INTO v_feedback
    FROM combined_feedback cf
    JOIN profiles p ON p.id::text = cf.reviewer_id
    LEFT JOIN profile_trust_scores pts ON pts.user_id::text = cf.reviewer_id
    ORDER BY cf.created_at DESC
    LIMIT p_limit OFFSET p_offset;
    
    RAISE NOTICE 'Combined feedback count: %', jsonb_array_length(v_feedback);
    
    RETURN coalesce(v_feedback, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_all_user_feedback(uuid, int, int) TO authenticated;
