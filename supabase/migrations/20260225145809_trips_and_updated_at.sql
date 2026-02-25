-- 9.5 start_trip
CREATE OR REPLACE FUNCTION public.start_trip(
    p_trip_id UUID,
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION
) RETURNS JSONB AS $$
DECLARE
    v_trip RECORD;
BEGIN
    SELECT * INTO v_trip FROM public.trips WHERE id = p_trip_id FOR UPDATE;

    IF v_trip IS NULL OR v_trip.stage <> 'at_pickup' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid trip state');
    END IF;

    UPDATE public.trips SET
        stage = 'in_transit',
        start_time = NOW(),
        last_known_lat = p_lat,
        last_known_lng = p_lng,
        last_location_at = NOW(),
        updated_at = NOW()
    WHERE id = p_trip_id;

    UPDATE public.loads SET
        status = 'in_transit',
        super_status = CASE WHEN is_super_load THEN 'in_transit'::super_status ELSE super_status END,
        updated_at = NOW()
    WHERE id = v_trip.load_id;

    RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 10. updated_at Triggers for all tables

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_suppliers_updated_at BEFORE UPDATE ON public.suppliers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_truckers_updated_at BEFORE UPDATE ON public.truckers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON public.admin_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trucks_updated_at BEFORE UPDATE ON public.trucks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_diesel_prices_updated_at BEFORE UPDATE ON public.diesel_prices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_loads_updated_at BEFORE UPDATE ON public.loads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_support_tickets_updated_at BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payout_profiles_updated_at BEFORE UPDATE ON public.payout_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_feature_flags_updated_at BEFORE UPDATE ON public.feature_flags FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
