-- 11. Row Level Security (RLS)

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.truckers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.truck_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trucks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diesel_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read and update their own profile
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Suppliers: Anyone can read, only the supplier can update
CREATE POLICY "Anyone can view suppliers" ON public.suppliers FOR SELECT USING (true);
CREATE POLICY "Suppliers can update their own data" ON public.suppliers FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Suppliers can insert their own data" ON public.suppliers FOR INSERT WITH CHECK (auth.uid() = id);

-- Truckers: Anyone can read, only the trucker can update
CREATE POLICY "Anyone can view truckers" ON public.truckers FOR SELECT USING (true);
CREATE POLICY "Truckers can update their own data" ON public.truckers FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Truckers can insert their own data" ON public.truckers FOR INSERT WITH CHECK (auth.uid() = id);

-- Admin Users: Only admins can read/write, managed via Edge Functions
-- (Skipping detailed admin RLS here, assuming service_role handles it for V1)

-- Truck Models: Anyone can read
CREATE POLICY "Anyone can view truck models" ON public.truck_models FOR SELECT USING (true);

-- Trucks: Anyone can read, only owner can create/update
CREATE POLICY "Anyone can view trucks" ON public.trucks FOR SELECT USING (true);
CREATE POLICY "Truckers can insert their own trucks" ON public.trucks FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Truckers can update their own trucks" ON public.trucks FOR UPDATE USING (auth.uid() = owner_id);

-- Diesel Prices: Anyone can read
CREATE POLICY "Anyone can view diesel prices" ON public.diesel_prices FOR SELECT USING (true);

-- Loads: Anyone can read active/booked loads. Only supplier can create/update their loads.
CREATE POLICY "Anyone can view loads" ON public.loads FOR SELECT USING (status IN ('active', 'booked', 'in_transit', 'completed') OR auth.uid() = supplier_id OR auth.uid() = assigned_trucker_id);
CREATE POLICY "Suppliers can insert their own loads" ON public.loads FOR INSERT WITH CHECK (auth.uid() = supplier_id);
CREATE POLICY "Suppliers can update their own loads" ON public.loads FOR UPDATE USING (auth.uid() = supplier_id);
-- (Note: Child loads are created via RPC, which bypasses RLS if SECURITY DEFINER, or runs as user. The RPC handles auth checks.)

-- Trips: Users involved in the trip can read. Trucker can update stage/location. Supplier can confirm POD.
CREATE POLICY "Involved users can view trips" ON public.trips FOR SELECT USING (
    auth.uid() = trucker_id OR 
    auth.uid() IN (SELECT supplier_id FROM public.loads WHERE loads.id = trips.load_id)
);
CREATE POLICY "Truckers can update their trips" ON public.trips FOR UPDATE USING (auth.uid() = trucker_id);
-- (Supplier updates like confirming completion might be better via RPC to handle complex logic)

-- Conversations: Only participants can read
CREATE POLICY "Participants can view conversations" ON public.conversations FOR SELECT USING (auth.uid() = supplier_id OR auth.uid() = trucker_id);

-- Messages: Participants can read and insert
CREATE POLICY "Participants can view messages" ON public.messages FOR SELECT USING (
    auth.uid() IN (SELECT supplier_id FROM public.conversations WHERE id = messages.conversation_id) OR
    auth.uid() IN (SELECT trucker_id FROM public.conversations WHERE id = messages.conversation_id)
);
CREATE POLICY "Participants can insert messages" ON public.messages FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    (auth.uid() IN (SELECT supplier_id FROM public.conversations WHERE id = conversation_id) OR
     auth.uid() IN (SELECT trucker_id FROM public.conversations WHERE id = conversation_id))
);

-- Notifications: Users can only read/update their own
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Support Tickets: Users can only read/update their own
CREATE POLICY "Users can view their own tickets" ON public.support_tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own tickets" ON public.support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Support Ticket Messages: Users can read messages for their tickets, and insert
CREATE POLICY "Users can view messages for their tickets" ON public.support_ticket_messages FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.support_tickets WHERE id = ticket_id)
);
CREATE POLICY "Users can insert messages for their tickets" ON public.support_ticket_messages FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    auth.uid() IN (SELECT user_id FROM public.support_tickets WHERE id = ticket_id)
);

-- Ratings: Anyone can read, only users can insert (handled via trigger mostly, but explicit policy here)
CREATE POLICY "Anyone can view ratings" ON public.ratings FOR SELECT USING (true);
CREATE POLICY "Users can insert ratings" ON public.ratings FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- Payout Profiles: Users can only read/update their own
CREATE POLICY "Users can view their own payout profiles" ON public.payout_profiles FOR SELECT USING (auth.uid() = profile_id);
CREATE POLICY "Users can insert their own payout profiles" ON public.payout_profiles FOR INSERT WITH CHECK (auth.uid() = profile_id);
CREATE POLICY "Users can update their own payout profiles" ON public.payout_profiles FOR UPDATE USING (auth.uid() = profile_id);

-- User Consents: Users can read/insert their own
CREATE POLICY "Users can view their own consents" ON public.user_consents FOR SELECT USING (auth.uid() = profile_id);
CREATE POLICY "Users can insert their own consents" ON public.user_consents FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Feature Flags: Anyone can read
CREATE POLICY "Anyone can view feature flags" ON public.feature_flags FOR SELECT USING (true);

-- (Audit logs should ideally only be accessible by admins via service_role)
