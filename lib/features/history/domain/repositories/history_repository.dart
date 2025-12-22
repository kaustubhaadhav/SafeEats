import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/scan_history.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<ScanHistory>>> getScanHistory();
  Future<Either<Failure, ScanHistory>> saveScan(ScanHistory scan);
  Future<Either<Failure, void>> deleteScan(int id);
  Future<Either<Failure, void>> clearHistory();
}