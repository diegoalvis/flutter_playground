import 'dart:async';

import 'package:flutter_playground/features/products/data/datasources/product_local_data_source.dart';
import 'package:flutter_playground/features/products/data/datasources/product_remote_data_source.dart';
import 'package:flutter_playground/features/products/data/models/product_model.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;

  ProductRepositoryImpl(this._remote, this._local);

  @override
  Stream<List<Product>> getProducts() {
    unawaited(_doSync()); // fire-and-forget
    return _local.watchAll().map(
          (items) => items.map(ProductModel.fromDriftData).map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<Product> getProductDetail(int id) async {
    final data = await _local.getById(id);
    return ProductModel.fromDriftData(data).toEntity();
  }

  @override
  Future<void> syncProducts() => _doSync();

  Future<void> _doSync() async {
    try {
      final models = await _remote.fetchProducts();
      await _local.insertAll(models);
    } catch (_) {
      // Local data remains available on network failure
    }
  }
}
