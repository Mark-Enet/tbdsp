-- =============================================================================
-- TBDSP — The Big DataBase Standards Project
-- Domain   : E-Commerce
-- Database : PostgreSQL 14+
-- File     : schema.sql
-- Version  : 1.0.0
-- Description:
--   A production-ready e-commerce schema covering customers, addresses,
--   product catalog (with categories), orders, payments, and reviews.
--   Designed to reflect real-world best practices: surrogate PKs, FK
--   constraints, CHECK constraints for business rules, partial indexes,
--   and clear comments throughout.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- case-insensitive text for emails

-- ---------------------------------------------------------------------------
-- Enum types
-- ---------------------------------------------------------------------------

CREATE TYPE order_status AS ENUM (
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
);

CREATE TYPE payment_method AS ENUM (
    'credit_card',
    'debit_card',
    'paypal',
    'bank_transfer',
    'crypto',
    'gift_card'
);

CREATE TYPE payment_status AS ENUM (
    'pending',
    'authorized',
    'captured',
    'failed',
    'refunded',
    'voided'
);

CREATE TYPE address_type AS ENUM (
    'billing',
    'shipping',
    'both'
);

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
-- Stores registered users. Email uses the citext extension so that
-- uniqueness checks are case-insensitive without lowercasing on every write.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT          NOT NULL,
    password_hash   TEXT            NOT NULL,
    first_name      VARCHAR(100)    NOT NULL,
    last_name       VARCHAR(100)    NOT NULL,
    phone           VARCHAR(30),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_customers_email UNIQUE (email)
);

CREATE INDEX idx_customers_email         ON customers (email);
CREATE INDEX idx_customers_created_at    ON customers (created_at DESC);

COMMENT ON TABLE  customers              IS 'Registered customer accounts.';
COMMENT ON COLUMN customers.email        IS 'Login email — unique, case-insensitive.';
COMMENT ON COLUMN customers.password_hash IS 'bcrypt / argon2 hash; never store plain-text.';

-- ---------------------------------------------------------------------------
-- addresses
-- ---------------------------------------------------------------------------
-- A customer may have multiple saved addresses (billing, shipping, or both).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS addresses (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID            NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
    type            address_type    NOT NULL DEFAULT 'shipping',
    is_default      BOOLEAN         NOT NULL DEFAULT FALSE,
    full_name       VARCHAR(200)    NOT NULL,
    line1           VARCHAR(255)    NOT NULL,
    line2           VARCHAR(255),
    city            VARCHAR(100)    NOT NULL,
    state           VARCHAR(100),
    postal_code     VARCHAR(20)     NOT NULL,
    country_code    CHAR(2)         NOT NULL,   -- ISO 3166-1 alpha-2
    phone           VARCHAR(30),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_addresses_customer_id ON addresses (customer_id);

COMMENT ON TABLE  addresses              IS 'Saved billing/shipping addresses per customer.';
COMMENT ON COLUMN addresses.country_code IS 'ISO 3166-1 alpha-2 country code, e.g. US, GB, DE.';

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
-- Self-referencing adjacency-list for a multi-level category tree.
-- Use a recursive CTE when querying full paths or subtrees.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id              SERIAL          PRIMARY KEY,
    parent_id       INTEGER         REFERENCES categories (id) ON DELETE SET NULL,
    name            VARCHAR(150)    NOT NULL,
    slug            VARCHAR(150)    NOT NULL,
    description     TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_categories_slug UNIQUE (slug)
);

CREATE INDEX idx_categories_parent_id ON categories (parent_id);

COMMENT ON TABLE  categories           IS 'Hierarchical product categories (adjacency list).';
COMMENT ON COLUMN categories.slug      IS 'URL-safe unique identifier, e.g. "mens-shoes".';
COMMENT ON COLUMN categories.parent_id IS 'NULL for top-level categories.';

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
-- Core product catalog. Inventory and variant management (size, colour, etc.)
-- is handled by the product_variants table below.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id     INTEGER         REFERENCES categories (id) ON DELETE SET NULL,
    name            VARCHAR(255)    NOT NULL,
    slug            VARCHAR(255)    NOT NULL,
    description     TEXT,
    base_price      NUMERIC(12, 2)  NOT NULL,
    currency        CHAR(3)         NOT NULL DEFAULT 'USD',  -- ISO 4217
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_products_base_price CHECK (base_price >= 0),
    CONSTRAINT uq_products_slug         UNIQUE (slug)
);

CREATE INDEX idx_products_category_id  ON products (category_id);
CREATE INDEX idx_products_is_active    ON products (is_active) WHERE is_active = TRUE;
CREATE INDEX idx_products_slug         ON products (slug);

COMMENT ON TABLE  products             IS 'Master product catalog.';
COMMENT ON COLUMN products.base_price  IS 'List price before discounts; variants may override.';
COMMENT ON COLUMN products.currency    IS 'ISO 4217 currency code, e.g. USD, EUR.';

-- ---------------------------------------------------------------------------
-- product_variants
-- ---------------------------------------------------------------------------
-- Each variant represents a specific purchasable SKU (e.g., size M / blue).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product_variants (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id      UUID            NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    sku             VARCHAR(100)    NOT NULL,
    attributes      JSONB           NOT NULL DEFAULT '{}',  -- e.g. {"size":"M","color":"blue"}
    price_override  NUMERIC(12, 2),  -- NULL means use products.base_price
    stock_qty       INTEGER         NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_product_variants_sku  UNIQUE (sku),
    CONSTRAINT chk_variant_stock        CHECK (stock_qty >= 0),
    CONSTRAINT chk_variant_price        CHECK (price_override IS NULL OR price_override >= 0)
);

