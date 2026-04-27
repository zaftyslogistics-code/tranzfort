-- Fix get_trip_detail_with_supplier RPC to remove dispute_summary
-- The trip_disputes table doesn't exist, so the LEFT JOIN causes ServerFailure

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
        'supplier_profile', jsonb_build_object(
            'id', p.id,
            'full_name', p.full_name,
            'mobile', case 
                when p.mobile is not null then 
                    overlay(p.mobile placing '****' from 3 for 4)
                else null
            end,
            'city', p.city,
            'state', p.state,
            'verification_status', p.verification_status,
            'avg_rating', coalesce(pts.avg_rating, 0),
            'review_count', coalesce(pts.review_count, 0)
        ),
        'supplier_extension', jsonb_build_object(
            'id', s.id,
            'company_name', s.company_name
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
grant execute on function get_trip_detail_with_supplier(uuid, uuid) to authenticated;
