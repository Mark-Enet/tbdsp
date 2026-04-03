-- =============================================================================
-- TBDSP — The Big DataBase Standards Project
-- Domain   : Blogging / CMS
-- Database : PostgreSQL 14+
-- File     : sample_data.sql
-- Version  : 1.0.0
-- Description:
--   Realistic sample data for the blogging schema. Run schema.sql first.
--   All inserts are wrapped in a transaction so the load is atomic.
--   Includes 5 authors, 8 categories, 12 tags, 12 posts (published + draft),
--   post-category and post-tag assignments, 18 comments (threaded), and
--   8 media assets.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
INSERT INTO users (id, email, password_hash, display_name, bio, avatar_url, role) VALUES
    (
        'u1000000-0000-0000-0000-000000000001',
        'admin@example.com',
        '$2b$12$examplehash_admin',
        'Site Admin',
        'Platform administrator and occasional writer.',
        'https://cdn.example.com/avatars/admin.jpg',
        'admin'
    ),
    (
        'u1000000-0000-0000-0000-000000000002',
        'alice.chen@example.com',
        '$2b$12$examplehash_alice',
        'Alice Chen',
        'Senior software engineer and open-source contributor. Writes about databases, backend architecture, and DevOps.',
        'https://cdn.example.com/avatars/alice.jpg',
        'author'
    ),
    (
        'u1000000-0000-0000-0000-000000000003',
        'bob.okafor@example.com',
        '$2b$12$examplehash_bob',
        'Bob Okafor',
        'Full-stack developer passionate about JavaScript, React, and web performance.',
        'https://cdn.example.com/avatars/bob.jpg',
        'author'
    ),
    (
        'u1000000-0000-0000-0000-000000000004',
        'carla.reyes@example.com',
        '$2b$12$examplehash_carla',
        'Carla Reyes',
        'Data scientist and ML engineer. Explores Python, statistics, and real-world AI applications.',
        'https://cdn.example.com/avatars/carla.jpg',
        'author'
    ),
    (
        'u1000000-0000-0000-0000-000000000005',
        'dan.kowalski@example.com',
        '$2b$12$examplehash_dan',
        'Dan Kowalski',
        'DevOps engineer specialising in cloud infrastructure, CI/CD, and platform reliability.',
        'https://cdn.example.com/avatars/dan.jpg',
        'editor'
    );

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
INSERT INTO categories (id, parent_id, name, slug, description) VALUES
    (1,  NULL, 'Technology',       'technology',        'General technology articles and industry news'),
    (2,  NULL, 'Programming',      'programming',       'Coding tutorials, tips, and best practices'),
    (3,  NULL, 'Data & AI',        'data-and-ai',       'Databases, data engineering, machine learning, and AI'),
    (4,  NULL, 'DevOps & Cloud',   'devops-and-cloud',  'Infrastructure, CI/CD, containers, and cloud platforms'),
    (5,  2,    'Python',           'python',            'Python language, libraries, and ecosystem'),
    (6,  2,    'JavaScript',       'javascript',        'JavaScript, TypeScript, and the web ecosystem'),
    (7,  3,    'Databases',        'databases',         'SQL, NoSQL, schema design, and query optimisation'),
    (8,  4,    'Containers',       'containers',        'Docker, Kubernetes, and container orchestration');

-- Advance the SERIAL sequence so new inserts don't collide with explicit IDs above.
SELECT setval('categories_id_seq', (SELECT MAX(id) FROM categories));

-- ---------------------------------------------------------------------------
-- tags
-- ---------------------------------------------------------------------------
INSERT INTO tags (id, name, slug) VALUES
    (1,  'PostgreSQL',      'postgresql'),
    (2,  'Open Source',     'open-source'),
    (3,  'Tutorial',        'tutorial'),
    (4,  'Performance',     'performance'),
    (5,  'Security',        'security'),
    (6,  'Python',          'python'),
    (7,  'Docker',          'docker'),
    (8,  'Kubernetes',      'kubernetes'),
    (9,  'Machine Learning','machine-learning'),
    (10, 'React',           'react'),
    (11, 'TypeScript',      'typescript'),
    (12, 'Best Practices',  'best-practices');

-- Advance the SERIAL sequence
SELECT setval('tags_id_seq', (SELECT MAX(id) FROM tags));

