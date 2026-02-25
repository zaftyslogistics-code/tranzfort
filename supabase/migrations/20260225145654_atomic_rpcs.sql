-- 9. Atomic RPCs (Concurrency Guards)

-- 9.1 book_load
CREATE OR REPLACE FUNCTION public.book_load(
    p_parent_load_id UUID,
    p_trucker_id UUID,
    p_truck_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_parent RECORD;
    v_truck RECORD;
    v_child_id UUID;
BEGIN
    -- 1) Lock Parent Load
    SELECT * INTO v_parent
    FROM public.loads
    WHERE id = p_parent_load_id
      AND parent_load_id IS NULL
    FOR UPDATE;

    IF v_parent IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid parent load');
    END IF;

    IF v_parent.status <> 'active' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load no longer active');
    END IF;

    IF v_parent.trucks_booked >= v_parent.trucks_needed THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load fully booked');
    END IF;

    -- 2) Verify truck ownership + status
    SELECT * INTO v_truck
    FROM public.trucks
    WHERE id = p_truck_id
      AND owner_id = p_trucker_id
      AND status = 'verified';

    IF v_truck IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Truck not found or not verified');
    END IF;

    -- 3) Create Child Load (pending supplier approval)
    INSERT INTO public.loads (
        supplier_id,
        parent_load_id,
        origin_city, origin_state, dest_city, dest_state,
        origin_lat, origin_lng, dest_lat, dest_lng,
        distance_km, duration_hours, route_polyline,
        material, weight_tonnes,
        required_truck_type, required_tyres,
        price, price_type, advance_percentage,
        pickup_date,
        status,
        trucks_needed, trucks_booked,
        is_super_load, super_status,
        assigned_trucker_id, assigned_truck_id,
        booking_truck_snapshot
    ) VALUES (
        v_parent.supplier_id,
        v_parent.id,
        v_parent.origin_city, v_parent.origin_state, v_parent.dest_city, v_parent.dest_state,
        v_parent.origin_lat, v_parent.origin_lng, v_parent.dest_lat, v_parent.dest_lng,
        v_parent.distance_km, v_parent.duration_hours, v_parent.route_polyline,
        v_parent.material, v_parent.weight_tonnes,
        v_parent.required_truck_type, v_parent.required_tyres,
        v_parent.price, v_parent.price_type, v_parent.advance_percentage,
        v_parent.pickup_date,
        'pending_approval',
        1, 0,
        v_parent.is_super_load, v_parent.super_status,
        p_trucker_id, p_truck_id,
        jsonb_build_object(
            'truck_number', v_truck.truck_number,
            'body_type', v_truck.body_type::text,
            'tyres', v_truck.tyres,
            'capacity_tonnes', v_truck.capacity_tonnes,
            'rc_photo_url', v_truck.rc_photo_url
        )
    ) RETURNING id INTO v_child_id;

    -- 4) Increment Parent counters
    UPDATE public.loads
    SET trucks_booked = trucks_booked + 1,
        status = CASE
            WHEN trucks_booked + 1 >= trucks_needed THEN 'booked'::load_status
            ELSE status
        END,
        updated_at = NOW()
    WHERE id = p_parent_load_id;

    RETURN jsonb_build_object('success', true, 'child_load_id', v_child_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.2 approve_booking
CREATE OR REPLACE FUNCTION public.approve_booking(
    p_child_load_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_child RECORD;
BEGIN
    SELECT * INTO v_child
    FROM public.loads
    WHERE id = p_child_load_id
      AND parent_load_id IS NOT NULL
    FOR UPDATE;

    IF v_child IS NULL OR v_child.status <> 'pending_approval' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load not in pending approval state');
    END IF;

    INSERT INTO public.trips (load_id, trucker_id, truck_id)
    VALUES (p_child_load_id, v_child.assigned_trucker_id, v_child.assigned_truck_id);

    UPDATE public.loads
    SET status = 'booked', updated_at = NOW()
    WHERE id = p_child_load_id;

    RETURN jsonb_build_object('success', true, 'child_load_id', p_child_load_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.3 reject_booking
CREATE OR REPLACE FUNCTION public.reject_booking(
    p_child_load_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_child RECORD;
BEGIN
    SELECT * INTO v_child
    FROM public.loads
    WHERE id = p_child_load_id
      AND parent_load_id IS NOT NULL
    FOR UPDATE;

    IF v_child IS NULL OR v_child.status <> 'pending_approval' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid child load');
    END IF;

    -- 1) Cancel Child Load
    UPDATE public.loads
    SET status = 'cancelled', updated_at = NOW()
    WHERE id = p_child_load_id;

    -- 2) Decrement Parent Load counters
    UPDATE public.loads
    SET trucks_booked = GREATEST(trucks_booked - 1, 0),
        status = 'active',
        updated_at = NOW()
    WHERE id = v_child.parent_load_id;

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9.4 admin_force_assign_super_load
CREATE OR REPLACE FUNCTION public.admin_force_assign_super_load(
    p_parent_load_id UUID,
    p_trucker_id UUID,
    p_truck_id UUID,
    p_admin_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_parent RECORD;
    v_truck RECORD;
    v_child_id UUID;
BEGIN
    SELECT * INTO v_parent FROM public.loads WHERE id = p_parent_load_id FOR UPDATE;
    
    IF v_parent IS NULL OR v_parent.parent_load_id IS NOT NULL OR v_parent.is_super_load = FALSE THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid parent super load');
    END IF;
    
    IF v_parent.status != 'active' OR v_parent.trucks_booked >= v_parent.trucks_needed THEN
        RETURN jsonb_build_object('success', false, 'error', 'Load not active or fully booked');
    END IF;

    SELECT * INTO v_truck FROM public.trucks
    WHERE id = p_truck_id AND owner_id = p_trucker_id AND status = 'verified';

    IF v_truck IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Truck not verified');
    END IF;

    -- 1. Create Child Load already in 'booked' state
    INSERT INTO public.loads (
        supplier_id, parent_load_id,
        origin_city, origin_state, dest_city, dest_state,
        origin_lat, origin_lng, dest_lat, dest_lng, distance_km, duration_hours, route_polyline,
        material, weight_tonnes, price, price_type, advance_percentage, pickup_date,
        status, is_super_load, super_status, trucks_needed, trucks_booked,
        assigned_trucker_id, assigned_truck_id, assigned_by, booking_truck_snapshot
    ) VALUES (
        v_parent.supplier_id, v_parent.id,
        v_parent.origin_city, v_parent.origin_state, v_parent.dest_city, v_parent.dest_state,
        v_parent.origin_lat, v_parent.origin_lng, v_parent.dest_lat, v_parent.dest_lng, v_parent.distance_km, v_parent.duration_hours, v_parent.route_polyline,
        v_parent.material, v_parent.weight_tonnes, v_parent.price, v_parent.price_type, v_parent.advance_percentage, v_parent.pickup_date,
        'booked', true, 'assigned', 1, 1,
        p_trucker_id, p_truck_id, p_admin_id,
        jsonb_build_object('truck_number', v_truck.truck_number, 'body_type', v_truck.body_type::text)
    ) RETURNING id INTO v_child_id;

    -- 2. Create Trip
    INSERT INTO public.trips (load_id, trucker_id, truck_id, stage)
    VALUES (v_child_id, p_trucker_id, p_truck_id, 'at_pickup');

    -- 3. Update Parent Load
    UPDATE public.loads SET
        trucks_booked = trucks_booked + 1,
        status = CASE WHEN trucks_booked + 1 >= trucks_needed THEN 'booked'::load_status ELSE status END,
        super_status = 'assigned',
        updated_at = NOW()
    WHERE id = p_parent_load_id;

    RETURN jsonb_build_object('success', true, 'child_load_id', v_child_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
