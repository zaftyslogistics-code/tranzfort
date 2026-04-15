-- Proper sync trigger now that profiles has city/state columns
-- This replaces the temporary no-op trigger with the actual sync logic

create or replace function sync_supplier_location_to_profile()
returns trigger as $$
begin
  -- When supplier verification location is updated, sync to profiles
  if new.verification_location_city is not null then
    update profiles
    set 
      city = new.verification_location_city,
      state = new.verification_location_state
    where id = new.id;
  end if;
  return new;
end;
$$ language plpgsql;

-- Drop and recreate trigger
drop trigger if exists trg_sync_supplier_location on suppliers;

create trigger trg_sync_supplier_location
after update of verification_location_city, verification_location_state on suppliers
for each row execute function sync_supplier_location_to_profile();

-- Add comment
comment on function sync_supplier_location_to_profile() is 'Syncs supplier verification location to profiles.city/state columns';
