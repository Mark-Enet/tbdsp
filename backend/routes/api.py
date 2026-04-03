import os
import re

from flask import Blueprint, current_app, jsonify

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
