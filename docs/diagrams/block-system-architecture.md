# Block Diagram: System Architecture

This diagram shows the overall system architecture of SafeEats.

```mermaid
block-beta
    columns 3
    
    block:client["Flutter App (Client)"]:3
        columns 3
        
        block:presentation["Presentation Layer"]:3
            ScannerPage["Scanner\nPage"]
            ProductPage["Product\nResults Page"]
            HistoryPage["History\nPage"]
        end
        
        block:blocs["BLoC Layer"]:3
            ScannerBloc["Scanner\nBLoC"]
            ProductBloc["Product\nBLoC"]
            HistoryBloc["History\nBLoC"]
        end
        
        block:domain["Domain Layer"]:3
            GetProduct["GetProduct\nByBarcode"]
            CheckCarcinogens["Check\nCarcinogens"]
            SaveScan["Save\nScan"]
        end
        
        block:data["Data Layer"]:3
            BackendDS["Backend\nDataSource"]
            RemoteDS["OFF\nDataSource"]
            LocalDS["Local\nDataSource"]
        end
    end
    
    space:3
    
    block:backend["SafeEats Backend (FastAPI)"]:3
        columns 3
        
        ScanEndpoint["POST /scan\nEndpoint"]
        RulesEngine["Risk Rules\nEngine v1.0"]
        Cache["SQLite\nCache"]
    end
    
    space:3
    
    block:external["External Services"]:3
        columns 3
        OFF_API["Open Food\nFacts API"]
        space
        space
    end
    
    BackendDS --> ScanEndpoint
    RemoteDS --> OFF_API
    ScanEndpoint --> OFF_API
    ScanEndpoint --> RulesEngine
    ScanEndpoint --> Cache
```

## Alternative View: Component Relationships

```mermaid
flowchart TB
    subgraph Flutter["Flutter App"]
        direction TB
        
        subgraph UI["UI Layer"]
            HomePage[Home Page]
            ScannerPage[Scanner Page]
            ResultsPage[Results Page]
            HistoryPage[History Page]
            DatabasePage[Database Page]
        end
        
        subgraph BLoCs["State Management"]
            ScannerBloc[Scanner BLoC]
            ProductBloc[Product BLoC]
            CarcinogenBloc[Carcinogen BLoC]
            HistoryBloc[History BLoC]
        end
        
        subgraph UseCases["Use Cases"]
            GetProduct[GetProductByBarcode]
            CheckCarcinogens[CheckIngredientsForCarcinogens]
            GetHistory[GetScanHistory]
            SaveScan[SaveScan]
        end
        
        subgraph Repos["Repositories"]
            ProductRepo[ProductRepository]
            CarcinogenRepo[CarcinogenRepository]
            HistoryRepo[HistoryRepository]
        end
        
        subgraph DataSources["Data Sources"]
            BackendDS[Backend DataSource]
            OFFDS[OFF DataSource]
            LocalDS[Local DataSource]
        end
        
        subgraph LocalDB["Local Storage"]
            SQLite[(SQLite DB)]
        end
    end
    
    subgraph Backend["SafeEats Backend"]
        direction TB
        FastAPI[FastAPI App]
        Rules[Risk Rules Engine]
        Normalizer[Ingredient Normalizer]
        BackendCache[(SQLite Cache)]
    end
    
    subgraph External["External APIs"]
        OFF[Open Food Facts API]
    end
    
    UI --> BLoCs
    BLoCs --> UseCases
    UseCases --> Repos
    Repos --> DataSources
    DataSources --> LocalDB
    
    BackendDS -->|POST /scan| FastAPI
    OFFDS -->|Fallback| OFF
    
    FastAPI --> Rules
    FastAPI --> Normalizer
    FastAPI --> BackendCache
    FastAPI -->|Fetch product| OFF
```

## Layer Responsibilities

| Layer | Components | Responsibility |
|-------|------------|----------------|
| **UI** | Pages, Widgets | User interaction, display |
| **BLoC** | ScannerBloc, ProductBloc, etc. | State management, business logic orchestration |
| **Use Cases** | GetProductByBarcode, SaveScan, etc. | Single-purpose business operations |
| **Repository** | ProductRepository, HistoryRepository | Data access abstraction |
| **Data Source** | BackendDS, LocalDS, RemoteDS | Concrete data fetching |
| **Backend** | FastAPI, Rules Engine | Centralized processing, risk classification |