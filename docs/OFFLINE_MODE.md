# Offline Mode & Caching Strategy

SafeEats is designed to work both online and offline, with intelligent caching to minimize network requests and provide a seamless user experience.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              ProductRepositoryImpl                   │    │
│  │  ┌────────────┐  ┌─────────────┐  ┌─────────────┐   │    │
│  │  │ NetworkInfo│  │LocalDataSrc │  │RemoteDataSrc│   │    │
│  │  │(connectivity)│  │  (SQLite)   │  │   (HTTP)    │   │    │
│  │  └────────────┘  └─────────────┘  └─────────────┘   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Caching Strategy: Cache-First with Network Fallback

### Request Flow

1. **Check Local Cache First**
   - Query SQLite for cached product by barcode
   - If found and not expired (< 24 hours), return immediately
   - If expired, delete from cache and proceed to step 2

2. **Check Network Connectivity**
   - Use `connectivity_plus` to detect WiFi/Mobile data
   - If no connection and no cache, return `NetworkFailure`

3. **Fetch from Remote**
   - Call backend `/scan` endpoint
   - On success, cache the response locally
   - Return the product to UI

### Code Flow

```dart
// ProductRepositoryImpl.getProductByBarcode()

// Step 1: Try cache first
final cachedProduct = await localDataSource.getCachedProduct(barcode);
if (cachedProduct != null) {
  return Right(cachedProduct);  // Cache hit! Return immediately
}

// Step 2: Check network
if (await networkInfo.isConnected) {
  // Step 3: Fetch from remote
  final product = await remoteDataSource.getProductByBarcode(barcode);
  await localDataSource.cacheProduct(product);  // Cache for later
  return Right(product);
} else {
  return Left(NetworkFailure('No internet connection'));
}
```

## Cache Configuration

| Setting | Value | Location |
|---------|-------|----------|
| Cache TTL | 24 hours | `ProductLocalDataSourceImpl.cacheDuration` |
| Database Name | `safeeats.db` | `injection_container.dart` |
| Table Name | `cached_products` | `injection_container.dart` |
| Conflict Strategy | Replace | `ProductLocalDataSourceImpl.cacheProduct()` |

## Database Schema

```sql
CREATE TABLE cached_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  barcode TEXT UNIQUE NOT NULL,
  product_data TEXT NOT NULL,     -- JSON serialized ProductModel
  cached_at TEXT NOT NULL         -- ISO8601 timestamp
)
```

## Offline Scenarios

### Scenario 1: Previous Scan Available
- User scans barcode they've scanned before
- Cache contains valid (< 24 hours) product data
- **Result**: Instant response from cache, no network needed

### Scenario 2: Previous Scan Expired
- User scans barcode they've scanned > 24 hours ago
- Cache entry is deleted
- **Result**: If online, fetches fresh data; if offline, shows error

### Scenario 3: New Barcode While Offline
- User scans new barcode with no internet
- No cache entry exists
- **Result**: Shows "No internet connection" error with retry option

### Scenario 4: Backend Unavailable
- Backend is down but device has internet
- **Result**: Shows "Server error" with retry option
- Previously cached products still work

## Why This Strategy?

### Benefits
1. **Fast**: Most scans return instantly from cache
2. **Offline-capable**: Previously scanned products always available
3. **Fresh enough**: 24-hour TTL ensures reasonably current data
4. **Simple**: No complex sync logic or conflict resolution

### Trade-offs
1. **First scan requires network**: New products need internet
2. **Stale window**: Data could be up to 24 hours old
3. **Storage growth**: Cache grows with each new scan (mitigated by `clearCache()`)

## Cache Management

### Clear All Cache
```dart
// Available in SettingsPage
await localDataSource.clearCache();
```

### Clear Specific Product
Not implemented (products auto-expire after 24 hours)

### View Cache Size
Not implemented (future enhancement)

## Network Detection

Uses `connectivity_plus` package:

```dart
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

**Note**: This checks for network interface availability, not actual internet connectivity. A device may report "connected" but still fail if:
- Behind a captive portal (airport WiFi)
- Firewall blocking the backend
- DNS resolution failing

## Backend Caching (Complementary)

The backend also caches scan results independently:

| Cache | Location | TTL | Purpose |
|-------|----------|-----|---------|
| Flutter | SQLite (device) | 24h | Offline access |
| Backend | SQLite (server) | 24h | Reduce Open Food Facts API calls |

Both caches are independent - the Flutter cache stores final results, while the backend cache stores processed scan responses.

## Future Improvements

1. **Prefetching**: Cache products from history on app launch
2. **Background sync**: Refresh expired cache when online
3. **Cache size limits**: LRU eviction when cache exceeds threshold
4. **Connectivity check**: Ping backend to verify actual connectivity
5. **Partial offline**: Show cached product info with "risk data unavailable" when rules update fails