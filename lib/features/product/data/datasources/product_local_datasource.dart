import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<ProductModel?> getCachedProduct(String barcode);
  Future<void> cacheProduct(ProductModel product);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final Database database;
  
  // Cache validity duration (24 hours)
  static const cacheDuration = Duration(hours: 24);

  ProductLocalDataSourceImpl({required this.database});

  @override
  Future<ProductModel?> getCachedProduct(String barcode) async {
    try {
      final results = await database.query(
        'cached_products',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );

      if (results.isEmpty) return null;

      final row = results.first;
      final cachedAt = DateTime.parse(row['cached_at'] as String);
      
      // Check if cache is still valid
      if (DateTime.now().difference(cachedAt) > cacheDuration) {
        // Cache expired, delete it
        await database.delete(
          'cached_products',
          where: 'barcode = ?',
          whereArgs: [barcode],
        );
        return null;
      }

      return ProductModel.fromJsonString(row['product_data'] as String);
    } catch (e) {
      throw CacheException('Failed to get cached product: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheProduct(ProductModel product) async {
    try {
      await database.insert(
        'cached_products',
        {
          'barcode': product.barcode,
          'product_data': product.toJsonString(),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache product: ${e.toString()}');
    }
  }
}