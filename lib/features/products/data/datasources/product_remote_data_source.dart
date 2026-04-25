import 'package:dio/dio.dart';
import 'package:flutter_playground/features/products/data/models/product_model.dart';

class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource(this._dio);

  Future<List<ProductModel>> fetchProducts() async {
    final response = await _dio.get(
      '/products',
      queryParameters: {
        'limit': 10,
        'skip': 0,
        'select': 'id,title,price,description,thumbnail',
      },
    );
    final products = response.data['products'] as List<dynamic>;
    return products
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