-- ---------------------------------------------------------------------------
-- media
-- ---------------------------------------------------------------------------
INSERT INTO media (id, uploader_id, filename, original_filename, mime_type, file_size_bytes, storage_url, alt_text) VALUES
    ('m4000000-0000-0000-0000-000000000001', 'u1000000-0000-0000-0000-000000000002', 'postgres-index-hero.webp',  'hero.webp',         'image/webp', 182400,  'https://cdn.example.com/media/postgres-index-hero.webp',  'Diagram showing PostgreSQL B-tree and GIN index structures'),
    ('m4000000-0000-0000-0000-000000000002', 'u1000000-0000-0000-0000-000000000002', 'uuid-vs-serial.png',        'comparison.png',    'image/png',  94300,   'https://cdn.example.com/media/uuid-vs-serial.png',        'Side-by-side comparison of UUID and SERIAL primary keys'),
    ('m4000000-0000-0000-0000-000000000003', 'u1000000-0000-0000-0000-000000000003', 'react-hooks-banner.webp',   'banner.webp',       'image/webp', 143200,  'https://cdn.example.com/media/react-hooks-banner.webp',   'React logo with hooks illustration'),
    ('m4000000-0000-0000-0000-000000000004', 'u1000000-0000-0000-0000-000000000003', 'ts-generics-cover.png',     'generics.png',      'image/png',  110500,  'https://cdn.example.com/media/ts-generics-cover.png',     'TypeScript generics code snippet on dark background'),
    ('m4000000-0000-0000-0000-000000000005', 'u1000000-0000-0000-0000-000000000004', 'ml-pipeline-diagram.webp',  'pipeline.webp',     'image/webp', 204800,  'https://cdn.example.com/media/ml-pipeline-diagram.webp',  'End-to-end machine learning pipeline flowchart'),
    ('m4000000-0000-0000-0000-000000000006', 'u1000000-0000-0000-0000-000000000004', 'pandas-performance.png',    'perf-chart.png',    'image/png',  87600,   'https://cdn.example.com/media/pandas-performance.png',    'Bar chart comparing Pandas and Polars query times'),
    ('m4000000-0000-0000-0000-000000000007', 'u1000000-0000-0000-0000-000000000005', 'docker-compose-hero.webp',  'compose.webp',      'image/webp', 167300,  'https://cdn.example.com/media/docker-compose-hero.webp',  'Docker Compose multi-container architecture diagram'),
    ('m4000000-0000-0000-0000-000000000008', 'u1000000-0000-0000-0000-000000000005', 'k8s-cluster-overview.png',  'k8s-overview.png',  'image/png',  231100,  'https://cdn.example.com/media/k8s-cluster-overview.png',  'Kubernetes cluster architecture with nodes and pods');

