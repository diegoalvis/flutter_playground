import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_playground/core/database/app_database.dart' as db;
import 'package:flutter_playground/features/products/domain/entities/product.dart';

class ProductModel extends Equatable {
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

  factory ProductModel.fromDriftData(db.Product data) => ProductModel(
        id: data.remoteId,
        title: data.title,
        price: data.price,
        description: data.description,
        thumbnail: data.thumbnail,
      );

  Product toEntity() => Product(
        id: id,
        title: title,
        price: price,
        description: description,
        thumbnail: thumbnail,
      );

  db.ProductsCompanion toCompanion() => db.ProductsCompanion(
        remoteId: Value(id),
        title: Value(title),
        price: Value(price),
        description: Value(description),
        thumbnail: Value(thumbnail),
      );

  @override
  List<Object?> get props => [id];
}
