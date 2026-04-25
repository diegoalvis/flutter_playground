import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';

class GetProducts {
  final ProductRepository repository;
  GetProducts(this.repository);
  Stream<List<Product>> call() => repository.getProducts();
}
