-- AAROGYA Business Manager Pro: starter Supabase schema
-- Run in Supabase SQL Editor only after reviewing. This is a development foundation, not a production audit.
create extension if not exists pgcrypto;
create table if not exists public.businesses (
 id uuid primary key default gen_random_uuid(), display_name text not null,
 phone text, pan_vat text, address text, vat_registered boolean not null default false,
 bill_language text not null default 'en', logo_url text, theme_color text default '#0f766e',
 created_at timestamptz not null default now()
);
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 email text not null, tenant_id uuid references public.businesses(id) on delete cascade,
 role text not null default 'business_admin', status text not null default 'pending',
 created_at timestamptz not null default now()
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null references businesses(id) on delete cascade,
 name text not null, sku text, category text, unit text, stock numeric(14,3) not null default 0,
 cost numeric(14,2) not null default 0, price numeric(14,2) not null default 0,
 batch_no text, expiry_date date, reorder_level numeric(14,3) not null default 0,
 created_at timestamptz not null default now()
);
create table if not exists public.parties (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null references businesses(id) on delete cascade,
 name text not null, party_type text, pan_vat text, phone text, address text, email text,
 created_at timestamptz not null default now()
);
create table if not exists public.sales (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null references businesses(id) on delete cascade,
 invoice_no text not null, party_id uuid references parties(id), items jsonb not null default '[]',
 subtotal numeric(14,2) not null default 0, tax_amount numeric(14,2) not null default 0,
 total numeric(14,2) not null default 0, payment_mode text, created_at timestamptz not null default now(),
 unique(tenant_id,invoice_no)
);
create table if not exists public.purchases (
 id uuid primary key default gen_random_uuid(), tenant_id uuid not null references businesses(id) on delete cascade,
 supplier_name text, items jsonb not null default '[]', total numeric(14,2) not null default 0,
 created_at timestamptz not null default now()
);
create or replace function public.current_tenant() returns uuid language sql stable security definer set search_path=public as $$
 select tenant_id from public.profiles where id=auth.uid() and status='approved' limit 1;
$$;
alter table businesses enable row level security;
alter table profiles enable row level security;
alter table products enable row level security;
alter table parties enable row level security;
alter table sales enable row level security;
alter table purchases enable row level security;
create policy "profile self read" on profiles for select to authenticated using(id=auth.uid());
create policy "tenant business read" on businesses for select to authenticated using(id=public.current_tenant());
create policy "tenant products access" on products for all to authenticated using(tenant_id=public.current_tenant()) with check(tenant_id=public.current_tenant());
create policy "tenant parties access" on parties for all to authenticated using(tenant_id=public.current_tenant()) with check(tenant_id=public.current_tenant());
create policy "tenant sales access" on sales for all to authenticated using(tenant_id=public.current_tenant()) with check(tenant_id=public.current_tenant());
create policy "tenant purchases access" on purchases for all to authenticated using(tenant_id=public.current_tenant()) with check(tenant_id=public.current_tenant());
-- User registration trigger, master-admin approval and production-grade policies must be added
-- after deciding the secure onboarding and tenant provisioning workflow.
