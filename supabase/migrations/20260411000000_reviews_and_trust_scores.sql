-- Migration: Reviews and Trust Scores System
-- Created: April 11, 2026
-- Based on: user-rating-comments.md v2.2

-- ============================================
-- 1. REVIEWS TABLE (Visible Identity)
-- ============================================

create table if not exists reviews (
    id uuid primary key default gen_random_uuid(),
    
    -- Who is being reviewed
    reviewed_user_id uuid not null references profiles(id) on delete cascade,
    
    -- Who wrote the review (VISIBLE, not anonymous)
    reviewer_id uuid not null references profiles(id) on delete cascade,
    reviewer_role text not null check (reviewer_role in ('supplier', 'trucker')),
    
    -- Interaction context
    context_type text not null check (context_type in ('chat', 'load_closed', 'trip_completed')),
    context_id uuid,
    
    -- Review content
    rating int not null check (rating between 1 and 5),
    comment text check (length(comment) <= 500),
    
    -- Reply from reviewed user (one-time only)
    reply text check (length(reply) <= 500),
    reply_at timestamptz,
    
    created_at timestamptz default now(),
    
    -- One review per reviewer per reviewed user
    unique(reviewed_user_id, reviewer_id)
);

-- Indexes for efficient lookups
comment on table reviews is 'User reviews with visible reviewer identity';
create index idx_reviews_user_date on reviews(reviewed_user_id, created_at desc);
create index idx_reviews_reviewer on reviews(reviewer_id);
create index idx_reviews_context on reviews(context_type, context_id);

-- ============================================
-- 2. PROFILE TRUST SCORES TABLE
-- ============================================

create table if not exists profile_trust_scores (
    user_id uuid primary key references profiles(id) on delete cascade,
    
    -- Rating aggregates
    avg_rating numeric(2,1) default 0,
    review_count int default 0,
    
    -- Trust metrics (for internal scoring)
    five_star_count int default 0,
    one_star_count int default 0,
    
    -- Engagement metrics
    total_interactions int default 0,  -- chats + trips + load closures
    
    updated_at timestamptz default now()
);

comment on table profile_trust_scores is 'Materialized trust metrics per profile';

-- ============================================
-- 3. TRIGGER FUNCTION (Updates both profile_trust_scores AND truckers.rating)
-- ============================================

create or replace function update_profile_trust_score()
returns trigger as $$
declare
    v_avg_rating numeric(2,1);
    v_review_count int;
    v_reviewed_role text;
    v_target_user_id uuid;
begin
    v_target_user_id := coalesce(new.reviewed_user_id, old.reviewed_user_id);

    -- Calculate aggregates for the reviewed user
    select 
        avg(rating)::numeric(2,1),
        count(*)
    into v_avg_rating, v_review_count
    from reviews
    where reviewed_user_id = v_target_user_id;
    
    -- Update profile_trust_scores
    insert into profile_trust_scores (user_id, avg_rating, review_count)
    values (v_target_user_id, coalesce(v_avg_rating, 0), coalesce(v_review_count, 0))
    on conflict (user_id) do update set
        avg_rating = excluded.avg_rating,
        review_count = excluded.review_count,
        updated_at = now();
    
    -- ALSO update truckers.rating for backward compatibility
    -- Check if reviewed user is a trucker
    select user_role_type into v_reviewed_role from profiles where id = v_target_user_id;
    if v_reviewed_role = 'trucker' then
        update truckers 
        set rating = coalesce(v_avg_rating, 0)
        where id = v_target_user_id;
    end if;
    
    return coalesce(new, old);
end;
$$ language plpgsql;

-- Create trigger
drop trigger if exists trg_update_trust_score on reviews;
create trigger trg_update_trust_score
    after insert or update or delete on reviews
    for each row execute function update_profile_trust_score();

-- ============================================
-- 4. RLS POLICIES
-- ============================================

-- Enable RLS on reviews
alter table reviews enable row level security;

-- Reviews are publicly visible (open marketplace - no tiers)
create policy "Reviews are viewable by everyone"
    on reviews for select
    using (true);

-- Users can only insert their own reviews
create policy "Users can insert their own reviews"
    on reviews for insert
    with check (auth.uid() = reviewer_id);

-- Reviewed users can only update reply
create policy "Reviewed users can update reply only"
    on reviews for update
    using (auth.uid() = reviewed_user_id);

-- Enable RLS on profile_trust_scores
alter table profile_trust_scores enable row level security;

-- Trust scores are publicly viewable
create policy "Public trust scores are viewable by everyone"
    on profile_trust_scores for select
    using (true);

