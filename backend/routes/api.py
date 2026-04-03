import logging
import os
import re

from flask import Blueprint, current_app, jsonify

api_bp = Blueprint("api", __name__, url_prefix="/api")

# Only allow simple alphanumeric path segments (no slashes, dots, or parent refs)
_SAFE_SEGMENT = re.compile(r"^[A-Za-z0-9_-]+$")


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

    for domain in sorted(os.listdir(base)):
        domain_path = os.path.join(base, domain)
        if not os.path.isdir(domain_path):
            continue
        for db in sorted(os.listdir(domain_path)):
            db_path = os.path.join(domain_path, db)
            if not os.path.isdir(db_path):
                continue

            files = os.listdir(db_path)
            entry = {
                "domain": domain,
                "database": db,
                "files": {
                    "schema": "schema.sql" if "schema.sql" in files else None,
                    "sample_data": "sample_data.sql" if "sample_data.sql" in files else None,
                    "readme": "README.md" if "README.md" in files else None,
                    "erd": "erd.mmd" if "erd.mmd" in files else None,
                },
            }
            schemas.append(entry)

    return schemas


@api_bp.route("/domains", methods=["GET"])
def list_domains():
    """Return a sorted list of unique domain names found in the schemas directory."""
    base = _schemas_dir()
    if not os.path.isdir(base):
        return jsonify([])

    domains = sorted(
        name for name in os.listdir(base) if os.path.isdir(os.path.join(base, name))
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
    allowed = {"schema.sql", "sample_data.sql", "README.md", "erd.mmd"}
    if filename not in allowed:
        return jsonify({"error": "File not found"}), 404

    if not _is_safe_segment(domain) or not _is_safe_segment(database):
        return jsonify({"error": "Invalid domain or database name"}), 400

    # Resolve the real path and confirm it stays inside the schemas directory
    schemas_base = os.path.realpath(_schemas_dir())
    file_path = os.path.realpath(os.path.join(schemas_base, domain, database, filename))
    if os.path.commonpath([schemas_base, file_path]) != schemas_base:
        return jsonify({"error": "File not found"}), 404

    if not os.path.isfile(file_path):
        return jsonify({"error": "File not found"}), 404

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except (OSError, UnicodeDecodeError) as exc:
        current_app.logger.error("Could not read schema file %s: %s", file_path, exc)
        return jsonify({"error": "Could not read file"}), 500

    return jsonify({"domain": domain, "database": database, "filename": filename, "content": content})
