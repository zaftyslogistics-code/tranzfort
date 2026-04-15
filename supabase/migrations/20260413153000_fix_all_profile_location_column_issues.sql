-- Fix all RPCs that reference non-existent city/state columns in profiles table
-- The profiles table only has basic identity fields, not location fields

-- Fix get_profile_reviews RPC
create or replace function get_profile_reviews(
    p_user_id uuid,
    p_limit int default 5,
    p_offset int default 0
)
returns jsonb as $$
DECLARE
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
            'reviewer_location', null,  -- profiles table doesn't have city/state columns
            'reviewer_member_since', p.created_at,
            'context_type', r.context_type,
            'context_id', r.context_id,
            'rating', r.rating,
            'comment', r.comment,
            'reply', r.reply,
            'reply_at', r.reply_at,
            'created_at', r.created_at
        ) order by r.created_at desc
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

-- Fix get_trip_detail_with_supplier RPC
create or replace function get_trip_detail_with_supplier(
    p_trip_id uuid,
    p_trucker_id uuid
)
returns jsonb as $$
declare
    v_result jsonb;
begin
    select jsonb_build_object(
        'trip', jsonb_build_object(
            'id', t.id,
            'status', t.status,
            'created_at', t.created_at,
            'started_at', t.started_at,
            'completed_at', t.completed_at
        ),
        'supplier', jsonb_build_object(
            'id', p.id,
            'full_name', p.full_name,
            'mobile', case 
                when p.mobile is not null then 
                    overlay(p.mobile placing '****' from 3 for 4)
                else null
            end,
            'city', null,  -- profiles table doesn't have city/state columns
            'state', null,  -- profiles table doesn't have city/state columns
            'company_name', s.company_name,
            'verification_status', p.verification_status,
            'avg_rating', coalesce(pts.avg_rating, 0),
            'review_count', coalesce(pts.review_count, 0)
        ),
        'load', jsonb_build_object(
            'origin_label', l.origin_label,
            'origin_city', l.origin_city,
            'origin_state', l.origin_state,
            'origin_lat', l.origin_lat,
            'origin_lng', l.origin_lng,
            'destination_label', l.destination_label,
            'destination_city', l.destination_city,
            'destination_state', l.destination_state,
            'destination_lat', l.destination_lat,
            'destination_lng', l.destination_lng,
            'route_distance_km', l.route_distance_km,
            'route_duration_minutes', l.route_duration_minutes,
            'route_snapshot_source', l.route_snapshot_source,
            'material', l.material,
            'pickup_date', l.pickup_date
        ),
        'truck', jsonb_build_object(
            'truck_number', tr.truck_number,
            'body_type', tr.body_type,
            'tyres', tr.tyres
        )
    )
    into v_result
    from trips t
    join loads l on l.id = t.load_id
    join profiles p on p.id = t.supplier_id
    left join suppliers s on s.id = t.supplier_id
    left join profile_trust_scores pts on pts.user_id = t.supplier_id
    left join trucks tr on tr.id = t.truck_id
    where t.id = p_trip_id
    and t.trucker_id = p_trucker_id;
    
    return v_result;
end;
$$ language plpgsql security definer;

-- Fix sync_supplier_location_to_profile trigger function (remove references to p.city/p.state)
create or replace function sync_supplier_location_to_profile()
returns trigger as $$
begin
    -- This function is now a no-op since profiles table doesn't have city/state columns
    -- Location data is stored in suppliers table (verification_location_city, verification_location_state)
    -- Future: Add city/state columns to profiles table if location is needed there
    return new;
end;
$$ language plpgsql;