-- ---------------------------------------------------------------------------
-- posts
-- ---------------------------------------------------------------------------
INSERT INTO posts (id, author_id, title, slug, excerpt, body, status, featured_image_url, meta_title, meta_description, like_count, view_count, published_at) VALUES
    (
        'p2000000-0000-0000-0000-000000000001',
        'u1000000-0000-0000-0000-000000000002',
        'Understanding PostgreSQL Indexes: B-Tree, GIN, and GiST',
        'understanding-postgresql-indexes',
        'A practical deep-dive into the three most important PostgreSQL index types — when to use each, and how to measure their impact on query performance.',
        'PostgreSQL ships with several index types, each optimised for different workloads. In this article we cover the three you will encounter most often: B-Tree for range and equality queries, GIN for full-text search and JSONB containment, and GiST for geometric and nearest-neighbour lookups. We also walk through EXPLAIN ANALYZE output and show you how to interpret index scans vs sequential scans.',
        'published',
        'https://cdn.example.com/media/postgres-index-hero.webp',
        'PostgreSQL Indexes Explained: B-Tree, GIN, GiST',
        'Learn when and how to use PostgreSQL B-Tree, GIN, and GiST indexes to dramatically speed up your queries.',
        142, 8340,
        NOW() - INTERVAL '60 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000002',
        'u1000000-0000-0000-0000-000000000002',
        'UUID vs SERIAL: Choosing the Right Primary Key Strategy',
        'uuid-vs-serial-primary-keys',
        'Comparing UUID and SERIAL primary keys across security, portability, and performance — with practical guidance on which to choose.',
        'Choosing a primary key strategy is one of the most consequential early decisions in database design. SERIAL (auto-increment) keys are simple and compact; UUID keys are globally unique and do not leak row counts. This post compares both approaches across insert performance, index fragmentation, distributed systems concerns, and security — and offers a decision framework for common use cases.',
        'published',
        'https://cdn.example.com/media/uuid-vs-serial.png',
        NULL,
        NULL,
        98, 5210,
        NOW() - INTERVAL '45 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000003',
        'u1000000-0000-0000-0000-000000000002',
        'Row-Level Security in PostgreSQL: A Complete Guide',
        'postgresql-row-level-security',
        'Step-by-step guide to enabling and writing PostgreSQL Row-Level Security policies to enforce multi-tenant data isolation at the database layer.',
        'Row-Level Security (RLS) lets you define which rows a given database role can read or write, enforced transparently on every query. This is invaluable for multi-tenant SaaS applications where each customer must see only their own data. We cover enabling RLS on a table, writing USING and WITH CHECK policies, testing with SET ROLE, and common pitfalls such as policy bypass by superusers.',
        'published',
        NULL,
        NULL,
        NULL,
        76, 3980,
        NOW() - INTERVAL '30 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000004',
        'u1000000-0000-0000-0000-000000000002',
        'Designing a Time-Series Schema in PostgreSQL',
        'time-series-schema-postgresql',
        'How to model high-frequency time-series data in PostgreSQL using table partitioning, BRIN indexes, and retention policies.',
        'Time-series data — sensor readings, financial ticks, server metrics — arrives fast and is queried by time range. PostgreSQL handles this well with declarative table partitioning (PARTITION BY RANGE on a timestamp column), BRIN indexes that exploit natural time ordering, and pg_partman for automated partition maintenance. This article designs a complete schema from scratch and benchmarks it against a naive single-table approach.',
        'draft',
        NULL,
        NULL,
        NULL,
        0, 0,
        NULL
    ),
    (
        'p2000000-0000-0000-0000-000000000005',
        'u1000000-0000-0000-0000-000000000003',
        'React Hooks in Depth: useState, useEffect, and Custom Hooks',
        'react-hooks-in-depth',
        'Master the most important React hooks with real-world examples, common gotchas, and patterns for building reusable custom hooks.',
        'Hooks transformed how we write React components. This comprehensive guide walks through useState for local state, useEffect for side effects and cleanup, useContext for consuming context, useMemo and useCallback for memoisation, and useRef for imperative DOM access. The final section builds three reusable custom hooks: useFetch, useLocalStorage, and useDebounce.',
        'published',
        'https://cdn.example.com/media/react-hooks-banner.webp',
        NULL,
        NULL,
        211, 12700,
        NOW() - INTERVAL '55 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000006',
        'u1000000-0000-0000-0000-000000000003',
        'TypeScript Generics: From Basics to Advanced Patterns',
        'typescript-generics-advanced',
        'A hands-on tour of TypeScript generics — from simple identity functions to conditional types, mapped types, and inference with infer.',
        'Generics are the most powerful — and most misunderstood — feature in TypeScript. We start with the classic identity function and build up to generic constraints, default type parameters, conditional types (T extends U ? X : Y), mapped types that transform object shapes, and template literal types. Each section includes real-world examples drawn from popular open-source libraries.',
        'published',
        'https://cdn.example.com/media/ts-generics-cover.png',
        NULL,
        NULL,
        175, 9450,
        NOW() - INTERVAL '40 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000007',
        'u1000000-0000-0000-0000-000000000003',
        'Building a Real-Time Dashboard with Next.js and WebSockets',
        'nextjs-websocket-dashboard',
        'Learn how to stream live data into a Next.js application using WebSockets, React state, and a lightweight Node.js server.',
        'Real-time UIs require a persistent connection between browser and server. This tutorial builds a live metrics dashboard: a Node.js server broadcasts updates over WebSocket, a custom React hook manages the connection lifecycle and reconnection logic, and a Next.js page renders the charts with Recharts. We also cover authentication of WebSocket connections and graceful degradation to polling.',
        'published',
        NULL,
        NULL,
        NULL,
        88, 6020,
        NOW() - INTERVAL '20 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000008',
        'u1000000-0000-0000-0000-000000000003',
        'State Management in 2025: Zustand, Jotai, and Beyond',
        'state-management-2025',
        'An opinionated comparison of modern React state management libraries — covering Zustand, Jotai, TanStack Query, and when to use each.',
        'Redux dominated state management for years, but the ecosystem has diversified dramatically. This post compares Zustand (simple global store), Jotai (atomic state inspired by Recoil), TanStack Query (server state caching), and the built-in Context + useReducer pattern. We evaluate each on boilerplate, performance, DevTools support, and suitability for different application sizes.',
        'draft',
        NULL,
        NULL,
        NULL,
        0, 0,
        NULL
    ),
    (
        'p2000000-0000-0000-0000-000000000009',
        'u1000000-0000-0000-0000-000000000004',
        'Building an End-to-End ML Pipeline with Python and DVC',
        'ml-pipeline-python-dvc',
        'A practical walkthrough of building a reproducible machine learning pipeline using scikit-learn, DVC for data versioning, and MLflow for experiment tracking.',
        'Reproducibility is the cornerstone of trustworthy machine learning. This article guides you through structuring a project with DVC stages (data ingestion → feature engineering → training → evaluation), tracking parameters and metrics with MLflow, and automating the pipeline in CI/CD. The example project classifies customer churn using a gradient-boosted tree and achieves 91% AUC on the holdout set.',
        'published',
        'https://cdn.example.com/media/ml-pipeline-diagram.webp',
        NULL,
        NULL,
        133, 7600,
        NOW() - INTERVAL '35 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000010',
        'u1000000-0000-0000-0000-000000000004',
        'Pandas vs Polars: Performance Benchmarks and Migration Guide',
        'pandas-vs-polars-benchmarks',
        'Benchmarking Pandas and Polars on 10 million-row datasets — and a practical migration guide for common operations.',
        'Polars has emerged as a serious challenger to Pandas for large-scale data manipulation, delivering 5–20× speedups on many workloads by exploiting multi-threading and Apache Arrow columnar storage. We benchmark both libraries on filtering, groupby, joins, and string operations on a 10-million-row synthetic dataset, analyse the results, and provide a side-by-side migration cheat sheet for the most common Pandas idioms.',
        'published',
        'https://cdn.example.com/media/pandas-performance.png',
        NULL,
        NULL,
        109, 5880,
        NOW() - INTERVAL '15 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000011',
        'u1000000-0000-0000-0000-000000000005',
        'Docker Compose for Local Development: A Complete Setup',
        'docker-compose-local-development',
        'Everything you need to set up a reliable multi-service local development environment with Docker Compose, health checks, and volume mounts.',
        'Running your entire stack locally — database, cache, API, and workers — is the most productive development setup. Docker Compose makes this repeatable and shareable. This guide covers writing a production-parity compose.yml, configuring health checks so dependent services wait for dependencies, using named volumes for data persistence, and layering overrides with compose.override.yml for local secrets.',
        'published',
        'https://cdn.example.com/media/docker-compose-hero.webp',
        NULL,
        NULL,
        164, 10200,
        NOW() - INTERVAL '50 days'
    ),
    (
        'p2000000-0000-0000-0000-000000000012',
        'u1000000-0000-0000-0000-000000000005',
        'Kubernetes Zero to Production: Core Concepts and First Deployment',
        'kubernetes-zero-to-production',
        'A beginner-friendly introduction to Kubernetes — covering Pods, Deployments, Services, ConfigMaps, and rolling your first application to a real cluster.',
        'Kubernetes has become the de-facto platform for running containerised workloads at scale, but its learning curve is steep. This post demystifies the core concepts: the control plane, Pods as the unit of deployment, ReplicaSets for availability, Deployments for declarative rollouts, Services for stable networking, and ConfigMaps / Secrets for configuration. We finish with a step-by-step first deployment to a managed cluster (GKE / EKS / AKS).',
        'published',
        'https://cdn.example.com/media/k8s-cluster-overview.png',
        NULL,
        NULL,
        192, 11500,
        NOW() - INTERVAL '25 days'
    );

