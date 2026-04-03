-- =============================================================================
-- TBDSP — The Big DataBase Standards Project
-- Domain   : E-Commerce
-- Database : PostgreSQL 14+
-- File     : sample_data.sql
-- Version  : 1.0.0
-- Description:
--   Realistic sample data for the e-commerce schema. Run schema.sql first.
--   All inserts are wrapped in a transaction so the load is atomic.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, description) VALUES
    (1,  NULL, 'Electronics',       'electronics',       'Consumer electronics and accessories'),
    (2,  NULL, 'Clothing',          'clothing',          'Apparel for all ages and genders'),
    (3,  NULL, 'Home & Garden',     'home-garden',       'Furniture, décor, and outdoor products'),
    (4,  1,    'Smartphones',       'smartphones',       'Mobile phones and accessories'),
    (5,  1,    'Laptops',           'laptops',           'Portable computers'),
    (6,  1,    'Audio',             'audio',             'Headphones, speakers, and earbuds'),
    (7,  2,    'Men''s Clothing',   'mens-clothing',     'Shirts, trousers, jackets for men'),
    (8,  2,    'Women''s Clothing', 'womens-clothing',   'Dresses, tops, and accessories for women'),
    (9,  3,    'Furniture',         'furniture',         'Sofas, beds, tables, and chairs'),
    (10, 3,    'Garden Tools',      'garden-tools',      'Tools and equipment for gardening');

-- Advance the SERIAL sequence so new inserts don't collide with explicit IDs above.
SELECT setval('categories_id_seq', (SELECT MAX(id) FROM categories));

-- ---------------------------------------------------------------------------
-- customers
-- ---------------------------------------------------------------------------
INSERT INTO customers (id, email, password_hash, first_name, last_name, phone) VALUES
    ('a1000000-0000-0000-0000-000000000001', 'alice.morgan@example.com',    '$2b$12$examplehash_alice',   'Alice',   'Morgan',    '+1-555-100-0001'),
    ('a1000000-0000-0000-0000-000000000002', 'bob.santos@example.com',      '$2b$12$examplehash_bob',     'Bob',     'Santos',    '+1-555-100-0002'),
    ('a1000000-0000-0000-0000-000000000003', 'carol.white@example.com',     '$2b$12$examplehash_carol',   'Carol',   'White',     '+44-20-7946-0301'),
    ('a1000000-0000-0000-0000-000000000004', 'david.kim@example.com',       '$2b$12$examplehash_david',   'David',   'Kim',       '+82-10-1234-5678'),
    ('a1000000-0000-0000-0000-000000000005', 'eva.martinez@example.com',    '$2b$12$examplehash_eva',     'Eva',     'Martinez',  '+34-91-123-4567'),
    ('a1000000-0000-0000-0000-000000000006', 'frank.nguyen@example.com',    '$2b$12$examplehash_frank',   'Frank',   'Nguyen',    '+1-555-100-0006'),
    ('a1000000-0000-0000-0000-000000000007', 'grace.patel@example.com',     '$2b$12$examplehash_grace',   'Grace',   'Patel',     '+91-99-0000-0007');

