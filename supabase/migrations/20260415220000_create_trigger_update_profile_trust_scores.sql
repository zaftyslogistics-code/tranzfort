-- Create trigger to update profile_trust_scores when ratings change
-- This ensures the review system's trust scores are synchronized with the ratings table

CREATE OR REPLACE FUNCTION update_profile_trust_scores()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert or update profile_trust_scores for the reviewed user
  INSERT INTO profile_trust_scores (user_id, avg_rating, review_count, updated_at)
  VALUES (
    NEW.reviewee_id,
    (SELECT COALESCE(AVG(r.score), 0) FROM ratings r WHERE r.reviewee_id = NEW.reviewee_id),
    (SELECT COUNT(*) FROM ratings r WHERE r.reviewee_id = NEW.reviewee_id),
    NOW()
  )
  ON CONFLICT (user_id) 
  DO UPDATE SET
    avg_rating = EXCLUDED.avg_rating,
    review_count = EXCLUDED.review_count,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for INSERT on ratings
DROP TRIGGER IF EXISTS trg_update_profile_trust_scores_insert ON ratings;
CREATE TRIGGER trg_update_profile_trust_scores_insert
  AFTER INSERT ON ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_profile_trust_scores();

-- Create trigger for UPDATE on ratings
DROP TRIGGER IF EXISTS trg_update_profile_trust_scores_update ON ratings;
CREATE TRIGGER trg_update_profile_trust_scores_update
  AFTER UPDATE ON ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_profile_trust_scores();

-- Create trigger for DELETE on ratings
DROP TRIGGER IF EXISTS trg_update_profile_trust_scores_delete ON ratings;
CREATE TRIGGER trg_update_profile_trust_scores_delete
  AFTER DELETE ON ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_profile_trust_scores();

-- Recalculate trust scores for all users who have ratings
INSERT INTO profile_trust_scores (user_id, avg_rating, review_count, updated_at)
SELECT 
  r.reviewee_id,
  COALESCE(AVG(r.score), 0),
  COUNT(*),
  NOW()
FROM ratings r
GROUP BY r.reviewee_id
ON CONFLICT (user_id) 
DO UPDATE SET
  avg_rating = EXCLUDED.avg_rating,
  review_count = EXCLUDED.review_count,
  updated_at = NOW();
