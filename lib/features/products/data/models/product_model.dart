import 'package:flutter_playground/features/products/domain/entities/product.dart';

class ProductModel {
  final int id;
  final String title;
  final double price;
  final String description;
  final String thumbnail;

  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.thumbnail,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as int,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        description: json['description'] as String,
        thumbnail: json['thumbnail'] as String,
      );

  Product toEntity() => Product(
        id: id,
        title: title,
        price: price,
        description: description,
        thumbnail: thumbnail,
      );
}
