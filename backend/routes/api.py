import json
import os
import re

from flask import Blueprint, current_app, g, jsonify, request

import psycopg2
import psycopg2.extras

api_bp = Blueprint("api", __name__, url_prefix="/api")

# Only allow simple alphanumeric path segments — no slashes, dots, or hyphens at
# the start/end (guards against path traversal and shell-ambiguous names).
_SAFE_SEGMENT = re.compile(r"^[A-Za-z0-9_]([A-Za-z0-9_-]*[A-Za-z0-9_])?$")

_ALLOWED_FILES = {"schema.sql", "sample_data.sql", "README.md", "erd.mmd"}


def _schemas_dir():
    return current_app.config["SCHEMAS_DIR"]


def _is_safe_segment(value):
    """Return True only if *value* is a safe, single path segment."""
    return bool(_SAFE_SEGMENT.match(value))


def _list_schemas():
    """Scan the schemas directory and return a list of schema metadata dicts."""
    schemas = []
    base = _schemas_dir()
    if not os.path.isdir(base):
        return schemas

    for domain_entry in sorted(os.scandir(base), key=lambda e: e.name):
        if not domain_entry.is_dir():
            continue
        for db_entry in sorted(os.scandir(domain_entry.path), key=lambda e: e.name):
            if not db_entry.is_dir():
                continue

            files = {e.name for e in os.scandir(db_entry.path) if e.is_file()}
            entry = {
                "domain": domain_entry.name,
                "database": db_entry.name,
                "files": {
                    "schema": "schema.sql" if "schema.sql" in files else None,
                    "sample_data": "sample_data.sql" if "sample_data.sql" in files else None,
                    "readme": "README.md" if "README.md" in files else None,
                    "erd": "erd.mmd" if "erd.mmd" in files else None,
                },
            }
            schemas.append(entry)

    return schemas


def _find_db_path(domain, database):
    """Walk the filesystem to find the directory for *domain*/*database*.

    Returns the real, filesystem-derived path (not built from user input) so that
    subsequent file operations are not tainted by user-supplied values.
    Returns ``None`` if the combination does not exist.
    """
    schemas_base = os.path.realpath(_schemas_dir())
    try:
        for domain_entry in os.scandir(schemas_base):
            if domain_entry.is_dir() and domain_entry.name == domain:
                for db_entry in os.scandir(domain_entry.path):
                    if db_entry.is_dir() and db_entry.name == database:
                        return db_entry.path  # filesystem-derived, not user input
    except OSError:
        pass
    return None


@api_bp.route("/domains", methods=["GET"])
def list_domains():
    """Return a sorted list of unique domain names found in the schemas directory."""
    base = _schemas_dir()
    if not os.path.isdir(base):
        return jsonify([])

    domains = sorted(
        e.name for e in os.scandir(base) if e.is_dir()
    )
    return jsonify(domains)


@api_bp.route("/schemas/", methods=["GET"])
@api_bp.route("/schemas", methods=["GET"])
def list_schemas():
    """Return metadata for all available schemas."""
    return jsonify(_list_schemas())


@api_bp.route("/schemas/<domain>", methods=["GET"])
def list_schemas_by_domain(domain):
    """Return metadata for all schemas belonging to a specific domain."""
    if not _is_safe_segment(domain):
        return jsonify({"error": "Invalid domain name"}), 400
    all_schemas = _list_schemas()
    filtered = [s for s in all_schemas if s["domain"] == domain]
    if not filtered:
        return jsonify({"error": f"Domain '{domain}' not found"}), 404
    return jsonify(filtered)


@api_bp.route("/schemas/<domain>/<database>", methods=["GET"])
def get_schema(domain, database):
    """Return metadata for a specific domain/database schema."""
    if not _is_safe_segment(domain) or not _is_safe_segment(database):
        return jsonify({"error": "Invalid domain or database name"}), 400
    all_schemas = _list_schemas()
    for s in all_schemas:
        if s["domain"] == domain and s["database"] == database:
            return jsonify(s)
    return jsonify({"error": f"Schema '{domain}/{database}' not found"}), 404


