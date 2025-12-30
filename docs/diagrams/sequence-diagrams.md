# SafeEats App Flow Sequence Diagrams

This document contains sequence diagrams for all major flows in the SafeEats application.

## 1. Complete Barcode Scan Flow

This shows the end-to-end flow from user scanning a barcode to displaying risk results.

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant SP as ScannerPage
    participant SB as ScannerBloc
    participant PB as ProductBloc
    participant BV as BarcodeValidator
    participant PR as ProductRepository
    participant BD as BackendDataSource
    participant FoodAPI as FoodFactsAPI
    participant LD as LocalDataSource
    participant CC as CheckCarcinogens
    participant CR as CarcinogenRepository
    participant CM as CarcinogenMatcher
    participant SS as SaveScan
    participant HR as HistoryRepository
    participant RP as ResultsPage

    U->>SP: Point camera at barcode
    SP->>SB: BarcodeDetectedEvent
    SB-->>SP: ScannerState with barcode
    SP->>PB: FetchProductEvent with barcode
    
    Note over PB,BV: Barcode Validation
    PB->>BV: validate barcode
    BV-->>PB: ValidationResult
    
    alt Invalid Barcode
        PB-->>SP: ProductState with error
        SP-->>U: Show error message
    else Valid Barcode
        PB->>PR: getProductByBarcode
        
        Note over PR,LD: Check Local Cache First
        PR->>LD: getCachedProduct
        
        alt Cache Hit
            LD-->>PR: cached Product
            PR-->>PB: Right with Product
        else Cache Miss
            Note over PR,FoodAPI: Try Backend First with Fallback
            PR->>BD: scanProduct
            
            alt Backend Success
                BD-->>PR: BackendResponse
                PR->>LD: cacheProduct
                PR-->>PB: Right with Product
            else Backend Failed
                PR->>FoodAPI: getProductByBarcode
                FoodAPI-->>PR: ProductModel
                PR->>LD: cacheProduct
                PR-->>PB: Right with Product
            end
        end
        
        Note over PB,CM: Carcinogen Analysis
        PB->>CC: call with ingredientsText
        CC->>CR: getAllCarcinogens
        CR-->>CC: List of Carcinogens
        CC->>CM: findMatches
        CM-->>CC: MatchResults
        CC->>CM: calculateOverallRisk
        CM-->>CC: RiskLevel
        CC-->>PB: AnalysisResult
        
        Note over PB,HR: Save to History
        PB->>SS: call with ScanHistory
        SS->>HR: saveScan
        HR-->>SS: saved ScanHistory
        SS-->>PB: Right
        
        PB-->>SP: ProductState with loaded data
        SP->>RP: Navigate to results
        RP-->>U: Display product and risk analysis
    end
```

## 2. Product Data Retrieval Flow

Detailed flow of how product data is retrieved with caching and fallback logic.

```mermaid
sequenceDiagram
    autonumber
    participant PB as ProductBloc
    participant PR as ProductRepositoryImpl
    participant NI as NetworkInfo
    participant LD as LocalDataSource
    participant BD as BackendDataSource
    participant AC as ApiClient
    participant FoodAPI as FoodFactsAPI
    participant DB as SQLiteCache

    PB->>PR: getProductByBarcode
    
    Note over PR,DB: Step 1 - Try Cache
    PR->>LD: getCachedProduct
    LD->>DB: query cached_products
    DB-->>LD: cached data or null
    
    alt Cache Hit and Fresh
        LD-->>PR: ProductModel
        PR-->>PB: Right with Product
    else Cache Miss or Stale
        Note over PR,NI: Step 2 - Check Network
        PR->>NI: isConnected
        
        alt No Network
            NI-->>PR: false
            PR-->>PB: Left with NetworkFailure
        else Has Network
            Note over PR,BD: Step 3 - Try Backend
            PR->>BD: scanProduct
            BD->>AC: post to scan endpoint
            
            alt Backend Success
                AC-->>BD: BackendResponse
                BD-->>PR: response with ingredients
                PR->>LD: cacheProduct
                LD->>DB: insert into cached_products
                PR-->>PB: Right with Product
            else Backend 404
                Note over PR,FoodAPI: Step 4 - Fallback API
                PR->>FoodAPI: getProductByBarcode
                FoodAPI->>AC: get from external API
                
                alt Product Found
                    AC-->>FoodAPI: Product JSON
                    FoodAPI-->>PR: ProductModel
                    PR->>LD: cacheProduct
                    PR-->>PB: Right with Product
                else Product Not Found
                    FoodAPI-->>PR: NotFoundException
                    PR-->>PB: Left with NotFoundFailure
                end
            else Backend Error
                PR->>FoodAPI: fallback to external API
                FoodAPI-->>PR: ProductModel or Exception
                PR-->>PB: Result
            end
        end
    end
