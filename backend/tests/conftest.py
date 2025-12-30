import pytest
import os
from fastapi.testclient import TestClient
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from app import app
from db import init_db

@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """
    Set the TESTING environment variable for the entire test session.
    """
    os.environ["TESTING"] = "1"
    yield
    del os.environ["TESTING"]

@pytest.fixture(scope="function")
def client():
    """
    Pytest fixture to create a new TestClient for each test function.
    Initializes an in-memory SQLite database for test isolation.
    """
    # Initialize a clean database for each test
    init_db()
    
    with TestClient(app) as c:
        yield c