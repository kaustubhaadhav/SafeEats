"""
SafeEats Backend API - Minimal FastAPI server for ingredient risk analysis.

Run with: uvicorn app:app --reload
"""

import json
import re
from pathlib import Path
from typing import Optional

import httpx
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from db import init_db, get_cached_scan, cache_scan
from rules import get_risk_with_source, get_overall_risk, get_rules_metadata, RULES_VERSION

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialize the database on startup
    init_db()
    yield
    # Clean up resources on shutdown if needed

# Initialize FastAPI app
app = FastAPI(
    title="SafeEats API",
    version="1.0.0",
    description="Ingredient risk analysis API for the SafeEats mobile app",
    lifespan=lifespan,
)

# Load ingredient map at module level (for both app and tests)
INGREDIENT_MAP_PATH = Path(__file__).parent / "data" / "ingredient_map.json"
INGREDIENT_MAP: dict[str, str] = {}

# Load immediately so it's available for tests and startup
if INGREDIENT_MAP_PATH.exists():
    with open(INGREDIENT_MAP_PATH, "r") as f:
        INGREDIENT_MAP.update(json.load(f))

OPEN_FOOD_FACTS_URL = "https://world.openfoodfacts.org/api/v2/product/{barcode}.json"


class ScanRequest(BaseModel):
    barcode: str


class IngredientResult(BaseModel):
    raw: str
    canonical: str
    risk: str
    source: Optional[str] = None
    notes: Optional[str] = None


class ScanResponse(BaseModel):
    product_name: str
    ingredients: list[IngredientResult]
    overall_risk: str
    cached: bool
    rules_version: str




def validate_barcode(barcode: str) -> bool:
    """Validates barcode is numeric and 8-14 digits."""
    return bool(re.match(r"^\d{8,14}$", barcode))


def normalize_ingredient(raw: str) -> str:
    """Normalizes and maps ingredient to canonical name."""
    normalized = raw.lower().strip()
    return INGREDIENT_MAP.get(normalized, normalized)


def parse_ingredients(ingredients_text: Optional[str]) -> list[str]:
    """Parses ingredient text into individual ingredients."""
    if not ingredients_text:
        return []
    
    # Clean and split by common delimiters
    cleaned = ingredients_text.lower()
    cleaned = re.sub(r"\([^)]*\)", " ", cleaned)  # Remove parenthetical info
    cleaned = re.sub(r"\[[^\]]*\]", " ", cleaned)  # Remove bracketed info
    cleaned = re.sub(r"\d+\.?\d*\s*%", "", cleaned)  # Remove percentages
    
    # Split by comma, semicolon, or period
    parts = re.split(r"[,;.]", cleaned)
    
    # Clean and filter
    ingredients = []
    for part in parts:
        ingredient = part.strip()
        if ingredient and len(ingredient) > 1:
            ingredients.append(ingredient)
    
    return list(set(ingredients))  # Remove duplicates


async def fetch_product(barcode: str) -> dict:
    """Fetches product from Open Food Facts API."""
    async with httpx.AsyncClient(timeout=10.0) as client:
        try:
            response = await client.get(OPEN_FOOD_FACTS_URL.format(barcode=barcode))
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            raise HTTPException(status_code=502, detail=f"Failed to fetch from Open Food Facts: {e}")


@app.post("/scan", response_model=ScanResponse)
async def scan(request: ScanRequest) -> ScanResponse:
    """
    Scan a product barcode and return risk analysis.
    
    - Validates barcode format (8-14 numeric digits)
    - Returns cached result if available (<24h)
    - Fetches from Open Food Facts if not cached
    - Normalizes ingredients and applies risk rules
    """
    barcode = request.barcode.strip()
    
    # 1. Validate barcode
    if not validate_barcode(barcode):
        raise HTTPException(status_code=400, detail="Invalid barcode: must be 8-14 digits")
    
    # 2. Check cache
    cached = get_cached_scan(barcode)
    if cached:
        cached["cached"] = True
        # Ensure rules_version is present (for backward compatibility with old cache entries)
        if "rules_version" not in cached:
            cached["rules_version"] = RULES_VERSION
        return ScanResponse(**cached)
    
    # 3. Fetch from Open Food Facts
    data = await fetch_product(barcode)
    
    if data.get("status") != 1 or not data.get("product"):
        raise HTTPException(status_code=404, detail="Product not found in Open Food Facts")
    
    product = data["product"]
    
    # 4. Extract product name and ingredients
    product_name = (
        product.get("product_name") or
        product.get("product_name_en") or
        "Unknown Product"
    )
    
    ingredients_text = (
        product.get("ingredients_text") or
        product.get("ingredients_text_en")
    )
    
    if not ingredients_text:
        raise HTTPException(status_code=422, detail="Product has no ingredient information")
    
    # 5. Parse and normalize ingredients
    raw_ingredients = parse_ingredients(ingredients_text)
    
    if not raw_ingredients:
        raise HTTPException(status_code=422, detail="Could not parse ingredients from product")
    
    # 6. Apply risk rules
    ingredient_results = []
    risks = []
    
    for raw in raw_ingredients:
        canonical = normalize_ingredient(raw)
        risk, source, notes = get_risk_with_source(canonical)
        risks.append(risk)
        ingredient_results.append(IngredientResult(
            raw=raw,
            canonical=canonical,
            risk=risk,
            source=source if risk != "safe" else None,
            notes=notes if risk != "safe" else None
        ))
    
    overall_risk = get_overall_risk(risks)
    
    # 7. Build response
    response_data = {
        "product_name": product_name,
        "ingredients": [i.model_dump() for i in ingredient_results],
        "overall_risk": overall_risk,
        "cached": False,
        "rules_version": RULES_VERSION
    }
    
    # 8. Cache the result
    cache_scan(barcode, response_data)
    
    return ScanResponse(**response_data)


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "ok", "rules_version": RULES_VERSION}


@app.get("/rules/metadata")
def rules_metadata():
    """Returns metadata about the risk classification rules."""
    return get_rules_metadata()