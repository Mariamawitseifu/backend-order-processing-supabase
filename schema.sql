-- Enable UUID generation (used by Supabase)
create extension if not exists "pgcrypto";

--  Businesses (Tenants)
create table businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz default now()
);

-- Customers
create table customers (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  name text not null,
  credit_limit numeric not null,
  credit_used numeric not null default 0,
  created_at timestamptz default now()
);

-- Products
create table products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  name text not null,
  price numeric not null,
  stock integer not null,
  created_at timestamptz default now()
);

-- Orders
create table orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  customer_id uuid not null references customers(id),
  total_amount numeric not null,
  status text not null default 'unpaid',
  created_at timestamptz default now()
);

-- Order Items
create table order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders(id) on delete cascade,
  product_id uuid not null references products(id),
  quantity integer not null,
  unit_price numeric not null
);

-- Credit Ledger
create table credit_ledger (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  customer_id uuid not null references customers(id),
  order_id uuid not null references orders(id),
  amount numeric not null,
  paid boolean not null default false,
  created_at timestamptz default now()
);
