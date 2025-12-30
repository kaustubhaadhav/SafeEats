# SafeEats Backend Implementation Plan

## Overview

This plan outlines the implementation of a minimal FastAPI backend for the SafeEats Flutter app. The backend centralizes ingredient normalization and risk classification logic, reducing client complexity.

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │  Scanner    │───▶│  Product    │───▶│  Product Result     │  │
│  │  Page       │    │  BLoC       │    │  Page               │  │
│  └─────────────┘    └─────────────┘    └─────────────────────┘  │
└───────────────────────────┬─────────────────────────────────────┘
                            │ POST /scan
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     FastAPI Backend                              │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    POST /scan                                ││
│  │  1. Validate barcode (8-14 digits)                          ││
│  │  2. Check SQLite cache (<24h)                               ││
│  │  3. If miss: call Open Food Facts API                       ││
│  │  4. Normalize ingredients via ingredient_map.json           ││
│  │  5. Apply risk rules from rules.py                          ││
│  │  6. Cache result, return response                           ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│              ┌───────────────┼───────────────┐                   │
│              ▼               ▼               ▼                   │
│     ┌──────────────┐  ┌────────────┐  ┌────────────────┐        │
│     │ safeeats.db  │  │ rules.py   │  │ ingredient_    │        │
│     │ (SQLite)     │  │ RISK_RULES │  │ map.json       │        │
│     └──────────────┘  └────────────┘  └────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Open Food Facts API                             │
│                  world.openfoodfacts.org                         │
└─────────────────────────────────────────────────────────────────┘
```

## File Structure

```
backend/
├── app.py              # FastAPI application (~120 lines)
├── db.py               # SQLite cache operations (~60 lines)
├── rules.py            # Risk classification rules (~50 lines)
├── requirements.txt    # Python dependencies
├── safeeats.db         # SQLite database (auto-created)
└── data/
    └── ingredient_map.json  # Ingredient alias mappings
```

## API Contract

### Request: POST /scan

```json
{
  "barcode": "8901234567890"
}
```

### Response: 200 OK

```json
{
  "product_name": "Instant Noodles",
  "ingredients": [
    {
      "raw": "E621",
      "canonical": "monosodium glutamate",
      "risk": "moderate"
    },
    {
      "raw": "salt",
      "canonical": "salt",
      "risk": "low"
    }
  ],
  "overall_risk": "moderate",
  "cached": true
}
```

### Error Responses

| Status | Condition | Response |
|--------|-----------|----------|
| 400 | Invalid barcode format | `{"detail": "Invalid barcode: must be 8-14 digits"}` |
| 404 | Product not found | `{"detail": "Product not found in Open Food Facts"}` |
| 422 | No ingredients | `{"detail": "Product has no ingredient information"}` |
| 502 | External API failure | `{"detail": "Failed to fetch from Open Food Facts"}` |

## Implementation Details

### 1. Barcode Validation (app.py)

```python
def validate_barcode(barcode: str) -> bool:
    """Validates barcode is numeric, length 8-14"""
    return barcode.isdigit() and 8 <= len(barcode) <= 14
```

### 2. SQLite Schema (db.py)

```sql
CREATE TABLE IF NOT EXISTS scan_cache (
    barcode TEXT PRIMARY KEY,
    response_json TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
```

Cache operations:
- `get_cached_scan(barcode)` - Returns cached response if <24h old
- `cache_scan(barcode, response)` - Stores scan result
- `init_db()` - Creates table if not exists

### 3. Ingredient Normalization

Process:
1. Lowercase the raw ingredient
2. Trim whitespace
3. Look up in `ingredient_map.json`
4. If found, use canonical name; otherwise, use normalized raw

Example `ingredient_map.json`:
```json
{
  "e621": "monosodium glutamate",
  "msg": "monosodium glutamate",
  "e951": "aspartame",
  "e950": "acesulfame potassium",
  "e211": "sodium benzoate",
  "red 40": "allura red",
  "red #40": "allura red",
  "fd&c red no. 40": "allura red"
}
```

### 4. Risk Classification (rules.py)

Deterministic risk levels mapped from Flutter's `RiskLevel` enum:
- `"low"` - Minor concerns (RiskLevel.low = 1)
- `"moderate"` - Possible concerns (RiskLevel.medium = 2)  
- `"high"` - Probable carcinogen (RiskLevel.high = 3)
- `"critical"` - Known carcinogen (RiskLevel.critical = 4)

Example rules:
```python
RISK_RULES = {
    # High risk - IARC Group 1/2A equivalent
    "aspartame": "high",
    "acesulfame potassium": "moderate",
    "sodium nitrite": "high",
    "sodium nitrate": "moderate",
    
    # Moderate risk - IARC Group 2B equivalent
    "monosodium glutamate": "moderate",
    "sodium benzoate": "moderate",
    "caramel color": "moderate",
    
    # Low risk - some concern
    "allura red": "low",
    "tartrazine": "low",
}

DEFAULT_RISK = "low"
```

Overall risk = highest individual ingredient risk.

### 5. Open Food Facts Integration

Endpoint: `https://world.openfoodfacts.org/api/v2/product/{barcode}.json`

Extract from response:
- `product.product_name` or `product.product_name_en`
- `product.ingredients_text` or `product.ingredients_text_en`

### 6. Caching Strategy

- Cache key: barcode
- Cache value: full JSON response
- TTL: 24 hours (checked via `updated_at`)
- Cache stores **final decisions**, not raw API responses

## Dependencies (requirements.txt)

```
fastapi==0.109.0
uvicorn==0.27.0
httpx==0.26.0
pydantic==2.5.3
```

## Running Locally

```bash
cd backend
pip install -r requirements.txt
uvicorn app:app --reload --port 8000
```

Test with:
```bash
curl -X POST http://localhost:8000/scan \
  -H "Content-Type: application/json" \
  -d '{"barcode": "3017620422003"}'
```

## Flutter Integration (Optional)

To integrate with Flutter, update `ProductRemoteDataSource` to call the backend instead of Open Food Facts directly:

```dart
// Current: Direct Open Food Facts call
final response = await apiClient.get('/product/$barcode', ...);

// New: Call local backend
final response = await dio.post(
  'http://localhost:8000/scan',
  data: {'barcode': barcode},
);
```

## Constraints Checklist

- [x] FastAPI (Python)
- [x] SQLite local file database
- [x] No authentication
- [x] No user models
- [x] No cloud services
- [x] No microservices
- [x] No ML/probabilistic logic
- [x] No background jobs
- [x] No external database (Postgres, MongoDB)
- [x] Single endpoint (POST /scan)
- [x] Under ~300 lines total

## Line Count Estimate

| File | Estimated Lines |
|------|-----------------|
| app.py | ~120 |
| db.py | ~60 |
| rules.py | ~50 |
| ingredient_map.json | ~40 |
| requirements.txt | ~5 |
| **Total** | **~275 lines** |