```

## 3. Carcinogen Analysis Flow

Flow showing how ingredients are analyzed for potential carcinogens.

```mermaid
sequenceDiagram
    autonumber
    participant PB as ProductBloc
    participant CC as CheckIngredientsForCarcinogens
    participant CR as CarcinogenRepository
    participant CDS as CarcinogenLocalDataSource
    participant DB as SQLiteDB
    participant IP as IngredientParser
    participant CM as CarcinogenMatcher

    PB->>CC: call with ingredientsText
    
    alt Empty Ingredients
        CC-->>PB: AnalysisResult with safe risk
    else Has Ingredients
        Note over CC,DB: Load Carcinogen Database
        CC->>CR: getAllCarcinogens
        CR->>CDS: getAllCarcinogens
        CDS->>DB: SELECT FROM carcinogens
        DB-->>CDS: carcinogen rows
        CDS-->>CR: List of CarcinogenModel
        CR-->>CC: List of Carcinogen entities
        
        Note over CC,IP: Parse Ingredients
        CC->>IP: parse ingredientsText
        IP-->>CC: List of ingredient strings
        CC->>IP: extractENumbers
        IP-->>CC: List of E-numbers
        
        Note over CC,CM: Match Against Database
        CC->>CM: new CarcinogenMatcher with carcinogens
        CC->>CM: findMatches with all ingredients
        
        loop For Each Ingredient
            CM->>CM: normalize ingredient
            CM->>CM: check against carcinogen name
            CM->>CM: check against aliases
            CM->>CM: check E-number patterns
            CM->>CM: fuzzy match if needed
        end
        
        CM-->>CC: List of CarcinogenMatchResult
        
        CC->>CM: getUniqueCarcinogens
        CM-->>CC: deduplicated carcinogens
        
        CC->>CM: calculateOverallRisk
        CM-->>CC: highest RiskLevel found
        
        CC-->>PB: AnalysisResult
    end
```

## 4. History Management Flow

Flow showing how scan history is loaded, displayed, and managed.

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant HP as HistoryPage
    participant HB as HistoryBloc
    participant GH as GetScanHistory
    participant DS as DeleteScan
    participant HR as HistoryRepository
    participant HDS as HistoryLocalDataSource
    participant DB as SQLiteDB

    U->>HP: Navigate to History
    HP->>HB: LoadHistoryEvent
    
    HB->>GH: call
    GH->>HR: getScanHistory
    HR->>HDS: getScanHistory
    HDS->>DB: SELECT FROM scan_history ORDER BY scanned_at DESC
    DB-->>HDS: history rows
    HDS-->>HR: List of ScanHistoryModel
    HR-->>GH: List of ScanHistory
    GH-->>HB: Right with history list
    
    HB-->>HP: HistoryState with loaded scans
    HP-->>U: Display scan history list
    
    alt User Deletes Scan
        U->>HP: Swipe to delete
        HP->>HB: DeleteScanEvent with scanId
        HB->>DS: call with scanId
        DS->>HR: deleteScan
        HR->>HDS: deleteScan
        HDS->>DB: DELETE FROM scan_history WHERE id equals param
        DB-->>HDS: success
        HDS-->>HR: void
        HR-->>DS: Right
        DS-->>HB: Right
        HB-->>HP: Updated HistoryState without deleted scan
        HP-->>U: Updated list
    end
    
    alt User Refreshes
        U->>HP: Pull to refresh
        HP->>HB: RefreshHistoryEvent
        HB->>HB: add LoadHistoryEvent
        Note over HB,DB: Same flow as initial load
    end
```

## 5. Scanner Camera Flow

Flow showing the barcode scanning camera interaction.

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant SP as ScannerPage
    participant MS as MobileScannerWidget
    participant SB as ScannerBloc
    participant PB as ProductBloc

    U->>SP: Open Scanner
    SP->>SB: StartScanningEvent
    SB-->>SP: ScannerState with scanning status
    SP->>MS: Initialize camera
    MS-->>SP: Camera ready
    
    loop Camera Active
        MS->>MS: Process frames
        MS->>MS: Detect barcodes
        
        alt Barcode Detected
            MS-->>SP: onDetect callback with barcode
            SP->>SB: BarcodeDetectedEvent
            
            Note over SB: Prevent duplicates
            alt Same barcode already detected
                SB-->>SP: No state change
            else New barcode
                SB-->>SP: ScannerState with barcodeDetected
                SP->>SB: StopScanningEvent
                SB-->>SP: ScannerState paused
                SP->>PB: FetchProductEvent
                Note over PB: Continue with Product Flow
            end
        end
    end
    
    alt Toggle Flash
        U->>SP: Tap flash button
        SP->>SB: ToggleFlashEvent
        SB-->>SP: ScannerState with toggled flash
        SP->>MS: Update flash mode
    end
    
    alt Switch Camera
        U->>SP: Tap camera switch
        SP->>SB: SwitchCameraEvent
        SB-->>SP: ScannerState with switched camera
        SP->>MS: Switch camera facing
    end
    
    alt Reset Scanner
        U->>SP: Scan another product
        SP->>SB: ResetScannerEvent
        SB-->>SP: Fresh ScannerState scanning
    end
