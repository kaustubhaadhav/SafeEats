# Sequence Diagram: Barcode Scan Flow

This diagram shows the complete flow when a user scans a barcode.

```mermaid
sequenceDiagram
    autonumber
    participant User
    participant ScannerPage
    participant ScannerBloc
    participant ProductBloc
    participant ProductRepository
    participant BackendDataSource
    participant RemoteDataSource
    participant LocalDataSource
    participant Backend as SafeEats Backend
    participant OFF as Open Food Facts API

    User->>ScannerPage: Scan barcode
    ScannerPage->>ScannerBloc: BarcodeScanned(barcode)
    ScannerBloc-->>ScannerPage: ScannerSuccess(barcode)
    ScannerPage->>ProductBloc: GetProduct(barcode)
    
    ProductBloc->>ProductRepository: getProductByBarcode(barcode)
    
    Note over ProductRepository: Check local cache first
    ProductRepository->>LocalDataSource: getCachedProduct(barcode)
    
    alt Cache Hit
        LocalDataSource-->>ProductRepository: Product
        ProductRepository-->>ProductBloc: Right(Product)
    else Cache Miss
        LocalDataSource-->>ProductRepository: null
        
        Note over ProductRepository: Try backend (primary)
        ProductRepository->>BackendDataSource: scanProduct(barcode)
        BackendDataSource->>Backend: POST /scan {barcode}
        
        alt Backend Success
            Backend->>OFF: GET /product/{barcode}
            OFF-->>Backend: Product data
            Backend->>Backend: Normalize ingredients
            Backend->>Backend: Classify risks
            Backend->>Backend: Cache decision
            Backend-->>BackendDataSource: ScanResponse
            BackendDataSource-->>ProductRepository: BackendScanResponse
            ProductRepository->>LocalDataSource: cacheProduct(product)
            ProductRepository-->>ProductBloc: Right(Product)
        else Backend Unavailable
            Backend-->>BackendDataSource: Error/Timeout
            
            Note over ProductRepository: Fallback to OFF
            ProductRepository->>RemoteDataSource: getProductByBarcode(barcode)
            RemoteDataSource->>OFF: GET /product/{barcode}
            OFF-->>RemoteDataSource: Product data
            RemoteDataSource-->>ProductRepository: ProductModel
            ProductRepository->>LocalDataSource: cacheProduct(product)
            ProductRepository-->>ProductBloc: Right(Product)
        end
    end
    
    ProductBloc-->>ScannerPage: ProductLoaded(product)
    ScannerPage->>User: Navigate to Results Page
    User->>User: View risk assessment
```

## Flow Description

1. **User Initiates Scan**: User taps scan button or points camera at barcode
2. **Scanner Processing**: ScannerBloc processes the barcode detection event
3. **Product Lookup**: ProductBloc receives the barcode and initiates lookup
4. **Cache Check**: Repository first checks local SQLite cache
5. **Backend Request**: If no cache, tries SafeEats backend (primary source)
6. **Backend Processing**: Backend fetches from Open Food Facts, normalizes, classifies, caches
7. **Fallback**: If backend fails, falls back to direct Open Food Facts API call
8. **Display Results**: Product with risk assessment shown to user