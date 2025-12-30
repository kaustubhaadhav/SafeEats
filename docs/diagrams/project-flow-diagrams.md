# SafeEats Project Flow & Sequence Diagrams

A comprehensive collection of all application flows and architecture diagrams.

---

## 1. High-Level Application Flow

Shows the complete user journey through the app.

```mermaid
flowchart TB
    subgraph User Journey
        Start([App Launch]) --> Home[Home Screen]
        Home --> |Tap Scan| Scanner[Scanner Screen]
        Home --> |Tap History| History[History Screen]
        Home --> |Tap Settings| Settings[Settings Screen]
        
        Scanner --> |Barcode Detected| Loading[Loading State]
        Loading --> |Success| Results[Results Screen]
        Loading --> |Error| Error[Error Screen]
        
        Results --> |Tap Ingredient| Details[Carcinogen Details]
        Results --> |Save| History
        Details --> Results
        
        History --> |Tap Item| Results
        Error --> Scanner
    end
```

---

## 2. Complete System Architecture

End-to-end architecture showing all components.

```mermaid
flowchart TB
    subgraph Mobile["📱 Flutter App"]
        subgraph Presentation["Presentation Layer"]
            Pages[Pages/Screens]
            Widgets[Widgets]
            BLoCs[BLoC State Management]
        end
        
        subgraph Domain["Domain Layer"]
            UseCases[Use Cases]
            Entities[Entities]
            RepoInterfaces[Repository Interfaces]
        end
        
        subgraph Data["Data Layer"]
            Repos[Repository Implementations]
            DS[Data Sources]
            Models[Data Models]
        end
    end
    
    subgraph Backend["🖥️ SafeEats Backend"]
        FastAPI[FastAPI App]
        RulesEngine[Risk Rules Engine]
        Cache[SQLite Cache]
    end
    
    subgraph External["🌐 External Services"]
        OFF[Open Food Facts API]
    end
    
    subgraph Device["📲 Device"]
        Camera[Camera]
        LocalDB[SQLite Database]
    end
    
    Pages --> BLoCs
    BLoCs --> UseCases
    UseCases --> RepoInterfaces
    RepoInterfaces -.-> Repos
    Repos --> DS
    
    DS <--> Backend
    DS <--> LocalDB
    DS <--> Camera
    
    Backend --> OFF
    Backend --> RulesEngine
    Backend --> Cache
```

---

## 3. Barcode Scanning Sequence (Detailed)

Complete flow from user scan to displaying results.

```mermaid
sequenceDiagram
    autonumber
    participant 👤 as User
    participant 📱 as Scanner Page
    participant 🧠 as Scanner BLoC
    participant 📦 as Product BLoC
    participant 🗃️ as Product Repository
    participant 💾 as Local Cache
    participant 🖥️ as Backend API
    participant 🌐 as Open Food Facts
    
    👤->>📱: Opens Camera & Scans
    📱->>🧠: BarcodeScanned(barcode)
    🧠->>🧠: Validate barcode format
    🧠-->>📱: ScannerSuccess(barcode)
    
    📱->>📦: GetProduct(barcode)
    📦->>🗃️: getProductByBarcode()
    
    🗃️->>💾: getCachedProduct()
    
    alt Cache Hit (Valid & Fresh)
        💾-->>🗃️: Cached Product
        🗃️-->>📦: Product with risks
    else Cache Miss or Expired
        💾-->>🗃️: null
        🗃️->>🖥️: POST /scan {barcode}
        
        alt Backend Available
            🖥️->>🌐: GET /product/{barcode}
            🌐-->>🖥️: Product data
            🖥️->>🖥️: Parse & Normalize ingredients
            🖥️->>🖥️: Classify risk for each ingredient
            🖥️->>🖥️: Calculate overall risk
            🖥️-->>🗃️: ScanResponse with risks
        else Backend Unavailable
            🗃️->>🌐: GET /product/{barcode}
            🌐-->>🗃️: Raw product data
            🗃️->>🗃️: Client-side risk analysis
        end
        
        🗃️->>💾: Cache product
        🗃️-->>📦: Product with risks
    end
    
    📦-->>📱: ProductLoaded(product)
    📱-->>👤: Display Results with Risk Level
```

---

## 4. Risk Classification Flow

How ingredients are classified into risk levels.