@api_bp.route("/schemas/<domain>/<database>/<filename>", methods=["GET"])
def get_schema_file(domain, database, filename):
    """Return the raw content of a schema file (schema.sql, sample_data.sql, README.md, erd.mmd)."""
    if filename not in _ALLOWED_FILES:
        return jsonify({"error": "File not found"}), 404

    if not _is_safe_segment(domain) or not _is_safe_segment(database):
        return jsonify({"error": "Invalid domain or database name"}), 400

    # Resolve the directory from the filesystem (path is NOT built from user input).
    db_path = _find_db_path(domain, database)
    if db_path is None:
        return jsonify({"error": "File not found"}), 404

    # Use the value from the allowlist (not the raw user input) to build the path,
    # so the path is constructed entirely from trusted/filesystem-derived values.
    safe_filename = next(f for f in _ALLOWED_FILES if f == filename)
    file_path = os.path.join(db_path, safe_filename)
    if not os.path.isfile(file_path):
        return jsonify({"error": "File not found"}), 404

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except (OSError, UnicodeDecodeError) as exc:
        current_app.logger.error("Could not read schema file %s: %s", file_path, exc)
        return jsonify({"error": "Could not read file"}), 500

    return jsonify({"domain": domain, "database": database, "filename": filename, "content": content})


# ===========================================================================
# Metadata routes — /api/meta/*
# Data is read from the PostgreSQL metadata tables populated by seed.py.
# ===========================================================================

_DB_JSON = os.path.join(os.path.dirname(os.path.dirname(__file__)), "config", "config.json")


def _get_db():
    """Return a per-request psycopg2 connection, stored in Flask's g object."""
    if "db" not in g:
        env = os.environ.get("APP_ENV", "development")
        if env == "default":
            env = "development"
        with open(_DB_JSON, encoding="utf-8") as fh:
            all_cfg = json.load(fh)
        cfg = all_cfg.get(env) or all_cfg.get("development")
        g.db = psycopg2.connect(
            dbname=cfg["database"],
            user=cfg["username"],
            password=cfg["password"],
            host=cfg.get("host", "127.0.0.1"),
            port=int(cfg.get("port", 5432)),
        )
    return g.db


def _cur():
    return _get_db().cursor(cursor_factory=psycopg2.extras.RealDictCursor)


@api_bp.route("/meta/domains", methods=["GET"])
def meta_domains():
    """Return all domains with per-domain engine, table, and column counts."""
    cur = _cur()
    cur.execute(
        """
        SELECT
            d.id,
            d.name,
            d.description,
            COUNT(DISTINCT de.id)  AS engine_count,
            COUNT(DISTINCT st.id)  AS table_count,
            COUNT(DISTINCT sc.id)  AS column_count
        FROM domains d
        LEFT JOIN database_engines de ON de.domain_id = d.id
        LEFT JOIN schema_tables    st ON st.engine_id  = de.id
        LEFT JOIN schema_columns   sc ON sc.table_id   = st.id
        GROUP BY d.id, d.name, d.description
        ORDER BY d.name
        """
    )
    rows = [dict(r) for r in cur.fetchall()]
    return jsonify(rows)


@api_bp.route("/meta/domains/<domain>/engines", methods=["GET"])
def meta_domain_engines(domain):
    """Return the database engines available for a domain, with table counts."""
    if not _is_safe_segment(domain):
        return jsonify({"error": "Invalid domain name"}), 400
    cur = _cur()
    cur.execute(
        """
        SELECT
            de.id,
            de.engine,
            de.version_note,
            COUNT(DISTINCT st.id) AS table_count,
            COUNT(DISTINCT sc.id) AS column_count,
            COUNT(DISTINCT se.id) AS enum_count
        FROM database_engines de
        JOIN domains d ON d.id = de.domain_id
        LEFT JOIN schema_tables  st ON st.engine_id = de.id
        LEFT JOIN schema_columns sc ON sc.table_id  = st.id
        LEFT JOIN schema_enums   se ON se.engine_id = de.id
        WHERE d.name = %s
        GROUP BY de.id, de.engine, de.version_note
        ORDER BY de.engine
        """,
        (domain,),
    )
    rows = [dict(r) for r in cur.fetchall()]
    if not rows:
        return jsonify({"error": f"Domain '{domain}' not found or not yet seeded"}), 404
    return jsonify(rows)


@api_bp.route("/meta/domains/<domain>/<engine>/tables", methods=["GET"])
def meta_tables(domain, engine):
    """Return all tables for a domain/engine with column, index, and FK counts."""
    if not _is_safe_segment(domain) or not _is_safe_segment(engine):
        return jsonify({"error": "Invalid domain or engine name"}), 400
    cur = _cur()
    cur.execute(
        """
        SELECT
            st.id,
            st.name,
            st.table_comment,
            COUNT(DISTINCT sc.id)  AS column_count,
            COUNT(DISTINCT si.id)  AS index_count,
            COUNT(DISTINCT sfk.id) AS fk_count
        FROM schema_tables st
        JOIN database_engines de ON de.id = st.engine_id
        JOIN domains d            ON d.id  = de.domain_id
        LEFT JOIN schema_columns     sc  ON sc.table_id  = st.id
        LEFT JOIN schema_indexes     si  ON si.table_id  = st.id
        LEFT JOIN schema_foreign_keys sfk ON sfk.table_id = st.id
        WHERE d.name = %s AND de.engine = %s
        GROUP BY st.id, st.name, st.table_comment
        ORDER BY st.name
        """,
        (domain, engine),
    )
    rows = [dict(r) for r in cur.fetchall()]
    return jsonify(rows)


