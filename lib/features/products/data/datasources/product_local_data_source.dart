import 'package:drift/drift.dart';
import 'package:flutter_playground/core/database/app_database.dart' as db;
import 'package:flutter_playground/features/products/data/models/product_model.dart';

class ProductLocalDataSource {
  final db.AppDatabase _db;

  ProductLocalDataSource(this._db);

  Stream<List<db.Product>> watchAllProducts() => _db.select(_db.products).watch();

  Future<void> insertAll(List<ProductModel> models) async {
    for (final m in models) {
      final companion = m.toCompanion();
      await _db.into(_db.products).insert(
        companion,
        onConflict: DoUpdate(
          (_) => companion,
          target: [_db.products.remoteId],
        ),
      );
    }
  }

  Future<db.Product> getById(int id) {
    return (_db.select(_db.products)..where((p) => p.internalId.equals(id))).getSingle();
  }
}
