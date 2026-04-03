#!/usr/bin/env python3
"""seed.py — Parse schema.sql files and populate the TBDSP metadata database.

Run standalone:
    venv/bin/python seed.py

Run as Flask CLI command (after registering in app.py):
    flask seed
"""

import json
import os
import re
import sys

# ---------------------------------------------------------------------------
# Ensure backend/ is on the path so we can import db and config
# ---------------------------------------------------------------------------
_HERE = os.path.dirname(os.path.abspath(__file__))
if _HERE not in sys.path:
    sys.path.insert(0, _HERE)

from db import get_connection  # noqa: E402

# ---------------------------------------------------------------------------
# SQL parsing helpers
# ---------------------------------------------------------------------------


def _strip_line_comments(text: str) -> str:
    """Remove -- style comments from every line (naive but sufficient here)."""
    lines = []
    for line in text.split("\n"):
        idx = line.find("--")
        if idx >= 0:
            line = line[:idx]
        lines.append(line)
    return "\n".join(lines)


def _split_at_depth_zero(text: str, delimiter: str = ",") -> list[str]:
    """Split *text* at each *delimiter* that is not inside parentheses."""
    parts: list[str] = []
    current: list[str] = []
    depth = 0
    for ch in text:
        if ch == "(":
            depth += 1
            current.append(ch)
        elif ch == ")":
            depth -= 1
            current.append(ch)
        elif ch == delimiter and depth == 0:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
    tail = "".join(current).strip()
    if tail:
        parts.append(tail)
    return parts


def _extract_table_blocks(sql: str) -> list[tuple[str, str]]:
    """Return [(table_name, body_str)] for every CREATE TABLE in *sql*."""
    results = []
    pat = re.compile(
        r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)\s*\(",
        re.IGNORECASE,
    )
    for m in pat.finditer(sql):
        table_name = m.group(1)
        start = m.end() - 1  # position of the opening (
        depth = 0
        end = start
        for i in range(start, len(sql)):
            if sql[i] == "(":
                depth += 1
            elif sql[i] == ")":
                depth -= 1
                if depth == 0:
                    end = i
                    break
        body = sql[start + 1 : end]
        results.append((table_name, body))
    return results


def _extract_type_token(text: str) -> tuple[str, str]:
    """Return (type_str, remainder) where type_str is the SQL data type."""
    m = re.match(r"(\w+(?:\s*\([^)]*\))?)\s*(.*)", text.strip(), re.DOTALL)
    if m:
        return m.group(1).strip(), m.group(2).strip()
    tokens = text.strip().split()
    return (tokens[0] if tokens else ""), ""


_NOT_NULL_RE = re.compile(r"\bNOT\s+NULL\b", re.IGNORECASE)
_PK_RE = re.compile(r"\bPRIMARY\s+KEY\b", re.IGNORECASE)
_DEFAULT_RE = re.compile(r"\bDEFAULT\s+", re.IGNORECASE)
_REFS_RE = re.compile(
    r"\bREFERENCES\s+(\w+)\s*\(\s*(\w+)\s*\)"
    r"(?:\s+ON\s+DELETE\s+"
    r"(CASCADE|RESTRICT|SET\s+NULL|SET\s+DEFAULT|NO\s+ACTION))?"
    r"(?:\s+ON\s+UPDATE\s+"
    r"(CASCADE|RESTRICT|SET\s+NULL|SET\s+DEFAULT|NO\s+ACTION))?",
    re.IGNORECASE,
)


def _extract_default(after_type: str) -> str | None:
    m = _DEFAULT_RE.search(after_type)
    if not m:
        return None
    rest = after_type[m.end() :]
    stop = re.search(
        r"\s+(?:NOT\s+NULL|NULL|PRIMARY\s+KEY|REFERENCES|UNIQUE|CONSTRAINT|CHECK)\b",
        rest,
        re.IGNORECASE,
    )
    raw = rest[: stop.start()].strip() if stop else re.split(r"[;,\n]", rest)[0].strip()
    return raw or None


