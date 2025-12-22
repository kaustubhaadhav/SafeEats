import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/history_repository.dart';

class DeleteScan {
  final HistoryRepository repository;

  DeleteScan(this.repository);

  Future<Either<Failure, void>> call(int id) async {
    return await repository.deleteScan(id);
  }
}