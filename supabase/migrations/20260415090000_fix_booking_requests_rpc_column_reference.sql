-- Fix get_supplier_booking_requests RPC column reference and avatar handling
-- Issue 1: RPC was trying to access t.full_name (truckers table) which doesn't exist
-- Issue 2: RPC was trying to use storage_signed_url function which doesn't exist
-- Fix: Join with profiles table and return raw avatar fields (follow pattern from chat RPC)

drop function if exists get_supplier_booking_requests(uuid);

create function get_supplier_booking_requests(p_load_id uuid)
returns jsonb as $$
declare
  v_requests jsonb;
begin
  select jsonb_agg(
      jsonb_build_object(
          'id', req.id,
          'load_id', req.load_id,
          'trucker_id', req.trucker_id,
          'truck_id', req.truck_id,
          'status', req.status,
          'decision_reason', req.decision_reason,
          'created_at', req.created_at,
          'decided_at', req.decided_at,
          'trucker_name', p.full_name,
          'trucker_verification_status', p.verification_status,
          'trucker_rating', coalesce(ts.avg_rating, 0),
          'trucker_avatar_url', coalesce(p.avatar_url, p.profile_photo_document_path),
          'truck_number', tr.number,
          'truck_body_type', tm.body_type,
          'truck_tyres', tr.tyres,
          'truck_model_label', tm.label
      )
  ) into v_requests
  from booking_requests req
  join trucks tr on tr.id = req.truck_id
  join truck_models tm on tm.id = tr.truck_model_id
  join truckers t on t.id = req.trucker_id
  join profiles p on p.id = t.id
  left join profile_trust_scores ts on ts.user_id = t.id
  where req.load_id = p_load_id
  order by req.created_at desc;

  return coalesce(v_requests, '[]'::jsonb);
end;
$$ language plpgsql security definer;

GRANT EXECUTE ON FUNCTION public.get_supplier_booking_requests(uuid) TO authenticated;