-- ============================================
-- 5. SEED EXISTING TRUCKERS RATINGS
-- ============================================

-- Initialize profile_trust_scores for existing profiles with reviews
-- and sync truckers.rating for backward compatibility
insert into profile_trust_scores (user_id, avg_rating, review_count)
select 
    t.id as user_id,
    coalesce(t.rating, 0) as avg_rating,
    0 as review_count
from truckers t
left join profile_trust_scores pts on pts.user_id = t.id
where pts.user_id is null;

-- ============================================
-- 6. RPC FUNCTIONS
-- ============================================

-- 6.1 submit_review() - Submit review with visible identity
create or replace function submit_review(
    p_reviewed_user_id uuid,
    p_context_type text,      -- 'chat', 'load_closed', 'trip_completed'
    p_context_id uuid,
    p_rating int,             -- 1-5
    p_comment text default null
)
returns jsonb as $$
declare
    v_reviewer_id uuid;
    v_reviewer_role text;
    v_review_id uuid;
    v_existing_review_id uuid;
begin
    -- Get current user info
    v_reviewer_id := auth.uid();
    if v_reviewer_id is null then
        return jsonb_build_object('success', false, 'error', 'Authentication required');
    end if;
    
    -- Cannot review yourself
    if v_reviewer_id = p_reviewed_user_id then
        return jsonb_build_object('success', false, 'error', 'Cannot review yourself');
    end if;
    
    -- Validate rating 1-5
    if p_rating is null or p_rating < 1 or p_rating > 5 then
        return jsonb_build_object('success', false, 'error', 'Rating must be between 1 and 5');
    end if;
    
    -- Validate context_type
    if p_context_type not in ('chat', 'load_closed', 'trip_completed') then
        return jsonb_build_object('success', false, 'error', 'Invalid context type');
    end if;
    
    -- Get reviewer role from profiles
    select user_role_type into v_reviewer_role from profiles where id = v_reviewer_id;
    if v_reviewer_role is null then
        return jsonb_build_object('success', false, 'error', 'Reviewer profile not found');
    end if;
    
    -- Check if review already exists (one review per reviewer per reviewed user)
    select id into v_existing_review_id from reviews 
    where reviewed_user_id = p_reviewed_user_id and reviewer_id = v_reviewer_id;
    
    if v_existing_review_id is not null then
        return jsonb_build_object('success', false, 'error', 'You have already reviewed this user');
    end if;
    
    -- Insert the review
    insert into reviews (
        reviewed_user_id,
        reviewer_id,
        reviewer_role,
        context_type,
        context_id,
        rating,
        comment
    ) values (
        p_reviewed_user_id,
        v_reviewer_id,
        v_reviewer_role,
        p_context_type,
        p_context_id,
        p_rating,
        p_comment
    )
    returning id into v_review_id;
    
    return jsonb_build_object('success', true, 'review_id', v_review_id);
    
exception when unique_violation then
    return jsonb_build_object('success', false, 'error', 'You have already reviewed this user');
when others then
    return jsonb_build_object('success', false, 'error', SQLERRM);
end;
$$ language plpgsql security definer;

-- 6.2 add_reply_to_review() - Add reply to review (one-time only)
create or replace function add_reply_to_review(
    p_review_id uuid,
    p_reply text
)
returns boolean as $$
declare
    v_reviewed_user_id uuid;
    v_current_user_id uuid;
    v_existing_reply text;
begin
    v_current_user_id := auth.uid();
    if v_current_user_id is null then
        return false;
    end if;
    
    -- Validate reply length
    if p_reply is null or length(trim(p_reply)) = 0 then
        return false;
    end if;
    if length(p_reply) > 500 then
        return false;
    end if;
    
    -- Check if user is the reviewed user and no reply exists yet
    update reviews 
    set reply = trim(p_reply),
        reply_at = now()
    where id = p_review_id 
      and reviewed_user_id = v_current_user_id
      and reply is null;
    
    return found;
end;
$$ language plpgsql security definer;

-- 6.3 get_profile_reviews() - Get paginated reviews with reviewer details
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

-- 6.4 can_review_user() - Check if user can review another user
create or replace function can_review_user(
    p_target_user_id uuid,
    p_context_type text default null,
    p_context_id uuid default null
)
returns jsonb as $$
declare
    v_current_user_id uuid;
    v_already_reviewed boolean;
    v_target_exists boolean;
