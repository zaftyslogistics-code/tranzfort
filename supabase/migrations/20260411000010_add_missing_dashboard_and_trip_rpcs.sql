-- Migration: Add missing dashboard and trip RPC functions
-- Created: April 11, 2026
-- Purpose: Fix runtime errors by creating RPCs referenced in Dart code but missing from database

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: get_trucker_dashboard_stats
-- Returns: Consolidated dashboard stats for trucker in single call
-- ═══════════════════════════════════════════════════════════════════════════════
create or replace function get_trucker_dashboard_stats(p_trucker_id uuid)
returns jsonb language plpgsql security definer as $$
declare
    v_active_bids bigint;
    v_upcoming_trips bigint;
    v_in_transit_trips bigint;
    v_completed_trips bigint;
    v_total_trucks bigint;
    v_approved_trucks bigint;
    v_pending_trucks bigint;
    v_rejected_trucks bigint;
    v_pending_approval_trucks bigint;
begin
    -- Active bids count
    select count(*) into v_active_bids from booking_requests 
    where trucker_id = p_trucker_id and status = 'submitted';
    
    -- Upcoming trips (assigned, pickup_pending, picked_up)
    select count(*) into v_upcoming_trips from trips 
    where trucker_id = p_trucker_id 
    and stage in ('assigned', 'pickup_pending', 'picked_up');
    
    -- In transit trips
    select count(*) into v_in_transit_trips from trips 
    where trucker_id = p_trucker_id and stage = 'in_transit';
    
    -- Completed trips
    select count(*) into v_completed_trips from trips 
    where trucker_id = p_trucker_id and stage = 'completed';
    
    -- Total trucks
    select count(*) into v_total_trucks from trucks 
    where owner_id = p_trucker_id;
    
    -- Approved trucks
    select count(*) into v_approved_trucks from trucks 
    where owner_id = p_trucker_id and status = 'verified';
    
    -- Pending trucks
    select count(*) into v_pending_trucks from trucks 
    where owner_id = p_trucker_id and status = 'pending';
    
    -- Rejected trucks
    select count(*) into v_rejected_trucks from trucks 
    where owner_id = p_trucker_id and status = 'rejected';
    
    -- Pending re-approval trucks
    select count(*) into v_pending_approval_trucks from trucks 
    where owner_id = p_trucker_id and status = 'edited_pending_reapproval';
    
    return jsonb_build_object(
        'active_bids', v_active_bids,
        'upcoming_trips', v_upcoming_trips,
        'in_transit_trips', v_in_transit_trips,
        'completed_trips', v_completed_trips,
        'total_trucks', v_total_trucks,
        'approved_trucks', v_approved_trucks,
        'pending_trucks', v_pending_trucks,
        'rejected_trucks', v_rejected_trucks,
        'pending_approval_trucks', v_pending_approval_trucks
    );
end;
$$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- RPC: get_trip_detail_with_supplier
-- Returns: Trip details with supplier info, phone masking applied
-- ═══════════════════════════════════════════════════════════════════════════════
create or replace function get_trip_detail_with_supplier(
    p_trip_id uuid,
    p_trucker_id uuid
)
returns jsonb language plpgsql security definer as $$
declare
    v_result jsonb;
begin
    select jsonb_build_object(
        'trip', jsonb_build_object(
            'id', t.id,
            'load_id', t.load_id,
            'supplier_id', t.supplier_id,
            'truck_id', t.truck_id,
            'stage', t.stage,
            'assigned_at', t.assigned_at,
            'started_at', t.started_at,
            'delivered_at', t.delivered_at,
            'pod_uploaded_at', t.pod_uploaded_at,
            'completed_at', t.completed_at,
            'lr_document_path', t.lr_document_path,
            'pod_document_path', t.pod_document_path,
            'load_snapshot_summary', t.load_snapshot_summary
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
$$;

-- Grant execute permissions
grant execute on function get_trucker_dashboard_stats(uuid) to authenticated;
grant execute on function get_trip_detail_with_supplier(uuid, uuid) to authenticated;
