# SafeEats Backend

A minimal FastAPI backend for ingredient risk analysis. This backend centralizes ingredient normalization and deterministic risk classification logic for the SafeEats Flutter app.

## Features

- **Single `/scan` Endpoint**: Barcode scanning and risk analysis
- **Versioned Risk Rules**: Tracked with semantic versioning
- **SQLite Caching**: 24-hour cache for final decisions
- **Ingredient Normalization**: Maps E-numbers and aliases to canonical names
- **Deterministic Risk Rules**: No ML, purely rule-based classification
- **Source Transparency**: Each risk decision includes source attribution

## Project Structure

```
backend/
├── app.py              # FastAPI application
├── db.py               # SQLite cache operations
├── rules.py            # Versioned risk classification rules
├── requirements.txt    # Python dependencies
├── safeeats.db         # SQLite database (auto-created)
├── README.md           # This file
├── data/
│   └── ingredient_map.json  # Ingredient alias mappings
└── tests/
    ├── __init__.py
    ├── test_rules.py   # Risk classification tests
    └── test_app.py     # API endpoint tests
```

## Quick Start

### Prerequisites

- Python 3.10+
- pip

### Installation

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Run the Server

```bash
uvicorn app:app --reload --port 8000
```

The API will be available at `http://localhost:8000`

### Run Tests

```bash
pytest tests/ -v
```

## API Reference

### POST /scan

Scan a barcode and get ingredient risk analysis.

**Request:**
```json
{
  "barcode": "3017620422003"
}
```

**Response (200 OK):**
```json
{
  "product_name": "Nutella",
  "ingredients": [
    {
      "raw": "sugar",
      "canonical": "sugar",
      "risk": "safe",
      "source": null,
      "notes": null
    },
    {
      "raw": "soy lecithin",
      "canonical": "lecithin",
      "risk": "low",
      "source": "NONE",
      "notes": "Emulsifier (E322). Natural compound from soy, sunflower, or eggs."
    }
  ],
  "overall_risk": "low",
  "cached": false,
  "rules_version": "1.0.0"
}
```

**Error Responses:**

| Status | Condition | Response |
|--------|-----------|----------|
| 400 | Invalid barcode format | `{"detail": "Invalid barcode: must be 8-14 digits"}` |
| 404 | Product not found | `{"detail": "Product not found in Open Food Facts"}` |
| 422 | No ingredients | `{"detail": "Product has no ingredient information"}` |
| 502 | External API failure | `{"detail": "Failed to fetch from Open Food Facts: ..."}` |

### GET /health

Health check endpoint with rules version.

**Response:**
```json
{
  "status": "ok",
  "rules_version": "1.0.0"
}
```

### GET /rules/metadata

Returns metadata about the risk classification rules.

**Response:**
```json
{
  "version": "1.0.0",
  "last_updated": "2024-12-24",
  "sources": [
    "IARC Monographs on the Identification of Carcinogenic Hazards to Humans",
    "California Proposition 65 (Safe Drinking Water and Toxic Enforcement Act)"
  ],
  "conflict_resolution": "IARC classifications take precedence over Prop 65...",
  "disclaimer": "This classification system is for informational purposes only..."
}
```

## Risk Levels

Risk levels are aligned with the Flutter app's `RiskLevel` enum:

| Level | Description | Example |
|-------|-------------|---------|
| `safe` | No known concerns | Water, salt |
| `low` | Minor concerns, limited evidence | Food dyes (IARC Group 3) |
| `moderate` | Possible carcinogen (IARC Group 2B) | Aspartame |
| `high` | Probable carcinogen (IARC Group 2A) | Acrylamide |
| `critical` | Known carcinogen (IARC Group 1) | Processed meat |

## Source Attribution

Each risk classification includes its source:

| Source | Description |
|--------|-------------|
| `IARC_GROUP_1` | Known carcinogen to humans |
| `IARC_GROUP_2A` | Probably carcinogenic |
| `IARC_GROUP_2B` | Possibly carcinogenic |
| `IARC_GROUP_3` | Not classifiable |
| `PROP65_CARCINOGEN` | California Prop 65 carcinogen list |
| `PROP65_REPRODUCTIVE` | California Prop 65 reproductive toxicant |
| `NONE` | No classification in database |

## Configuration

### Ingredient Map

Edit `data/ingredient_map.json` to add ingredient aliases:

```json
{
  "e621": "monosodium glutamate",
  "msg": "monosodium glutamate"
}
```

### Risk Rules

Edit `rules.py` to modify risk classifications:

```python
RISK_RULES = {
    "aspartame": {
        "risk": "moderate",
        "source": "IARC_GROUP_2B",
        "iarc_group": "Group 2B",
        "notes": "Artificial sweetener (E951). Classified as possibly carcinogenic in July 2023."
    },
    # ... more rules
}
```

### Cache TTL

Edit `db.py` to change cache duration:

```python
CACHE_TTL_HOURS = 24  # Change this value
```

## Interactive API Docs

FastAPI provides auto-generated documentation:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Test with curl

```bash
# Scan a product (Nutella)
curl -X POST http://localhost:8000/scan \
  -H "Content-Type: application/json" \
  -d '{"barcode": "3017620422003"}'

# Health check
curl http://localhost:8000/health

# Rules metadata
curl http://localhost:8000/rules/metadata
```

## Flutter Integration

To integrate with the Flutter app, update the data source to call this backend:

```dart
// In lib/features/product/data/datasources/product_remote_datasource.dart

@override
Future<ProductModel> getProductByBarcode(String barcode) async {
  final response = await dio.post(
    'http://localhost:8000/scan',
    data: {'barcode': barcode},
  );
  
  if (response.statusCode == 200) {
    return ProductModel.fromBackendResponse(response.data);
  }
  // Handle errors...
}
```

## Design Constraints

This backend follows these constraints:

- ✅ FastAPI (Python)
- ✅ SQLite local file database
- ✅ No authentication
- ✅ No user models
- ✅ No cloud services
- ✅ No microservices
- ✅ No ML/probabilistic logic
- ✅ No background jobs
- ✅ No external database (Postgres, MongoDB)
- ✅ Versioned risk rules
- ✅ Source attribution for transparency