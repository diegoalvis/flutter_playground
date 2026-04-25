import 'package:flutter_playground/features/products/domain/entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> getProducts();
  Future<Product> getProductDetail(int id);
  Future<void> syncProducts();
}