@api_bp.route("/meta/domains/<domain>/<engine>/enums", methods=["GET"])
def meta_enums(domain, engine):
    """Return all enum types for a domain/engine."""
    if not _is_safe_segment(domain) or not _is_safe_segment(engine):
        return jsonify({"error": "Invalid domain or engine name"}), 400
    cur = _cur()
    cur.execute(
        """
        SELECT se.name, se.values
        FROM schema_enums se
        JOIN database_engines de ON de.id = se.engine_id
        JOIN domains d            ON d.id  = de.domain_id
        WHERE d.name = %s AND de.engine = %s
        ORDER BY se.name
        """,
        (domain, engine),
    )
    rows = [dict(r) for r in cur.fetchall()]
    return jsonify(rows)


@api_bp.route("/meta/domains/<domain>/<engine>/tables/<table>", methods=["GET"])
def meta_table_detail(domain, engine, table):
    """Return full metadata for one table: columns, indexes, and foreign keys."""
    if (
        not _is_safe_segment(domain)
        or not _is_safe_segment(engine)
        or not _is_safe_segment(table)
    ):
        return jsonify({"error": "Invalid path segment"}), 400

    cur = _cur()

    # Table header
    cur.execute(
        """
        SELECT st.id, st.name, st.table_comment, de.engine, de.version_note, d.name AS domain
        FROM schema_tables st
        JOIN database_engines de ON de.id = st.engine_id
        JOIN domains d            ON d.id  = de.domain_id
        WHERE d.name = %s AND de.engine = %s AND st.name = %s
        """,
        (domain, engine, table),
    )
    row = cur.fetchone()
    if row is None:
        return jsonify({"error": f"Table '{table}' not found"}), 404
    table_id = row["id"]
    result = {
        "name": row["name"],
        "comment": row["table_comment"],
        "engine": row["engine"],
        "version_note": row["version_note"],
        "domain": row["domain"],
    }

    # Columns
    cur.execute(
        """
        SELECT name, data_type, is_nullable, default_value,
               is_primary_key, column_comment, position
        FROM schema_columns
        WHERE table_id = %s
        ORDER BY position
        """,
        (table_id,),
    )
    result["columns"] = [dict(r) for r in cur.fetchall()]

    # Indexes
    cur.execute(
        """
        SELECT name, index_type, is_unique, is_partial, where_clause, columns
        FROM schema_indexes
        WHERE table_id = %s
        ORDER BY name
        """,
        (table_id,),
    )
    result["indexes"] = [dict(r) for r in cur.fetchall()]

    # Foreign keys
    cur.execute(
        """
        SELECT constraint_name, from_columns, to_table, to_columns, on_delete, on_update
        FROM schema_foreign_keys
        WHERE table_id = %s
        ORDER BY id
        """,
        (table_id,),
    )
    result["foreign_keys"] = [dict(r) for r in cur.fetchall()]

    return jsonify(result)


@api_bp.route("/meta/search", methods=["GET"])
def meta_search():
    """
    Cross-domain full-text search across table names, column names,
    table comments, and column comments.
    Returns up to 100 results ordered by domain/engine/table/column.
    """
    q = request.args.get("q", "").strip()
    if not q:
        return jsonify([])
    if len(q) > 200:
        return jsonify({"error": "Query too long"}), 400

    pattern = f"%{q}%"
    cur = _cur()
    cur.execute(
        """
        SELECT
            d.name        AS domain,
            de.engine,
            st.name       AS table_name,
            st.table_comment,
            sc.name       AS column_name,
            sc.data_type,
            sc.is_nullable,
            sc.is_primary_key,
            sc.column_comment
        FROM schema_columns sc
        JOIN schema_tables     st ON st.id = sc.table_id
        JOIN database_engines  de ON de.id = st.engine_id
        JOIN domains           d  ON d.id  = de.domain_id
        WHERE
            sc.name          ILIKE %s OR
            st.name          ILIKE %s OR
            sc.column_comment ILIKE %s OR
            st.table_comment  ILIKE %s
        ORDER BY d.name, de.engine, st.name, sc.position
        LIMIT 100
        """,
        (pattern, pattern, pattern, pattern),
    )
    rows = [dict(r) for r in cur.fetchall()]
    return jsonify(rows)