def _parse_column_def(raw: str) -> dict | None:
    """Parse one column-definition item; return None if it is a table constraint."""
    text = _strip_line_comments(raw).strip()
    if not text:
        return None
    first = text.split()[0].upper() if text.split() else ""
    if first in ("CONSTRAINT", "PRIMARY", "UNIQUE", "CHECK", "FOREIGN"):
        return None

    col_name = text.split()[0]
    rest = text[len(col_name) :].strip()
    data_type, after_type = _extract_type_token(rest)

    is_nullable = not bool(_NOT_NULL_RE.search(after_type))
    is_primary_key = bool(_PK_RE.search(after_type))
    # PKs are implicitly NOT NULL
    if is_primary_key:
        is_nullable = False
    default_value = _extract_default(after_type)

    ref_table = ref_col = on_delete = on_update = None
    rm = _REFS_RE.search(after_type)
    if rm:
        ref_table = rm.group(1)
        ref_col = rm.group(2)
        on_delete = rm.group(3)
        on_update = rm.group(4)

    return {
        "name": col_name,
        "data_type": data_type,
        "is_nullable": is_nullable,
        "default_value": default_value,
        "is_primary_key": is_primary_key,
        "ref_table": ref_table,
        "ref_col": ref_col,
        "on_delete": on_delete,
        "on_update": on_update,
    }


def _parse_table_pk_constraint(raw: str) -> list[str]:
    """If *raw* is a table-level PRIMARY KEY constraint, return column names."""
    text = _strip_line_comments(raw).strip()
    m = re.match(
        r"(?:CONSTRAINT\s+\w+\s+)?PRIMARY\s+KEY\s*\(([^)]+)\)",
        text,
        re.IGNORECASE,
    )
    return [c.strip() for c in m.group(1).split(",")] if m else []


def _parse_table_fk_constraint(raw: str) -> dict | None:
    """If *raw* is a table-level FOREIGN KEY constraint, return a dict."""
    text = _strip_line_comments(raw).strip()
    m = re.match(
        r"(?:CONSTRAINT\s+(\w+)\s+)?FOREIGN\s+KEY\s*\(([^)]+)\)\s+"
        r"REFERENCES\s+(\w+)\s*\(([^)]+)\)"
        r"(?:\s+ON\s+DELETE\s+(CASCADE|RESTRICT|SET\s+NULL|SET\s+DEFAULT|NO\s+ACTION))?"
        r"(?:\s+ON\s+UPDATE\s+(CASCADE|RESTRICT|SET\s+NULL|SET\s+DEFAULT|NO\s+ACTION))?",
        text,
        re.IGNORECASE,
    )
    if m:
        return {
            "constraint_name": m.group(1),
            "from_columns": [c.strip() for c in m.group(2).split(",")],
            "to_table": m.group(3),
            "to_columns": [c.strip() for c in m.group(4).split(",")],
            "on_delete": m.group(5),
            "on_update": m.group(6),
        }
    return None


def _parse_enums(sql: str) -> list[dict]:
    results = []
    pat = re.compile(
        r"CREATE\s+TYPE\s+(\w+)\s+AS\s+ENUM\s*\((.*?)\)",
        re.DOTALL | re.IGNORECASE,
    )
    for m in pat.finditer(sql):
        vals = [
            v.strip().strip("'")
            for v in _split_at_depth_zero(m.group(2))
            if v.strip()
        ]
        results.append({"name": m.group(1), "values": vals})
    return results


