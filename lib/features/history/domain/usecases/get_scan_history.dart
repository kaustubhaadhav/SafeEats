import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_history.dart';
import '../repositories/history_repository.dart';

class GetScanHistory {
  final HistoryRepository repository;

  GetScanHistory(this.repository);

  Future<Either<Failure, List<ScanHistory>>> call() async {
    return await repository.getScanHistory();
  }
}