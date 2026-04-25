import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_playground/features/products/data/models/product_model.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';

void main() {
  const tJson = {
    'id': 1,
    'title': 'Essence Mascara',
    'price': 9.99,
    'description': 'A great mascara',
    'thumbnail': 'https://cdn.dummyjson.com/img.jpg',
  };

  const tModel = ProductModel(
    id: 1,
    title: 'Essence Mascara',
    price: 9.99,
    description: 'A great mascara',
    thumbnail: 'https://cdn.dummyjson.com/img.jpg',
  );

  const tProduct = Product(
    id: 1,
    title: 'Essence Mascara',
    price: 9.99,
    description: 'A great mascara',
    thumbnail: 'https://cdn.dummyjson.com/img.jpg',
  );

  test('fromJson parses all fields correctly', () {
    final result = ProductModel.fromJson(tJson);
    expect(result.id, 1);
    expect(result.title, 'Essence Mascara');
    expect(result.price, 9.99);
    expect(result.description, 'A great mascara');
    expect(result.thumbnail, 'https://cdn.dummyjson.com/img.jpg');
  });

  test('toEntity returns correct Product', () {
    expect(tModel.toEntity(), tProduct);
  });

  test('fromJson handles integer price field', () {
    final json = {...tJson, 'price': 10};
    final result = ProductModel.fromJson(json);
    expect(result.price, 10.0);
  });
}
