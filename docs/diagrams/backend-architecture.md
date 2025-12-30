# Backend Architecture Diagrams

This document contains diagrams specific to the SafeEats FastAPI backend.

## API Endpoint Flow

```mermaid
sequenceDiagram
    participant Client as Flutter App
    participant API as FastAPI
    participant Cache as SQLite Cache
    participant Rules as Risk Rules Engine
    participant OFF as Open Food Facts
    
    Client->>API: POST /scan {barcode}
    
    API->>API: Validate barcode format
    
    alt Invalid Barcode
        API-->>Client: 400 Bad Request
    end
    
    API->>Cache: Check cache for barcode
    
    alt Cache Hit
        Cache-->>API: Cached response
        API-->>Client: 200 OK (cached)
    else Cache Miss
        API->>OFF: GET /product/{barcode}
        
        alt Product Not Found
            OFF-->>API: 404
            API-->>Client: 404 Not Found
        else Product Found
            OFF-->>API: Product data
            
            API->>API: Parse ingredients
            
            alt No Ingredients
                API-->>Client: 422 No Ingredients
            end
            
            API->>Rules: Normalize ingredients
            Rules-->>API: Normalized list
            
            API->>Rules: Classify each ingredient
            Rules-->>API: Risk assessments
            
            API->>Rules: Calculate overall risk
            Rules-->>API: Overall risk level
            
            API->>Cache: Store decision
            
            API-->>Client: 200 OK (ScanResponse)
        end
    end
```

## Backend Module Structure

```mermaid
flowchart TB
    subgraph API["app.py - FastAPI Application"]
        ScanEndpoint["/scan endpoint"]
        HealthEndpoint["/health endpoint"]
        MetadataEndpoint["/rules/metadata endpoint"]
    end
    
    subgraph Rules["rules.py - Risk Classification"]
        Normalize[normalize_ingredient]
        ClassifyRisk[classify_risk]
        RiskWithSource[get_risk_with_source]
        OverallRisk[calculate_overall_risk]
        RulesVersion[RULES_VERSION = '1.0.0']
        
        subgraph Data["Carcinogen Data"]
            IARC1[IARC Group 1]
            IARC2A[IARC Group 2A]
            IARC2B[IARC Group 2B]
            IARC3[IARC Group 3]
            Prop65[Prop 65 List]
            IngredientMap[ingredient_map.json]
        end
    end
    
    subgraph DB["db.py - SQLite Cache"]
        GetConn[get_connection]
        InitDB[init_db]
        GetCached[get_cached_scan]
        SaveCached[save_scan_to_cache]
    end
    
    ScanEndpoint --> Normalize
    ScanEndpoint --> ClassifyRisk
    ScanEndpoint --> OverallRisk
    ScanEndpoint --> GetCached
    ScanEndpoint --> SaveCached
    
    ClassifyRisk --> IARC1
    ClassifyRisk --> IARC2A
    ClassifyRisk --> IARC2B
    ClassifyRisk --> Prop65
    
    Normalize --> IngredientMap
```

## Database Schema

```mermaid
erDiagram
    SCAN_CACHE {
        text barcode PK
        text product_name
        text brand
        text image_url
        text raw_ingredients
        text normalized_ingredients
        text ingredient_risks
        text overall_risk
        text rules_version
        text created_at
        text expires_at
    }
```

## Response Models

```mermaid
classDiagram
    class ScanRequest {
        +str barcode
    }
    
    class ScanResponse {
        +str product_name
        +str? brand
        +str? image_url
        +list~str~ raw_ingredients
        +list~str~ normalized_ingredients
        +list~IngredientRisk~ ingredient_risks
        +str overall_risk
        +str rules_version
    }
    
    class IngredientRisk {
        +str ingredient
        +str normalized_name
        +str risk
        +str? source
        +str? classification
    }
    
    class HealthResponse {
        +str status
        +str rules_version
    }
    
    class RulesMetadata {
        +str version
        +list~str~ sources
        +dict conflict_resolution
        +str last_updated
        +str disclaimer
    }
    
    ScanResponse "1" *-- "many" IngredientRisk
```

## Caching Strategy

```mermaid
flowchart TD
    Request[Incoming Scan Request] --> CheckCache{Cache exists?}
    
    CheckCache -->|Yes| CheckExpiry{Expired?}
    CheckCache -->|No| FetchOFF[Fetch from Open Food Facts]
    
    CheckExpiry -->|No| CheckVersion{Rules version<br/>matches?}
    CheckExpiry -->|Yes| FetchOFF
    
    CheckVersion -->|Yes| ReturnCached[Return cached response]
    CheckVersion -->|No| FetchOFF
    
    FetchOFF --> Process[Process & Classify]
    Process --> SaveCache[Save to cache<br/>TTL: 24 hours]
    SaveCache --> ReturnFresh[Return fresh response]
    
    ReturnCached --> Response[Response to Client]
    ReturnFresh --> Response
```

## Error Handling

```mermaid
flowchart LR
    subgraph Errors["HTTP Status Codes"]
        E400[400 Bad Request<br/>Invalid barcode format]
        E404[404 Not Found<br/>Product not in OFF]
        E422[422 Unprocessable<br/>No ingredients]
        E502[502 Bad Gateway<br/>OFF API error]
        E500[500 Internal Error<br/>Unexpected error]
    end
    
    subgraph Causes
        C400[Non-numeric barcode<br/>Too short/long]
        C404[Barcode not found<br/>in Open Food Facts]
        C422[Product exists but<br/>has no ingredients]
        C502[OFF API timeout<br/>or error]
        C500[Database error<br/>Processing error]
    end
    
    C400 --> E400
    C404 --> E404
    C422 --> E422
    C502 --> E502
    C500 --> E500
```

## Test Coverage

```mermaid
pie title Backend Test Distribution
    "Risk Classification" : 24
    "API Endpoints" : 14
    "Normalization" : 6
    "Versioning" : 4
    "Conflict Resolution" : 4
```

| Test Category | Count | Description |
|---------------|-------|-------------|
| Risk Classification | 24 | Single ingredient, multiple sources, edge cases |
| API Endpoints | 14 | /scan, /health, /rules/metadata responses |
| Normalization | 6 | Case handling, punctuation, synonyms |
| Versioning | 4 | Version format, metadata completeness |
| Conflict Resolution | 4 | Source priority, deterministic results |