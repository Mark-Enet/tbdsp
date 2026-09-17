-- =============================================================================
-- TBDSP - The Big DataBase Standards Project
-- Domain   : ERP
-- Database : PostgreSQL 14+
-- File     : sample_data.sql
-- Version  : 1.0.0
-- Description:
--   Realistic starter data for the ERP domain. Run schema.sql first.
-- =============================================================================

INSERT INTO organizations (name, tax_id, base_currency)
VALUES ('Acme Industrial Group', 'US-99-1234567', 'USD')
ON CONFLICT (name) DO NOTHING;

INSERT INTO suppliers (organization_id, name, contact_email, payment_terms_days)
SELECT o.id, 'Northwind Components', 'orders@northwind.example', 45
FROM organizations o
WHERE o.name = 'Acme Industrial Group'
ON CONFLICT (organization_id, name) DO NOTHING;

INSERT INTO customers (organization_id, name, email, credit_limit)
SELECT o.id, 'Vertex Retail LLC', 'ap@vertex-retail.example', 50000
FROM organizations o
WHERE o.name = 'Acme Industrial Group'
ON CONFLICT (organization_id, name) DO NOTHING;

INSERT INTO products (organization_id, sku, name, unit_of_measure, list_price)
SELECT o.id, 'ERP-CPU-1000', 'Industrial Controller Unit', 'each', 950.00
FROM organizations o
WHERE o.name = 'Acme Industrial Group'
ON CONFLICT (organization_id, sku) DO NOTHING;

INSERT INTO products (organization_id, sku, name, unit_of_measure, list_price)
SELECT o.id, 'ERP-SEN-220', 'Temperature Sensor', 'each', 75.00
FROM organizations o
WHERE o.name = 'Acme Industrial Group'
ON CONFLICT (organization_id, sku) DO NOTHING;

INSERT INTO warehouses (organization_id, code, name, city)
SELECT o.id, 'MAIN', 'Main Distribution Center', 'Austin'
FROM organizations o
WHERE o.name = 'Acme Industrial Group'
ON CONFLICT (organization_id, code) DO NOTHING;

INSERT INTO purchase_orders (organization_id, supplier_id, po_number, status, total_amount)
SELECT o.id, s.id, 'PO-2026-0001', 'approved', 19000.00
FROM organizations o
JOIN suppliers s ON s.organization_id = o.id AND s.name = 'Northwind Components'
WHERE o.name = 'Acme Industrial Group'
ON CONFLICT (organization_id, po_number) DO NOTHING;

INSERT INTO purchase_order_items (purchase_order_id, product_id, line_no, quantity_ordered, unit_cost)
SELECT po.id, p.id, 1, 20, 700.00
FROM purchase_orders po
JOIN organizations o ON o.id = po.organization_id
JOIN products p ON p.organization_id = o.id AND p.sku = 'ERP-CPU-1000'
WHERE o.name = 'Acme Industrial Group' AND po.po_number = 'PO-2026-0001'
ON CONFLICT (purchase_order_id, line_no) DO NOTHING;

INSERT INTO purchase_order_items (purchase_order_id, product_id, line_no, quantity_ordered, unit_cost)
SELECT po.id, p.id, 2, 100, 42.00
FROM purchase_orders po
JOIN organizations o ON o.id = po.organization_id
JOIN products p ON p.organization_id = o.id AND p.sku = 'ERP-SEN-220'
WHERE o.name = 'Acme Industrial Group' AND po.po_number = 'PO-2026-0001'
ON CONFLICT (purchase_order_id, line_no) DO NOTHING;

INSERT INTO sales_orders (organization_id, customer_id, order_number, status, subtotal_amount, tax_amount, total_amount)
SELECT o.id, c.id, 'SO-2026-0001', 'confirmed', 5500.00, 440.00, 5940.00
FROM organizations o
JOIN customers c ON c.organization_id = o.id AND c.name = 'Vertex Retail LLC'
WHERE o.name = 'Acme Industrial Group'
ON CONFLICT (organization_id, order_number) DO NOTHING;

INSERT INTO sales_order_items (sales_order_id, product_id, line_no, quantity, unit_price, discount_amount)
SELECT so.id, p.id, 1, 5, 950.00, 0
FROM sales_orders so
JOIN organizations o ON o.id = so.organization_id
JOIN products p ON p.organization_id = o.id AND p.sku = 'ERP-CPU-1000'
WHERE o.name = 'Acme Industrial Group' AND so.order_number = 'SO-2026-0001'
ON CONFLICT (sales_order_id, line_no) DO NOTHING;

INSERT INTO sales_order_items (sales_order_id, product_id, line_no, quantity, unit_price, discount_amount)
SELECT so.id, p.id, 2, 10, 75.00, 0
FROM sales_orders so
JOIN organizations o ON o.id = so.organization_id
JOIN products p ON p.organization_id = o.id AND p.sku = 'ERP-SEN-220'
WHERE o.name = 'Acme Industrial Group' AND so.order_number = 'SO-2026-0001'
ON CONFLICT (sales_order_id, line_no) DO NOTHING;

INSERT INTO stock_moves (organization_id, product_id, warehouse_id, move_type, quantity, unit_cost, reference_type, reference_id)
SELECT o.id, p.id, w.id, 'purchase_receipt', 20, 700.00, 'purchase_order', po.id
FROM organizations o
JOIN warehouses w ON w.organization_id = o.id AND w.code = 'MAIN'
JOIN products p ON p.organization_id = o.id AND p.sku = 'ERP-CPU-1000'
JOIN purchase_orders po ON po.organization_id = o.id AND po.po_number = 'PO-2026-0001'
WHERE o.name = 'Acme Industrial Group';

INSERT INTO stock_moves (organization_id, product_id, warehouse_id, move_type, quantity, reference_type, reference_id)
SELECT o.id, p.id, w.id, 'sale_shipment', 5, 'sales_order', so.id
FROM organizations o
JOIN warehouses w ON w.organization_id = o.id AND w.code = 'MAIN'
JOIN products p ON p.organization_id = o.id AND p.sku = 'ERP-CPU-1000'
JOIN sales_orders so ON so.organization_id = o.id AND so.order_number = 'SO-2026-0001'
WHERE o.name = 'Acme Industrial Group';
