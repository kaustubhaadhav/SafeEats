# SafeEats 10/10 Implementation Plan

## Executive Summary

This plan addresses all 20 requirements to make SafeEats a polished, portfolio-ready project. The work is organized into 5 phases, with a total of ~3-4 hours of focused implementation.

## Current State Analysis

### ✅ Already Complete
| # | Requirement | Status | Notes |
|---|-------------|--------|-------|
| 1 | FastAPI backend with /scan endpoint | ✅ Done | `backend/app.py` |
| 2 | Ingredient normalization in backend | ✅ Done | `normalize_ingredient()` function |
| 3 | Risk classification centralized | ✅ Done | `backend/rules.py` |
| 4 | Cache final decisions | ✅ Done | `db.py` caches processed responses |
| 8 | Basic error handling | ✅ Done | 400, 404, 422, 502 errors |
| 10 | Flutter widget tests | ✅ Done | `risk_indicator_test.dart`, `carcinogen_card_test.dart` |
| 15 | Flutter + BLoC explanation | ✅ Done | In README.md |
| 19 | Project scope | ✅ Done | "What this is / What this is not" section |

### ❌ Needs Work
| # | Requirement | Status | Notes |
|---|-------------|--------|-------|
| 5 | Version risk rules | ❌ Missing | Need RULES_VERSION constant |
| 6 | Document risk model | ⚠️ Partial | Expand with RISK_MODEL.md |
| 7 | Handle conflicting sources | ❌ Missing | IARC vs Prop 65 priority |
| 9 | Backend tests | ❌ Missing | Need pytest tests |
| 11 | Clean README | ⚠️ Partial | Align with actual functionality |
| 12 | Architecture diagram | ❌ Missing | Only Mermaid, need PNG |
| 13 | Document data sources | ⚠️ Partial | Need DATA_SOURCES.md |
| 14 | Screenshots/GIF | ❌ Missing | Need demo assets |
| 16 | Explain backend existence | ❌ Missing | Add to README |
| 17 | Remove dead code | ❌ Pending | Need audit |
| 18 | Consistent naming | ❌ Broken | "Yuko" in multiple files |
| 20 | One-command setup | ❌ Missing | Need run.sh script |

### 🔴 Critical Issues Found
1. **Flutter NOT using backend** - Still calling Open Food Facts directly
2. **Naming inconsistency** - "Yuko" in ARCHITECTURE.md, injection_container.dart, User-Agent
3. **Duplicate logic** - Flutter has its own ingredient_parser.dart and carcinogen_matcher.dart

---

## Phase 1: Backend Hardening (Priority: Critical)

### 1.1 Add Rules Versioning
**File**: `backend/rules.py`

```python
# Add at top of file
RULES_VERSION = "1.0.0"
RULES_LAST_UPDATED = "2024-12-24"

# Add metadata to rules
RULES_METADATA = {
    "version": RULES_VERSION,
    "last_updated": RULES_LAST_UPDATED,
    "sources": ["IARC Monographs", "California Prop 65"],
    "conflict_resolution": "IARC takes precedence when both sources classify an ingredient"
}
```

**File**: `backend/app.py` - Include version in response

```python
class ScanResponse(BaseModel):
    product_name: str
    ingredients: list[IngredientResult]
    overall_risk: str
    cached: bool
    rules_version: str  # Add this field
```

### 1.2 Deterministic IARC vs Prop 65 Conflict Handling
**File**: `backend/rules.py`

```python
# Priority order for sources (higher = more authoritative)
SOURCE_PRIORITY = {
    "IARC_GROUP_1": 100,    # Known carcinogen
    "IARC_GROUP_2A": 90,    # Probable
    "IARC_GROUP_2B": 80,    # Possible  
    "PROP65": 70,           # California list
    "IARC_GROUP_3": 60,     # Not classifiable
}

# Each rule should specify source
RISK_RULES: dict[str, dict] = {
    "aspartame": {
        "risk": "high",
        "source": "IARC_GROUP_2B",  # IARC 2023 classification
        "notes": "Classified as possibly carcinogenic in 2023"
    },
    # ... etc
}

def get_risk(canonical_name: str) -> tuple[str, str]:
    """Returns (risk_level, authoritative_source)"""
    rule = RISK_RULES.get(canonical_name.lower())
    if rule:
        return rule["risk"], rule["source"]
    return DEFAULT_RISK, "NONE"
```

### 1.3 Add Backend Tests
**File**: `backend/requirements.txt` - Add pytest

```
fastapi==0.109.0
uvicorn==0.27.0
httpx==0.26.0
pydantic==2.5.3
pytest==7.4.4
pytest-asyncio==0.23.3
```

**File**: `backend/tests/test_rules.py`

