import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';

void main() {
  const tProduct = Product(
    id: 1,
    title: 'Test Product',
    price: 9.99,
    description: 'A test product',
    thumbnail: 'https://example.com/img.jpg',
  );

  test('two Products with same id are equal', () {
    const same = Product(
      id: 1,
      title: 'Different title',
      price: 0.0,
      description: '',
      thumbnail: '',
    );
    expect(tProduct, equals(same));
  });

  test('two Products with different ids are not equal', () {
    const other = Product(
      id: 2,
      title: 'Test Product',
      price: 9.99,
      description: 'A test product',
      thumbnail: 'https://example.com/img.jpg',
    );
    expect(tProduct, isNot(equals(other)));
  });
}
