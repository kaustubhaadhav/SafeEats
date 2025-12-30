"""
SQLite cache operations for scan results.
"""

import json
import sqlite3
import os
import tempfile
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

# Database file path (same directory as this module)
DB_PATH = Path(__file__).parent / "safeeats.db"

# Cache validity duration
CACHE_TTL_HOURS = 24

# Test database path (temporary file for cross-thread access)
_test_db_path: Optional[str] = None


def get_connection() -> sqlite3.Connection:
    """
    Returns a database connection with row factory.
    Uses a file-based test database if the TESTING environment variable is set.
    """
    global _test_db_path
    
    if os.environ.get("TESTING") == "1":
        # Use a file-based database for tests to allow cross-thread access
        if _test_db_path is None:
            # Create a temporary database file
            fd, _test_db_path = tempfile.mkstemp(suffix=".db")
            os.close(fd)
        conn = sqlite3.connect(_test_db_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        return conn
    else:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        return conn


def init_db() -> None:
    """Creates the scan_cache table if it doesn't exist."""
    global _test_db_path
    
    # Reset test database for each test
    if os.environ.get("TESTING") == "1":
        if _test_db_path is not None:
            try:
                os.remove(_test_db_path)
            except OSError:
                pass
            _test_db_path = None
    
    conn = get_connection()
    try:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS scan_cache (
                barcode TEXT PRIMARY KEY,
                response_json TEXT NOT NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
    finally:
        conn.close()


def get_cached_scan(barcode: str) -> Optional[dict]:
    """
    Returns cached response if exists and is less than 24 hours old.
    Returns None if not cached or expired.
    """
    conn = get_connection()
    try:
        cursor = conn.execute(
            "SELECT response_json, updated_at FROM scan_cache WHERE barcode = ?",
            (barcode,)
        )
        row = cursor.fetchone()
        
        if row is None:
            return None
        
        # Check if cache is still valid
        updated_at = datetime.fromisoformat(row["updated_at"])
        if datetime.now() - updated_at > timedelta(hours=CACHE_TTL_HOURS):
            return None
        
        return json.loads(row["response_json"])
    finally:
        conn.close()


def cache_scan(barcode: str, response: dict) -> None:
    """Stores or updates a scan result in the cache."""
    conn = get_connection()
    try:
        conn.execute(
            """
            INSERT INTO scan_cache (barcode, response_json, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(barcode) DO UPDATE SET
                response_json = excluded.response_json,
                updated_at = excluded.updated_at
            """,
            (barcode, json.dumps(response), datetime.now().isoformat())
        )
        conn.commit()
    finally:
        conn.close()