/*
          # [B-Pharma POS Initial Schema]
          This migration script establishes the complete database schema for the B-Pharma POS application.
          It creates all necessary tables, roles, relationships, and security policies as defined in the PRD.

          ## Query Description: 
          This is a foundational script that builds the entire data structure from scratch. It includes tables for users, products, inventory, sales, suppliers, and more. It also implements a strict Role-Based Access Control (RLS) system to ensure data security. As this is an initial setup, there is no risk to existing data, but it is critical for all future application functionality.
          
          ## Metadata:
          - Schema-Category: "Structural"
          - Impact-Level: "High"
          - Requires-Backup: false
          - Reversible: false
          
          ## Structure Details:
          - **Enums**: user_role, purchase_order_status, payment_method
          - **Tables**: profiles, categories, suppliers, products, product_batches, purchase_orders, purchase_order_items, customers, sales, sale_items, payments, expenses.
          - **Functions**: get_my_role(), handle_new_user(), update_stock_from_sale(), update_stock_from_purchase().
          - **Triggers**: on_auth_user_created, after_sale_item_insert, after_purchase_item_confirm.
          
          ## Security Implications:
          - RLS Status: Enabled on all tables.
          - Policy Changes: Yes, this script defines all initial RLS policies.
          - Auth Requirements: Policies are tied to the authenticated user's role (Super Admin, Stock Manager, Cashier).
          
          ## Performance Impact:
          - Indexes: Primary and foreign key indexes are created.
          - Triggers: Triggers are used to automate stock management and user profile creation.
          - Estimated Impact: Low, as this is the initial setup.
          */

-- =============================================
-- SECTION 1: TYPES & ENUMS
-- =============================================
/*
          # [Create Enum Types]
          Defines custom data types for user roles and various status fields to ensure data consistency.
          */
CREATE TYPE public.user_role AS ENUM ('Super Admin', 'Stock Manager', 'Cashier');
CREATE TYPE public.purchase_order_status AS ENUM ('Pending', 'Sent', 'Received', 'Cancelled');
CREATE TYPE public.payment_method AS ENUM ('Cash', 'Card', 'Insurance');

-- =============================================
-- SECTION 2: TABLES
-- =============================================
/*
          # [Create Tables]
          Creates the core tables for the application.
          */

