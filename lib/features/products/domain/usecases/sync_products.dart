import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';

class SyncProducts {
  final ProductRepository repository;
  SyncProducts(this.repository);
  Future<void> call() => repository.syncProducts();
}
