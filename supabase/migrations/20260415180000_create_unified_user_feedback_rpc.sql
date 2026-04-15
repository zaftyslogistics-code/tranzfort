-- Create unified RPC to combine ratings and reviews tables
-- This provides a single source of truth for all user feedback on profile pages

CREATE OR REPLACE FUNCTION get_all_user_feedback(
    p_user_id uuid,
    p_limit int default 10,
    p_offset int default 0
)
RETURNS jsonb AS $$
DECLARE
    v_feedback jsonb;
BEGIN
    -- Combine ratings (trip completions) and reviews (general feedback)
    -- Normalize column names and add context labels
    -- Cast reviewer_role to text to handle type mismatch between user_role enum and text
    WITH trip_ratings AS (
        SELECT
            r.id,
            r.reviewee_id as reviewed_user_id,
            r.reviewer_id,
            r.reviewer_role::text as reviewer_role,
            'trip_completed' as context_type,
            r.trip_id as context_id,
            r.score as rating,
            r.comment,
            NULL as reply,
            NULL as reply_at,
            r.created_at,
            'Trip Completed' as context_label,
            l.origin_city,
            l.destination_city
        FROM ratings r
        LEFT JOIN loads l ON l.id = r.load_id
        WHERE r.reviewee_id = p_user_id
    ),
    general_reviews AS (
        SELECT
            r.id,
            r.reviewed_user_id,
            r.reviewer_id,
            r.reviewer_role,
            r.context_type,
            r.context_id,
            r.rating,
            r.comment,
            r.reply,
            r.reply_at,
            r.created_at,
            CASE
                WHEN r.context_type = 'chat' THEN 'Chat Interaction'
                WHEN r.context_type = 'load_closed' THEN 'Load Closed'
                WHEN r.context_type = 'trip_completed' THEN 'Trip Completed'
                ELSE r.context_type
            END as context_label,
            NULL as origin_city,
            NULL as destination_city
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
            'rating', cf.rating,
            'comment', cf.comment,
            'reply', cf.reply,
            'reply_at', cf.reply_at,
            'created_at', cf.created_at,
            'origin_city', cf.origin_city,
            'destination_city', cf.destination_city
        )
    ) INTO v_feedback
    FROM combined_feedback cf
    JOIN profiles p ON p.id = cf.reviewer_id
    LEFT JOIN profile_trust_scores pts ON pts.user_id = cf.reviewer_id
    ORDER BY cf.created_at DESC
    LIMIT p_limit OFFSET p_offset;
    
    RETURN coalesce(v_feedback, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_all_user_feedback(uuid, int, int) TO authenticated;