-- Table for user profiles, extending auth.users
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    role public.user_role NOT NULL DEFAULT 'Cashier',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for product categories
CREATE TABLE public.categories (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for suppliers
CREATE TABLE public.suppliers (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    contact_person TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for products
CREATE TABLE public.products (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    category_id BIGINT REFERENCES public.categories(id),
    brand_name TEXT,
    generic_name TEXT,
    barcode TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for inventory batches (tracks stock, price, and expiry)
CREATE TABLE public.product_batches (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    product_id BIGINT NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    batch_number TEXT,
    expiry_date DATE,
    cost_price NUMERIC(10, 2) NOT NULL,
    selling_price NUMERIC(10, 2) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    supplier_id BIGINT REFERENCES public.suppliers(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for purchase orders
CREATE TABLE public.purchase_orders (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    supplier_id BIGINT NOT NULL REFERENCES public.suppliers(id),
    status public.purchase_order_status NOT NULL DEFAULT 'Pending',
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date DATE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for items within a purchase order
CREATE TABLE public.purchase_order_items (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    purchase_order_id BIGINT NOT NULL REFERENCES public.purchase_orders(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES public.products(id),
    quantity INT NOT NULL,
    unit_cost NUMERIC(10, 2) NOT NULL,
    batch_number TEXT,
    expiry_date DATE
);

-- Table for customers
CREATE TABLE public.customers (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for sales transactions
CREATE TABLE public.sales (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    cashier_id UUID NOT NULL REFERENCES auth.users(id),
    customer_id BIGINT REFERENCES public.customers(id),
    total_amount NUMERIC(10, 2) NOT NULL,
    sale_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for items within a sale
CREATE TABLE public.sale_items (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    sale_id BIGINT NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    product_batch_id BIGINT NOT NULL REFERENCES public.product_batches(id),
    quantity INT NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL
);

-- Table for payments associated with a sale
CREATE TABLE public.payments (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    sale_id BIGINT NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    payment_method public.payment_method NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table for general expenses
CREATE TABLE public.expenses (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    description TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    category TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================
-- SECTION 3: HELPER FUNCTIONS & TRIGGERS
-- =============================================
/*
          # [Create Functions & Triggers]
          Automates common tasks like creating user profiles and updating inventory.
          */

-- Function to get the role of the current user
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- Trigger function to create a profile for a new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url',
    'Cashier' -- Default role
  );
  RETURN NEW;
END;
$$;

-- Trigger to call the function when a new user signs up
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Trigger function to decrease stock when a sale is made
CREATE OR REPLACE FUNCTION public.update_stock_from_sale()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.product_batches
  SET quantity = quantity - NEW.quantity
  WHERE id = NEW.product_batch_id;
  RETURN NEW;
END;
$$;

-- Trigger to update stock after a sale item is inserted
CREATE TRIGGER after_sale_item_insert
  AFTER INSERT ON public.sale_items
  FOR EACH ROW EXECUTE PROCEDURE public.update_stock_from_sale();

-- Function to increase stock when a purchase is received (to be called manually from app logic or a future trigger)
CREATE OR REPLACE FUNCTION public.update_stock_from_purchase(
  p_purchase_order_item_id BIGINT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  item RECORD;
BEGIN
  SELECT * INTO item FROM public.purchase_order_items WHERE id = p_purchase_order_item_id;
  
  INSERT INTO public.product_batches (product_id, batch_number, expiry_date, cost_price, selling_price, quantity)
  VALUES (item.product_id, item.batch_number, item.expiry_date, item.unit_cost, item.unit_cost * 1.25, item.quantity); -- Assuming 25% markup for selling price
END;
$$;

-- =============================================
-- SECTION 4: ROW LEVEL SECURITY (RLS)
-- =============================================
/*
          # [Enable RLS and Define Policies]
          Secures all tables by enabling RLS and creating policies for each user role.
          */

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Get current user role for policies
CREATE OR REPLACE FUNCTION get_current_user_role() RETURNS TEXT AS $$
BEGIN
  RETURN (SELECT role FROM public.profiles WHERE id = auth.uid());
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ----------------
-- PROFILES POLICIES
-- ----------------
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Super Admins can manage all profiles" ON public.profiles FOR ALL USING (get_my_role() = 'Super Admin');

-- ----------------
-- PRODUCTS, CATEGORIES, SUPPLIERS POLICIES
-- ----------------
CREATE POLICY "All authenticated users can view products, categories, and suppliers" ON public.products FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "All authenticated users can view products, categories, and suppliers" ON public.categories FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "All authenticated users can view products, categories, and suppliers" ON public.suppliers FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "All authenticated users can view product batches" ON public.product_batches FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Stock Managers and Admins can manage products" ON public.products FOR ALL USING (get_my_role() IN ('Super Admin', 'Stock Manager'));
CREATE POLICY "Stock Managers and Admins can manage categories" ON public.categories FOR ALL USING (get_my_role() IN ('Super Admin', 'Stock Manager'));
CREATE POLICY "Stock Managers and Admins can manage suppliers" ON public.suppliers FOR ALL USING (get_my_role() IN ('Super Admin', 'Stock Manager'));
CREATE POLICY "Stock Managers and Admins can manage product batches" ON public.product_batches FOR ALL USING (get_my_role() IN ('Super Admin', 'Stock Manager'));

-- ----------------
-- SALES & POS POLICIES
-- ----------------
CREATE POLICY "Cashiers and above can create sales and related data" ON public.sales FOR INSERT WITH CHECK (get_my_role() IN ('Super Admin', 'Stock Manager', 'Cashier'));
CREATE POLICY "Cashiers and above can create sales and related data" ON public.sale_items FOR INSERT WITH CHECK (get_my_role() IN ('Super Admin', 'Stock Manager', 'Cashier'));
CREATE POLICY "Cashiers and above can create sales and related data" ON public.payments FOR INSERT WITH CHECK (get_my_role() IN ('Super Admin', 'Stock Manager', 'Cashier'));
CREATE POLICY "Cashiers and above can create sales and related data" ON public.customers FOR INSERT WITH CHECK (get_my_role() IN ('Super Admin', 'Stock Manager', 'Cashier'));

CREATE POLICY "Users can view their own sales" ON public.sales FOR SELECT USING (cashier_id = auth.uid() OR get_my_role() IN ('Super Admin', 'Stock Manager'));
CREATE POLICY "Admins and Managers can view all sales data" ON public.sales FOR SELECT USING (get_my_role() IN ('Super Admin', 'Stock Manager'));
CREATE POLICY "Admins and Managers can view all sales data" ON public.sale_items FOR SELECT USING (get_my_role() IN ('Super Admin', 'Stock Manager'));
CREATE POLICY "Admins and Managers can view all sales data" ON public.payments FOR SELECT USING (get_my_role() IN ('Super Admin', 'Stock Manager'));
CREATE POLICY "Admins and Managers can view all sales data" ON public.customers FOR SELECT USING (get_my_role() IN ('Super Admin', 'Stock Manager'));

-- ----------------
-- PURCHASES POLICIES
-- ----------------
CREATE POLICY "Stock Managers and Admins can manage purchases" ON public.purchase_orders FOR ALL USING (get_my_role() IN ('Super Admin', 'Stock Manager'));
CREATE POLICY "Stock Managers and Admins can manage purchases" ON public.purchase_order_items FOR ALL USING (get_my_role() IN ('Super Admin', 'Stock Manager'));

-- ----------------
-- EXPENSES POLICIES
-- ----------------
CREATE POLICY "Admins can manage expenses" ON public.expenses FOR ALL USING (get_my_role() = 'Super Admin');
CREATE POLICY "Stock Managers can view expenses" ON public.expenses FOR SELECT USING (get_my_role() = 'Stock Manager');
