-- Fix GROUP BY error in get_all_user_feedback RPC
-- Issue: ORDER BY with aggregate function requires GROUP BY
-- Fix: Use subquery to sort before aggregation

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
    -- All columns must have matching types for UNION - cast all to text
    -- Use subquery to handle sorting without GROUP BY issues
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
    ),
    joined_feedback AS (
        SELECT
            cf.*,
            p.full_name as reviewer_name,
            coalesce(pts.avg_rating, 0) as reviewer_avg_rating,
            coalesce(pts.review_count, 0) as reviewer_review_count,
            coalesce(p.avatar_url, p.profile_photo_document_path) as reviewer_avatar_url
        FROM combined_feedback cf
        JOIN profiles p ON p.id::text = cf.reviewer_id
        LEFT JOIN profile_trust_scores pts ON pts.user_id::text = cf.reviewer_id
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', jf.id,
            'reviewed_user_id', jf.reviewed_user_id,
            'reviewer_id', jf.reviewer_id,
            'reviewer_name', jf.reviewer_name,
            'reviewer_role', jf.reviewer_role,
            'reviewer_avg_rating', jf.reviewer_avg_rating,
            'reviewer_review_count', jf.reviewer_review_count,
            'reviewer_avatar_url', jf.reviewer_avatar_url,
            'context_type', jf.context_type,
            'context_id', jf.context_id,
            'context_label', jf.context_label,
            'rating', jf.rating::int,
            'comment', jf.comment,
            'reply', jf.reply,
            'reply_at', jf.reply_at,
            'created_at', jf.created_at,
            'origin_city', jf.origin_city,
            'destination_city', jf.destination_city
        )
    ) INTO v_feedback
    FROM (
        SELECT * FROM joined_feedback
        ORDER BY created_at DESC
        LIMIT p_limit OFFSET p_offset
    ) jf;
    
    RAISE NOTICE 'Combined feedback count: %', jsonb_array_length(v_feedback);
    
    RETURN coalesce(v_feedback, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_all_user_feedback(uuid, int, int) TO authenticated;
