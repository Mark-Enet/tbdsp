-- =============================================================================
-- TBDSP — The Big DataBase Standards Project
-- Domain   : Blogging / CMS
-- Database : PostgreSQL 14+
-- File     : schema.sql
-- Version  : 1.0.0
-- Description:
--   A production-ready blogging / content-management schema covering authors,
--   hierarchical categories, tags, posts (with draft/published workflow),
--   nested comments, and media assets.
--   Designed to reflect real-world best practices: surrogate UUID PKs, FK
--   constraints, CHECK constraints for business rules, partial indexes for
--   published content, GIN indexes for JSONB, and auto-updating triggers.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "citext";     -- case-insensitive text for emails

-- ---------------------------------------------------------------------------
-- Enum types
-- ---------------------------------------------------------------------------

CREATE TYPE user_role AS ENUM (
    'admin',
    'editor',
    'author'
);

CREATE TYPE post_status AS ENUM (
    'draft',
    'published',
    'scheduled',
    'archived'
);

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
-- Stores authors and editorial staff. Email uses citext so that uniqueness
-- is enforced case-insensitively without lowercasing on every write.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT          NOT NULL,
    password_hash   TEXT            NOT NULL,
    display_name    VARCHAR(150)    NOT NULL,
    bio             TEXT,
    avatar_url      TEXT,
    role            user_role       NOT NULL DEFAULT 'author',
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_users_email UNIQUE (email)
);

CREATE INDEX idx_users_email      ON users (email);
CREATE INDEX idx_users_role       ON users (role);
CREATE INDEX idx_users_created_at ON users (created_at DESC);

COMMENT ON TABLE  users              IS 'Blog authors and editorial staff.';
COMMENT ON COLUMN users.email        IS 'Login email — unique, case-insensitive.';
COMMENT ON COLUMN users.password_hash IS 'bcrypt / Argon2 hash; never store plain-text.';
COMMENT ON COLUMN users.display_name IS 'Public-facing author name shown on posts.';
COMMENT ON COLUMN users.role         IS 'admin: full access; editor: manage all posts; author: own posts only.';

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

COMMENT ON TABLE  categories           IS 'Hierarchical post categories (adjacency list).';
COMMENT ON COLUMN categories.slug      IS 'URL-safe unique identifier, e.g. "web-development".';
COMMENT ON COLUMN categories.parent_id IS 'NULL for top-level categories.';

-- ---------------------------------------------------------------------------
-- tags
-- ---------------------------------------------------------------------------
-- Flat taxonomy for cross-cutting keywords. Posts can have many tags via
-- the post_tags junction table.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tags (
    id              SERIAL          PRIMARY KEY,
    name            VARCHAR(100)    NOT NULL,
    slug            VARCHAR(100)    NOT NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_tags_slug UNIQUE (slug),
    CONSTRAINT uq_tags_name UNIQUE (name)
);

COMMENT ON TABLE  tags      IS 'Flat keyword tags for cross-cutting classification.';
COMMENT ON COLUMN tags.slug IS 'URL-safe unique identifier, e.g. "open-source".';

-- ---------------------------------------------------------------------------
-- posts
-- ---------------------------------------------------------------------------
-- Core content table. body stores the full article text; excerpt is a short
-- summary (plain text) used in listing pages and meta descriptions.
-- meta_title / meta_description support SEO overrides independently of the
-- post title and excerpt.
-- published_at is NULL for drafts and set explicitly when publishing so that
-- scheduled posts can be pre-dated.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS posts (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id           UUID            NOT NULL REFERENCES users (id),
    title               VARCHAR(255)    NOT NULL,
    slug                VARCHAR(255)    NOT NULL,
    excerpt             TEXT,
    body                TEXT            NOT NULL,
    status              post_status     NOT NULL DEFAULT 'draft',
    featured_image_url  TEXT,
    meta_title          VARCHAR(255),
    meta_description    VARCHAR(500),
    like_count          INTEGER         NOT NULL DEFAULT 0,
    view_count          INTEGER         NOT NULL DEFAULT 0,
    published_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_posts_slug         UNIQUE (slug),
    CONSTRAINT chk_posts_like_count  CHECK (like_count >= 0),
    CONSTRAINT chk_posts_view_count  CHECK (view_count >= 0)
);

-- General lookups
CREATE INDEX idx_posts_author_id    ON posts (author_id);
CREATE INDEX idx_posts_status       ON posts (status);
CREATE INDEX idx_posts_published_at ON posts (published_at DESC);
-- Partial index: most queries only care about published posts
CREATE INDEX idx_posts_published    ON posts (published_at DESC) WHERE status = 'published';
CREATE INDEX idx_posts_slug         ON posts (slug);

COMMENT ON TABLE  posts                   IS 'Blog posts and CMS articles.';
COMMENT ON COLUMN posts.slug              IS 'URL-safe unique identifier, e.g. "getting-started-with-postgres".';
COMMENT ON COLUMN posts.body              IS 'Full article content (Markdown / HTML / plain text).';
COMMENT ON COLUMN posts.excerpt           IS 'Short plain-text summary for listing pages and RSS feeds.';
COMMENT ON COLUMN posts.status            IS 'Workflow state: draft → published (or scheduled → published).';
COMMENT ON COLUMN posts.published_at      IS 'NULL until published; set explicitly to support scheduled publishing.';
COMMENT ON COLUMN posts.meta_title        IS 'SEO <title> override; falls back to title when NULL.';
COMMENT ON COLUMN posts.meta_description  IS 'SEO <meta description> override; falls back to excerpt when NULL.';
COMMENT ON COLUMN posts.like_count        IS 'Denormalised counter — increment via application logic or trigger.';

