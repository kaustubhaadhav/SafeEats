import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/backend_response_model.dart';

/// Data source that connects to the SafeEats backend
/// instead of directly calling Open Food Facts.
abstract class ProductBackendDataSource {
  /// Scans a barcode through the backend, which handles:
  /// - Fetching from Open Food Facts
  /// - Ingredient normalization
  /// - Risk classification
  /// - Caching
  Future<BackendScanResponse> scanProduct(String barcode);
}

class ProductBackendDataSourceImpl implements ProductBackendDataSource {
  final ApiClient apiClient;

  ProductBackendDataSourceImpl({required this.apiClient});

  @override
  Future<BackendScanResponse> scanProduct(String barcode) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/scan',
        data: {'barcode': barcode},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          return BackendScanResponse.fromJson(data);
        } else {
          throw const ServerException('Empty response from backend');
        }
      } else if (response.statusCode == 400) {
        throw const InvalidBarcodeException('Invalid barcode format');
      } else if (response.statusCode == 404) {
        throw const NotFoundException('Product not found');
      } else if (response.statusCode == 422) {
        throw const NotFoundException('Product has no ingredient information');
      } else {
        throw ServerException('Backend returned status code: ${response.statusCode}');
      }
    } on NotFoundException {
      rethrow;
    } on InvalidBarcodeException {
      rethrow;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to scan product: ${e.toString()}');
    }
  }
}