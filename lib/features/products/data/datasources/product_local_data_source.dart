import 'package:drift/drift.dart';
import 'package:flutter_playground/core/database/app_database.dart' as db;
import 'package:flutter_playground/features/products/data/models/product_model.dart';

class ProductLocalDataSource {
  final db.AppDatabase _db;

  ProductLocalDataSource(this._db);

  Stream<List<db.Product>> watchAll() => _db.select(_db.products).watch();

  Future<void> insertAll(List<ProductModel> models) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.products,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<db.Product> getById(int id) {
    return (_db.select(_db.products)..where((p) => p.id.equals(id))).getSingle();
  }
}