def _parse_indexes(sql: str) -> list[dict]:
    results = []
    pat = re.compile(
        r"CREATE\s+(UNIQUE\s+)?INDEX\s+(\w+)\s+ON\s+(\w+)\s*"
        r"(?:USING\s+(\w+)\s*)?\(([^)]+)\)"
        r"(?:\s+WHERE\s+(.+?))?;",
        re.IGNORECASE | re.DOTALL,
    )
    for m in pat.finditer(sql):
        raw_cols = m.group(5) or ""
        cols = [c.strip().split()[0] for c in raw_cols.split(",") if c.strip()]
        where = m.group(6).strip() if m.group(6) else None
        results.append(
            {
                "name": m.group(2),
                "table_name": m.group(3),
                "index_type": (m.group(4) or "btree").lower(),
                "is_unique": bool(m.group(1)),
                "is_partial": where is not None,
                "where_clause": where,
                "columns": cols,
            }
        )
    return results


def _parse_comments(sql: str) -> tuple[dict, dict]:
    table_comments: dict = {}
    col_comments: dict = {}
    for m in re.finditer(
        r"COMMENT\s+ON\s+TABLE\s+(\w+)\s+IS\s+'((?:[^']|'')*)'",
        sql,
        re.IGNORECASE,
    ):
        table_comments[m.group(1)] = m.group(2)
    for m in re.finditer(
        r"COMMENT\s+ON\s+COLUMN\s+(\w+)\.(\w+)\s+IS\s+'((?:[^']|'')*)'",
        sql,
        re.IGNORECASE,
    ):
        col_comments[f"{m.group(1)}.{m.group(2)}"] = m.group(3)
    return table_comments, col_comments


def _parse_version_note(sql: str) -> str | None:
    m = re.search(r"--\s*Database\s*:\s*(.+)$", sql, re.IGNORECASE | re.MULTILINE)
    return m.group(1).strip() if m else None


def parse_schema_file(sql_text: str) -> dict:
    """Return structured metadata parsed from a schema.sql file."""
    version_note = _parse_version_note(sql_text)
    enums = _parse_enums(sql_text)
    indexes = _parse_indexes(sql_text)
    table_comments, col_comments = _parse_comments(sql_text)

    tables: dict = {}
    for table_name, body in _extract_table_blocks(sql_text):
        items = _split_at_depth_zero(body)
        columns: list = []
        table_fks: list = []
        pk_cols_from_constraint: list = []

        for item in items:
            item = item.strip()
            if not item:
                continue

            pk_cols = _parse_table_pk_constraint(item)
            if pk_cols:
                pk_cols_from_constraint.extend(pk_cols)
                continue

            fk = _parse_table_fk_constraint(item)
            if fk:
                table_fks.append(fk)
                continue

            first_upper = item.split()[0].upper() if item.split() else ""
            if first_upper in ("CONSTRAINT", "UNIQUE", "CHECK", "FOREIGN", "PRIMARY"):
                continue

            col = _parse_column_def(item)
            if col:
                col["position"] = len(columns)
                columns.append(col)

        # Apply table-level PK markers
        for col in columns:
            if col["name"] in pk_cols_from_constraint:
                col["is_primary_key"] = True
                col["is_nullable"] = False

        # Attach COMMENT ON COLUMN values
        for col in columns:
            col["comment"] = col_comments.get(f"{table_name}.{col['name']}")

        tables[table_name] = {
            "columns": columns,
            "fks": table_fks,
            "comment": table_comments.get(table_name),
        }

    return {
        "version_note": version_note,
        "enums": enums,
        "tables": tables,
        "indexes": indexes,
    }


# ---------------------------------------------------------------------------
# Database upsert helpers
# ---------------------------------------------------------------------------


def _upsert_domain(cur, name: str, description: str | None) -> int:
    cur.execute(
        """
        INSERT INTO domains (name, description, created_at, updated_at)
        VALUES (%s, %s, NOW(), NOW())
        ON CONFLICT (name) DO UPDATE
          SET description = EXCLUDED.description,
              updated_at  = NOW()
        RETURNING id
        """,
        (name, description),
    )
    return cur.fetchone()[0]


