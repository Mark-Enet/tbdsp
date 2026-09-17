-- =============================================================================
-- TBDSP - The Big DataBase Standards Project
-- Domain   : ERP
-- Database : PostgreSQL 14+
-- File     : schema.sql
-- Version  : 1.0.0
-- Description:
--   A production-ready ERP schema covering organizations, suppliers,
--   customers, products, warehouses, inventory movements, sales orders,
--   and purchase orders.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

CREATE TYPE order_status AS ENUM (
    'draft',
    'confirmed',
    'partially_fulfilled',
    'fulfilled',
    'cancelled'
);

CREATE TYPE procurement_status AS ENUM (
    'draft',
    'approved',
    'partially_received',
    'received',
    'cancelled'
);

CREATE TYPE stock_move_type AS ENUM (
    'purchase_receipt',
    'sale_shipment',
    'adjustment_in',
    'adjustment_out',
    'transfer'
);

CREATE TABLE IF NOT EXISTS organizations (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name                VARCHAR(200)    NOT NULL,
    tax_id              VARCHAR(40),
    base_currency       CHAR(3)         NOT NULL DEFAULT 'USD',
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_organizations_name UNIQUE (name),
    CONSTRAINT uq_organizations_tax_id UNIQUE (tax_id)
);

CREATE TABLE IF NOT EXISTS suppliers (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    name                VARCHAR(200)    NOT NULL,
    contact_email       CITEXT,
    payment_terms_days  INTEGER         NOT NULL DEFAULT 30 CHECK (payment_terms_days >= 0),
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_suppliers_org_name UNIQUE (organization_id, name)
);

CREATE TABLE IF NOT EXISTS customers (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    name                VARCHAR(200)    NOT NULL,
    email               CITEXT,
    credit_limit        NUMERIC(14, 2)  NOT NULL DEFAULT 0 CHECK (credit_limit >= 0),
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_customers_org_name UNIQUE (organization_id, name)
);

CREATE TABLE IF NOT EXISTS products (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    sku                 VARCHAR(80)     NOT NULL,
    name                VARCHAR(200)    NOT NULL,
    unit_of_measure     VARCHAR(20)     NOT NULL DEFAULT 'each',
    list_price          NUMERIC(14, 2)  NOT NULL CHECK (list_price >= 0),
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_products_org_sku UNIQUE (organization_id, sku)
);

CREATE TABLE IF NOT EXISTS warehouses (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    code                VARCHAR(30)     NOT NULL,
    name                VARCHAR(200)    NOT NULL,
    city                VARCHAR(120),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_warehouses_org_code UNIQUE (organization_id, code)
);

CREATE TABLE IF NOT EXISTS sales_orders (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    customer_id         UUID            REFERENCES customers (id) ON DELETE SET NULL,
    order_number        VARCHAR(40)     NOT NULL,
    status              order_status    NOT NULL DEFAULT 'draft',
    ordered_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    required_at         DATE,
    subtotal_amount     NUMERIC(14, 2)  NOT NULL DEFAULT 0 CHECK (subtotal_amount >= 0),
    tax_amount          NUMERIC(14, 2)  NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount        NUMERIC(14, 2)  NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    notes               TEXT,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_sales_orders_org_number UNIQUE (organization_id, order_number)
);

CREATE TABLE IF NOT EXISTS sales_order_items (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    sales_order_id      UUID            NOT NULL REFERENCES sales_orders (id) ON DELETE CASCADE,
    product_id          UUID            NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    line_no             INTEGER         NOT NULL CHECK (line_no > 0),
    quantity            NUMERIC(14, 3)  NOT NULL CHECK (quantity > 0),
    unit_price          NUMERIC(14, 2)  NOT NULL CHECK (unit_price >= 0),
    discount_amount     NUMERIC(14, 2)  NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_sales_order_items_line UNIQUE (sales_order_id, line_no)
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    supplier_id         UUID            REFERENCES suppliers (id) ON DELETE SET NULL,
    po_number           VARCHAR(40)     NOT NULL,
    status              procurement_status NOT NULL DEFAULT 'draft',
    ordered_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    expected_at         DATE,
    total_amount        NUMERIC(14, 2)  NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_purchase_orders_org_number UNIQUE (organization_id, po_number)
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id   UUID            NOT NULL REFERENCES purchase_orders (id) ON DELETE CASCADE,
    product_id          UUID            NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    line_no             INTEGER         NOT NULL CHECK (line_no > 0),
    quantity_ordered    NUMERIC(14, 3)  NOT NULL CHECK (quantity_ordered > 0),
    unit_cost           NUMERIC(14, 2)  NOT NULL CHECK (unit_cost >= 0),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_purchase_order_items_line UNIQUE (purchase_order_id, line_no)
);

CREATE TABLE IF NOT EXISTS stock_moves (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations (id) ON DELETE CASCADE,
    product_id          UUID            NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    warehouse_id        UUID            NOT NULL REFERENCES warehouses (id) ON DELETE RESTRICT,
    move_type           stock_move_type NOT NULL,
    quantity            NUMERIC(14, 3)  NOT NULL CHECK (quantity > 0),
    unit_cost           NUMERIC(14, 2)  CHECK (unit_cost >= 0),
    reference_type      VARCHAR(40),
    reference_id        UUID,
    moved_at            TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_suppliers_org_id          ON suppliers (organization_id);
CREATE INDEX idx_customers_org_id          ON customers (organization_id);
CREATE INDEX idx_products_org_id           ON products (organization_id);
CREATE INDEX idx_warehouses_org_id         ON warehouses (organization_id);
CREATE INDEX idx_sales_orders_org_id       ON sales_orders (organization_id);
CREATE INDEX idx_sales_orders_customer_id  ON sales_orders (customer_id);
CREATE INDEX idx_sales_items_product_id    ON sales_order_items (product_id);
CREATE INDEX idx_purchase_orders_org_id    ON purchase_orders (organization_id);
CREATE INDEX idx_purchase_orders_supplier  ON purchase_orders (supplier_id);
CREATE INDEX idx_purchase_items_product_id ON purchase_order_items (product_id);
CREATE INDEX idx_stock_moves_lookup        ON stock_moves (organization_id, product_id, warehouse_id);
CREATE INDEX idx_stock_moves_moved_at      ON stock_moves (moved_at DESC);

COMMENT ON TABLE organizations IS 'Tenant/legal entities in a multi-company ERP setup.';
COMMENT ON TABLE suppliers IS 'Supplier master records per organization.';
COMMENT ON TABLE customers IS 'Customer master records per organization.';
COMMENT ON TABLE products IS 'Product catalog and pricing baseline for order lines.';
COMMENT ON TABLE warehouses IS 'Inventory locations per organization.';
COMMENT ON TABLE sales_orders IS 'Sales order headers.';
COMMENT ON TABLE sales_order_items IS 'Sales order line items.';
COMMENT ON TABLE purchase_orders IS 'Purchase order headers.';
COMMENT ON TABLE purchase_order_items IS 'Purchase order line items.';
COMMENT ON TABLE stock_moves IS 'Inventory movement ledger for receipts, shipments, and adjustments.';
