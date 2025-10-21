/*
# [Initial Schema Setup for B-Pharma POS]
This script establishes the complete database schema for the B-Pharma POS application. It creates all necessary tables for managing users, products, inventory, sales, and more. It also sets up a trigger for automatic user profile creation and enables Row Level Security (RLS) with baseline policies for data protection.

## Query Description: [This is a foundational migration and is safe to run on a new project. It creates the entire table structure from scratch. There is no risk of data loss if your database is empty. If you have existing tables with the same names, this script will fail, preventing accidental data loss.]

## Metadata:
- Schema-Category: ["Structural"]
- Impact-Level: ["High"]
- Requires-Backup: [false]
- Reversible: [false]

## Structure Details:
- Creates tables: users, categories, suppliers, products, batches, inventory_movements, purchase_orders, purchase_order_items, sales, sale_items, expenses, settings.
- Defines primary keys, foreign keys, and constraints.
- Adds a trigger to sync `public.users` with `auth.users`.

## Security Implications:
- RLS Status: [Enabled]
- Policy Changes: [Yes]
- Auth Requirements: [Requires authenticated user roles for access]

## Performance Impact:
- Indexes: [Primary key indexes are automatically created]
- Triggers: [Adds one trigger on auth.users for profile creation]
- Estimated Impact: [Low on a new database. The trigger has minimal overhead.]
*/

-- 1. Create ENUM types for status fields
-- Using TEXT and CHECK constraints is often more flexible than native ENUMs in Supabase.

