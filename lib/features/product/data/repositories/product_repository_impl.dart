import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_datasource.dart';
import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
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
    if (await networkInfo.isConnected) {
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
    } else {
      return const Left(NetworkFailure('No internet connection. Please check your network and try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheProduct(Product product) async {
    try {
      await localDataSource.cacheProduct(ProductModel.fromEntity(product));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Product?>> getCachedProduct(String barcode) async {
    try {
      final product = await localDataSource.getCachedProduct(barcode);
      return Right(product);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}