import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';

class GetProductDetail {
  final ProductRepository repository;
  GetProductDetail(this.repository);
  Future<Product> call(int id) => repository.getProductDetail(id);
}