```mermaid
flowchart TD
    Input([📥 Ingredient List]) --> Parse
    
    Parse[Parse ingredients from text]
    Parse --> Loop
    
    Loop{For each ingredient}
    Loop --> Normalize
    
    Normalize[🔧 Normalize Name<br/>• lowercase<br/>• trim whitespace<br/>• remove percentages<br/>• resolve aliases]
    Normalize --> CheckIARC
    
    CheckIARC{Check IARC Database}
    
    CheckIARC -->|Group 1| Critical[🔴 CRITICAL<br/>Carcinogenic to humans]
    CheckIARC -->|Group 2A| High[🟠 HIGH<br/>Probably carcinogenic]
    CheckIARC -->|Group 2B| Moderate[🟡 MODERATE<br/>Possibly carcinogenic]
    CheckIARC -->|Group 3| Low[🟢 LOW<br/>Not classifiable]
    CheckIARC -->|Not Found| CheckProp65
    
    CheckProp65{Check Prop 65}
    CheckProp65 -->|Known Carcinogen| High
    CheckProp65 -->|Reproductive Toxicant| Moderate
    CheckProp65 -->|Not Found| Safe[✅ SAFE<br/>No known concerns]
    
    Critical --> Aggregate
    High --> Aggregate
    Moderate --> Aggregate
    Low --> Aggregate
    Safe --> Aggregate
    
    Aggregate[📊 Aggregate All Risks]
    Aggregate --> Overall
    
    Overall[🎯 Overall Risk = MAX<br/>of all ingredient risks]
    Overall --> Result([📤 Return Assessment])
```

---

## 5. BLoC State Machine

State transitions for ProductBloc.

```mermaid
stateDiagram-v2
    [*] --> Initial: App Start
    
    Initial --> Loading: GetProduct Event
    
    Loading --> Loaded: Product Found
    Loading --> Error: API Error
    Loading --> NotFound: Product Not in Database
    
    Loaded --> Loading: Scan Another
    Error --> Loading: Retry
    NotFound --> Loading: Scan Another
    
    Loaded --> [*]
    Error --> [*]
    NotFound --> [*]
    
    note right of Loading
        Shows shimmer animation
        Fetches from backend/cache
    end note
    
    note right of Loaded
        Displays product info
        Shows risk assessment
        Lists all ingredients
    end note
    
    note right of Error
        Shows error message
        Offers retry option
    end note
```

---

## 6. Data Layer Flow

How data moves through repositories and data sources.

```mermaid
flowchart LR
    subgraph Repository["ProductRepository"]
        direction TB
        Interface[ProductRepository Interface<br/>Domain Layer]
        Impl[ProductRepositoryImpl<br/>Data Layer]
    end
    
    subgraph DataSources["Data Sources"]
        Backend[BackendDataSource<br/>Primary]
        Remote[RemoteDataSource<br/>Fallback to OFF]
        Local[LocalDataSource<br/>SQLite Cache]
    end
    
    subgraph External["External"]
        API1[SafeEats Backend<br/>localhost:8000]
        API2[Open Food Facts<br/>world.openfoodfacts.org]
        DB[(SQLite<br/>Database)]
    end
    
    Interface --> Impl
    Impl --> Local
    Impl --> Backend
    Impl --> Remote
    
    Backend <--> API1
    Remote <--> API2
    Local <--> DB
    
    API1 --> API2
```

---

## 7. Offline Mode Flow

How the app handles offline scenarios.

```mermaid
flowchart TD
    Scan([User Scans Barcode]) --> CheckNet{Network<br/>Available?}
    
    CheckNet -->|Yes| Online[Proceed Online]
    CheckNet -->|No| Offline[Offline Mode]
    
    Online --> CheckCache{In Cache?}
    CheckCache -->|Yes, Valid| ReturnCache[Return Cached Data]
    CheckCache -->|No| FetchAPI[Fetch from Backend]
    FetchAPI --> Cache[Store in Cache]
    Cache --> Return1[Return Fresh Data]
    
    Offline --> CheckLocalCache{In Local<br/>Cache?}
    CheckLocalCache -->|Yes| ReturnOffline[Return Cached Data<br/>with Offline Badge]
    CheckLocalCache -->|No| QueueScan[Add to Pending Queue]
    QueueScan --> ShowPending[Show 'Will scan when online']
    
    subgraph Sync["When Back Online"]
        Monitor[Monitor Connectivity]
        Monitor --> |Connected| ProcessQueue[Process Pending Scans]
        ProcessQueue --> Notify[Notify User of Results]
    end
```

---

## 8. API Request/Response Flow

Backend endpoint processing.