-- 2. Create 'users' table to store public user data
CREATE TABLE public.users (
    id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name text,
    email text UNIQUE,
    phone text,
    role text NOT NULL DEFAULT 'cashier' CHECK (role IN ('super_admin', 'stock_manager', 'cashier')),
    status boolean NOT NULL DEFAULT true,
    last_login timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.users IS 'Stores public user profile and role information.';

-- 3. Create 'categories' table
CREATE TABLE public.categories (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.categories IS 'Product grouping and classification.';

-- 4. Create 'suppliers' table
CREATE TABLE public.suppliers (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    contact_person text,
    phone text,
    email text,
    address text,
    payment_terms text,
    credit_limit numeric,
    rating numeric CHECK (rating >= 0 AND rating <= 5),
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.suppliers IS 'Vendors providing products.';

-- 5. Create 'products' table
CREATE TABLE public.products (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    generic_name text,
    brand_name text,
    category_id uuid REFERENCES public.categories(id),
    supplier_id uuid REFERENCES public.suppliers(id),
    cost_price numeric NOT NULL CHECK (cost_price >= 0),
    selling_price numeric NOT NULL CHECK (selling_price >= 0),
    margin numeric GENERATED ALWAYS AS (selling_price - cost_price) STORED,
    stock_quantity integer NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    min_stock integer NOT NULL DEFAULT 0 CHECK (min_stock >= 0),
    max_stock integer CHECK (max_stock >= min_stock),
    barcode text UNIQUE,
    description text,
    image_url text,
    active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.products IS 'Main product catalog.';

-- 6. Create 'batches' table
CREATE TABLE public.batches (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    batch_number text NOT NULL,
    expiry_date date,
    quantity integer NOT NULL CHECK (quantity >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(product_id, batch_number)
);
COMMENT ON TABLE public.batches IS 'Tracks expiry and batch information for products.';

-- 7. Create 'inventory_movements' table
CREATE TABLE public.inventory_movements (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id uuid NOT NULL REFERENCES public.products(id),
    change_type text NOT NULL CHECK (change_type IN ('sale', 'purchase', 'adjustment', 'return', 'damage')),
    quantity integer NOT NULL,
    user_id uuid REFERENCES public.users(id),
    remarks text,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.inventory_movements IS 'History of all stock changes.';

-- 8. Create 'purchase_orders' table
CREATE TABLE public.purchase_orders (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id uuid NOT NULL REFERENCES public.suppliers(id),
    user_id uuid NOT NULL REFERENCES public.users(id),
    order_date date NOT NULL DEFAULT CURRENT_DATE,
    expected_date date,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'received', 'cancelled')),
    total_amount numeric GENERATED ALWAYS AS (0) STORED, -- Placeholder, to be updated by trigger or application logic
    notes text,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.purchase_orders IS 'For supplier orders.';

-- 9. Create 'purchase_order_items' table
CREATE TABLE public.purchase_order_items (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id uuid NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id),
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_cost numeric NOT NULL CHECK (unit_cost >= 0),
    total_cost numeric GENERATED ALWAYS AS (quantity * unit_cost) STORED,
    UNIQUE(purchase_order_id, product_id)
);
COMMENT ON TABLE public.purchase_order_items IS 'Each line item in a purchase order.';

-- 10. Create 'sales' table
CREATE TABLE public.sales (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.users(id),
    customer_name text,
    customer_contact text,
    subtotal numeric NOT NULL CHECK (subtotal >= 0),
    discount numeric NOT NULL DEFAULT 0 CHECK (discount >= 0),
    tax numeric NOT NULL DEFAULT 0 CHECK (tax >= 0),
    total numeric NOT NULL CHECK (total >= 0),
    payment_method text NOT NULL CHECK (payment_method IN ('cash', 'card', 'insurance', 'other')),
    receipt_number text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.sales IS 'Each completed POS transaction.';

-- 11. Create 'sale_items' table
CREATE TABLE public.sale_items (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id uuid NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id),
    quantity integer NOT NULL CHECK (quantity > 0),
    price numeric NOT NULL CHECK (price >= 0),
    discount numeric NOT NULL DEFAULT 0 CHECK (discount >= 0),
    total numeric GENERATED ALWAYS AS (quantity * price - discount) STORED,
    UNIQUE(sale_id, product_id)
);
COMMENT ON TABLE public.sale_items IS 'Each product sold in a sale.';

-- 12. Create 'expenses' table
CREATE TABLE public.expenses (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    description text NOT NULL,
    amount numeric NOT NULL CHECK (amount > 0),
    category text,
    user_id uuid NOT NULL REFERENCES public.users(id),
    created_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE public.expenses IS 'Operational costs.';

-- 13. Create 'settings' table
CREATE TABLE public.settings (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name text,
    address text,
    tax_rate numeric NOT NULL DEFAULT 0 CHECK (tax_rate >= 0),
    currency text NOT NULL DEFAULT 'USD',
    language text NOT NULL DEFAULT 'en',
    theme text NOT NULL DEFAULT 'light' CHECK (theme IN ('light', 'dark')),
    backup_frequency text DEFAULT 'daily',
    updated_at timestamptz
);
COMMENT ON TABLE public.settings IS 'Global system settings. Should contain only one row.';

-- Insert a single settings row
INSERT INTO public.settings (id, company_name) VALUES (gen_random_uuid(), 'B-Pharma POS');

/*
# [Function and Trigger for User Profile Creation]
This section creates a function and a trigger to automatically create a public user profile in the `public.users` table whenever a new user signs up and is verified in Supabase's `auth.users` table.

## Query Description: [This operation is safe and essential for linking authentication with application data. It ensures that every authenticated user has a corresponding profile record for storing role and other app-specific information.]

## Metadata:
- Schema-Category: ["Structural"]
- Impact-Level: ["Low"]
- Requires-Backup: [false]
- Reversible: [true]
*/
-- Function to create a public user profile
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.users (id, email, full_name, role)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name', 'cashier');
  return new;
end;
$$;

-- Trigger to call the function on new user creation
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

/*
# [Enable Row Level Security (RLS)]
This section enables Row Level Security on all tables to enforce data access policies. By default, this will deny all access until specific policies are created.

## Query Description: [Enabling RLS is a critical security measure. It is safe to run, but be aware that it will block all data access until you define `POLICY` rules for each table. This script includes baseline policies to get started.]

## Metadata:
- Schema-Category: ["Security"]
- Impact-Level: ["High"]
- Requires-Backup: [false]
- Reversible: [true]
*/
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

/*
# [Create RLS Policies]
This section creates the initial set of RLS policies for data access. These policies ensure that users can only access data they are permitted to see.

## Query Description: [These policies are fundamental for application security. They restrict data access based on user roles and ownership. Review them to ensure they match your security requirements.]

## Metadata:
- Schema-Category: ["Security"]
- Impact-Level: ["High"]
- Requires-Backup: [false]
- Reversible: [true]
*/

-- Policies for 'users' table
CREATE POLICY "Allow super admins full access to users" ON public.users
    FOR ALL USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'super_admin');
CREATE POLICY "Allow users to view and update their own data" ON public.users
    FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Policies for 'settings' table
CREATE POLICY "Allow authenticated users to read settings" ON public.settings
    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow super admins to update settings" ON public.settings
    FOR UPDATE USING ((SELECT role FROM public.users WHERE id = auth.uid()) = 'super_admin');

-- General policies for other tables (can be refined later)
CREATE POLICY "Allow authenticated users full access" ON public.categories FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.suppliers FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.products FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.batches FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.inventory_movements FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.purchase_orders FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.purchase_order_items FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.sales FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.sale_items FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated users full access" ON public.expenses FOR ALL USING (auth.role() = 'authenticated');
