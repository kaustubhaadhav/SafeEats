# SafeEats Troubleshooting Log

This document captures all issues encountered during testing and build processes, along with their resolutions.

---

## Table of Contents

- [SafeEats Troubleshooting Log](#safeeats-troubleshooting-log)
  - [Table of Contents](#table-of-contents)
  - [Flutter Tests](#flutter-tests)
  - [Android APK Build](#android-apk-build)
  - [Python Backend Tests (pytest)](#python-backend-tests-pytest)
    - [Issue 1: Missing `httpx_mock` Fixture](#issue-1-missing-httpx_mock-fixture)
    - [Issue 2: SQLite "no such table: scan\_cache"](#issue-2-sqlite-no-such-table-scan_cache)
    - [Issue 3: SQLite Thread Safety Error](#issue-3-sqlite-thread-safety-error)
  - [Flutter-Backend Integration (10/10 Upgrade)](#flutter-backend-integration-1010-upgrade)
    - [Issue 4: Missing Required Parameter `backendDataSource`](#issue-4-missing-required-parameter-backenddatasource)
    - [Issue 5: Python Version Path Issues](#issue-5-python-version-path-issues)
    - [Issue 6: Unused Import Warning](#issue-6-unused-import-warning)
    - [Issue 7: Unused Catch Clause Warning](#issue-7-unused-catch-clause-warning)
    - [Issue 8: Named Dio Instances for Multiple APIs](#issue-8-named-dio-instances-for-multiple-apis)
  - [Summary of Fixes](#summary-of-fixes)
  - [Best Practices Identified](#best-practices-identified)

---

## Flutter Tests

**Status:** ✅ Passed (202 tests)

**Command:** `flutter test`

No issues encountered. All 202 tests passed successfully.

---

## Android APK Build

**Status:** ✅ Success

**Command:** `flutter build apk --release`

**Output:**
- APK Location: `build/app/outputs/flutter-apk/app-release.apk`
- APK Size: 65.5MB
- Font optimization: MaterialIcons-Regular.otf reduced from 1.6MB to 7.3KB (99.6% reduction)

No issues encountered during the build process.

---

## Python Backend Tests (pytest)

### Issue 1: Missing `httpx_mock` Fixture

**Error Message:**
```
fixture 'httpx_mock' not found
available fixtures: _class_scoped_runner, _function_scoped_runner, ...
```

**Root Cause:**
The `pytest-httpx` package was installed globally but the tests were running with a different Python version (3.13) that didn't have the package in its path.

**Resolution:**
Installed `pytest-httpx` directly using the Python 3.13 pip:
```bash
/Library/Frameworks/Python.framework/Versions/3.13/bin/pip3 install pytest-httpx
```

**Lesson Learned:**
When using specific Python versions, ensure all required packages are installed for that specific version's environment.

---

### Issue 2: SQLite "no such table: scan_cache"

**Error Message:**
```
sqlite3.OperationalError: no such table: scan_cache
```

**Affected Tests:**
- `TestScanEndpoint.test_product_not_found_returns_404`
- `TestScanEndpoint.test_open_food_facts_api_error_returns_502`
- `TestScanResponseFormat.test_successful_scan_response_format`

**Root Cause:**
The test database was using a shared in-memory SQLite database (`file::memory:?cache=shared`), but each new connection to this database started fresh when all connections were closed. The data and schema were not persisting between the `init_db()` call in the fixture and the actual test execution.

**Initial Attempted Solution:**
Modified [`backend/db.py`](../backend/db.py) to use a module-level connection holder:
```python
_test_connection: Optional[sqlite3.Connection] = None

def get_connection() -> sqlite3.Connection:
    global _test_connection
    if os.environ.get("TESTING") == "1":
        if _test_connection is None:
            _test_connection = sqlite3.connect(":memory:")
            _test_connection.row_factory = sqlite3.Row
        return _test_connection
    # ...
```

This approach led to Issue 3.

---

### Issue 3: SQLite Thread Safety Error

**Error Message:**
```
sqlite3.ProgrammingError: SQLite objects created in a thread can only be used in that same thread. 
The object was created in thread id 8474324032 and this is thread id 6173683712.
```

**Root Cause:**
SQLite connections cannot be shared across threads by default. The FastAPI `TestClient` uses `anyio` which runs in a different thread than the pytest fixture. When the test tried to close or reuse the connection created in one thread from another thread, SQLite raised this error.

**Final Solution:**
Changed from in-memory database to a file-based temporary database with `check_same_thread=False`:

**File:** [`backend/db.py`](../backend/db.py)

```python
import tempfile

# Test database path (temporary file for cross-thread access)
_test_db_path: Optional[str] = None

def get_connection() -> sqlite3.Connection:
    global _test_db_path
    
    if os.environ.get("TESTING") == "1":
        # Use a file-based database for tests to allow cross-thread access
        if _test_db_path is None:
            # Create a temporary database file
            fd, _test_db_path = tempfile.mkstemp(suffix=".db")
            os.close(fd)
        conn = sqlite3.connect(_test_db_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        return conn
    else:
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        return conn

def init_db() -> None:
    global _test_db_path
    
    # Reset test database for each test
    if os.environ.get("TESTING") == "1":
        if _test_db_path is not None:
            try:
                os.remove(_test_db_path)
            except OSError:
                pass
            _test_db_path = None
    
    conn = get_connection()
    try:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS scan_cache (...)
        """)
        conn.commit()
    finally:
        conn.close()  # Always close connections now
```

**Key Changes:**
1. Used `tempfile.mkstemp()` to create a temporary database file instead of in-memory database
2. Added `check_same_thread=False` to allow cross-thread access
3. Properly close connections after each use (no need to keep one alive)
4. Delete and recreate the temp database file for each test to ensure isolation

**Final Result:** All 54 pytest tests passed successfully.

---

## Flutter-Backend Integration (10/10 Upgrade)

This section documents issues encountered while wiring the Flutter app to use the SafeEats backend as the primary data source.

### Issue 4: Missing Required Parameter `backendDataSource`

**Error Message:**
```
The named parameter 'backendDataSource' is required, but there's no corresponding argument.
```

**Affected Files:**
- `lib/injection_container.dart:106`

**Root Cause:**
When creating the new `ProductRepositoryImpl` that uses `ProductBackendDataSource` as primary and `ProductRemoteDataSource` (Open Food Facts) as fallback, the dependency injection configuration was not updated to pass the new required parameter.

**Resolution:**
Updated `injection_container.dart` to include `backendDataSource`:

```dart
// Before
sl.registerLazySingleton<ProductRepository>(
  () => ProductRepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
    networkInfo: sl(),
  ),
);

// After
sl.registerLazySingleton<ProductRepository>(
  () => ProductRepositoryImpl(
    backendDataSource: sl(),  // Added
    remoteDataSource: sl(),
    localDataSource: sl(),
    networkInfo: sl(),
  ),
);
```

**Lesson Learned:**
When adding new dependencies to a class, always update the DI container immediately.

---

### Issue 5: Python Version Path Issues

**Error Message:**
```
/usr/local/bin/activate:5: bad pattern: n^A^@H\M-\tB(H\M-^M^E
/usr/local/bin/activate:1: command not found: u^A
```

**Root Cause:**
The system had a corrupted `/usr/local/bin/activate` file that was interfering with shell command execution. Additionally, multiple Python versions were installed (`python3` pointed to 3.12, but we needed 3.13).

**Initial Attempts:**
```bash
# Failed attempts
python3.13 -m pytest tests/ -v
/opt/homebrew/bin/python3.13 -m pytest tests/ -v
```

**Resolution:**
Found the correct Python 3.13 path using `which python3.13`:
```bash
/Library/Frameworks/Python.framework/Versions/3.13/bin/python3.13 -m pytest tests/ -v
```

**Final Command That Worked:**
```bash
/Library/Frameworks/Python.framework/Versions/3.13/bin/python3.13 -m pytest /Users/xaero/Downloads/SafeEats/backend/tests/ -v
```

**Lesson Learned:**
When encountering Python version issues, use `which` to find the exact path and use absolute paths to avoid shell script conflicts.

---

### Issue 6: Unused Import Warning

**Error Message:**
```
warning • Unused import: '../models/product_model.dart' • lib/features/product/data/datasources/product_backend_datasource.dart:3:8 • unused_import
```

**Root Cause:**
While creating `product_backend_datasource.dart`, the `ProductModel` import was included but not actually used (the datasource returns `BackendScanResponse`, not `ProductModel`).

**Resolution:**
Removed the unused import:

```dart
// Before
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/product_model.dart';
import '../models/backend_response_model.dart';

// After
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/backend_response_model.dart';
```

**Lesson Learned:**
Run `flutter analyze` after creating new files to catch unused imports early.

---

### Issue 7: Unused Catch Clause Warning

**Error Message:**
```
warning • The exception variable 'e' isn't used, so the 'catch' clause can be removed • lib/features/product/data/repositories/product_repository_impl.dart:59:35 • unused_catch_clause
```

**Root Cause:**
In the repository's error handling, the `NotFoundException` was caught with a variable `e` that was never used (we just called the fallback method).

**Resolution:**
Removed the unused variable from the catch clause:

```dart
// Before
} on NotFoundException catch (e) {
  // Backend returned 404, try falling back to Open Food Facts directly
  return _fallbackToOpenFoodFacts(barcode);
}

// After
} on NotFoundException {
  // Backend returned 404, try falling back to Open Food Facts directly
  return _fallbackToOpenFoodFacts(barcode);
}
```

**Lesson Learned:**
Only capture exception variables when you actually need to use them.

---

### Issue 8: Named Dio Instances for Multiple APIs

**Challenge:**
The Flutter app needed to connect to two different APIs:
1. SafeEats Backend (`http://localhost:8000`) - Primary
2. Open Food Facts (`https://world.openfoodfacts.org/api/v2`) - Fallback

**Problem:**
GetIt doesn't allow registering two instances of the same type without differentiation.

**Resolution:**
Used GetIt's `instanceName` parameter to register named instances:

```dart
// Backend Dio instance
sl.registerLazySingleton<Dio>(() => Dio(BaseOptions(
  baseUrl: backendUrl,
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
  headers: {
    'User-Agent': 'SafeEats - Food Carcinogen Scanner - Version 1.0',
    'Content-Type': 'application/json',
  },
)), instanceName: 'backend');

// Open Food Facts Dio instance
sl.registerLazySingleton<Dio>(() => Dio(BaseOptions(
  baseUrl: 'https://world.openfoodfacts.org/api/v2',
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
  headers: {
    'User-Agent': 'SafeEats - Food Carcinogen Scanner - Version 1.0',
  },
)), instanceName: 'openFoodFacts');

// API Clients
sl.registerLazySingleton<ApiClient>(
  () => ApiClient(sl<Dio>(instanceName: 'backend')),
  instanceName: 'backend',
);
sl.registerLazySingleton<ApiClient>(
  () => ApiClient(sl<Dio>(instanceName: 'openFoodFacts')),
  instanceName: 'openFoodFacts',
);

// Data sources use named instances
sl.registerLazySingleton<ProductBackendDataSource>(
  () => ProductBackendDataSourceImpl(apiClient: sl<ApiClient>(instanceName: 'backend')),
);
sl.registerLazySingleton<ProductRemoteDataSource>(
  () => ProductRemoteDataSourceImpl(apiClient: sl<ApiClient>(instanceName: 'openFoodFacts')),
);
```

**Lesson Learned:**
When a project needs multiple instances of the same type (e.g., multiple API clients), use named instances in DI to differentiate them.

---

## Summary of Fixes

| Issue | Root Cause | Solution |
|-------|------------|----------|
| Missing httpx_mock fixture | Package not installed for Python 3.13 | Install pytest-httpx for specific Python version |
| No such table: scan_cache | In-memory DB not persisting schema | Use file-based temp database |
| SQLite thread safety | Sharing connection across threads | Use `check_same_thread=False` with file-based DB |
| Missing backendDataSource param | DI not updated after class change | Add new parameter to DI registration |
| Python version path issues | Corrupted activate script | Use full absolute path to python3.13 |
| Unused import warning | Leftover import after refactor | Remove unused import |
| Unused catch clause | Exception variable not used | Remove variable from catch |
| Multiple API clients | GetIt single-type limitation | Use named instances with `instanceName` |

---

## Best Practices Identified

1. **Python Package Management:** When working with multiple Python versions, always verify packages are installed for the correct version.

2. **Test Database Isolation:** Use file-based temporary databases instead of in-memory databases when:
   - Tests run in multi-threaded environments
   - Multiple connections need to access the same data
   - The framework (like FastAPI TestClient) uses async operations

3. **SQLite Thread Safety:** Always use `check_same_thread=False` when SQLite connections might be accessed from different threads (common in async web frameworks).

4. **Test Cleanup:** Ensure test databases are properly reset between tests to prevent state leakage.

5. **Dependency Injection Updates:** When adding new required parameters to a class, immediately update the DI container to prevent compile errors.

6. **Named DI Instances:** Use `instanceName` in GetIt when registering multiple instances of the same type (e.g., multiple Dio clients for different APIs).

7. **Run Analyzer Frequently:** Run `flutter analyze` after each significant change to catch warnings early.

8. **Fallback Architecture:** When designing systems with external dependencies (APIs), always implement fallback mechanisms for resilience.

9. **Environment Variables for Config:** Use environment variables (like `BACKEND_URL`) to make deployments configurable without code changes:
   ```dart
   const String backendUrl = String.fromEnvironment(
     'BACKEND_URL',
     defaultValue: 'http://localhost:8000',
   );
   ```