def _upsert_engine(cur, domain_id: int, engine: str, version_note: str | None) -> int:
    cur.execute(
        """
        INSERT INTO database_engines
            (domain_id, engine, version_note, created_at, updated_at)
        VALUES (%s, %s, %s, NOW(), NOW())
        ON CONFLICT (domain_id, engine) DO UPDATE
          SET version_note = EXCLUDED.version_note,
              updated_at   = NOW()
        RETURNING id
        """,
        (domain_id, engine, version_note),
    )
    return cur.fetchone()[0]


def _upsert_schema_file(cur, engine_id: int, file_key: str, rel_path: str) -> None:
    cur.execute(
        """
        INSERT INTO schema_files
            (engine_id, file_key, rel_path, created_at, updated_at)
        VALUES (%s, %s, %s, NOW(), NOW())
        ON CONFLICT (engine_id, file_key) DO UPDATE
          SET rel_path   = EXCLUDED.rel_path,
              updated_at = NOW()
        """,
        (engine_id, file_key, rel_path),
    )


def _upsert_enum(cur, engine_id: int, name: str, values: list) -> None:
    cur.execute(
        """
        INSERT INTO schema_enums (engine_id, name, values)
        VALUES (%s, %s, %s)
        ON CONFLICT (engine_id, name) DO UPDATE
          SET values = EXCLUDED.values
        """,
        (engine_id, name, json.dumps(values)),
    )


def _upsert_table(cur, engine_id: int, name: str, comment: str | None) -> int:
    cur.execute(
        """
        INSERT INTO schema_tables
            (engine_id, name, table_comment, created_at, updated_at)
        VALUES (%s, %s, %s, NOW(), NOW())
        ON CONFLICT (engine_id, name) DO UPDATE
          SET table_comment = EXCLUDED.table_comment,
              updated_at    = NOW()
        RETURNING id
        """,
        (engine_id, name, comment),
    )
    return cur.fetchone()[0]


def _upsert_column(cur, table_id: int, col: dict, position: int) -> None:
    cur.execute(
        """
        INSERT INTO schema_columns
            (table_id, name, data_type, is_nullable, default_value,
             is_primary_key, column_comment, position, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        ON CONFLICT (table_id, name) DO UPDATE
          SET data_type      = EXCLUDED.data_type,
              is_nullable    = EXCLUDED.is_nullable,
              default_value  = EXCLUDED.default_value,
              is_primary_key = EXCLUDED.is_primary_key,
              column_comment = EXCLUDED.column_comment,
              position       = EXCLUDED.position,
              updated_at     = NOW()
        """,
        (
            table_id,
            col["name"],
            col["data_type"],
            col["is_nullable"],
            col["default_value"],
            col["is_primary_key"],
            col.get("comment"),
            position,
        ),
    )


def _upsert_index(cur, table_id: int, idx: dict) -> None:
    cur.execute(
        """
        INSERT INTO schema_indexes
            (table_id, name, index_type, is_unique, is_partial,
             where_clause, columns, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        ON CONFLICT (table_id, name) DO UPDATE
          SET index_type   = EXCLUDED.index_type,
              is_unique    = EXCLUDED.is_unique,
              is_partial   = EXCLUDED.is_partial,
              where_clause = EXCLUDED.where_clause,
              columns      = EXCLUDED.columns,
              updated_at   = NOW()
        """,
        (
            table_id,
            idx["name"],
            idx["index_type"],
            idx["is_unique"],
            idx["is_partial"],
            idx["where_clause"],
            json.dumps(idx["columns"]),
        ),
    )


def _insert_fk(
    cur,
    table_id: int,
    from_cols: list,
    to_table: str,
    to_cols: list,
    on_delete: str | None,
    on_update: str | None,
    constraint_name: str | None = None,
) -> None:
    cur.execute(
        """
        INSERT INTO schema_foreign_keys
            (table_id, constraint_name, from_columns, to_table,
             to_columns, on_delete, on_update, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        """,
        (
            table_id,
            constraint_name,
            json.dumps(from_cols),
            to_table,
            json.dumps(to_cols),
            on_delete,
            on_update,
        ),
    )


