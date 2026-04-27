-- Fix get_profile_reviews RPC - remove ORDER BY inside jsonb_agg()
-- This fixes "column r.created_at must appear in the GROUP BY clause" error

create or replace function get_profile_reviews(
    p_user_id uuid,
    p_limit int default 5,
    p_offset int default 0
)
returns jsonb as $$
declare
  v_reviews jsonb;
begin
  select jsonb_agg(
      jsonb_build_object(
          'id', r.id,
          'reviewed_user_id', r.reviewed_user_id,
          'reviewer_id', r.reviewer_id,
          'reviewer_name', p.full_name,
          'reviewer_role', r.reviewer_role,
          'reviewer_avg_rating', coalesce(pts.avg_rating, 0),
          'reviewer_review_count', coalesce(pts.review_count, 0),
          'reviewer_location', nullif(concat_ws(', ', nullif(trim(p.city), ''), nullif(trim(p.state), '')), ''),
          'reviewer_member_since', p.created_at,
          'context_type', r.context_type,
          'context_id', r.context_id,
          'rating', r.rating,
          'comment', r.comment,
          'reply', r.reply,
          'reply_at', r.reply_at,
          'created_at', r.created_at
      )
  ) into v_reviews
  from reviews r
  join profiles p on p.id = r.reviewer_id
  left join profile_trust_scores pts on pts.user_id = r.reviewer_id
  where r.reviewed_user_id = p_user_id
  order by r.created_at desc
  limit p_limit offset p_offset;

  return coalesce(v_reviews, '[]'::jsonb);
end;
$$ language plpgsql security definer;
