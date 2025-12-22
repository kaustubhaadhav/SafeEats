import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/scan_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_datasource.dart';
import '../models/scan_history_model.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDatasource localDatasource;

  HistoryRepositoryImpl({required this.localDatasource});

  @override
  Future<Either<Failure, List<ScanHistory>>> getScanHistory() async {
    try {
      final history = await localDatasource.getScanHistory();
      return Right(history);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, ScanHistory>> saveScan(ScanHistory scan) async {
    try {
      final scanModel = ScanHistoryModel.fromEntity(scan);
      final id = await localDatasource.saveScan(scanModel);
      // Return the scan with the new ID
      final savedScan = ScanHistory(
        id: id,
        barcode: scan.barcode,
        productName: scan.productName,
        brand: scan.brand,
        imageUrl: scan.imageUrl,
        ingredients: scan.ingredients,
        detectedCarcinogenIds: scan.detectedCarcinogenIds,
        overallRiskLevel: scan.overallRiskLevel,
        scannedAt: scan.scannedAt,
      );
      return Right(savedScan);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteScan(int id) async {
    try {
      await localDatasource.deleteScan(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory() async {
    try {
      await localDatasource.clearHistory();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: $e'));
    }
  }
}