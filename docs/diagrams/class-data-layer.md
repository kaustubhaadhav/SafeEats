# Class Diagram: Data Layer

This diagram shows the data layer architecture including repositories, data sources, and models.

```mermaid
classDiagram
    direction TB
    
    %% Abstract Repository Interfaces
    class ProductRepository {
        <<interface>>
        +getProductByBarcode(barcode: String) Future~Either~Failure, Product~~
        +cacheProduct(product: Product) Future~Either~Failure, void~~
        +getCachedProduct(barcode: String) Future~Either~Failure, Product?~~
    }
    
    class CarcinogenRepository {
        <<interface>>
        +getAllCarcinogens() Future~Either~Failure, List~Carcinogen~~~
        +checkIngredients(ingredients: List~String~) Future~Either~Failure, List~Carcinogen~~~
    }
    
    class HistoryRepository {
        <<interface>>
        +getScanHistory() Future~Either~Failure, List~ScanHistory~~~
        +saveScan(history: ScanHistory) Future~Either~Failure, void~~
        +deleteScan(id: int) Future~Either~Failure, void~~
    }
    
    %% Repository Implementations
    class ProductRepositoryImpl {
        -backendDataSource: ProductBackendDataSource
        -remoteDataSource: ProductRemoteDataSource
        -localDataSource: ProductLocalDataSource
        -networkInfo: NetworkInfo
        +getProductByBarcode(barcode: String) Future~Either~Failure, Product~~
        -_fallbackToOpenFoodFacts(barcode: String) Future~Either~Failure, Product~~
    }
    
    class CarcinogenRepositoryImpl {
        -localDataSource: CarcinogenLocalDataSource
        +getAllCarcinogens() Future~Either~Failure, List~Carcinogen~~~
        +checkIngredients(ingredients: List~String~) Future~Either~Failure, List~Carcinogen~~~
    }
    
    class HistoryRepositoryImpl {
        -localDatasource: HistoryLocalDatasource
        +getScanHistory() Future~Either~Failure, List~ScanHistory~~~
        +saveScan(history: ScanHistory) Future~Either~Failure, void~~
        +deleteScan(id: int) Future~Either~Failure, void~~
    }
    
    %% Data Sources
    class ProductBackendDataSource {
        <<interface>>
        +scanProduct(barcode: String) Future~BackendScanResponse~
    }
    
    class ProductRemoteDataSource {
        <<interface>>
        +getProductByBarcode(barcode: String) Future~ProductModel~
    }
    
    class ProductLocalDataSource {
        <<interface>>
        +cacheProduct(product: ProductModel) Future~void~
        +getCachedProduct(barcode: String) Future~ProductModel?~
    }
    
    class ProductBackendDataSourceImpl {
        -apiClient: ApiClient
        +scanProduct(barcode: String) Future~BackendScanResponse~
    }
    
    class ProductRemoteDataSourceImpl {
        -apiClient: ApiClient
        +getProductByBarcode(barcode: String) Future~ProductModel~
    }
    
    class ProductLocalDataSourceImpl {
        -database: Database
        +cacheProduct(product: ProductModel) Future~void~
        +getCachedProduct(barcode: String) Future~ProductModel?~
    }
    
    %% Models
    class ProductModel {
        +String barcode
        +String name
        +String? brand
        +List~IngredientModel~ ingredients
        +fromJson(json: Map) ProductModel
        +fromBackendResponse(response: BackendScanResponse, barcode: String) ProductModel
        +toJson() Map
        +toEntity() Product
    }
    
    class BackendScanResponse {
        +String productName
        +String? brand
        +String? imageUrl
        +List~String~ rawIngredients
        +List~String~ normalizedIngredients
        +List~IngredientRisk~ ingredientRisks
        +String overallRisk
        +String rulesVersion
        +fromJson(json: Map) BackendScanResponse
    }
    
    class IngredientRisk {
        +String ingredient
        +String normalizedName
        +String risk
        +String? source
        +String? classification
    }
    
    %% Relationships
    ProductRepository <|.. ProductRepositoryImpl : implements
    CarcinogenRepository <|.. CarcinogenRepositoryImpl : implements
    HistoryRepository <|.. HistoryRepositoryImpl : implements
    
    ProductBackendDataSource <|.. ProductBackendDataSourceImpl : implements
    ProductRemoteDataSource <|.. ProductRemoteDataSourceImpl : implements
    ProductLocalDataSource <|.. ProductLocalDataSourceImpl : implements
    
    ProductRepositoryImpl --> ProductBackendDataSource : primary
    ProductRepositoryImpl --> ProductRemoteDataSource : fallback
    ProductRepositoryImpl --> ProductLocalDataSource : cache
    
    ProductBackendDataSourceImpl --> ApiClient : uses
    ProductRemoteDataSourceImpl --> ApiClient : uses
    ProductLocalDataSourceImpl --> Database : uses
    
    ProductBackendDataSourceImpl ..> BackendScanResponse : returns
    ProductRemoteDataSourceImpl ..> ProductModel : returns
```

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph Repository["ProductRepositoryImpl"]
        direction TB
        Entry[getProductByBarcode]
        Entry --> CacheCheck{Cache?}
        CacheCheck -->|Hit| Return[Return Product]
        CacheCheck -->|Miss| Backend[Try Backend]
        Backend -->|Success| Cache[Cache & Return]
        Backend -->|Fail| Fallback[Try OFF API]
        Fallback -->|Success| Cache
        Fallback -->|Fail| Error[Return Failure]
    end
    
    subgraph DataSources["Data Sources"]
        BackendDS[Backend DataSource]
        RemoteDS[OFF DataSource]
        LocalDS[Local DataSource]
    end
    
    subgraph External["External"]
        SafeEatsAPI[SafeEats Backend]
        OFFAPI[Open Food Facts API]
        SQLite[(SQLite)]
    end
    
    Backend --> BackendDS
    Fallback --> RemoteDS
    Cache --> LocalDS
    CacheCheck --> LocalDS
    
    BackendDS --> SafeEatsAPI
    RemoteDS --> OFFAPI
    LocalDS --> SQLite