# ---------------------------------------------------------------------------
# Per-directory seeding
# ---------------------------------------------------------------------------

_FILE_KEYS = {
    "schema.sql": "schema",
    "sample_data.sql": "sample_data",
    "README.md": "readme",
    "erd.mmd": "erd",
}


def _seed_engine_dir(cur, engine_id: int, engine_path: str, sql_text: str | None) -> None:
    """Seed schema_files + parsed metadata for one engine directory."""
    for fname, fkey in _FILE_KEYS.items():
        full = os.path.join(engine_path, fname)
        if os.path.isfile(full):
            rel = os.path.relpath(full, start=_HERE)
            _upsert_schema_file(cur, engine_id, fkey, rel)

    if not sql_text:
        return

    parsed = parse_schema_file(sql_text)

    for enum in parsed["enums"]:
        _upsert_enum(cur, engine_id, enum["name"], enum["values"])

    table_id_map: dict[str, int] = {}
    for tname, tdata in parsed["tables"].items():
        table_id = _upsert_table(cur, engine_id, tname, tdata.get("comment"))
        table_id_map[tname] = table_id

        # Remove stale FKs before re-inserting for idempotency
        cur.execute(
            "DELETE FROM schema_foreign_keys WHERE table_id = %s", (table_id,)
        )

        for pos, col in enumerate(tdata["columns"]):
            _upsert_column(cur, table_id, col, pos)
            if col.get("ref_table"):
                _insert_fk(
                    cur,
                    table_id,
                    [col["name"]],
                    col["ref_table"],
                    [col["ref_col"]],
                    col.get("on_delete"),
                    col.get("on_update"),
                )

        for fk in tdata.get("fks", []):
            _insert_fk(
                cur,
                table_id,
                fk["from_columns"],
                fk["to_table"],
                fk["to_columns"],
                fk.get("on_delete"),
                fk.get("on_update"),
                fk.get("constraint_name"),
            )

    for idx in parsed["indexes"]:
        tname = idx["table_name"]
        if tname not in table_id_map:
            continue
        _upsert_index(cur, table_id_map[tname], idx)


def seed_domain(conn, domain_name: str, domain_path: str) -> None:
    """Seed one domain directory tree into the database."""
    cur = conn.cursor()
    domain_id = _upsert_domain(cur, domain_name, None)

    for engine_name in sorted(os.listdir(domain_path)):
        engine_path = os.path.join(domain_path, engine_name)
        if not os.path.isdir(engine_path):
            continue

        schema_sql_path = os.path.join(engine_path, "schema.sql")
        sql_text: str | None = None
        if os.path.isfile(schema_sql_path):
            with open(schema_sql_path, encoding="utf-8") as fh:
                sql_text = fh.read()

        version_note = _parse_version_note(sql_text) if sql_text else None
        engine_id = _upsert_engine(cur, domain_id, engine_name, version_note)
        _seed_engine_dir(cur, engine_id, engine_path, sql_text)

    conn.commit()
    cur.close()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def run_seed(schemas_dir: str | None = None) -> None:
    if schemas_dir is None:
        # Use same resolution as Flask config: <backend>/schemas
        schemas_dir = os.path.join(_HERE, "schemas")

    if not os.path.isdir(schemas_dir):
        print(f"ERROR: schemas directory not found: {schemas_dir}", file=sys.stderr)
        sys.exit(1)

    conn = get_connection()
    print(f"Connected. Seeding from: {schemas_dir}")

    for domain_name in sorted(os.listdir(schemas_dir)):
        domain_path = os.path.join(schemas_dir, domain_name)
        if not os.path.isdir(domain_path):
            continue
        print(f"  {domain_name} ...", end="", flush=True)
        seed_domain(conn, domain_name, domain_path)
        print(" done")

    conn.close()
    print("Seed complete.")


if __name__ == "__main__":
    run_seed()