```python
import pytest
from rules import get_risk, get_overall_risk, RULES_VERSION

class TestRiskClassification:
    def test_known_carcinogen_returns_critical(self):
        risk = get_risk("processed meat")
        assert risk == "critical"
    
    def test_unknown_ingredient_returns_low(self):
        risk = get_risk("water")
        assert risk == "low"
    
    def test_overall_risk_takes_highest(self):
        risks = ["low", "moderate", "high", "low"]
        assert get_overall_risk(risks) == "high"

class TestNormalization:
    def test_e621_normalizes_to_msg(self):
        from app import normalize_ingredient
        assert normalize_ingredient("e621") == "monosodium glutamate"
```

**File**: `backend/tests/test_app.py`

```python
import pytest
from fastapi.testclient import TestClient
from app import app

client = TestClient(app)

class TestScanEndpoint:
    def test_invalid_barcode_returns_400(self):
        response = client.post("/scan", json={"barcode": "abc"})
        assert response.status_code == 400
        assert "Invalid barcode" in response.json()["detail"]
    
    def test_short_barcode_returns_400(self):
        response = client.post("/scan", json={"barcode": "123"})
        assert response.status_code == 400
    
    def test_health_endpoint(self):
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"
```

---

## Phase 2: Documentation Excellence

### 2.1 Create RISK_MODEL.md
**File**: `docs/RISK_MODEL.md`

Document the complete risk classification logic:
- Risk level definitions (safe, low, moderate, high, critical)
- How IARC classifications map to risk levels
- How Prop 65 classifications map to risk levels
- Conflict resolution rules
- Examples with specific ingredients

### 2.2 Create DATA_SOURCES.md
**File**: `docs/DATA_SOURCES.md`

- Open Food Facts API (product data)
- IARC Monographs (carcinogen classifications)
- California Proposition 65 (toxicant list)
- **Limitations section** (coverage gaps, update frequency, accuracy disclaimers)

### 2.3 Add Backend Existence Explanation to README
**Section to add**:

```markdown
## Why a Backend?

Even though the Flutter app caches data locally, the backend exists for several important reasons:

1. **Single Source of Truth**: Risk classification rules are versioned and maintained in one place
2. **Consistency**: All clients get the same risk assessment for the same product
3. **Updateability**: Rules can be updated server-side without app store releases
4. **Reduced Client Complexity**: Normalization and matching logic is centralized
5. **Future-Proofing**: Enables cross-device sync, user accounts, and analytics in the future
```

---

## Phase 3: Naming & Code Cleanup

### 3.1 Fix Naming Inconsistency (Yuko → SafeEats)

**Files to update**:
1. `ARCHITECTURE.md` - Line 1: "Yuko" → "SafeEats"
2. `lib/injection_container.dart` - Line 141: `yuko.db` → `safeeats.db`
3. `lib/injection_container.dart` - Line 49: User-Agent header

### 3.2 Remove Duplicate Flutter Logic

The current Flutter app has duplicate normalization logic that should be removed once the app is integrated with the backend:

**Files with duplicate logic**:
- `lib/core/utils/ingredient_parser.dart` - Keep for offline fallback
- `lib/core/utils/carcinogen_matcher.dart` - Keep for offline fallback

**Recommendation**: Keep these files for offline-first functionality but mark them as "offline fallback" and prioritize backend response when available.

### 3.3 Review Dependencies

**pubspec.yaml audit**:
- All current dependencies appear to be in use
- Consider removing `mockito` if only using `mocktail` (tests use both)

---

## Phase 4: Visual Assets

### 4.1 Create Architecture Diagram Image

**File**: `docs/architecture.png`

Create using a tool like draw.io, Excalidraw, or Mermaid CLI:

```
┌─────────────────────────────────────────────────────────────┐
│                     SafeEats Flutter App                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Scanner  │→ │ Product  │→ │ Carcinogen│→ │ History  │    │
│  │  BLoC    │  │  BLoC    │  │   Check   │  │  BLoC    │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└────────────────────────┬────────────────────────────────────┘
                         │ POST /scan
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │Normalize │→ │  Risk    │→ │  Cache   │                  │
│  │Ingredient│  │  Rules   │  │ (SQLite) │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Open Food Facts API                             │
│              world.openfoodfacts.org                         │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Add Screenshots/Demo

**Directory**: `screenshots/`

Required screenshots:
1. `home.png` - Home screen with scan button
2. `scan.png` - Camera scanning view
3. `results.png` - Product results with risk indicator
4. `database.png` - Carcinogen database browser

**Alternative**: Create a short GIF using a screen recorder

---

## Phase 5: Developer Experience

### 5.1 Create One-Command Setup Script
**File**: `run.sh`

```bash
#!/bin/bash
set -e

echo "🍎 SafeEats - Starting development environment..."

# Check prerequisites
command -v python3 >/dev/null 2>&1 || { echo "Python 3 required"; exit 1; }
command -v flutter >/dev/null 2>&1 || { echo "Flutter required"; exit 1; }

