"""
==============================================
HR Analytics - PostgreSQL Ingestion using COPY
==============================================
"""

import os
import sys
import time
from pathlib import Path

from dotenv import load_dotenv
import psycopg2

load_dotenv()

# ── Paths ──────────────────────────────────────────────────────
BASE_DIR   = Path(__file__).resolve().parent.parent
CSV_PATH   = BASE_DIR / 'data' / 'raw' / 'hr_raw.csv'
SCHEMA     = 'raw'
TABLE      = 'hr_employees_raw'

# ── DB connection ──────────────────────────────────────────────
DATABASE_URL = os.environ.get('DATABASE_URL')
if not DATABASE_URL:
    msg = 'DATABASE_URL not set. Create a .env file or export it.'
    sys.exit(msg)


def count_csv_lines(path: Path) -> int:
    """Return number of data rows in a CSV file (excludes header)."""
    with open(path, 'r', encoding='utf-8') as f:
        return sum(1 for _ in f) - 1


def main() -> None:
    # ── Pre-flight checks ─────────────────────────────────────
    if not CSV_PATH.is_file():
        sys.exit(f'File not found: {CSV_PATH}')

    total_rows = count_csv_lines(CSV_PATH)
    start = time.time()

    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = False
        cur = conn.cursor()

        # Ensure table exists
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_schema = %s AND table_name = %s
            )
        """, (SCHEMA, TABLE))
        if not cur.fetchone()[0]:
            conn.rollback()
            sys.exit(
                f'Table {SCHEMA}.{TABLE} does not exist.\n'
                f'Run sql/01_schema.sql first:\n'
                f'  psql "$DATABASE_URL" -f sql/01_schema.sql'
            )

        # Truncate for idempotent re-runs
        cur.execute(f'TRUNCATE TABLE {SCHEMA}.{TABLE}')

        # ── COPY CSV directly into PostgreSQL ──────────────────
        with open(CSV_PATH, 'r', encoding='utf-8') as f:
            cur.copy_expert(
                f'COPY {SCHEMA}.{TABLE} FROM STDIN WITH CSV HEADER',
                f,
            )

        conn.commit()
        elapsed = time.time() - start

        # Verify row count
        cur.execute(f'SELECT COUNT(*) FROM {SCHEMA}.{TABLE}')
        db_count = cur.fetchone()[0]

        if db_count != total_rows:
            conn.rollback()
            sys.exit(
                f'Row count mismatch: CSV={total_rows:,}, DB={db_count:,}\n'
                f'Check CSV file integrity and table schema.'
            )

        cur.close()
        conn.close()

        print(f'Loaded {total_rows:,} rows into {SCHEMA}.{TABLE}')
        print(f'Duration: {elapsed:.1f}s  ({total_rows/elapsed/1000:.0f}k rows/s)')

    except psycopg2.Error as e:
        print(f'Database error: {e}', file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f'Unexpected error: {e}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
