import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductModel> getProductByBarcode(String barcode);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient apiClient;

  ProductRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProductModel> getProductByBarcode(String barcode) async {
    try {
      final response = await apiClient.get(
        '/product/$barcode',
        queryParameters: {
          'fields': 'code,product_name,product_name_en,brands,ingredients_text,ingredients_text_en,ingredients,image_url,image_front_url,image_front_small_url,nutriments,quantity,categories',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        if (data['status'] == 1 && data['product'] != null) {
          return ProductModel.fromJson(data['product'] as Map<String, dynamic>);
        } else {
          throw const NotFoundException('Product not found in Open Food Facts database');
        }
      } else {
        throw ServerException('Server returned status code: ${response.statusCode}');
      }
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch product: ${e.toString()}');
    }
  }
}