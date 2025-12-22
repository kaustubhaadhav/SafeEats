import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_history.dart';
import '../repositories/history_repository.dart';

class SaveScan {
  final HistoryRepository repository;

  SaveScan(this.repository);

  Future<Either<Failure, ScanHistory>> call(ScanHistory scan) async {
    return await repository.saveScan(scan);
  }
}