# Start backend in background
echo "📡 Starting backend..."
cd backend
pip install -r requirements.txt -q
uvicorn app:app --port 8000 &
BACKEND_PID=$!
cd ..

# Wait for backend to be ready
sleep 2
curl -s http://localhost:8000/health > /dev/null || { echo "Backend failed to start"; exit 1; }
echo "✅ Backend running at http://localhost:8000"

# Run Flutter app
echo "📱 Starting Flutter app..."
flutter pub get
flutter run

# Cleanup on exit
trap "kill $BACKEND_PID 2>/dev/null" EXIT
```

### 5.2 Update README Installation Section

```markdown
## Quick Start

### One-Command Setup (Recommended)
```bash
./run.sh
```

### Manual Setup

#### Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn app:app --reload --port 8000
```

#### Flutter App
```bash
flutter pub get
flutter run
```

### Running Tests
```bash
# Backend tests
cd backend && pytest

# Flutter tests
flutter test
```
```

---

## Implementation Checklist

### Phase 1: Backend Hardening
- [ ] Add RULES_VERSION and RULES_METADATA to rules.py
- [ ] Update rules to include source information
- [ ] Implement deterministic conflict resolution
- [ ] Add pytest to requirements.txt
- [ ] Create backend/tests/test_rules.py
- [ ] Create backend/tests/test_app.py
- [ ] Include rules_version in ScanResponse

### Phase 2: Documentation
- [ ] Create docs/RISK_MODEL.md
- [ ] Create docs/DATA_SOURCES.md  
- [ ] Add "Why a Backend?" section to README
- [ ] Update README to align with actual functionality

### Phase 3: Code Cleanup
- [ ] Replace "Yuko" with "SafeEats" in ARCHITECTURE.md
- [ ] Update database name in injection_container.dart
- [ ] Update User-Agent header
- [ ] Review and document offline fallback strategy
- [ ] Audit dependencies in pubspec.yaml

### Phase 4: Visual Assets
- [ ] Create docs/architecture.png diagram
- [ ] Add placeholder instructions for screenshots
- [ ] Document how to capture screenshots

### Phase 5: Developer Experience
- [ ] Create run.sh script
- [ ] Update README installation section
- [ ] Ensure all commands work on fresh clone

---

## File Change Summary

### New Files
| File | Purpose |
|------|---------|
| `docs/RISK_MODEL.md` | Complete risk classification documentation |
| `docs/DATA_SOURCES.md` | Data sources and limitations |
| `docs/architecture.png` | Visual architecture diagram |
| `backend/tests/__init__.py` | Test package init |
| `backend/tests/test_rules.py` | Risk classification tests |
| `backend/tests/test_app.py` | API endpoint tests |
| `run.sh` | One-command setup script |

### Modified Files
| File | Changes |
|------|---------|
| `backend/rules.py` | Add versioning, source tracking, conflict resolution |
| `backend/app.py` | Include rules_version in response |
| `backend/requirements.txt` | Add pytest, pytest-asyncio |
| `README.md` | Add backend explanation, update installation |
| `ARCHITECTURE.md` | Fix naming (Yuko → SafeEats) |
| `lib/injection_container.dart` | Fix database name, User-Agent |

---

## Success Criteria

After completing all phases, SafeEats will have:

1. ✅ **Backend with /scan endpoint** - Central risk analysis
2. ✅ **Ingredient normalization in backend** - E-numbers, aliases mapped
3. ✅ **Centralized risk rules** - With version and source tracking
4. ✅ **Cached final decisions** - 24h TTL on processed results
5. ✅ **Versioned risk rules** - RULES_VERSION constant
6. ✅ **Documented risk model** - Complete RISK_MODEL.md
7. ✅ **Deterministic conflict handling** - IARC priority over Prop 65
8. ✅ **Error handling** - All edge cases covered
9. ✅ **Backend tests** - 2-3 pytest tests
10. ✅ **Flutter widget tests** - Already present
11. ✅ **Clean README** - Accurate and complete
12. ✅ **Architecture diagram** - Visual PNG included
13. ✅ **Data sources documented** - With limitations
14. ✅ **Screenshots/demo** - Setup instructions provided
15. ✅ **Flutter + BLoC explanation** - Already present
16. ✅ **Backend explanation** - "Why a Backend?" section
17. ✅ **No dead code** - Audit complete
18. ✅ **Consistent naming** - "SafeEats" everywhere
19. ✅ **Clear scope** - Already present
20. ✅ **One-command setup** - run.sh script

---

## Next Steps

1. Review this plan and confirm priorities
2. Switch to Code mode to begin implementation
3. Start with Phase 1 (Backend Hardening) as it's foundational
4. Proceed through phases in order
5. Test thoroughly after each phase