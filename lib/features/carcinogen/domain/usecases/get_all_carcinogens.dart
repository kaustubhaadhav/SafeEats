import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/carcinogen.dart';
import '../repositories/carcinogen_repository.dart';

class GetAllCarcinogens {
  final CarcinogenRepository repository;

  GetAllCarcinogens(this.repository);

  Future<Either<Failure, List<Carcinogen>>> call() async {
    return await repository.getAllCarcinogens();
  }
}