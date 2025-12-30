"""
Tests for the FastAPI application endpoints.

Tests cover:
1. /scan endpoint validation and error handling
2. /health endpoint
3. /rules/metadata endpoint
4. Ingredient normalization
"""

import pytest
import sys
from pathlib import Path
from unittest.mock import patch, AsyncMock

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from fastapi.testclient import TestClient
from app import app, validate_barcode, normalize_ingredient, parse_ingredients


class TestBarcodeValidation:
    """Tests for barcode validation logic."""
    
    def test_valid_ean13_barcode(self):
        """13-digit EAN barcode should be valid."""
        assert validate_barcode("3017620422003") is True
    
    def test_valid_upc_barcode(self):
        """12-digit UPC barcode should be valid."""
        assert validate_barcode("012345678905") is True
    
    def test_valid_ean8_barcode(self):
        """8-digit EAN barcode should be valid."""
        assert validate_barcode("12345678") is True
    
    def test_too_short_barcode(self):
        """Barcode with less than 8 digits should be invalid."""
        assert validate_barcode("1234567") is False
    
    def test_too_long_barcode(self):
        """Barcode with more than 14 digits should be invalid."""
        assert validate_barcode("123456789012345") is False
    
    def test_non_numeric_barcode(self):
        """Non-numeric barcode should be invalid."""
        assert validate_barcode("abc12345678") is False
        assert validate_barcode("12345-67890") is False
    
    def test_empty_barcode(self):
        """Empty barcode should be invalid."""
        assert validate_barcode("") is False


class TestIngredientNormalization:
    """Tests for ingredient normalization logic."""
    
    def test_e_number_normalization(self):
        """E-numbers should normalize to canonical names."""
        assert normalize_ingredient("e621") == "monosodium glutamate"
        assert normalize_ingredient("E621") == "monosodium glutamate"
        assert normalize_ingredient("e951") == "aspartame"
    
    def test_alias_normalization(self):
        """Common aliases should normalize to canonical names."""
        assert normalize_ingredient("msg") == "monosodium glutamate"
        assert normalize_ingredient("bha") == "butylated hydroxyanisole"
        assert normalize_ingredient("bht") == "butylated hydroxytoluene"
    
    def test_unknown_ingredient_passthrough(self):
        """Unknown ingredients should pass through normalized (lowercase, trimmed)."""
        assert normalize_ingredient("sugar") == "sugar"
        assert normalize_ingredient("  WATER  ") == "water"
    
    def test_preserves_canonical_names(self):
        """Already-canonical names should remain unchanged."""
        assert normalize_ingredient("aspartame") == "aspartame"
        assert normalize_ingredient("sodium benzoate") == "sodium benzoate"


class TestIngredientParsing:
    """Tests for ingredient text parsing."""
    
    def test_comma_separated(self):
        """Should parse comma-separated ingredients."""
        result = parse_ingredients("water, sugar, salt")
        assert "water" in result
        assert "sugar" in result
        assert "salt" in result
    
    def test_semicolon_separated(self):
        """Should parse semicolon-separated ingredients."""
        result = parse_ingredients("water; sugar; salt")
        assert len(result) >= 3
    
    def test_removes_parenthetical_info(self):
        """Should remove parenthetical information."""
        result = parse_ingredients("sugar (from beets), salt (sea salt)")
        assert not any("beets" in i for i in result)
        assert not any("sea" in i for i in result)
    
    def test_removes_percentages(self):
        """Should remove percentage values."""
        result = parse_ingredients("water 50%, sugar 30%")
        assert not any("50" in i for i in result)
        assert not any("30" in i for i in result)
    
    def test_empty_string(self):
        """Empty string should return empty list."""
        assert parse_ingredients("") == []
        assert parse_ingredients(None) == []
    
    def test_deduplicates(self):
        """Should remove duplicate ingredients."""
        result = parse_ingredients("sugar, water, sugar, salt, water")
        sugar_count = sum(1 for i in result if i == "sugar")
        assert sugar_count == 1


