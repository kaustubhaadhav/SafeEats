import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/carcinogen.dart';

abstract class CarcinogenRepository {
  Future<Either<Failure, List<Carcinogen>>> getAllCarcinogens();
  Future<Either<Failure, List<Carcinogen>>> getCarcinogensBySource(CarcinogenSource source);
  Future<Either<Failure, Carcinogen?>> getCarcinogenById(String id);
  Future<Either<Failure, List<Carcinogen>>> searchCarcinogens(String query);
}