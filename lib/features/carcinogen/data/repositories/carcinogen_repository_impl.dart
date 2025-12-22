import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/carcinogen.dart';
import '../../domain/repositories/carcinogen_repository.dart';
import '../datasources/carcinogen_local_datasource.dart';

class CarcinogenRepositoryImpl implements CarcinogenRepository {
  final CarcinogenLocalDataSource localDataSource;

  CarcinogenRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Carcinogen>>> getAllCarcinogens() async {
    try {
      final carcinogens = await localDataSource.getAllCarcinogens();
      return Right(carcinogens);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Carcinogen>>> getCarcinogensBySource(
    CarcinogenSource source,
  ) async {
    try {
      final carcinogens = await localDataSource.getCarcinogensBySource(source);
      return Right(carcinogens);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Carcinogen?>> getCarcinogenById(String id) async {
    try {
      final carcinogen = await localDataSource.getCarcinogenById(id);
      return Right(carcinogen);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Carcinogen>>> searchCarcinogens(String query) async {
    try {
      final carcinogens = await localDataSource.searchCarcinogens(query);
      return Right(carcinogens);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}