```

## API Client Architecture

```mermaid
classDiagram
    class ApiClient {
        -Dio dio
        +get~T~(path: String, params: Map?) Future~Response~T~~
        +post~T~(path: String, data: Map?) Future~Response~T~~
    }
    
    class Dio {
        +BaseOptions options
        +get(path: String) Future~Response~
        +post(path: String, data: dynamic) Future~Response~
    }
    
    class NetworkInfo {
        <<interface>>
        +isConnected Future~bool~
    }
    
    class NetworkInfoImpl {
        -Connectivity connectivity
        +isConnected Future~bool~
    }
    
    ApiClient --> Dio : wraps
    NetworkInfo <|.. NetworkInfoImpl : implements
```

## Dependency Injection Setup

```dart
// Two API clients for different backends
sl.registerLazySingleton<Dio>(() => Dio(BaseOptions(
  baseUrl: backendUrl,  // SafeEats backend
)), instanceName: 'backend');

sl.registerLazySingleton<Dio>(() => Dio(BaseOptions(
  baseUrl: 'https://world.openfoodfacts.org/api/v2',
)), instanceName: 'openFoodFacts');

// Data sources use specific API clients
sl.registerLazySingleton<ProductBackendDataSource>(
  () => ProductBackendDataSourceImpl(
    apiClient: sl<ApiClient>(instanceName: 'backend'),
  ),
);

sl.registerLazySingleton<ProductRemoteDataSource>(
  () => ProductRemoteDataSourceImpl(
    apiClient: sl<ApiClient>(instanceName: 'openFoodFacts'),
  ),
);