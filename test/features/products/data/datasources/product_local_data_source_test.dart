import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_playground/core/database/app_database.dart' as db;
import 'package:flutter_playground/features/products/data/datasources/product_local_data_source.dart';
import 'package:flutter_playground/features/products/data/models/product_model.dart';

void main() {
  late db.AppDatabase database;
  late ProductLocalDataSource dataSource;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dataSource = ProductLocalDataSource(database);
  });

  tearDown(() => database.close());

  const tModel = ProductModel(
    id: 1,
    title: 'Test Product',
    price: 9.99,
    description: 'Desc',
    thumbnail: 'https://example.com/img.jpg',
  );

  test('insertAll and watchAll returns inserted products', () async {
    await dataSource.insertAll([tModel]);

    final result = await dataSource.watchAllProducts().first;
    expect(result.length, 1);
    expect(result.first.remoteId, 1);
    expect(result.first.title, 'Test Product');
  });

  test('insertAll upserts on conflict', () async {
    await dataSource.insertAll([tModel]);
    const updated = ProductModel(
      id: 1,
      title: 'Updated',
      price: 19.99,
      description: 'Updated desc',
      thumbnail: 'https://example.com/img2.jpg',
    );
    await dataSource.insertAll([updated]);

    final result = await dataSource.watchAllProducts().first;
    expect(result.length, 1);
    expect(result.first.title, 'Updated');
  });

  test('getById returns correct product', () async {
    await dataSource.insertAll([tModel]);

    final result = await dataSource.getById(1);
    expect(result.remoteId, 1);
    expect(result.title, 'Test Product');
  });
}
