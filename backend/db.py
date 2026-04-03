"""db.py — psycopg2 connection helper for the TBDSP Flask backend.

Reads connection parameters from the existing Sequelize config/config.json
so there is a single source of truth for DB credentials.
"""

import json
import os

import psycopg2
import psycopg2.extras

_HERE = os.path.dirname(os.path.abspath(__file__))
_CONFIG_JSON = os.path.join(_HERE, "config", "config.json")


def _db_params(env: str = "development") -> dict:
    with open(_CONFIG_JSON, encoding="utf-8") as fh:
        all_cfg = json.load(fh)
    cfg = all_cfg.get(env) or all_cfg.get("development")
    return {
        "dbname": cfg["database"],
        "user": cfg["username"],
        "password": cfg["password"],
        "host": cfg.get("host", "127.0.0.1"),
        "port": int(cfg.get("port", 5432)),
    }


def get_connection(env: str | None = None) -> psycopg2.extensions.connection:
    """Return a new psycopg2 connection using config/config.json."""
    if env is None:
        env = os.environ.get("APP_ENV", "development")
        if env == "default":
            env = "development"
    return psycopg2.connect(**_db_params(env))


def dict_cursor(conn) -> psycopg2.extras.RealDictCursor:
    """Return a DictCursor on *conn* that yields rows as dicts."""
    return conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
