# ERP - PostgreSQL Schema

> **TBDSP domain:** ERP | **Database:** PostgreSQL 14+

This schema models a core enterprise resource planning workflow for mid-market operations: organization setup, supplier and customer masters, product catalog, warehouse inventory movements, sales orders, and purchase orders.

---

## Table of Contents

1. [Entity-Relationship Diagram](#entity-relationship-diagram)
2. [Tables at a Glance](#tables-at-a-glance)
3. [Design Decisions](#design-decisions)
4. [Setup Instructions](#setup-instructions)
5. [Sample Queries](#sample-queries)

---

## Entity-Relationship Diagram

```mermaid
%% Render from erd.mmd
```

See the full diagram in [erd.mmd](erd.mmd).

---

## Tables at a Glance

| Table | Purpose |
|---|---|
| organizations | Tenant or legal entity root for ERP data |
| suppliers | Vendor master records and payment terms |
| customers | Customer master records and credit limits |
| products | Product master and baseline pricing |
| warehouses | Inventory storage locations |
| stock_moves | Ledger of receipts, shipments, adjustments, transfers |
| sales_orders | Sales order headers |
| sales_order_items | Sales order lines |
| purchase_orders | Purchase order headers |
| purchase_order_items | Purchase order lines |

---

## Design Decisions

- Multi-tenant organization model via organization_id foreign keys.
- UUID primary keys for distributed-safe identifiers.
- Separate movement ledger (stock_moves) keeps inventory auditable.
- Strong financial constraints with numeric checks to avoid negative money values.
- Status enums model business lifecycle for sales and procurement.

---

## Setup Instructions

```bash
createdb erp_demo
psql -U <your_user> -d erp_demo -f schema.sql
psql -U <your_user> -d erp_demo -f sample_data.sql
```

---

## Sample Queries

```sql
-- Sales by customer
SELECT
    c.name AS customer,
    SUM(so.total_amount) AS gross_sales
FROM sales_orders so
JOIN customers c ON c.id = so.customer_id
GROUP BY c.name
ORDER BY gross_sales DESC;
```

```sql
-- Current on-hand by SKU and warehouse based on movement signs
SELECT
    p.sku,
    w.code AS warehouse_code,
    SUM(
        CASE sm.move_type
            WHEN 'purchase_receipt' THEN sm.quantity
            WHEN 'adjustment_in'    THEN sm.quantity
            WHEN 'transfer'         THEN sm.quantity
            WHEN 'sale_shipment'    THEN -sm.quantity
            WHEN 'adjustment_out'   THEN -sm.quantity
        END
    ) AS on_hand_qty
FROM stock_moves sm
JOIN products p   ON p.id = sm.product_id
JOIN warehouses w ON w.id = sm.warehouse_id
GROUP BY p.sku, w.code
ORDER BY p.sku, w.code;
```
