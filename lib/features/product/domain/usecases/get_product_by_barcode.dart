import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

class GetProductByBarcode {
  final ProductRepository repository;

  GetProductByBarcode(this.repository);

  Future<Either<Failure, Product>> call(String barcode) async {
    return await repository.getProductByBarcode(barcode);
  }
}