create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  preferred_language text not null default 'en' check (preferred_language in ('en','bn')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create or replace function public.handle_new_auth_user() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,full_name)
  values(new.id,nullif(trim(new.raw_user_meta_data->>'full_name'),''))
  on conflict (id) do nothing;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_auth_user();

create table public.business_types (
  id text primary key,
  name text not null,
  description text not null default '',
  display_order smallint not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.industry_modules (
  id text primary key,
  name text not null,
  description text not null default '',
  category text not null default 'core' check (category in ('core','industry','optional')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.industry_module_types (
  business_type_id text not null references public.business_types(id) on delete cascade,
  module_id text not null references public.industry_modules(id) on delete cascade,
  primary key (business_type_id,module_id)
);

create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 120),
  owner_name text not null,
  phone text not null,
  address text,
  gstin text check (gstin is null or gstin ~ '^[0-9A-Z]{15}$'),
  business_type text not null references public.business_types(id),
  currency char(3) not null default 'INR',
  timezone text not null default 'Asia/Kolkata',
  financial_year_start text not null default '04-01' check (financial_year_start in ('01-01','04-01','07-01')),
  inventory_enabled boolean not null default true,
  billing_enabled boolean not null default true,
  payment_preference text not null default 'cash_upi' check (payment_preference in ('cash_upi','cash','bank','mixed')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  archived_at timestamptz
);
create index businesses_created_by_idx on public.businesses(created_by) where archived_at is null;

create table public.business_categories (
  business_id uuid not null references public.businesses(id) on delete cascade,
  business_type_id text not null references public.business_types(id),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (business_id,business_type_id)
);
create unique index one_primary_category_per_business on public.business_categories(business_id) where is_primary;

create table public.business_members (
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','manager','accountant','sales','inventory','delivery')),
  created_at timestamptz not null default now(),
  primary key (business_id,user_id)
);
create index business_members_user_idx on public.business_members(user_id,business_id);

create table public.business_invitations (
  id uuid primary key default gen_random_uuid(), business_id uuid not null references public.businesses(id) on delete cascade,
  email text not null, role text not null check (role in ('manager','accountant','sales','inventory','delivery')),
  invited_by uuid not null references auth.users(id), token_hash text not null unique,
  expires_at timestamptz not null, accepted_at timestamptz, created_at timestamptz not null default now()
);

create table public.business_modules (
  business_id uuid not null references public.businesses(id) on delete cascade,
  module_id text not null references public.industry_modules(id),
  enabled boolean not null default true,
  enabled_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  primary key (business_id,module_id)
);
create index business_modules_enabled_idx on public.business_modules(business_id) where enabled;

insert into public.business_types(id,name,description,display_order) values
('grocery','Grocery Store','Fresh stock, fast checkout and expiry tracking.',1),
('clothing','Clothing and Fashion Store','Manage sizes, colors, collections and seasons.',2),
('electronics','Electronics Store','Track serial numbers, warranty and repairs.',3),
('pharmacy','Pharmacy','Keep medicine batch and expiry details close at hand.',4),
('restaurant','Restaurant','Connect menus, tables, recipes and orders.',5),
('wholesale','Wholesale Business','Make bulk orders and customer pricing easier.',6),
('hardware','Hardware Store','Sell by weight, length, volume or piece.',7),
('ecommerce','Online / E-commerce Business','Bring orders, shipping and returns together.',8),
('distribution','Distributor and Wholesaler','Coordinate dealers, territories and delivery.',9)
on conflict (id) do update set name=excluded.name, description=excluded.description, display_order=excluded.display_order;

insert into public.industry_modules(id,name,category) values
('dashboard','Dashboard','core'),('customers','Customers','core'),('suppliers','Suppliers','core'),('products','Products','core'),('inventory','Inventory','core'),('sales','Sales','core'),('purchases','Purchases','core'),('payments','Payments','core'),('accounting','Accounting','core'),('expenses','Expenses','core'),('invoices','Invoices','core'),('reports','Reports','core'),('employees','Employees','core'),('notifications','Notifications','core'),('settings','Settings','core'),
('barcode','Barcode','industry'),('low_stock','Low stock alerts','industry'),('fast_moving','Fast-moving products','industry'),('expiry','Expiry tracking','industry'),('size_variants','Size variants','industry'),('color_variants','Color variants','industry'),('brands_collections','Brands and collections','industry'),('seasonal_inventory','Seasonal inventory','industry'),('serial_numbers','IMEI and serial numbers','industry'),('warranty','Warranty tracking','industry'),('repairs','Repair records','industry'),('product_models','Product models','industry'),('medicine_batches','Medicine batches','industry'),('prescriptions','Prescription records','industry'),('food_menu','Food menu','industry'),('table_management','Table management','industry'),('kitchen_display','Kitchen display','industry'),('recipes','Recipe management','industry'),('takeaway_delivery','Takeaway and delivery','industry'),('bulk_orders','Bulk orders','industry'),('wholesale_tiers','Wholesale price tiers','industry'),('credit_limits','Customer credit limits','industry'),('bulk_inventory','Bulk inventory','industry'),('measurement_products','Measurement-based products','industry'),('product_specifications','Product specifications','industry'),('online_orders','Online orders','industry'),('shipping_fulfillment','Shipping and fulfillment','industry'),('returns_refunds','Returns and refunds','industry'),('sales_channels','Sales channels','industry'),('dealer_management','Dealer management','industry'),('territories','Territory management','industry'),('sales_representatives','Sales representatives','industry'),('delivery_routes','Delivery routes and stock transfers','industry')
on conflict (id) do update set name=excluded.name, category=excluded.category;

insert into public.industry_module_types(business_type_id,module_id)
select bt, m from (values
('grocery','barcode'),('grocery','low_stock'),('grocery','fast_moving'),('grocery','expiry'),
('clothing','size_variants'),('clothing','color_variants'),('clothing','brands_collections'),('clothing','seasonal_inventory'),
('electronics','serial_numbers'),('electronics','warranty'),('electronics','repairs'),('electronics','product_models'),
('pharmacy','medicine_batches'),('pharmacy','expiry'),('pharmacy','prescriptions'),
('restaurant','food_menu'),('restaurant','table_management'),('restaurant','kitchen_display'),('restaurant','recipes'),('restaurant','takeaway_delivery'),
('wholesale','bulk_orders'),('wholesale','wholesale_tiers'),('wholesale','credit_limits'),('wholesale','bulk_inventory'),
('hardware','measurement_products'),('hardware','product_specifications'),('hardware','bulk_inventory'),
('ecommerce','online_orders'),('ecommerce','shipping_fulfillment'),('ecommerce','returns_refunds'),('ecommerce','sales_channels'),
('distribution','dealer_management'),('distribution','territories'),('distribution','sales_representatives'),('distribution','delivery_routes'),('distribution','bulk_inventory')
) as x(bt,m) on conflict do nothing;
insert into public.industry_module_types(business_type_id,module_id)
select bt.id, im.id from public.business_types bt cross join public.industry_modules im where im.category='core' on conflict do nothing;

create or replace function public.is_business_member(target_business uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.business_members bm where bm.business_id=target_business and bm.user_id=(select auth.uid()))
$$;
create or replace function public.has_business_role(target_business uuid, allowed_roles text[])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.business_members bm where bm.business_id=target_business and bm.user_id=(select auth.uid()) and bm.role=any(allowed_roles))
$$;
revoke all on function public.is_business_member(uuid) from public;
revoke all on function public.has_business_role(uuid,text[]) from public;
grant execute on function public.is_business_member(uuid) to authenticated;
grant execute on function public.has_business_role(uuid,text[]) to authenticated;

create or replace function public.create_business_onboarding(
  p_primary_type text, p_additional_types text[], p_name text, p_owner_name text, p_phone text,
  p_address text, p_gstin text, p_currency text, p_financial_year_start text,
  p_inventory_enabled boolean, p_billing_enabled boolean, p_payment_preference text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare new_business_id uuid; category_id text;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.business_types where id=p_primary_type and active) then raise exception 'Unknown industry'; end if;
  if exists(select 1 from unnest(coalesce(p_additional_types,'{}'::text[])) x where not exists(select 1 from public.business_types where id=x and active)) then raise exception 'Unknown industry'; end if;
  insert into public.businesses(name,owner_name,phone,address,gstin,business_type,currency,financial_year_start,inventory_enabled,billing_enabled,payment_preference,created_by)
  values (p_name,p_owner_name,p_phone,p_address,nullif(upper(p_gstin),''),p_primary_type,upper(p_currency),p_financial_year_start,p_inventory_enabled,p_billing_enabled,p_payment_preference,(select auth.uid())) returning id into new_business_id;
  insert into public.business_members(business_id,user_id,role) values(new_business_id,(select auth.uid()),'owner');
  insert into public.business_categories(business_id,business_type_id,is_primary) values(new_business_id,p_primary_type,true);
  foreach category_id in array coalesce(p_additional_types,'{}'::text[]) loop
    if category_id<>p_primary_type then insert into public.business_categories(business_id,business_type_id,is_primary) values(new_business_id,category_id,false) on conflict do nothing; end if;
  end loop;
  insert into public.profiles(id,full_name) values((select auth.uid()),p_owner_name)
  on conflict(id) do update set full_name=excluded.full_name,updated_at=now();
  insert into public.business_modules(business_id,module_id,enabled,enabled_by)
  select new_business_id,im.id,true,(select auth.uid()) from public.industry_modules im
  where im.category='core' or exists(select 1 from public.industry_module_types imt join public.business_categories bc on bc.business_type_id=imt.business_type_id where imt.module_id=im.id and bc.business_id=new_business_id)
  on conflict do nothing;
  if not p_inventory_enabled then update public.business_modules set enabled=false where business_id=new_business_id and module_id='inventory'; end if;
  if not p_billing_enabled then update public.business_modules set enabled=false where business_id=new_business_id and module_id='invoices'; end if;
  return jsonb_build_object('business_id',new_business_id);
end $$;
revoke all on function public.create_business_onboarding(text,text[],text,text,text,text,text,text,text,boolean,boolean,text) from public;
grant execute on function public.create_business_onboarding(text,text[],text,text,text,text,text,text,text,boolean,boolean,text) to authenticated;

create or replace function public.set_business_module(target_business uuid, target_module text, should_enable boolean)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.has_business_role(target_business,array['owner','manager']) then raise exception 'Not authorized'; end if;
  if target_module='dashboard' and not should_enable then raise exception 'Dashboard is required'; end if;
  if not exists(select 1 from public.business_modules where business_id=target_business and module_id=target_module) then raise exception 'Module is not available for this business'; end if;
  update public.business_modules set enabled=should_enable,enabled_by=(select auth.uid()),updated_at=now() where business_id=target_business and module_id=target_module;
end $$;
revoke all on function public.set_business_module(uuid,text,boolean) from public;
grant execute on function public.set_business_module(uuid,text,boolean) to authenticated;

create or replace function public.touch_updated_at() returns trigger language plpgsql set search_path='' as $$ begin new.updated_at=now(); return new; end $$;
create trigger profiles_touch_updated_at before update on public.profiles for each row execute function public.touch_updated_at();
create trigger businesses_touch_updated_at before update on public.businesses for each row execute function public.touch_updated_at();
create trigger business_modules_touch_updated_at before update on public.business_modules for each row execute function public.touch_updated_at();

alter table public.profiles enable row level security;
alter table public.business_types enable row level security;
alter table public.industry_modules enable row level security;
alter table public.industry_module_types enable row level security;
alter table public.businesses enable row level security;
alter table public.business_categories enable row level security;
alter table public.business_members enable row level security;
alter table public.business_invitations enable row level security;
alter table public.business_modules enable row level security;

create policy "users read own profile" on public.profiles for select to authenticated using (id=(select auth.uid()));
create policy "users update own profile" on public.profiles for update to authenticated using (id=(select auth.uid())) with check (id=(select auth.uid()));
create policy "authenticated users read active business types" on public.business_types for select to authenticated using (active);
create policy "authenticated users read active modules" on public.industry_modules for select to authenticated using (active);
create policy "authenticated users read module mappings" on public.industry_module_types for select to authenticated using (exists(select 1 from public.business_types bt where bt.id=business_type_id and bt.active));
create policy "members read businesses" on public.businesses for select to authenticated using (public.is_business_member(id) and archived_at is null);
create policy "owners update businesses" on public.businesses for update to authenticated using (public.has_business_role(id,array['owner'])) with check (public.has_business_role(id,array['owner']));
create policy "members read business categories" on public.business_categories for select to authenticated using (public.is_business_member(business_id));
create policy "members read business memberships" on public.business_members for select to authenticated using (public.is_business_member(business_id));
create policy "owners manage invitations" on public.business_invitations for all to authenticated using (public.has_business_role(business_id,array['owner','manager'])) with check (public.has_business_role(business_id,array['owner','manager']));
create policy "members read business modules" on public.business_modules for select to authenticated using (public.is_business_member(business_id));

grant select, update on public.profiles to authenticated;
grant select on public.business_types, public.industry_modules, public.industry_module_types to authenticated;
grant select on public.businesses to authenticated;
grant update (name,owner_name,phone,address,gstin,currency,timezone,financial_year_start,inventory_enabled,billing_enabled,payment_preference) on public.businesses to authenticated;
grant select on public.business_categories, public.business_members, public.business_modules to authenticated;
grant select, insert, update, delete on public.business_invitations to authenticated;

-- New business-owned tables must use business_id and enable RLS with is_business_member(business_id).
-- Module authorization must be checked in server operations/RPCs in addition to navigation filtering.