class TestScanEndpoint:
    """Tests for the /scan endpoint."""
    
    def test_invalid_barcode_returns_400(self, client):
        """Invalid barcode format should return 400."""
        response = client.post("/scan", json={"barcode": "abc"})
        assert response.status_code == 400
        assert "Invalid barcode" in response.json()["detail"]
    
    def test_short_barcode_returns_400(self, client):
        """Too-short barcode should return 400."""
        response = client.post("/scan", json={"barcode": "123"})
        assert response.status_code == 400
    
    def test_missing_barcode_returns_422(self, client):
        """Missing barcode field should return 422 (validation error)."""
        response = client.post("/scan", json={})
        assert response.status_code == 422
    
    def test_product_not_found_returns_404(self, client, httpx_mock):
        """Product not in Open Food Facts should return 404."""
        httpx_mock.add_response(
            url="https://world.openfoodfacts.org/api/v2/product/1234567890128.json",
            json={"status": 0, "product": None},
            status_code=200  # The API itself returns 200 even for not found
        )
        
        response = client.post("/scan", json={"barcode": "1234567890128"})
        assert response.status_code == 404
        assert "Product not found" in response.json()["detail"]

    def test_open_food_facts_api_error_returns_502(self, client, httpx_mock):
        """A 500 error from Open Food Facts should return 502."""
        httpx_mock.add_response(
            url="https://world.openfoodfacts.org/api/v2/product/1234567890128.json",
            status_code=500
        )
        
        response = client.post("/scan", json={"barcode": "1234567890128"})
        assert response.status_code == 502
        assert "Failed to fetch" in response.json()["detail"]


class TestHealthEndpoint:
    """Tests for the /health endpoint."""
    
    def test_health_returns_ok(self, client):
        """Health endpoint should return ok status."""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"
    
    def test_health_includes_rules_version(self, client):
        """Health endpoint should include rules version."""
        response = client.get("/health")
        assert "rules_version" in response.json()


class TestRulesMetadataEndpoint:
    """Tests for the /rules/metadata endpoint."""
    
    def test_metadata_returns_200(self, client):
        """Metadata endpoint should return 200."""
        response = client.get("/rules/metadata")
        assert response.status_code == 200
    
    def test_metadata_contains_version(self, client):
        """Metadata should contain version."""
        response = client.get("/rules/metadata")
        data = response.json()
        assert "version" in data
    
    def test_metadata_contains_sources(self, client):
        """Metadata should contain sources."""
        response = client.get("/rules/metadata")
        data = response.json()
        assert "sources" in data
        assert isinstance(data["sources"], list)
    
    def test_metadata_contains_conflict_resolution(self, client):
        """Metadata should explain conflict resolution."""
        response = client.get("/rules/metadata")
        data = response.json()
        assert "conflict_resolution" in data
    
    def test_metadata_contains_disclaimer(self, client):
        """Metadata should contain disclaimer."""
        response = client.get("/rules/metadata")
        data = response.json()
        assert "disclaimer" in data


class TestScanResponseFormat:
    """Tests for scan response format (using mocked data)."""
    
    def test_successful_scan_response_format(self, client, httpx_mock):
        """A successful scan should return the correct response format."""
        httpx_mock.add_response(
            url="https://world.openfoodfacts.org/api/v2/product/1234567890128.json",
            json={
                "status": 1,
                "product": {
                    "product_name": "Test Product",
                    "ingredients_text": "water, sugar, aspartame"
                }
            }
        )
        
        response = client.post("/scan", json={"barcode": "1234567890128"})
        assert response.status_code == 200
        data = response.json()
        
        assert data["product_name"] == "Test Product"
        assert data["overall_risk"] == "moderate"
        assert data["cached"] is False
        assert "rules_version" in data
        assert len(data["ingredients"]) == 3
        
        aspartame_result = next(i for i in data["ingredients"] if i["raw"] == "aspartame")
        assert aspartame_result["risk"] == "moderate"
        assert aspartame_result["source"] == "IARC_GROUP_2B"