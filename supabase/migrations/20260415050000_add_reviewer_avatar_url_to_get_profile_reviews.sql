-- Add reviewer_avatar_url to get_profile_reviews RPC
-- This enables displaying real profile photos in reviewer mini cards

create or replace function get_profile_reviews(
    p_user_id uuid,
    p_limit int default 5,
    p_offset int default 0
)
returns jsonb as $$
declare
  v_reviews jsonb;
begin
  -- Use a subquery to order the results before aggregating
  select jsonb_agg(
      jsonb_build_object(
          'id', sub.id,
          'reviewed_user_id', sub.reviewed_user_id,
          'reviewer_id', sub.reviewer_id,
          'reviewer_name', sub.full_name,
          'reviewer_role', sub.reviewer_role,
          'reviewer_avg_rating', coalesce(sub.avg_rating, 0),
          'reviewer_review_count', coalesce(sub.review_count, 0),
          'reviewer_location', nullif(concat_ws(', ', nullif(trim(sub.city), ''), nullif(trim(sub.state), '')), ''),
          'reviewer_avatar_url', coalesce(sub.avatar_url, sub.profile_photo_document_path),
          'reviewer_member_since', sub.reviewer_created_at,
          'context_type', sub.context_type,
          'context_id', sub.context_id,
          'rating', sub.rating,
          'comment', sub.comment,
          'reply', sub.reply,
          'reply_at', sub.reply_at,
          'created_at', sub.created_at
      )
  ) into v_reviews
  from (
    select r.*, p.full_name, p.city, p.state, p.avatar_url, p.profile_photo_document_path, p.created_at as reviewer_created_at, pts.avg_rating, pts.review_count
    from reviews r
    join profiles p on p.id = r.reviewer_id
    left join profile_trust_scores pts on pts.user_id = r.reviewer_id
    where r.reviewed_user_id = p_user_id
    order by r.created_at desc
    limit p_limit
    offset p_offset
  ) sub;
  
  return coalesce(v_reviews, '[]'::jsonb);
end;
$$ language plpgsql security definer;

GRANT EXECUTE ON FUNCTION public.get_profile_reviews(uuid, int, int) TO authenticated;
