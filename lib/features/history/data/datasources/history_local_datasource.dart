import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/scan_history_model.dart';

abstract class HistoryLocalDatasource {
  Future<List<ScanHistoryModel>> getScanHistory({int limit = 50, int offset = 0});
  Future<ScanHistoryModel?> getScanByBarcode(String barcode);
  Future<int> saveScan(ScanHistoryModel scan);
  Future<void> deleteScan(int id);
  Future<void> clearHistory();
  Future<int> getHistoryCount();
}

class HistoryLocalDatasourceImpl implements HistoryLocalDatasource {
  final Database database;
  
  static const String tableName = 'scan_history';

  HistoryLocalDatasourceImpl({required this.database});

  @override
  Future<List<ScanHistoryModel>> getScanHistory({int limit = 50, int offset = 0}) async {
    try {
      final results = await database.query(
        tableName,
        orderBy: 'scanned_at DESC',
        limit: limit,
        offset: offset,
      );
      
      return results.map((json) => ScanHistoryModel.fromJson(json)).toList();
    } catch (e) {
      throw CacheException('Failed to get scan history: $e');
    }
  }

  @override
  Future<ScanHistoryModel?> getScanByBarcode(String barcode) async {
    try {
      final results = await database.query(
        tableName,
        where: 'barcode = ?',
        whereArgs: [barcode],
        orderBy: 'scanned_at DESC',
        limit: 1,
      );
      
      if (results.isEmpty) return null;
      return ScanHistoryModel.fromJson(results.first);
    } catch (e) {
      throw CacheException('Failed to get scan by barcode: $e');
    }
  }

  @override
  Future<int> saveScan(ScanHistoryModel scan) async {
    try {
      // Check if product was scanned before
      final existing = await getScanByBarcode(scan.barcode);
      
      if (existing != null) {
        // Update existing record
        await database.update(
          tableName,
          scan.toJson()..remove('id'),
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        return existing.id!;
      } else {
        // Insert new record
        return await database.insert(
          tableName,
          scan.toJson()..remove('id'),
        );
      }
    } catch (e) {
      throw CacheException('Failed to save scan: $e');
    }
  }

  @override
  Future<void> deleteScan(int id) async {
    try {
      final count = await database.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count == 0) {
        throw CacheException('Scan not found with id: $id');
      }
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to delete scan: $e');
    }
  }

  @override
  Future<void> clearHistory() async {
    try {
      await database.delete(tableName);
    } catch (e) {
      throw CacheException('Failed to clear history: $e');
    }
  }

  @override
  Future<int> getHistoryCount() async {
    try {
      final result = await database.rawQuery('SELECT COUNT(*) as count FROM $tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw CacheException('Failed to get history count: $e');
    }
  }
}