```mermaid
sequenceDiagram
    participant Client as Flutter App
    participant API as FastAPI
    participant Val as Validator
    participant Cache as SQLite Cache
    participant Rules as Rules Engine
    participant OFF as Open Food Facts
    
    Client->>API: POST /scan {"barcode": "123456"}
    
    API->>Val: Validate barcode format
    
    alt Invalid Format
        Val-->>API: ValidationError
        API-->>Client: 400 Bad Request
    end
    
    API->>Cache: get_cached_scan(barcode)
    
    alt Cache Hit & Valid
        Cache-->>API: Cached ScanResponse
        API-->>Client: 200 OK (from cache)
    else Cache Miss
        API->>OFF: GET /api/v2/product/{barcode}
        
        alt Product Not Found
            OFF-->>API: 404
            API-->>Client: 404 Not Found
        else Product Found
            OFF-->>API: Product Data
            
            API->>Rules: normalize_ingredients(raw_list)
            Rules-->>API: normalized_list
            
            loop For each ingredient
                API->>Rules: classify_risk(ingredient)
                Rules-->>API: risk_assessment
            end
            
            API->>Rules: calculate_overall_risk(all_risks)
            Rules-->>API: overall_risk
            
            API->>Cache: save_scan(barcode, response)
            
            API-->>Client: 200 OK (ScanResponse)
        end
    end
```

---

## 9. Entity Relationship Diagram

Core domain entities and their relationships.

```mermaid
erDiagram
    PRODUCT ||--o{ INGREDIENT : contains
    INGREDIENT ||--o| CARCINOGEN : may_be
    SCAN_HISTORY ||--|| PRODUCT : references
    
    PRODUCT {
        string barcode PK
        string name
        string brand
        string imageUrl
        list ingredients
        string overallRisk
    }
    
    INGREDIENT {
        string id PK
        string name
        string normalizedName
        string riskLevel
        string source
    }
    
    CARCINOGEN {
        string id PK
        string name
        list aliases
        string casNumber
        string source
        string classification
        int riskLevel
        string description
    }
    
    SCAN_HISTORY {
        int id PK
        string barcode FK
        string productName
        datetime scannedAt
        string riskLevel
    }
```

---

## 10. Feature Module Structure

Clean Architecture implementation per feature.

```mermaid
flowchart TB
    subgraph Feature["Feature Module (e.g., Product)"]
        subgraph Presentation
            Page[ProductDetailsPage]
            Widget1[IngredientList]
            Widget2[RiskIndicator]
            Bloc[ProductBloc]
            Event[ProductEvent]
            State[ProductState]
        end
        
        subgraph Domain
            Entity[Product Entity]
            Repo[ProductRepository Interface]
            UC1[GetProductByBarcode]
            UC2[CacheProduct]
        end
        
        subgraph Data
            RepoImpl[ProductRepositoryImpl]
            RemoteDS[ProductRemoteDataSource]
            LocalDS[ProductLocalDataSource]
            Model[ProductModel]
        end
    end
    
    Page --> Bloc
    Bloc --> UC1
    Bloc --> UC2
    UC1 --> Repo
    UC2 --> Repo
    Repo -.-> RepoImpl
    RepoImpl --> RemoteDS
    RepoImpl --> LocalDS
    Model --> Entity
```

---

## Quick Reference

| Diagram | Purpose |
|---------|---------|
| [#1 Application Flow](#1-high-level-application-flow) | User journey through screens |
| [#2 System Architecture](#2-complete-system-architecture) | All components and their connections |
| [#3 Scan Sequence](#3-barcode-scanning-sequence-detailed) | Detailed scan-to-result flow |
| [#4 Risk Classification](#4-risk-classification-flow) | How risks are determined |
| [#5 BLoC States](#5-bloc-state-machine) | State transitions in ProductBloc |
| [#6 Data Layer](#6-data-layer-flow) | Repository pattern implementation |
| [#7 Offline Mode](#7-offline-mode-flow) | Offline handling strategy |
| [#8 API Flow](#8-api-requestresponse-flow) | Backend endpoint processing |
| [#9 ERD](#9-entity-relationship-diagram) | Domain entity relationships |
| [#10 Feature Structure](#10-feature-module-structure) | Clean Architecture per feature |

---

## Viewing These Diagrams

1. **GitHub**: Renders Mermaid automatically
2. **VS Code**: Install "Markdown Preview Mermaid Support" extension
3. **Online**: Paste code at [mermaid.live](https://mermaid.live)
