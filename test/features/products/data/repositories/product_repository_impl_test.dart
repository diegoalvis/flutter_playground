import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_playground/core/database/app_database.dart' as db;
import 'package:flutter_playground/features/products/data/datasources/product_local_data_source.dart';
import 'package:flutter_playground/features/products/data/datasources/product_remote_data_source.dart';
import 'package:flutter_playground/features/products/data/models/product_model.dart';
import 'package:flutter_playground/features/products/data/repositories/product_repository_impl.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';

class MockRemoteDataSource extends Mock implements ProductRemoteDataSource {}
class MockLocalDataSource extends Mock implements ProductLocalDataSource {}

void main() {
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  late ProductRepositoryImpl repository;

  const tModel = ProductModel(
    id: 1,
    title: 'Test',
    price: 9.99,
    description: 'Desc',
    thumbnail: 'https://example.com/img.jpg',
  );

  final tDriftData = db.Product(
    internalId: 1,
    remoteId: 1,
    title: 'Test',
    price: 9.99,
    description: 'Desc',
    thumbnail: 'https://example.com/img.jpg',
  );

  const tProduct = Product(
    id: 1,
    title: 'Test',
    price: 9.99,
    description: 'Desc',
    thumbnail: 'https://example.com/img.jpg',
  );

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    repository = ProductRepositoryImpl(mockRemote, mockLocal);
  });

  group('getProducts', () {
    test('triggers sync and returns stream of entities from local', () async {
      when(() => mockRemote.fetchProducts())
          .thenAnswer((_) async => [tModel]);
      when(() => mockLocal.insertAll(any())).thenAnswer((_) async {});
      when(() => mockLocal.watchAllProducts())
          .thenAnswer((_) => Stream.value([tDriftData]));

      final stream = repository.getProducts();
      final result = await stream.first;

      expect(result, [tProduct]);
    });
  });

  group('getProductDetail', () {
    test('returns product entity from local datasource', () async {
      when(() => mockLocal.getById(1)).thenAnswer((_) async => tDriftData);

      final result = await repository.getProductDetail(1);

      expect(result, tProduct);
    });
  });

  group('syncProducts', () {
    test('fetches from remote and inserts into local', () async {
      when(() => mockRemote.fetchProducts())
          .thenAnswer((_) async => [tModel]);
      when(() => mockLocal.insertAll(any())).thenAnswer((_) async {});

      await repository.syncProducts();

      verify(() => mockRemote.fetchProducts()).called(1);
      verify(() => mockLocal.insertAll(any())).called(1);
    });
  });
}