-- ---------------------------------------------------------------------------
-- post_categories
-- ---------------------------------------------------------------------------
INSERT INTO post_categories (post_id, category_id) VALUES
    -- Post 1: PostgreSQL Indexes
    ('p2000000-0000-0000-0000-000000000001', 7),   -- Databases
    ('p2000000-0000-0000-0000-000000000001', 2),   -- Programming
    -- Post 2: UUID vs SERIAL
    ('p2000000-0000-0000-0000-000000000002', 7),   -- Databases
    -- Post 3: Row-Level Security
    ('p2000000-0000-0000-0000-000000000003', 7),   -- Databases
    ('p2000000-0000-0000-0000-000000000003', 2),   -- Programming
    -- Post 4: Time-Series (draft)
    ('p2000000-0000-0000-0000-000000000004', 7),   -- Databases
    -- Post 5: React Hooks
    ('p2000000-0000-0000-0000-000000000005', 6),   -- JavaScript
    ('p2000000-0000-0000-0000-000000000005', 2),   -- Programming
    -- Post 6: TypeScript Generics
    ('p2000000-0000-0000-0000-000000000006', 6),   -- JavaScript
    ('p2000000-0000-0000-0000-000000000006', 2),   -- Programming
    -- Post 7: Next.js WebSockets
    ('p2000000-0000-0000-0000-000000000007', 6),   -- JavaScript
    ('p2000000-0000-0000-0000-000000000007', 1),   -- Technology
    -- Post 8: State Management (draft)
    ('p2000000-0000-0000-0000-000000000008', 6),   -- JavaScript
    -- Post 9: ML Pipeline
    ('p2000000-0000-0000-0000-000000000009', 5),   -- Python
    ('p2000000-0000-0000-0000-000000000009', 3),   -- Data & AI
    -- Post 10: Pandas vs Polars
    ('p2000000-0000-0000-0000-000000000010', 5),   -- Python
    ('p2000000-0000-0000-0000-000000000010', 3),   -- Data & AI
    -- Post 11: Docker Compose
    ('p2000000-0000-0000-0000-000000000011', 8),   -- Containers
    ('p2000000-0000-0000-0000-000000000011', 4),   -- DevOps & Cloud
    -- Post 12: Kubernetes
    ('p2000000-0000-0000-0000-000000000012', 8),   -- Containers
    ('p2000000-0000-0000-0000-000000000012', 4);   -- DevOps & Cloud

