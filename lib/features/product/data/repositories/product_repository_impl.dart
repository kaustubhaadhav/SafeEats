import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_backend_datasource.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

/// Repository implementation that uses backend as primary source
/// with fallback to Open Food Facts API.
class ProductRepositoryImpl implements ProductRepository {
  final ProductBackendDataSource backendDataSource;
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.backendDataSource,
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    // First, try to get from cache
    try {
      final cachedProduct = await localDataSource.getCachedProduct(barcode);
      if (cachedProduct != null) {
        return Right(cachedProduct);
      }
    } catch (_) {
      // Cache error, continue to try remote
    }

    // Check network connectivity
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection. Please check your network and try again.'));
    }

    // Try backend first (primary source)
    try {
      final response = await backendDataSource.scanProduct(barcode);
      final product = ProductModel.fromBackendResponse(response, barcode);
      
      // Cache the product for offline use
      try {
        await localDataSource.cacheProduct(product);
      } catch (_) {
        // Caching failed, but we still have the product
      }
      
      return Right(product);
    } on InvalidBarcodeException catch (e) {
      return Left(InvalidBarcodeFailure(e.message));
    } on NotFoundException {
      // Backend returned 404, try falling back to Open Food Facts directly
      return _fallbackToOpenFoodFacts(barcode);
    } on ServerException catch (_) {
      // Backend is unavailable, try fallback
      return _fallbackToOpenFoodFacts(barcode);
    } catch (_) {
      // Any other error, try fallback
      return _fallbackToOpenFoodFacts(barcode);
    }
  }

  /// Fallback to Open Food Facts API when backend is unavailable
  Future<Either<Failure, Product>> _fallbackToOpenFoodFacts(String barcode) async {
    try {
      final product = await remoteDataSource.getProductByBarcode(barcode);
      
      // Cache the product for offline use
      try {
        await localDataSource.cacheProduct(product);
      } catch (_) {
        // Caching failed, but we still have the product
      }
      
      return Right(product);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}