create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new."updatedAt" = now();
  return new;
end;
$$;

create table if not exists public.users_profiles (
  id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references auth.users(id) on delete cascade,
  cpf text unique,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now(),
  "onboardedAt" timestamptz,
  "growthLevel" text not null default 'Semente',
  "brandMargins" text,
  "planStatus" text not null default 'free' check ("planStatus" in ('free', 'pro')),
  "planExpiresAt" timestamptz,
  "themeColor" text,
  "emailVerified" boolean,
  constraint users_profiles_user_unique unique ("userId")
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text not null default '',
  "phoneNormalized" text not null default '',
  email text,
  address text,
  "balanceCents" integer not null default 0,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references auth.users(id) on delete cascade,
  "productId" text not null,
  sku text,
  "productName" text not null,
  brand text not null,
  quantity integer not null default 0,
  "costPriceCents" integer not null default 0,
  "sellingPriceCents" integer not null default 0,
  "expiryDate" timestamptz,
  "imageUrl" text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references auth.users(id) on delete cascade,
  "customerId" uuid not null references public.customers(id) on delete restrict,
  items text not null default '[]',
  "totalCents" integer not null default 0,
  "paidCents" integer not null default 0,
  "paymentType" text not null,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists public.receivables (
  id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references auth.users(id) on delete cascade,
  "saleId" uuid not null references public.sales(id) on delete cascade,
  "customerId" uuid not null references public.customers(id) on delete restrict,
  "dueDate" timestamptz not null,
  "amountCents" integer not null default 0,
  "paidCents" integer not null default 0,
  status text not null default 'pending' check (status in ('pending', 'partial', 'paid', 'late')),
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  "userId" uuid not null references auth.users(id) on delete cascade,
  "inventoryId" uuid references public.inventory_items(id) on delete cascade,
  type text,
  quantity integer not null default 0,
  reason text,
  "createdAt" timestamptz not null default now(),
  "updatedAt" timestamptz not null default now()
);

create index if not exists users_profiles_user_id_idx on public.users_profiles ("userId");
create index if not exists customers_user_created_idx on public.customers ("userId", "createdAt" desc);
create index if not exists customers_user_balance_idx on public.customers ("userId", "balanceCents" desc);
create index if not exists inventory_user_expiry_idx on public.inventory_items ("userId", "expiryDate" asc);
create index if not exists inventory_user_product_idx on public.inventory_items ("userId", "productId");
create index if not exists sales_user_created_idx on public.sales ("userId", "createdAt" desc);
create index if not exists sales_user_customer_idx on public.sales ("userId", "customerId");
create index if not exists receivables_user_due_idx on public.receivables ("userId", "dueDate" asc);
create index if not exists receivables_user_customer_idx on public.receivables ("userId", "customerId");
create index if not exists receivables_user_status_idx on public.receivables ("userId", status);
create index if not exists movements_user_created_idx on public.inventory_movements ("userId", "createdAt" desc);

drop trigger if exists users_profiles_set_updated_at on public.users_profiles;
create trigger users_profiles_set_updated_at
before update on public.users_profiles
for each row execute function public.set_updated_at();

drop trigger if exists customers_set_updated_at on public.customers;
create trigger customers_set_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

drop trigger if exists inventory_items_set_updated_at on public.inventory_items;
create trigger inventory_items_set_updated_at
before update on public.inventory_items
for each row execute function public.set_updated_at();

drop trigger if exists sales_set_updated_at on public.sales;
create trigger sales_set_updated_at
before update on public.sales
for each row execute function public.set_updated_at();

drop trigger if exists receivables_set_updated_at on public.receivables;
create trigger receivables_set_updated_at
before update on public.receivables
for each row execute function public.set_updated_at();

drop trigger if exists inventory_movements_set_updated_at on public.inventory_movements;
create trigger inventory_movements_set_updated_at
before update on public.inventory_movements
for each row execute function public.set_updated_at();

alter table public.users_profiles enable row level security;
alter table public.customers enable row level security;
alter table public.inventory_items enable row level security;
alter table public.sales enable row level security;
alter table public.receivables enable row level security;
alter table public.inventory_movements enable row level security;

drop policy if exists "users_profiles_select_own" on public.users_profiles;
drop policy if exists "users_profiles_insert_own" on public.users_profiles;
drop policy if exists "users_profiles_update_own" on public.users_profiles;
drop policy if exists "users_profiles_delete_own" on public.users_profiles;
drop policy if exists "customers_select_own" on public.customers;
drop policy if exists "customers_insert_own" on public.customers;
drop policy if exists "customers_update_own" on public.customers;
drop policy if exists "customers_delete_own" on public.customers;
drop policy if exists "inventory_items_select_own" on public.inventory_items;
drop policy if exists "inventory_items_insert_own" on public.inventory_items;
drop policy if exists "inventory_items_update_own" on public.inventory_items;
drop policy if exists "inventory_items_delete_own" on public.inventory_items;
drop policy if exists "sales_select_own" on public.sales;
drop policy if exists "sales_insert_own" on public.sales;
drop policy if exists "sales_update_own" on public.sales;
drop policy if exists "sales_delete_own" on public.sales;
drop policy if exists "receivables_select_own" on public.receivables;
drop policy if exists "receivables_insert_own" on public.receivables;
drop policy if exists "receivables_update_own" on public.receivables;
drop policy if exists "receivables_delete_own" on public.receivables;
drop policy if exists "inventory_movements_select_own" on public.inventory_movements;
drop policy if exists "inventory_movements_insert_own" on public.inventory_movements;
drop policy if exists "inventory_movements_update_own" on public.inventory_movements;
drop policy if exists "inventory_movements_delete_own" on public.inventory_movements;

create policy "users_profiles_select_own" on public.users_profiles
for select using ("userId" = auth.uid());
create policy "users_profiles_insert_own" on public.users_profiles
for insert with check ("userId" = auth.uid());
create policy "users_profiles_update_own" on public.users_profiles
for update using ("userId" = auth.uid()) with check ("userId" = auth.uid());
create policy "users_profiles_delete_own" on public.users_profiles
for delete using ("userId" = auth.uid());

create policy "customers_select_own" on public.customers
for select using ("userId" = auth.uid());
create policy "customers_insert_own" on public.customers
for insert with check ("userId" = auth.uid());
create policy "customers_update_own" on public.customers
for update using ("userId" = auth.uid()) with check ("userId" = auth.uid());
create policy "customers_delete_own" on public.customers
for delete using ("userId" = auth.uid());

create policy "inventory_items_select_own" on public.inventory_items
for select using ("userId" = auth.uid());
create policy "inventory_items_insert_own" on public.inventory_items
for insert with check ("userId" = auth.uid());
create policy "inventory_items_update_own" on public.inventory_items
for update using ("userId" = auth.uid()) with check ("userId" = auth.uid());
create policy "inventory_items_delete_own" on public.inventory_items
for delete using ("userId" = auth.uid());

create policy "sales_select_own" on public.sales
for select using ("userId" = auth.uid());
create policy "sales_insert_own" on public.sales
for insert with check ("userId" = auth.uid());
create policy "sales_update_own" on public.sales
for update using ("userId" = auth.uid()) with check ("userId" = auth.uid());
create policy "sales_delete_own" on public.sales
for delete using ("userId" = auth.uid());

create policy "receivables_select_own" on public.receivables
for select using ("userId" = auth.uid());
create policy "receivables_insert_own" on public.receivables
for insert with check ("userId" = auth.uid());
create policy "receivables_update_own" on public.receivables
for update using ("userId" = auth.uid()) with check ("userId" = auth.uid());
create policy "receivables_delete_own" on public.receivables
for delete using ("userId" = auth.uid());

create policy "inventory_movements_select_own" on public.inventory_movements
for select using ("userId" = auth.uid());
create policy "inventory_movements_insert_own" on public.inventory_movements
for insert with check ("userId" = auth.uid());
create policy "inventory_movements_update_own" on public.inventory_movements
for update using ("userId" = auth.uid()) with check ("userId" = auth.uid());
create policy "inventory_movements_delete_own" on public.inventory_movements
for delete using ("userId" = auth.uid());
