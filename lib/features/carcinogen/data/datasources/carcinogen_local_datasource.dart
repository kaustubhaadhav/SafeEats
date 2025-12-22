import 'package:sqflite/sqflite.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/carcinogen.dart';
import '../models/carcinogen_model.dart';

abstract class CarcinogenLocalDataSource {
  Future<List<CarcinogenModel>> getAllCarcinogens();
  Future<List<CarcinogenModel>> getCarcinogensBySource(CarcinogenSource source);
  Future<CarcinogenModel?> getCarcinogenById(String id);
  Future<List<CarcinogenModel>> searchCarcinogens(String query);
}

class CarcinogenLocalDataSourceImpl implements CarcinogenLocalDataSource {
  final Database database;

  CarcinogenLocalDataSourceImpl({required this.database});

  @override
  Future<List<CarcinogenModel>> getAllCarcinogens() async {
    try {
      final results = await database.query('carcinogens');
      return results.map((row) => CarcinogenModel.fromJson(row)).toList();
    } catch (e) {
      throw CacheException('Failed to get carcinogens: ${e.toString()}');
    }
  }

  @override
  Future<List<CarcinogenModel>> getCarcinogensBySource(CarcinogenSource source) async {
    try {
      final sourceString = source == CarcinogenSource.iarc ? 'IARC' : 'PROP65';
      final results = await database.query(
        'carcinogens',
        where: 'source = ?',
        whereArgs: [sourceString],
      );
      return results.map((row) => CarcinogenModel.fromJson(row)).toList();
    } catch (e) {
      throw CacheException('Failed to get carcinogens by source: ${e.toString()}');
    }
  }

  @override
  Future<CarcinogenModel?> getCarcinogenById(String id) async {
    try {
      final results = await database.query(
        'carcinogens',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) return null;
      return CarcinogenModel.fromJson(results.first);
    } catch (e) {
      throw CacheException('Failed to get carcinogen: ${e.toString()}');
    }
  }

  @override
  Future<List<CarcinogenModel>> searchCarcinogens(String query) async {
    try {
      final searchPattern = '%$query%';
      final results = await database.query(
        'carcinogens',
        where: 'name LIKE ? OR aliases LIKE ? OR description LIKE ?',
        whereArgs: [searchPattern, searchPattern, searchPattern],
      );
      return results.map((row) => CarcinogenModel.fromJson(row)).toList();
    } catch (e) {
      throw CacheException('Failed to search carcinogens: ${e.toString()}');
    }
  }
}