-- ---------------------------------------------------------------------------
-- addresses
-- ---------------------------------------------------------------------------
INSERT INTO addresses (id, customer_id, type, is_default, full_name, line1, line2, city, state, postal_code, country_code, phone) VALUES
    ('b2000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'both',     TRUE,  'Alice Morgan',  '42 Maple Street',          NULL,        'Boston',         'MA', '02101', 'US', '+1-555-100-0001'),
    ('b2000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'shipping', FALSE, 'Alice Morgan',  '7 Office Park Drive',      'Suite 300', 'Cambridge',      'MA', '02139', 'US', '+1-555-100-0001'),
    ('b2000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 'both',     TRUE,  'Bob Santos',    '99 Sunset Boulevard',      NULL,        'Los Angeles',    'CA', '90028', 'US', '+1-555-100-0002'),
    ('b2000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000003', 'shipping', TRUE,  'Carol White',   '12 Baker Street',          'Flat 2B',   'London',         NULL, 'NW1 6XE', 'GB', '+44-20-7946-0301'),
    ('b2000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000004', 'both',     TRUE,  'David Kim',     '88 Gangnam-daero',         NULL,        'Seoul',          NULL, '06135',  'KR', '+82-10-1234-5678'),
    ('b2000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000005', 'both',     TRUE,  'Eva Martinez',  'Calle Gran Via 35',        'Piso 4',    'Madrid',         NULL, '28013',  'ES', '+34-91-123-4567'),
    ('b2000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000006', 'both',     TRUE,  'Frank Nguyen',  '300 Tech Blvd',            NULL,        'Austin',         'TX', '78701',  'US', '+1-555-100-0006'),
    ('b2000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000007', 'both',     TRUE,  'Grace Patel',   '55 MG Road',               'Floor 3',   'Bengaluru',      NULL, '560001', 'IN', '+91-99-0000-0007');

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
INSERT INTO products (id, category_id, name, slug, description, base_price, currency) VALUES
    ('c3000000-0000-0000-0000-000000000001', 4,  'ProPhone X12',         'proPhone-x12',          'Flagship smartphone with 6.7" OLED display, 256 GB storage, and 50 MP camera.',                              999.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000002', 4,  'BudgetPhone Lite',     'budgetphone-lite',      'Affordable 6.1" LCD phone with 64 GB storage and long battery life.',                                         249.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000003', 5,  'UltraBook Pro 15',     'ultrabook-pro-15',      '15" laptop with Intel Core i7, 16 GB RAM, 512 GB NVMe SSD, and 4K display.',                                 1499.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000004', 5,  'StudentBook Air',      'studentbook-air',       'Lightweight 13" laptop ideal for students — 8 GB RAM, 256 GB SSD.',                                          699.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000005', 6,  'SoundWave ANC 500',    'soundwave-anc-500',     'Premium over-ear headphones with active noise cancellation and 30-hour battery.',                             349.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000006', 6,  'TrueAir Buds',        'trueair-buds',          'Wireless earbuds with 6-hour playback and quick-charge case.',                                                79.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000007', 7,  'Classic Oxford Shirt', 'classic-oxford-shirt',  '100% cotton Oxford weave button-down shirt. Available in multiple sizes and colours.',                         59.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000008', 8,  'Summer Floral Dress',  'summer-floral-dress',   'Lightweight floral-print midi dress, perfect for warm weather.',                                              89.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000009', 9,  'Ergonomic Office Chair','ergonomic-office-chair','Fully adjustable lumbar-support office chair, mesh back, 5-year warranty.',                                   389.00, 'USD'),
    ('c3000000-0000-0000-0000-000000000010', 10, 'Pro Spade Set',        'pro-spade-set',         'Heavy-duty stainless-steel spade with ash wood handle — ideal for all garden types.',                         45.00, 'USD');

-- ---------------------------------------------------------------------------
-- product_variants
-- ---------------------------------------------------------------------------
INSERT INTO product_variants (id, product_id, sku, attributes, price_override, stock_qty) VALUES
    -- ProPhone X12: colour options
    ('d4000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000001', 'PPX12-BLK', '{"color":"Midnight Black"}',  NULL,   120),
    ('d4000000-0000-0000-0000-000000000002', 'c3000000-0000-0000-0000-000000000001', 'PPX12-WHT', '{"color":"Pearl White"}',     NULL,    85),
    ('d4000000-0000-0000-0000-000000000003', 'c3000000-0000-0000-0000-000000000001', 'PPX12-GLD', '{"color":"Rose Gold"}',       1049.00, 42),
    -- BudgetPhone Lite
    ('d4000000-0000-0000-0000-000000000004', 'c3000000-0000-0000-0000-000000000002', 'BPL-BLK',   '{"color":"Slate Grey"}',      NULL,   300),
    ('d4000000-0000-0000-0000-000000000005', 'c3000000-0000-0000-0000-000000000002', 'BPL-BLU',   '{"color":"Ocean Blue"}',      NULL,   210),
    -- UltraBook Pro 15
    ('d4000000-0000-0000-0000-000000000006', 'c3000000-0000-0000-0000-000000000003', 'UBP15-16',  '{"ram":"16GB","storage":"512GB"}', NULL, 55),
    ('d4000000-0000-0000-0000-000000000007', 'c3000000-0000-0000-0000-000000000003', 'UBP15-32',  '{"ram":"32GB","storage":"1TB"}',  1799.00, 28),
    -- StudentBook Air
    ('d4000000-0000-0000-0000-000000000008', 'c3000000-0000-0000-0000-000000000004', 'SBA-SLV',   '{"color":"Silver"}',           NULL,   95),
    -- SoundWave ANC 500
    ('d4000000-0000-0000-0000-000000000009', 'c3000000-0000-0000-0000-000000000005', 'SWA500-BLK','{"color":"Matte Black"}',      NULL,   200),
    ('d4000000-0000-0000-0000-000000000010', 'c3000000-0000-0000-0000-000000000005', 'SWA500-WHT','{"color":"Arctic White"}',     NULL,   145),
    -- TrueAir Buds
    ('d4000000-0000-0000-0000-000000000011', 'c3000000-0000-0000-0000-000000000006', 'TAB-BLK',   '{"color":"Black"}',            NULL,   400),
    ('d4000000-0000-0000-0000-000000000012', 'c3000000-0000-0000-0000-000000000006', 'TAB-WHT',   '{"color":"White"}',            NULL,   370),
    -- Classic Oxford Shirt: size × colour
    ('d4000000-0000-0000-0000-000000000013', 'c3000000-0000-0000-0000-000000000007', 'COS-M-WHT', '{"size":"M","color":"White"}',  NULL,   80),
    ('d4000000-0000-0000-0000-000000000014', 'c3000000-0000-0000-0000-000000000007', 'COS-L-WHT', '{"size":"L","color":"White"}',  NULL,   75),
    ('d4000000-0000-0000-0000-000000000015', 'c3000000-0000-0000-0000-000000000007', 'COS-L-BLU', '{"size":"L","color":"Blue"}',   NULL,   60),
    -- Summer Floral Dress
    ('d4000000-0000-0000-0000-000000000016', 'c3000000-0000-0000-0000-000000000008', 'SFD-S',     '{"size":"S"}',                  NULL,   50),
    ('d4000000-0000-0000-0000-000000000017', 'c3000000-0000-0000-0000-000000000008', 'SFD-M',     '{"size":"M"}',                  NULL,   65),
    -- Ergonomic Office Chair
    ('d4000000-0000-0000-0000-000000000018', 'c3000000-0000-0000-0000-000000000009', 'EOC-BLK',   '{"color":"Black"}',             NULL,   30),
    -- Pro Spade Set
    ('d4000000-0000-0000-0000-000000000019', 'c3000000-0000-0000-0000-000000000010', 'PSS-STD',   '{"handle":"Ash Wood"}',         NULL,  150);

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
INSERT INTO orders (id, customer_id, status, shipping_address, subtotal, shipping_cost, discount_amount, tax_amount, total_amount) VALUES
    (
        'e5000000-0000-0000-0000-000000000001',
        'a1000000-0000-0000-0000-000000000001',
        'delivered',
        '{"full_name":"Alice Morgan","line1":"42 Maple Street","city":"Boston","state":"MA","postal_code":"02101","country_code":"US"}',
        1348.00, 0.00, 0.00, 107.84, 1455.84
    ),
    (
        'e5000000-0000-0000-0000-000000000002',
        'a1000000-0000-0000-0000-000000000002',
        'shipped',
        '{"full_name":"Bob Santos","line1":"99 Sunset Boulevard","city":"Los Angeles","state":"CA","postal_code":"90028","country_code":"US"}',
        699.00, 9.99, 0.00, 55.92, 764.91
    ),
    (
        'e5000000-0000-0000-0000-000000000003',
        'a1000000-0000-0000-0000-000000000003',
        'confirmed',
        '{"full_name":"Carol White","line1":"12 Baker Street","line2":"Flat 2B","city":"London","postal_code":"NW1 6XE","country_code":"GB"}',
        349.00, 4.99, 34.90, 0.00, 319.09
    ),
    (
        'e5000000-0000-0000-0000-000000000004',
        'a1000000-0000-0000-0000-000000000004',
        'pending',
        '{"full_name":"David Kim","line1":"88 Gangnam-daero","city":"Seoul","postal_code":"06135","country_code":"KR"}',
        2848.00, 19.99, 0.00, 0.00, 2867.99
    ),
    (
        'e5000000-0000-0000-0000-000000000005',
        'a1000000-0000-0000-0000-000000000005',
        'delivered',
        '{"full_name":"Eva Martinez","line1":"Calle Gran Via 35","line2":"Piso 4","city":"Madrid","postal_code":"28013","country_code":"ES"}',
        138.00, 0.00, 13.80, 26.08, 150.28
    ),
    (
        'e5000000-0000-0000-0000-000000000006',
        'a1000000-0000-0000-0000-000000000006',
        'processing',
        '{"full_name":"Frank Nguyen","line1":"300 Tech Blvd","city":"Austin","state":"TX","postal_code":"78701","country_code":"US"}',
        1657.00, 0.00, 0.00, 136.70, 1793.70
    ),
    (
        'e5000000-0000-0000-0000-000000000007',
        'a1000000-0000-0000-0000-000000000007',
        'cancelled',
        '{"full_name":"Grace Patel","line1":"55 MG Road","line2":"Floor 3","city":"Bengaluru","postal_code":"560001","country_code":"IN"}',
        389.00, 9.99, 0.00, 0.00, 398.99
    );

-- ---------------------------------------------------------------------------
-- order_items
-- ---------------------------------------------------------------------------
INSERT INTO order_items (id, order_id, variant_id, quantity, unit_price, discount) VALUES
    -- Order 1: Alice — ProPhone X12 Black + SoundWave ANC Black
    ('f6000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000001', 1, 999.00,  0.00),
    ('f6000000-0000-0000-0000-000000000002', 'e5000000-0000-0000-0000-000000000001', 'd4000000-0000-0000-0000-000000000009', 1, 349.00,  0.00),
    -- Order 2: Bob — StudentBook Air
    ('f6000000-0000-0000-0000-000000000003', 'e5000000-0000-0000-0000-000000000002', 'd4000000-0000-0000-0000-000000000008', 1, 699.00,  0.00),
    -- Order 3: Carol — SoundWave ANC 500 (10% discount)
    ('f6000000-0000-0000-0000-000000000004', 'e5000000-0000-0000-0000-000000000003', 'd4000000-0000-0000-0000-000000000010', 1, 349.00, 34.90),
    -- Order 4: David — UltraBook Pro 15 32GB + ProPhone X12 Gold
    ('f6000000-0000-0000-0000-000000000005', 'e5000000-0000-0000-0000-000000000004', 'd4000000-0000-0000-0000-000000000007', 1, 1799.00, 0.00),
    ('f6000000-0000-0000-0000-000000000006', 'e5000000-0000-0000-0000-000000000004', 'd4000000-0000-0000-0000-000000000003', 1, 1049.00, 0.00),
    -- Order 5: Eva — TrueAir Buds Black + Classic Oxford Shirt L White
    ('f6000000-0000-0000-0000-000000000007', 'e5000000-0000-0000-0000-000000000005', 'd4000000-0000-0000-0000-000000000011', 1,  79.00, 7.90),
    ('f6000000-0000-0000-0000-000000000008', 'e5000000-0000-0000-0000-000000000005', 'd4000000-0000-0000-0000-000000000014', 1,  59.00, 5.90),
    -- Order 6: Frank — UltraBook Pro 15 16GB + TrueAir Buds White × 2
    ('f6000000-0000-0000-0000-000000000009', 'e5000000-0000-0000-0000-000000000006', 'd4000000-0000-0000-0000-000000000006', 1, 1499.00, 0.00),
    ('f6000000-0000-0000-0000-000000000010', 'e5000000-0000-0000-0000-000000000006', 'd4000000-0000-0000-0000-000000000012', 2,  79.00,  0.00),
    -- Order 7: Grace — Ergonomic Office Chair (cancelled)
    ('f6000000-0000-0000-0000-000000000011', 'e5000000-0000-0000-0000-000000000007', 'd4000000-0000-0000-0000-000000000018', 1, 389.00,  0.00);

-- ---------------------------------------------------------------------------
-- payments
-- ---------------------------------------------------------------------------
INSERT INTO payments (id, order_id, method, status, amount, currency, provider_reference, processed_at) VALUES
    ('g7000000-0000-0000-0000-000000000001', 'e5000000-0000-0000-0000-000000000001', 'credit_card',   'captured', 1455.84, 'USD', 'stripe_ch_1A2B3C4D', NOW() - INTERVAL '10 days'),
    ('g7000000-0000-0000-0000-000000000002', 'e5000000-0000-0000-0000-000000000002', 'paypal',        'captured',  764.91, 'USD', 'pp_txn_XYZ789',      NOW() - INTERVAL '3 days'),
    ('g7000000-0000-0000-0000-000000000003', 'e5000000-0000-0000-0000-000000000003', 'credit_card',   'authorized', 319.09, 'USD', 'stripe_ch_5E6F7G8H', NOW() - INTERVAL '1 day'),
    ('g7000000-0000-0000-0000-000000000004', 'e5000000-0000-0000-0000-000000000004', 'bank_transfer', 'pending',  2867.99, 'USD', NULL,                  NULL),
    ('g7000000-0000-0000-0000-000000000005', 'e5000000-0000-0000-0000-000000000005', 'credit_card',   'captured',  150.28, 'USD', 'stripe_ch_9I0J1K2L', NOW() - INTERVAL '7 days'),
    -- Frank: first attempt failed, second succeeded
    ('g7000000-0000-0000-0000-000000000006', 'e5000000-0000-0000-0000-000000000006', 'credit_card',   'failed',   1793.70, 'USD', 'stripe_ch_3M4N5O6P', NOW() - INTERVAL '2 days'),
    ('g7000000-0000-0000-0000-000000000007', 'e5000000-0000-0000-0000-000000000006', 'debit_card',    'captured', 1793.70, 'USD', 'stripe_ch_7Q8R9S0T', NOW() - INTERVAL '2 days'),
    -- Grace: refunded because order was cancelled
    ('g7000000-0000-0000-0000-000000000008', 'e5000000-0000-0000-0000-000000000007', 'credit_card',   'refunded',  398.99, 'USD', 'stripe_ch_1U2V3W4X', NOW() - INTERVAL '5 days');

-- ---------------------------------------------------------------------------
-- reviews
-- ---------------------------------------------------------------------------
INSERT INTO reviews (id, product_id, customer_id, rating, title, body, is_verified) VALUES
    (
        'h8000000-0000-0000-0000-000000000001',
        'c3000000-0000-0000-0000-000000000001',
        'a1000000-0000-0000-0000-000000000001',
        5,
        'Best smartphone I''ve owned',
        'The camera quality is outstanding and the battery easily lasts a full day. Highly recommended!',
        TRUE
    ),
    (
        'h8000000-0000-0000-0000-000000000002',
        'c3000000-0000-0000-0000-000000000005',
        'a1000000-0000-0000-0000-000000000001',
        4,
        'Great noise cancellation, slightly heavy',
        'The ANC is top-notch and the sound quality is excellent. Knocked off one star because they feel a bit heavy after several hours.',
        TRUE
    ),
    (
        'h8000000-0000-0000-0000-000000000003',
        'c3000000-0000-0000-0000-000000000004',
        'a1000000-0000-0000-0000-000000000002',
        5,
        'Perfect laptop for university',
        'Light, fast, and the battery life is incredible. Handles all my coursework without breaking a sweat.',
        TRUE
    ),
    (
        'h8000000-0000-0000-0000-000000000004',
        'c3000000-0000-0000-0000-000000000005',
        'a1000000-0000-0000-0000-000000000003',
        3,
        'Good but could improve the app',
        'Sound quality is fine but the companion app crashes occasionally on iOS.',
        FALSE
    ),
    (
        'h8000000-0000-0000-0000-000000000005',
        'c3000000-0000-0000-0000-000000000003',
        'a1000000-0000-0000-0000-000000000004',
        5,
        'Absolute beast of a machine',
        '4K display is stunning and the 32 GB RAM handles everything I throw at it. Worth every penny.',
        TRUE
    ),
    (
        'h8000000-0000-0000-0000-000000000006',
        'c3000000-0000-0000-0000-000000000006',
        'a1000000-0000-0000-0000-000000000005',
        4,
        'Solid earbuds for the price',
        'Good sound, comfortable fit, and the case charges super fast. Not the best ANC but fine for commuting.',
        TRUE
    ),
    (
        'h8000000-0000-0000-0000-000000000007',
        'c3000000-0000-0000-0000-000000000003',
        'a1000000-0000-0000-0000-000000000006',
        5,
        'Top-tier laptop, zero regrets',
        'Upgraded from an old machine and the difference is night and day. The NVMe SSD boots in seconds.',
        TRUE
    );

COMMIT;