```

## 6. App Initialization Flow

Flow showing how the app initializes and sets up dependencies.

```mermaid
sequenceDiagram
    autonumber
    participant M as MainDart
    participant DI as InjectionContainer
    participant GI as GetIt
    participant CFG as AppConfig
    participant DB as Database
    participant NET as NetworkServices
    participant BLoC as BLoCs

    M->>M: WidgetsFlutterBinding.ensureInitialized
    M->>DI: init
    
    Note over DI,CFG: Configuration
    DI->>CFG: AppConfig.instance
    DI->>GI: registerLazySingleton AppConfig
    
    Note over DI,NET: Network Layer
    DI->>GI: registerLazySingleton Dio for backend
    DI->>GI: registerLazySingleton Dio for FoodFactsAPI
    DI->>GI: registerLazySingleton Connectivity
    DI->>GI: registerLazySingleton NetworkInfo
    DI->>GI: registerLazySingleton RetryConfig
    DI->>GI: registerLazySingleton ApiClient for backend
    DI->>GI: registerLazySingleton ApiClient for FoodFactsAPI
    
    Note over DI,DB: Database
    DI->>DB: _initDatabase
    DB->>DB: openDatabase
    DB->>DB: CREATE TABLE carcinogens
    DB->>DB: CREATE TABLE scan_history
    DB->>DB: CREATE TABLE cached_products
    DB-->>DI: Database instance
    DI->>GI: registerSingleton Database
    
    Note over DI,BLoC: Feature Dependencies
    DI->>GI: register DataSources
    DI->>GI: register Repositories
    DI->>GI: register UseCases
    DI->>GI: registerFactory BLoCs
    
    Note over DI,DB: Carcinogen Data
    DI->>DB: _initCarcinogenData
    DB->>DB: Check if carcinogens exist
    alt No Data
        DB->>DB: Batch insert IARC carcinogens
        DB->>DB: Batch insert Prop65 carcinogens
    end
    
    DI-->>M: Initialization complete
    M->>M: runApp SafeEatsApp
```

## 7. Backend API Integration Flow

Flow showing communication with the Python FastAPI backend.

```mermaid
sequenceDiagram
    autonumber
    participant App as FlutterApp
    participant BD as ProductBackendDataSource
    participant AC as ApiClient
    participant RH as RetryHelper
    participant BE as PythonBackend
    participant FoodAPI as FoodFactsAPI
    participant Cache as BackendCache

    App->>BD: scanProduct with barcode
    BD->>AC: post to scan endpoint
    AC->>RH: executeWithRetry
    
    loop Retry Logic
        RH->>BE: POST scan with barcode
        
        alt Backend Online
            BE->>Cache: Check cache
            
            alt Cache Hit
                Cache-->>BE: Cached product data
            else Cache Miss
                BE->>FoodAPI: Fetch from external API
                FoodAPI-->>BE: Product data
                BE->>BE: Analyze ingredients
                BE->>BE: Calculate risk scores
                BE->>Cache: Store in cache
            end
            
            BE-->>RH: BackendResponse JSON
            RH-->>AC: Success response
            AC-->>BD: BackendResponseModel
            BD-->>App: Product with analysis
        else Network Error
            RH->>RH: Wait with backoff
            RH->>RH: Increment retry count
            alt Max Retries Reached
                RH-->>AC: Throw exception
            else Retry Available
                Note over RH,BE: Retry request
            end
        else 4xx Error
            BE-->>RH: Client error
            RH-->>AC: Throw immediately no retry
        end
    end
```

## Legend

| Symbol | Meaning |
|--------|---------|
| `->>`  | Synchronous call |
| `-->>` | Response or Return |
| `alt`  | Alternative paths |
| `loop` | Repeated action |
| `Note` | Additional context |

## Risk Level Values

| Level | Value | Description |
|-------|-------|-------------|
| safe | 0 | No carcinogens detected |
| low | 1 | IARC Group 3 or minimal concern |
| medium | 2 | IARC Group 2B or moderate concern |
| high | 3 | IARC Group 2A or high concern |
| critical | 4 | IARC Group 1 - Known carcinogen |