CREATE INDEX idx_product_variants_product_id ON product_variants (product_id);
CREATE INDEX idx_product_variants_sku        ON product_variants (sku);
CREATE INDEX idx_product_variants_attributes ON product_variants USING GIN (attributes);

COMMENT ON TABLE  product_variants            IS 'Purchasable SKUs — size, colour, etc.';
COMMENT ON COLUMN product_variants.attributes IS 'Free-form JSONB for variant dimensions.';

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
-- An order belongs to one customer and has a snapshot of the shipping address
-- (stored as JSONB) so that the address can later be changed without
-- affecting historical orders.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id         UUID            NOT NULL REFERENCES customers (id),
    status              order_status    NOT NULL DEFAULT 'pending',
    shipping_address    JSONB           NOT NULL,  -- snapshot at time of order
    subtotal            NUMERIC(12, 2)  NOT NULL,
    shipping_cost       NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    discount_amount     NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    tax_amount          NUMERIC(12, 2)  NOT NULL DEFAULT 0,
    total_amount        NUMERIC(12, 2)  NOT NULL,
    notes               TEXT,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_orders_subtotal      CHECK (subtotal >= 0),
    CONSTRAINT chk_orders_shipping_cost CHECK (shipping_cost >= 0),
    CONSTRAINT chk_orders_discount      CHECK (discount_amount >= 0),
    CONSTRAINT chk_orders_tax           CHECK (tax_amount >= 0),
    CONSTRAINT chk_orders_total         CHECK (total_amount >= 0)
);

CREATE INDEX idx_orders_customer_id  ON orders (customer_id);
CREATE INDEX idx_orders_status       ON orders (status);
CREATE INDEX idx_orders_created_at   ON orders (created_at DESC);

COMMENT ON TABLE  orders                   IS 'Customer purchase orders.';
COMMENT ON COLUMN orders.shipping_address  IS 'JSON snapshot of the address at order time.';
COMMENT ON COLUMN orders.total_amount      IS 'subtotal + shipping_cost + tax_amount - discount_amount.';

-- ---------------------------------------------------------------------------
-- order_items
-- ---------------------------------------------------------------------------
-- Line items for each order. Unit price is a snapshot of the price paid;
-- it must not change when the product price changes later.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS order_items (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id        UUID            NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    variant_id      UUID            NOT NULL REFERENCES product_variants (id),
    quantity        INTEGER         NOT NULL,
    unit_price      NUMERIC(12, 2)  NOT NULL,  -- price at time of purchase
    discount        NUMERIC(12, 2)  NOT NULL DEFAULT 0,

    CONSTRAINT chk_order_items_qty       CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price     CHECK (unit_price >= 0),
    CONSTRAINT chk_order_items_discount  CHECK (discount >= 0)
);

CREATE INDEX idx_order_items_order_id   ON order_items (order_id);
CREATE INDEX idx_order_items_variant_id ON order_items (variant_id);

COMMENT ON TABLE  order_items            IS 'Individual line items within an order.';
COMMENT ON COLUMN order_items.unit_price IS 'Historical price snapshot — never update.';

-- ---------------------------------------------------------------------------
-- payments
-- ---------------------------------------------------------------------------
-- A single order may have multiple payment attempts (e.g., failed first card,
-- succeeded on second). Only one should have status='captured' per order.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            UUID            NOT NULL REFERENCES orders (id),
    method              payment_method  NOT NULL,
    status              payment_status  NOT NULL DEFAULT 'pending',
    amount              NUMERIC(12, 2)  NOT NULL,
    currency            CHAR(3)         NOT NULL DEFAULT 'USD',
    provider_reference  VARCHAR(255),   -- gateway transaction ID
    processed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_payments_amount CHECK (amount > 0)
);

CREATE INDEX idx_payments_order_id ON payments (order_id);
CREATE INDEX idx_payments_status   ON payments (status);

COMMENT ON TABLE  payments                   IS 'Payment transactions linked to orders.';
COMMENT ON COLUMN payments.provider_reference IS 'Opaque reference from the payment gateway.';

-- ---------------------------------------------------------------------------
-- reviews
-- ---------------------------------------------------------------------------
-- Customers can review a product (not a variant) once per product.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id      UUID            NOT NULL REFERENCES products (id) ON DELETE CASCADE,
    customer_id     UUID            NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
    rating          SMALLINT        NOT NULL,
    title           VARCHAR(255),
    body            TEXT,
    is_verified     BOOLEAN         NOT NULL DEFAULT FALSE,  -- verified purchase
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_reviews_product_customer UNIQUE (product_id, customer_id),
    CONSTRAINT chk_reviews_rating          CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX idx_reviews_product_id  ON reviews (product_id);
CREATE INDEX idx_reviews_customer_id ON reviews (customer_id);
CREATE INDEX idx_reviews_rating      ON reviews (rating);

COMMENT ON TABLE  reviews             IS 'Customer product reviews (one per customer per product).';
COMMENT ON COLUMN reviews.is_verified IS 'TRUE if the reviewer has a confirmed purchase.';

-- ---------------------------------------------------------------------------
-- Trigger helper: auto-update updated_at columns
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'customers', 'addresses', 'products',
        'product_variants', 'orders', 'payments', 'reviews'
    ] LOOP
        EXECUTE format(
            'CREATE OR REPLACE TRIGGER trg_%I_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
            t, t
        );
    END LOOP;
END;
$$;