-- ---------------------------------------------------------------------------
-- post_tags
-- ---------------------------------------------------------------------------
INSERT INTO post_tags (post_id, tag_id) VALUES
    -- Post 1: PostgreSQL Indexes
    ('p2000000-0000-0000-0000-000000000001', 1),   -- PostgreSQL
    ('p2000000-0000-0000-0000-000000000001', 4),   -- Performance
    ('p2000000-0000-0000-0000-000000000001', 3),   -- Tutorial
    -- Post 2: UUID vs SERIAL
    ('p2000000-0000-0000-0000-000000000002', 1),   -- PostgreSQL
    ('p2000000-0000-0000-0000-000000000002', 12),  -- Best Practices
    -- Post 3: Row-Level Security
    ('p2000000-0000-0000-0000-000000000003', 1),   -- PostgreSQL
    ('p2000000-0000-0000-0000-000000000003', 5),   -- Security
    ('p2000000-0000-0000-0000-000000000003', 3),   -- Tutorial
    -- Post 4: Time-Series (draft)
    ('p2000000-0000-0000-0000-000000000004', 1),   -- PostgreSQL
    ('p2000000-0000-0000-0000-000000000004', 4),   -- Performance
    -- Post 5: React Hooks
    ('p2000000-0000-0000-0000-000000000005', 10),  -- React
    ('p2000000-0000-0000-0000-000000000005', 3),   -- Tutorial
    ('p2000000-0000-0000-0000-000000000005', 12),  -- Best Practices
    -- Post 6: TypeScript Generics
    ('p2000000-0000-0000-0000-000000000006', 11),  -- TypeScript
    ('p2000000-0000-0000-0000-000000000006', 3),   -- Tutorial
    -- Post 7: Next.js WebSockets
    ('p2000000-0000-0000-0000-000000000007', 10),  -- React
    ('p2000000-0000-0000-0000-000000000007', 11),  -- TypeScript
    -- Post 8: State Management (draft)
    ('p2000000-0000-0000-0000-000000000008', 10),  -- React
    ('p2000000-0000-0000-0000-000000000008', 12),  -- Best Practices
    -- Post 9: ML Pipeline
    ('p2000000-0000-0000-0000-000000000009', 6),   -- Python
    ('p2000000-0000-0000-0000-000000000009', 9),   -- Machine Learning
    ('p2000000-0000-0000-0000-000000000009', 3),   -- Tutorial
    -- Post 10: Pandas vs Polars
    ('p2000000-0000-0000-0000-000000000010', 6),   -- Python
    ('p2000000-0000-0000-0000-000000000010', 4),   -- Performance
    -- Post 11: Docker Compose
    ('p2000000-0000-0000-0000-000000000011', 7),   -- Docker
    ('p2000000-0000-0000-0000-000000000011', 3),   -- Tutorial
    ('p2000000-0000-0000-0000-000000000011', 12),  -- Best Practices
    -- Post 12: Kubernetes
    ('p2000000-0000-0000-0000-000000000012', 8),   -- Kubernetes
    ('p2000000-0000-0000-0000-000000000012', 7),   -- Docker
    ('p2000000-0000-0000-0000-000000000012', 3);   -- Tutorial

