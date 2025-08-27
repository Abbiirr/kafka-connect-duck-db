"""
DuckDB helpers & tiny query utils.

- get_conn(read_only=True) -> duckdb.DuckDBPyConnection
- qv(sql, params=()) -> list[str]    : one-column list (for field_value)
- q1(sql, params=()) -> tuple|None   : existence checks, scalar fetches
"""
import os, duckdb

DB_PATH = os.getenv("DUCKDB_PATH", "identifier.db")

def get_conn(read_only=True):
    con = duckdb.connect(DB_PATH, read_only=read_only)
    try:
        con.execute("LOAD httpfs;")  # required if reading S3/MinIO
    except Exception:
        pass
    return con

def qv(sql: str, params=()) -> list[str]:
    with get_conn() as con:
        return [str(r[0]) for r in con.execute(sql, params).fetchall()]

def q1(sql: str, params=()):
    with get_conn() as con:
        return con.execute(sql, params).fetchone()