-- ---------------------------------------------------------------------------
-- post_categories
-- ---------------------------------------------------------------------------
-- Many-to-many junction between posts and categories.
-- A post may belong to multiple categories (e.g., "Technology" + "Tutorials").
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS post_categories (
    post_id         UUID        NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
    category_id     INTEGER     NOT NULL REFERENCES categories (id) ON DELETE CASCADE,

    CONSTRAINT pk_post_categories PRIMARY KEY (post_id, category_id)
);

CREATE INDEX idx_post_categories_category_id ON post_categories (category_id);

COMMENT ON TABLE post_categories IS 'Junction table — assigns categories to posts (many-to-many).';

-- ---------------------------------------------------------------------------
-- post_tags
-- ---------------------------------------------------------------------------
-- Many-to-many junction between posts and tags.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS post_tags (
    post_id     UUID        NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
    tag_id      INTEGER     NOT NULL REFERENCES tags (id) ON DELETE CASCADE,

    CONSTRAINT pk_post_tags PRIMARY KEY (post_id, tag_id)
);

CREATE INDEX idx_post_tags_tag_id ON post_tags (tag_id);

COMMENT ON TABLE post_tags IS 'Junction table — assigns tags to posts (many-to-many).';

-- ---------------------------------------------------------------------------
-- comments
-- ---------------------------------------------------------------------------
-- Threaded comment system using an adjacency-list (parent_comment_id).
-- Both registered users and anonymous guests can comment:
--   • Registered: author_id is set; guest_name / guest_email are NULL.
--   • Guest:      author_id is NULL; guest_name and guest_email are required.
-- is_approved supports moderation — set FALSE to hold comments for review.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS comments (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id             UUID            NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
    author_id           UUID            REFERENCES users (id) ON DELETE SET NULL,
    parent_comment_id   UUID            REFERENCES comments (id) ON DELETE CASCADE,
    guest_name          VARCHAR(150),
    guest_email         CITEXT,
    body                TEXT            NOT NULL,
    is_approved         BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- Either a registered author or guest credentials must be present
    CONSTRAINT chk_comments_author CHECK (
        author_id IS NOT NULL
        OR (guest_name IS NOT NULL AND guest_email IS NOT NULL)
    ),
    CONSTRAINT chk_comments_body_not_empty CHECK (LENGTH(TRIM(body)) > 0)
);

CREATE INDEX idx_comments_post_id           ON comments (post_id);
CREATE INDEX idx_comments_author_id         ON comments (author_id);
CREATE INDEX idx_comments_parent_comment_id ON comments (parent_comment_id);
-- Partial index: approved comments are the common read path
CREATE INDEX idx_comments_approved          ON comments (post_id, created_at) WHERE is_approved = TRUE;

COMMENT ON TABLE  comments                   IS 'Threaded post comments — supports registered users and anonymous guests.';
COMMENT ON COLUMN comments.parent_comment_id IS 'NULL for top-level comments; set to enable threaded replies.';
COMMENT ON COLUMN comments.guest_name        IS 'Display name for anonymous commenters; NULL for registered users.';
COMMENT ON COLUMN comments.guest_email       IS 'Email for anonymous commenters (not shown publicly); NULL for registered users.';
COMMENT ON COLUMN comments.is_approved       IS 'FALSE holds the comment for moderation before it appears publicly.';

-- ---------------------------------------------------------------------------
-- media
-- ---------------------------------------------------------------------------
-- Tracks uploaded images and files that can be attached to posts as featured
-- images or embedded in body content. storage_url points to the final
-- location (local filesystem, S3, CDN, etc.).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    uploader_id         UUID            REFERENCES users (id) ON DELETE SET NULL,
    filename            VARCHAR(255)    NOT NULL,
    original_filename   VARCHAR(255)    NOT NULL,
    mime_type           VARCHAR(100)    NOT NULL,
    file_size_bytes     BIGINT          NOT NULL,
    storage_url         TEXT            NOT NULL,
    alt_text            TEXT,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_media_file_size CHECK (file_size_bytes > 0)
);

CREATE INDEX idx_media_uploader_id ON media (uploader_id);
CREATE INDEX idx_media_mime_type   ON media (mime_type);
CREATE INDEX idx_media_created_at  ON media (created_at DESC);

COMMENT ON TABLE  media                   IS 'Uploaded media assets (images, documents) for use in posts.';
COMMENT ON COLUMN media.filename          IS 'Stored filename — may differ from the original (e.g. UUID-based).';
COMMENT ON COLUMN media.original_filename IS 'Filename as uploaded by the user, preserved for display purposes.';
COMMENT ON COLUMN media.storage_url       IS 'Absolute URL or path to the stored file (local, S3, CDN, etc.).';
COMMENT ON COLUMN media.file_size_bytes   IS 'File size in bytes — used for quota management.';

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
        'users', 'posts', 'comments'
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