begin
    v_current_user_id := auth.uid();
    
    -- Check if target user exists
    select exists(select 1 from profiles where id = p_target_user_id) into v_target_exists;
    
    if not v_target_exists then
        return jsonb_build_object(
            'can_review', false,
            'already_reviewed', false,
            'requires_interaction', true,
            'reason', 'Target user not found'
        );
    end if;
    
    -- Cannot review yourself
    if v_current_user_id = p_target_user_id then
        return jsonb_build_object(
            'can_review', false,
            'already_reviewed', false,
            'requires_interaction', true,
            'reason', 'Cannot review yourself'
        );
    end if;
    
    -- Check if already reviewed
    select exists(
        select 1 from reviews 
        where reviewed_user_id = p_target_user_id 
          and reviewer_id = v_current_user_id
    ) into v_already_reviewed;
    
    if v_already_reviewed then
        return jsonb_build_object(
            'can_review', false,
            'already_reviewed', true,
            'requires_interaction', true,
            'reason', 'You have already reviewed this user'
        );
    end if;
    
    -- Can review (requires interaction per current spec)
    return jsonb_build_object(
        'can_review', true,
        'already_reviewed', false,
        'requires_interaction', true,
        'reason', null
    );
end;
$$ language plpgsql security definer;

-- 6.5 get_public_profile() - Get public profile (open access)
create or replace function get_public_profile(
    p_user_id uuid,
    p_viewer_id uuid default null
)
returns jsonb as $$
declare
    v_profile jsonb;
    v_role text;
    v_is_self boolean;
    v_trust_scores jsonb;
    v_role_specific jsonb;
    v_fleet jsonb;
    v_trips_count int;
begin
    -- Check if self
    v_is_self := (p_viewer_id = p_user_id);
    
    -- Get user role
    select user_role_type into v_role from profiles where id = p_user_id;
    
    if v_role is null then
        return null;
    end if;
    
    -- Get trust scores
    select jsonb_build_object(
        'avg_rating', coalesce(pts.avg_rating, 0),
        'review_count', coalesce(pts.review_count, 0)
    ) into v_trust_scores
    from profile_trust_scores pts
    where pts.user_id = p_user_id;
    
    if v_trust_scores is null then
        v_trust_scores := jsonb_build_object('avg_rating', 0, 'review_count', 0);
    end if;
    
    -- Get completed trips count
    select count(*) into v_trips_count
    from trips
    where trucker_id = p_user_id and status = 'completed';
    
    -- Build role-specific data
    if v_role = 'trucker' then
        -- Get fleet for trucker
        select jsonb_agg(
            jsonb_build_object(
                'id', t.id,
                'truck_number', t.truck_number,
                'body_type', t.body_type,
                'tyres', t.tyres,
                'capacity_tonnes', t.capacity_tonnes,
                'status', t.status
            )
        ) into v_fleet
        from trucks t
        where t.owner_id = p_user_id and t.status = 'verified';
        
        v_role_specific := jsonb_build_object(
            'truck_count', coalesce(jsonb_array_length(coalesce(v_fleet, '[]'::jsonb)), 0),
            'fleet', coalesce(v_fleet, '[]'::jsonb),
            'completed_trips_count', v_trips_count
        );
    elsif v_role = 'supplier' then
        -- Get supplier metrics
        select jsonb_build_object(
            'total_loads_posted', coalesce(s.total_loads_posted, 0),
            'active_loads_count', coalesce(s.active_loads_count, 0),
            'is_super_load_eligible', false
        ) into v_role_specific
        from suppliers s
        where s.id = p_user_id;
    end if;
    
    -- Build final profile
    select jsonb_build_object(
        'id', p.id,
        'full_name', p.full_name,
        'company_name', s.company_name,
        'role', p.user_role_type,
        'verification_status', p.verification_status,
        'location', null,  -- profiles table doesn't have city/state columns
        'member_since', p.created_at,
        'is_self', v_is_self,
        'trust_scores', v_trust_scores,
        'role_specific', v_role_specific
    ) into v_profile
    from profiles p
    left join suppliers s on s.id = p.id
    where p.id = p_user_id;
    
    return v_profile;
end;
$$ language plpgsql security definer;

-- ============================================
-- 7. COMMENTS FOR DOCUMENTATION
-- ============================================

comment on column reviews.reviewed_user_id is 'User who received the review';
comment on column reviews.reviewer_id is 'User who wrote the review (VISIBLE identity)';
comment on column reviews.reviewer_role is 'Role of reviewer at time of review (supplier/trucker)';
comment on column reviews.context_type is 'What triggered the review: chat, load_closed, trip_completed';
comment on column reviews.reply is 'One-time reply from reviewed user (max 500 chars)';
comment on column profile_trust_scores.avg_rating is 'Average rating 0.0-5.0 (0 = no reviews yet)';
