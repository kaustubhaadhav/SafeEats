# State Diagram: ProductBloc

This diagram shows the state machine for the ProductBloc, which handles product loading and risk assessment.

```mermaid
stateDiagram-v2
    [*] --> ProductInitial
    
    ProductInitial --> ProductLoading: GetProduct(barcode)
    
    ProductLoading --> ProductLoaded: Success
    ProductLoading --> ProductError: Failure
    
    ProductLoaded --> ProductLoading: GetProduct(barcode)
    ProductLoaded --> ProductInitial: ClearProduct
    
    ProductError --> ProductLoading: GetProduct(barcode)
    ProductError --> ProductInitial: ClearProduct
    
    state ProductLoaded {
        [*] --> DisplayingProduct
        DisplayingProduct --> SavingToHistory: SaveScan
        SavingToHistory --> DisplayingProduct: SaveComplete
    }
    
    state ProductError {
        [*] --> ShowingError
        ShowingError: Display error message
        ShowingError: Offer retry option
    }
```

## State Descriptions

```mermaid
flowchart TB
    subgraph States
        Initial[ProductInitial<br/>Empty state, ready to scan]
        Loading[ProductLoading<br/>Fetching product data...]
        Loaded[ProductLoaded<br/>Product + risk assessment]
        Error[ProductError<br/>Error message]
    end
    
    subgraph Events
        GetProduct[GetProduct Event<br/>barcode: String]
        Clear[ClearProduct Event]
    end
    
    subgraph Transitions
        Initial -->|GetProduct| Loading
        Loading -->|"Either.Right(product)"| Loaded
        Loading -->|"Either.Left(failure)"| Error
        Loaded -->|GetProduct| Loading
        Loaded -->|Clear| Initial
        Error -->|GetProduct| Loading
        Error -->|Clear| Initial
    end
```

## Event-State Flow

```mermaid
sequenceDiagram
    participant UI as ProductResultPage
    participant Bloc as ProductBloc
    participant UseCase as GetProductByBarcode
    participant Carcinogen as CheckCarcinogens
    participant History as SaveScan
    
    Note over Bloc: State: ProductInitial
    
    UI->>Bloc: add(GetProduct(barcode))
    
    Note over Bloc: State: ProductLoading
    Bloc-->>UI: emit(ProductLoading)
    
    Bloc->>UseCase: execute(barcode)
    
    alt Success
        UseCase-->>Bloc: Right(Product)
        Bloc->>Carcinogen: execute(ingredients)
        Carcinogen-->>Bloc: Right(carcinogens)
        
        Note over Bloc: State: ProductLoaded
        Bloc-->>UI: emit(ProductLoaded(product, carcinogens))
        
        UI->>Bloc: add(SaveScanEvent)
        Bloc->>History: execute(ScanHistory)
        History-->>Bloc: Right(void)
        
    else Failure
        UseCase-->>Bloc: Left(Failure)
        
        Note over Bloc: State: ProductError
        Bloc-->>UI: emit(ProductError(message))
    end
```

## BLoC Implementation Details

### Events

```dart
// Base event class
abstract class ProductEvent extends Equatable {
  const ProductEvent();
}

// Get product by barcode
class GetProduct extends ProductEvent {
  final String barcode;
  const GetProduct(this.barcode);
  
  @override
  List<Object> get props => [barcode];
}

// Clear current product
class ClearProduct extends ProductEvent {
  const ClearProduct();
  
  @override
  List<Object> get props => [];
}
```

### States

```dart
// Base state class
abstract class ProductState extends Equatable {
  const ProductState();
}

// Initial empty state
class ProductInitial extends ProductState {
  const ProductInitial();
  
  @override
  List<Object> get props => [];
}

// Loading state
class ProductLoading extends ProductState {
  const ProductLoading();
  
  @override
  List<Object> get props => [];
}

// Loaded with product and risk assessment
class ProductLoaded extends ProductState {
  final Product product;
  final List<Carcinogen> detectedCarcinogens;
  final RiskLevel overallRisk;
  
  const ProductLoaded({
    required this.product,
    required this.detectedCarcinogens,
    required this.overallRisk,
  });
  
  @override
  List<Object> get props => [product, detectedCarcinogens, overallRisk];
}

// Error state
class ProductError extends ProductState {
  final String message;
  
  const ProductError(this.message);
  
  @override
  List<Object> get props => [message];
}
```

### BLoC Logic

```dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductByBarcode getProductByBarcode;
  final CheckIngredientsForCarcinogens checkIngredientsForCarcinogens;
  final SaveScan saveScan;

  ProductBloc({
    required this.getProductByBarcode,
    required this.checkIngredientsForCarcinogens,
    required this.saveScan,
  }) : super(const ProductInitial()) {
    on<GetProduct>(_onGetProduct);
    on<ClearProduct>(_onClearProduct);
  }

  Future<void> _onGetProduct(
    GetProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    
    // 1. Get product
    final productResult = await getProductByBarcode(event.barcode);
    
    await productResult.fold(
      (failure) async {
        emit(ProductError(_mapFailureToMessage(failure)));
      },
      (product) async {
        // 2. Check for carcinogens
        final ingredientNames = product.ingredients.map((i) => i.name).toList();
        final carcinogenResult = await checkIngredientsForCarcinogens(ingredientNames);
        
        await carcinogenResult.fold(
          (failure) async {
            emit(ProductError(_mapFailureToMessage(failure)));
          },
          (carcinogens) async {
            // 3. Calculate overall risk
            final overallRisk = _calculateOverallRisk(carcinogens);
            
            // 4. Emit loaded state
            emit(ProductLoaded(
              product: product,
              detectedCarcinogens: carcinogens,
              overallRisk: overallRisk,
            ));
            
            // 5. Save to history
            await _saveToHistory(product, carcinogens, overallRisk);
          },
        );
      },
    );
  }
}
```

## UI State Mapping

| State | UI Display |
|-------|------------|
| ProductInitial | Empty screen or scan prompt |
| ProductLoading | Loading spinner with message |
| ProductLoaded | Product details, ingredient list, risk indicators |
| ProductError | Error message with retry button |