-- ---------------------------------------------------------------------------
-- comments
-- ---------------------------------------------------------------------------
INSERT INTO comments (id, post_id, author_id, parent_comment_id, guest_name, guest_email, body, is_approved) VALUES
    -- Post 1: PostgreSQL Indexes — top-level comments
    (
        'c3000000-0000-0000-0000-000000000001',
        'p2000000-0000-0000-0000-000000000001',
        'u1000000-0000-0000-0000-000000000003',
        NULL, NULL, NULL,
        'Great article! I''ve been using GIN indexes for JSONB columns for a while but never fully understood why they outperform B-Tree on containment queries. The internals explanation really helped.',
        TRUE
    ),
    (
        'c3000000-0000-0000-0000-000000000002',
        'p2000000-0000-0000-0000-000000000001',
        NULL,
        NULL,
        'Marco Rossi',
        'marco.rossi@example.net',
        'Worth adding a section on BRIN indexes for append-only tables — they are tiny and very fast for time-series data.',
        TRUE
    ),
    -- Reply to Marco's comment
    (
        'c3000000-0000-0000-0000-000000000003',
        'p2000000-0000-0000-0000-000000000001',
        'u1000000-0000-0000-0000-000000000002',
        'c3000000-0000-0000-0000-000000000002',
        NULL, NULL,
        'Good point, Marco! BRIN is on my list for a follow-up post on time-series schemas. Stay tuned.',
        TRUE
    ),
    (
        'c3000000-0000-0000-0000-000000000004',
        'p2000000-0000-0000-0000-000000000001',
        'u1000000-0000-0000-0000-000000000004',
        NULL, NULL, NULL,
        'The EXPLAIN ANALYZE walkthrough is the clearest I''ve seen. Do you plan to cover partial indexes and index-only scans?',
        TRUE
    ),
    -- Reply to Carla
    (
        'c3000000-0000-0000-0000-000000000005',
        'p2000000-0000-0000-0000-000000000001',
        'u1000000-0000-0000-0000-000000000002',
        'c3000000-0000-0000-0000-000000000004',
        NULL, NULL,
        'Yes! Partial indexes and index-only scans are covered in Part 2, which I''m finishing up now.',
        TRUE
    ),
    -- Post 2: UUID vs SERIAL
    (
        'c3000000-0000-0000-0000-000000000006',
        'p2000000-0000-0000-0000-000000000002',
        NULL,
        NULL,
        'Sophie Dubois',
        'sophie.dubois@example.fr',
        'Very balanced comparison. For distributed systems we use ULIDs (Universally Unique Lexicographically Sortable Identifiers) — they combine the uniqueness of UUID with the sortability of SERIAL. Might be worth mentioning.',
        TRUE
    ),
    (
        'c3000000-0000-0000-0000-000000000007',
        'p2000000-0000-0000-0000-000000000002',
        'u1000000-0000-0000-0000-000000000005',
        NULL, NULL, NULL,
        'We migrated from SERIAL to UUID on a 50M-row table last year. The index fragmentation concern is real — we had to run VACUUM FULL during a maintenance window.',
        TRUE
    ),
    -- Post 5: React Hooks
    (
        'c3000000-0000-0000-0000-000000000008',
        'p2000000-0000-0000-0000-000000000005',
        NULL,
        NULL,
        'Lena Fischer',
        'lena.fischer@example.de',
        'The useDebounce custom hook example saved me hours. I had been rolling my own with setTimeout every time. Thank you!',
        TRUE
    ),
    (
        'c3000000-0000-0000-0000-000000000009',
        'p2000000-0000-0000-0000-000000000005',
        'u1000000-0000-0000-0000-000000000004',
        NULL, NULL, NULL,
        'Minor note: the useEffect cleanup in the useFetch example should also handle the case where the component unmounts mid-request to prevent the "Can''t perform a React state update on an unmounted component" warning.',
        TRUE
    ),
    -- Reply to Carla's note
    (
        'c3000000-0000-0000-0000-000000000010',
        'p2000000-0000-0000-0000-000000000005',
        'u1000000-0000-0000-0000-000000000003',
        'c3000000-0000-0000-0000-000000000009',
        NULL, NULL,
        'Great catch, Carla! Updated the snippet to use AbortController — the article now shows the full cleanup pattern.',
        TRUE
    ),
    -- Post 9: ML Pipeline — one pending moderation
    (
        'c3000000-0000-0000-0000-000000000011',
        'p2000000-0000-0000-0000-000000000009',
        NULL,
        NULL,
        'James Liu',
        'james.liu@example.com',
        'Does this pipeline approach work with PyTorch models too, or is it scikit-learn specific?',
        TRUE
    ),
    (
        'c3000000-0000-0000-0000-000000000012',
        'p2000000-0000-0000-0000-000000000009',
        'u1000000-0000-0000-0000-000000000004',
        'c3000000-0000-0000-0000-000000000011',
        NULL, NULL,
        'Great question, James. DVC is framework-agnostic — you can wrap any Python script as a stage, including PyTorch training loops. MLflow has first-class PyTorch support too.',
        TRUE
    ),
    -- Post 11: Docker Compose
    (
        'c3000000-0000-0000-0000-000000000013',
        'p2000000-0000-0000-0000-000000000011',
        NULL,
        NULL,
        'Carlos Mendez',
        'carlos.mendez@example.mx',
        'The health check section is gold. I''ve been burned so many times by the API starting before the database is ready.',
        TRUE
    ),
    (
        'c3000000-0000-0000-0000-000000000014',
        'p2000000-0000-0000-0000-000000000011',
        'u1000000-0000-0000-0000-000000000001',
        NULL, NULL, NULL,
        'Excellent tutorial Dan. One addition worth mentioning: Docker Compose Watch (introduced in Compose v2.22) can replace volume mounts for hot-reload in many cases.',
        TRUE
    ),
    -- Reply to admin comment
    (
        'c3000000-0000-0000-0000-000000000015',
        'p2000000-0000-0000-0000-000000000011',
        'u1000000-0000-0000-0000-000000000005',
        'c3000000-0000-0000-0000-000000000014',
        NULL, NULL,
        'Thanks! I''ll add a section on Compose Watch in a follow-up — it''s a big quality-of-life improvement.',
        TRUE
    ),
    -- Post 12: Kubernetes
    (
        'c3000000-0000-0000-0000-000000000016',
        'p2000000-0000-0000-0000-000000000012',
        'u1000000-0000-0000-0000-000000000002',
        NULL, NULL, NULL,
        'This is the article I wish existed when I was learning Kubernetes. The analogy between Deployment and ReplicaSet really clicked for me.',
        TRUE
    ),
    (
        'c3000000-0000-0000-0000-000000000017',
        'p2000000-0000-0000-0000-000000000012',
        NULL,
        NULL,
        'Yuki Tanaka',
        'yuki.tanaka@example.jp',
        'Would love a Part 2 covering Helm charts and GitOps with Argo CD.',
        TRUE
    ),
    -- A comment pending moderation
    (
        'c3000000-0000-0000-0000-000000000018',
        'p2000000-0000-0000-0000-000000000012',
        NULL,
        NULL,
        'Spambot9000',
        'spam@spam.invalid',
        'Check out my amazing blog for more Kubernetes tips!!!',
        FALSE
    );

COMMIT;
