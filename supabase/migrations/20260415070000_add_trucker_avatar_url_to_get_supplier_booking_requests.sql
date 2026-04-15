-- Add trucker_avatar_url to get_supplier_booking_requests RPC
-- This adds avatar support for booking requests with fallback pattern
-- Also changes return type from TABLE to JSONB to match other RPCs

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
          'trucker_avatar_url', coalesce(
              case 
                when p.avatar_url is not null and p.avatar_url != '' then 
                  case 
                    when p.avatar_url like 'http%' then p.avatar_url
                    else storage_signed_url('profile-photos', p.avatar_url)
                  end
                when p.profile_photo_document_path is not null and p.profile_photo_document_path != '' then
                  storage_signed_url('verification-documents', p.profile_photo_document_path)
                else null
              end,
              null
          ),
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
