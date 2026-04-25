import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_products.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_product_detail.dart';
import 'package:flutter_playground/features/products/domain/usecases/sync_products.dart';

class MockProductRepository extends Mock implements ProductRepository {}

const tProduct = Product(
  id: 1,
  title: 'Test',
  price: 9.99,
  description: 'Desc',
  thumbnail: 'https://example.com/img.jpg',
);

void main() {
  late MockProductRepository mockRepo;

  setUp(() => mockRepo = MockProductRepository());

  group('GetProducts', () {
    test('returns stream from repository', () {
      when(() => mockRepo.getProducts())
          .thenAnswer((_) => Stream.value([tProduct]));

      final result = GetProducts(mockRepo)();

      expect(result, emits([tProduct]));
      verify(() => mockRepo.getProducts()).called(1);
    });
  });

  group('GetProductDetail', () {
    test('returns product by id from repository', () async {
      when(() => mockRepo.getProductDetail(1))
          .thenAnswer((_) async => tProduct);

      final result = await GetProductDetail(mockRepo)(1);

      expect(result, tProduct);
      verify(() => mockRepo.getProductDetail(1)).called(1);
    });
  });

  group('SyncProducts', () {
    test('calls repository syncProducts', () async {
      when(() => mockRepo.syncProducts()).thenAnswer((_) async {});

      await SyncProducts(mockRepo)();

      verify(() => mockRepo.syncProducts()).called(1);
    });
  });
}
