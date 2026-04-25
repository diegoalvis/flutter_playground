# Product List App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter product list app with Clean Architecture, Bloc state management, Drift local DB, and Dio HTTP, displaying products from dummyjson.com across list and detail screens.

**Architecture:** Clean Architecture (domain/data/presentation). Remote data (Dio → dummyjson.com) is synced into a local Drift SQLite DB; Bloc subscribes to a reactive Drift stream as the single source of truth. Manual DI wiring in `main.dart` — no service locator.

**Tech Stack:** `flutter_bloc`, `bloc_concurrency`, `equatable`, `dio`, `drift`, `drift_flutter`, `build_runner`, `drift_dev`, `bloc_test`, `mocktail`

---

## File Map

```
lib/
├── core/
│   ├── database/
│   │   └── app_database.dart          # Drift table + AppDatabase
│   └── network/
│       └── dio_client.dart            # Dio singleton with base URL + interceptors
│
└── features/products/
    ├── data/
    │   ├── datasources/
    │   │   ├── product_remote_data_source.dart
    │   │   └── product_local_data_source.dart
    │   ├── models/
    │   │   └── product_model.dart     # JSON ↔ Drift ↔ entity conversions
    │   └── repositories/
    │       └── product_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── product.dart
    │   ├── repositories/
    │   │   └── product_repository.dart
    │   └── usecases/
    │       ├── get_products.dart
    │       ├── get_product_detail.dart
    │       └── sync_products.dart
    └── presentation/
        ├── bloc/
        │   ├── product_list_bloc.dart
        │   ├── product_list_event.dart
        │   ├── product_list_state.dart
        │   ├── product_detail_bloc.dart
        │   ├── product_detail_event.dart
        │   └── product_detail_state.dart
        ├── pages/
        │   ├── product_list_page.dart
        │   └── product_detail_page.dart
        └── widgets/
            └── product_card.dart

test/
└── features/products/
    ├── data/
    │   ├── models/product_model_test.dart
    │   ├── datasources/product_remote_data_source_test.dart
    │   ├── datasources/product_local_data_source_test.dart
    │   └── repositories/product_repository_impl_test.dart
    ├── domain/
    │   └── usecases/usecases_test.dart
    └── presentation/
        ├── bloc/product_list_bloc_test.dart
        └── bloc/product_detail_bloc_test.dart
```

---

### Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Update pubspec.yaml**

Replace the `dependencies` and `dev_dependencies` sections with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_bloc: ^8.1.6
  bloc_concurrency: ^0.2.5
  equatable: ^2.0.5
  dio: ^5.7.0
  drift: ^2.22.1
  drift_flutter: ^0.2.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  build_runner: ^2.4.13
  drift_dev: ^2.22.1
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

- [ ] **Step 2: Install dependencies**

```bash
flutter pub get
```

Expected: resolves without errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add flutter_bloc, dio, drift, mocktail dependencies"
```

---

### Task 2: Domain — Product entity

**Files:**
- Create: `lib/features/products/domain/entities/product.dart`
- Create: `test/features/products/domain/usecases/usecases_test.dart` (stub only here, expanded in Task 4)

- [ ] **Step 1: Write the failing test**

Create `test/features/products/domain/entities/product_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/products/domain/entities/product_test.dart
```

Expected: FAIL — `product.dart` not found.

- [ ] **Step 3: Create the entity**

Create `lib/features/products/domain/entities/product.dart`:

```dart
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String title;
  final double price;
  final String description;
  final String thumbnail;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.thumbnail,
  });

  @override
  List<Object?> get props => [id];
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/products/domain/entities/product_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/products/domain/entities/product.dart test/features/products/domain/entities/product_test.dart
git commit -m "feat: add Product domain entity"
```

---

### Task 3: Domain — Repository interface and use cases

**Files:**
- Create: `lib/features/products/domain/repositories/product_repository.dart`
- Create: `lib/features/products/domain/usecases/get_products.dart`
- Create: `lib/features/products/domain/usecases/get_product_detail.dart`
- Create: `lib/features/products/domain/usecases/sync_products.dart`
- Create: `test/features/products/domain/usecases/usecases_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/features/products/domain/usecases/usecases_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/products/domain/usecases/usecases_test.dart
```

Expected: FAIL — missing files.

- [ ] **Step 3: Create the repository interface**

Create `lib/features/products/domain/repositories/product_repository.dart`:

```dart
import 'package:flutter_playground/features/products/domain/entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> getProducts();
  Future<Product> getProductDetail(int id);
  Future<void> syncProducts();
}
```

- [ ] **Step 4: Create the use cases**

Create `lib/features/products/domain/usecases/get_products.dart`:

```dart
import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';

class GetProducts {
  final ProductRepository repository;
  GetProducts(this.repository);
  Stream<List<Product>> call() => repository.getProducts();
}
```

Create `lib/features/products/domain/usecases/get_product_detail.dart`:

```dart
import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';

class GetProductDetail {
  final ProductRepository repository;
  GetProductDetail(this.repository);
  Future<Product> call(int id) => repository.getProductDetail(id);
}
```

Create `lib/features/products/domain/usecases/sync_products.dart`:

```dart
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';

class SyncProducts {
  final ProductRepository repository;
  SyncProducts(this.repository);
  Future<void> call() => repository.syncProducts();
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/features/products/domain/usecases/usecases_test.dart
```

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/products/domain/ test/features/products/domain/
git commit -m "feat: add ProductRepository interface and use cases"
```

---

### Task 4: Data — ProductModel

**Files:**
- Create: `lib/features/products/data/models/product_model.dart`
- Create: `test/features/products/data/models/product_model_test.dart`

Note: `ProductModel.fromDriftData()` references the Drift-generated `ProductsData` class. The `app_database.dart` and its generated `app_database.g.dart` are created in Task 5. For now, we implement and test `fromJson` and `toEntity` only; `fromDriftData` and `toCompanion` are added in Task 5 after code-gen runs.

- [ ] **Step 1: Write the failing test**

Create `test/features/products/data/models/product_model_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/products/data/models/product_model_test.dart
```

Expected: FAIL — `product_model.dart` not found.

- [ ] **Step 3: Create ProductModel**

Create `lib/features/products/data/models/product_model.dart`:

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/products/data/models/product_model_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/products/data/models/product_model.dart test/features/products/data/models/product_model_test.dart
git commit -m "feat: add ProductModel with JSON parsing"
```

---

### Task 5: Data — Drift AppDatabase + ProductModel Drift methods

**Files:**
- Create: `lib/core/database/app_database.dart`
- Modify: `lib/features/products/data/models/product_model.dart`

- [ ] **Step 1: Create AppDatabase**

Create `lib/core/database/app_database.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get description => text()();
  TextColumn get thumbnail => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'products_db');
  }
}
```

- [ ] **Step 2: Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `lib/core/database/app_database.g.dart` without errors.

- [ ] **Step 3: Add Drift conversion methods to ProductModel**

Open `lib/features/products/data/models/product_model.dart` and add the following after the existing `toEntity()` method:

```dart
import 'package:flutter_playground/core/database/app_database.dart';
// add this import at the top of the file
```

Full updated file `lib/features/products/data/models/product_model.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_playground/core/database/app_database.dart';
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

  factory ProductModel.fromDriftData(ProductsData data) => ProductModel(
        id: data.id,
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

  ProductsCompanion toCompanion() => ProductsCompanion(
        id: Value(id),
        title: Value(title),
        price: Value(price),
        description: Value(description),
        thumbnail: Value(thumbnail),
      );
}
```

- [ ] **Step 4: Run all existing tests to ensure nothing broke**

```bash
flutter test test/features/products/data/models/product_model_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/ lib/features/products/data/models/product_model.dart
git commit -m "feat: add Drift AppDatabase and ProductModel Drift conversions"
```

---

### Task 6: Data — ProductLocalDataSource

**Files:**
- Create: `lib/features/products/data/datasources/product_local_data_source.dart`
- Create: `test/features/products/data/datasources/product_local_data_source_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/products/data/datasources/product_local_data_source_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_playground/core/database/app_database.dart';
import 'package:flutter_playground/features/products/data/datasources/product_local_data_source.dart';
import 'package:flutter_playground/features/products/data/models/product_model.dart';

void main() {
  late AppDatabase db;
  late ProductLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = ProductLocalDataSource(db);
  });

  tearDown(() => db.close());

  const tModel = ProductModel(
    id: 1,
    title: 'Test Product',
    price: 9.99,
    description: 'Desc',
    thumbnail: 'https://example.com/img.jpg',
  );

  test('insertAll and watchAll returns inserted products', () async {
    await dataSource.insertAll([tModel]);

    final result = await dataSource.watchAll().first;
    expect(result.length, 1);
    expect(result.first.id, 1);
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

    final result = await dataSource.watchAll().first;
    expect(result.length, 1);
    expect(result.first.title, 'Updated');
  });

  test('getById returns correct product', () async {
    await dataSource.insertAll([tModel]);

    final result = await dataSource.getById(1);
    expect(result.id, 1);
    expect(result.title, 'Test Product');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/products/data/datasources/product_local_data_source_test.dart
```

Expected: FAIL — `product_local_data_source.dart` not found.

- [ ] **Step 3: Create ProductLocalDataSource**

Create `lib/features/products/data/datasources/product_local_data_source.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter_playground/core/database/app_database.dart';
import 'package:flutter_playground/features/products/data/models/product_model.dart';

class ProductLocalDataSource {
  final AppDatabase _db;

  ProductLocalDataSource(this._db);

  Stream<List<ProductsData>> watchAll() => _db.select(_db.products).watch();

  Future<void> insertAll(List<ProductModel> models) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.products,
        models.map((m) => m.toCompanion()).toList(),
      );
    });
  }

  Future<ProductsData> getById(int id) {
    return (_db.select(_db.products)..where((p) => p.id.equals(id))).getSingle();
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/products/data/datasources/product_local_data_source_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/products/data/datasources/product_local_data_source.dart test/features/products/data/datasources/product_local_data_source_test.dart
git commit -m "feat: add ProductLocalDataSource with Drift"
```

---

### Task 7: Core — DioClient + Data — ProductRemoteDataSource

**Files:**
- Create: `lib/core/network/dio_client.dart`
- Create: `lib/features/products/data/datasources/product_remote_data_source.dart`
- Create: `test/features/products/data/datasources/product_remote_data_source_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/products/data/datasources/product_remote_data_source_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_playground/features/products/data/datasources/product_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProductRemoteDataSource dataSource;

  setUp(() {
    mockDio = MockDio();
    dataSource = ProductRemoteDataSource(mockDio);
  });

  final tResponseData = {
    'products': [
      {
        'id': 1,
        'title': 'Essence Mascara',
        'price': 9.99,
        'description': 'A great mascara',
        'thumbnail': 'https://cdn.dummyjson.com/img.jpg',
      }
    ]
  };

  test('fetchProducts returns list of ProductModel on success', () async {
    when(() => mockDio.get(
          '/products',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer(
      (_) async => Response(
        data: tResponseData,
        statusCode: 200,
        requestOptions: RequestOptions(path: '/products'),
      ),
    );

    final result = await dataSource.fetchProducts();

    expect(result.length, 1);
    expect(result.first.id, 1);
    expect(result.first.title, 'Essence Mascara');
  });

  test('fetchProducts throws when dio throws', () async {
    when(() => mockDio.get(
          '/products',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/products')),
    );

    expect(() => dataSource.fetchProducts(), throwsA(isA<DioException>()));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/products/data/datasources/product_remote_data_source_test.dart
```

Expected: FAIL — `product_remote_data_source.dart` not found.

- [ ] **Step 3: Create DioClient**

Create `lib/core/network/dio_client.dart`:

```dart
import 'package:dio/dio.dart';

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://dummyjson.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    dio.interceptors.add(LogInterceptor(responseBody: false));
  }
}
```

- [ ] **Step 4: Create ProductRemoteDataSource**

Create `lib/features/products/data/datasources/product_remote_data_source.dart`:

```dart
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
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/features/products/data/datasources/product_remote_data_source_test.dart
```

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/network/ lib/features/products/data/datasources/product_remote_data_source.dart test/features/products/data/datasources/product_remote_data_source_test.dart
git commit -m "feat: add DioClient and ProductRemoteDataSource"
```

---

### Task 8: Data — ProductRepositoryImpl

**Files:**
- Create: `lib/features/products/data/repositories/product_repository_impl.dart`
- Create: `test/features/products/data/repositories/product_repository_impl_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/products/data/repositories/product_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_playground/core/database/app_database.dart';
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

  final tDriftData = ProductsData(
    id: 1,
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
      when(() => mockLocal.watchAll())
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
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/products/data/repositories/product_repository_impl_test.dart
```

Expected: FAIL — `product_repository_impl.dart` not found.

- [ ] **Step 3: Create ProductRepositoryImpl**

Create `lib/features/products/data/repositories/product_repository_impl.dart`:

```dart
import 'package:flutter_playground/features/products/data/datasources/product_local_data_source.dart';
import 'package:flutter_playground/features/products/data/datasources/product_remote_data_source.dart';
import 'package:flutter_playground/features/products/data/models/product_model.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;

  ProductRepositoryImpl(this._remote, this._local);

  @override
  Stream<List<Product>> getProducts() {
    _doSync(); // fire-and-forget
    return _local.watchAll().map(
          (items) => items.map(ProductModel.fromDriftData).map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<Product> getProductDetail(int id) async {
    final data = await _local.getById(id);
    return ProductModel.fromDriftData(data).toEntity();
  }

  @override
  Future<void> syncProducts() => _doSync();

  Future<void> _doSync() async {
    try {
      final models = await _remote.fetchProducts();
      await _local.insertAll(models);
    } catch (_) {
      // Local data remains available on network failure
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/products/data/repositories/product_repository_impl_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/products/data/repositories/ test/features/products/data/repositories/
git commit -m "feat: add ProductRepositoryImpl with offline-first strategy"
```

---

### Task 9: Presentation — ProductListBloc

**Files:**
- Create: `lib/features/products/presentation/bloc/product_list_event.dart`
- Create: `lib/features/products/presentation/bloc/product_list_state.dart`
- Create: `lib/features/products/presentation/bloc/product_list_bloc.dart`
- Create: `test/features/products/presentation/bloc/product_list_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/products/presentation/bloc/product_list_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_products.dart';
import 'package:flutter_playground/features/products/domain/usecases/sync_products.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_event.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_state.dart';

class MockGetProducts extends Mock implements GetProducts {}
class MockSyncProducts extends Mock implements SyncProducts {}

const tProduct = Product(
  id: 1,
  title: 'Test',
  price: 9.99,
  description: 'Desc',
  thumbnail: 'https://example.com/img.jpg',
);

void main() {
  late MockGetProducts mockGetProducts;
  late MockSyncProducts mockSyncProducts;

  setUp(() {
    mockGetProducts = MockGetProducts();
    mockSyncProducts = MockSyncProducts();
  });

  blocTest<ProductListBloc, ProductListState>(
    'emits [loading, loaded] when LoadProducts succeeds',
    build: () {
      when(() => mockGetProducts())
          .thenAnswer((_) => Stream.fromIterable([[tProduct]]));
      return ProductListBloc(mockGetProducts, mockSyncProducts);
    },
    act: (bloc) => bloc.add(LoadProducts()),
    expect: () => [
      ProductListLoading(),
      ProductListLoaded(products: [tProduct]),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'emits [loading, error] when stream emits error',
    build: () {
      when(() => mockGetProducts())
          .thenAnswer((_) => Stream.error(Exception('network error')));
      return ProductListBloc(mockGetProducts, mockSyncProducts);
    },
    act: (bloc) => bloc.add(LoadProducts()),
    expect: () => [
      ProductListLoading(),
      isA<ProductListError>(),
    ],
  );

  blocTest<ProductListBloc, ProductListState>(
    'calls syncProducts when RefreshProducts is added',
    build: () {
      when(() => mockSyncProducts()).thenAnswer((_) async {});
      return ProductListBloc(mockGetProducts, mockSyncProducts);
    },
    act: (bloc) => bloc.add(RefreshProducts()),
    verify: (_) => verify(() => mockSyncProducts()).called(1),
    expect: () => [],
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/products/presentation/bloc/product_list_bloc_test.dart
```

Expected: FAIL — bloc files not found.

- [ ] **Step 3: Create events**

Create `lib/features/products/presentation/bloc/product_list_event.dart`:

```dart
abstract class ProductListEvent {}

class LoadProducts extends ProductListEvent {}

class RefreshProducts extends ProductListEvent {}
```

- [ ] **Step 4: Create states**

Create `lib/features/products/presentation/bloc/product_list_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';

abstract class ProductListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductListInitial extends ProductListState {}

class ProductListLoading extends ProductListState {}

class ProductListLoaded extends ProductListState {
  final List<Product> products;
  const ProductListLoaded({required this.products});

  @override
  List<Object?> get props => [products];
}

class ProductListError extends ProductListState {
  final String message;
  const ProductListError({required this.message});

  @override
  List<Object?> get props => [message];
}
```

- [ ] **Step 5: Create the Bloc**

Create `lib/features/products/presentation/bloc/product_list_bloc.dart`:

```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_products.dart';
import 'package:flutter_playground/features/products/domain/usecases/sync_products.dart';
import 'product_list_event.dart';
import 'product_list_state.dart';

class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final GetProducts _getProducts;
  final SyncProducts _syncProducts;

  ProductListBloc(this._getProducts, this._syncProducts)
      : super(ProductListInitial()) {
    on<LoadProducts>(
      (event, emit) async {
        emit(ProductListLoading());
        await emit.forEach(
          _getProducts(),
          onData: (products) => ProductListLoaded(products: products),
          onError: (e, _) => ProductListError(message: e.toString()),
        );
      },
      transformer: restartable(),
    );

    on<RefreshProducts>(
      (event, emit) async {
        await _syncProducts();
      },
      transformer: droppable(),
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
flutter test test/features/products/presentation/bloc/product_list_bloc_test.dart
```

Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/products/presentation/bloc/product_list_bloc.dart lib/features/products/presentation/bloc/product_list_event.dart lib/features/products/presentation/bloc/product_list_state.dart test/features/products/presentation/bloc/product_list_bloc_test.dart
git commit -m "feat: add ProductListBloc with stream subscription"
```

---

### Task 10: Presentation — ProductDetailBloc

**Files:**
- Create: `lib/features/products/presentation/bloc/product_detail_event.dart`
- Create: `lib/features/products/presentation/bloc/product_detail_state.dart`
- Create: `lib/features/products/presentation/bloc/product_detail_bloc.dart`
- Create: `test/features/products/presentation/bloc/product_detail_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/products/presentation/bloc/product_detail_bloc_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_product_detail.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_event.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_state.dart';

class MockGetProductDetail extends Mock implements GetProductDetail {}

const tProduct = Product(
  id: 1,
  title: 'Test',
  price: 9.99,
  description: 'Desc',
  thumbnail: 'https://example.com/img.jpg',
);

void main() {
  late MockGetProductDetail mockGetProductDetail;

  setUp(() => mockGetProductDetail = MockGetProductDetail());

  blocTest<ProductDetailBloc, ProductDetailState>(
    'emits [loading, loaded] when LoadProductDetail succeeds',
    build: () {
      when(() => mockGetProductDetail(1)).thenAnswer((_) async => tProduct);
      return ProductDetailBloc(mockGetProductDetail);
    },
    act: (bloc) => bloc.add(const LoadProductDetail(1)),
    expect: () => [
      ProductDetailLoading(),
      const ProductDetailLoaded(product: tProduct),
    ],
  );

  blocTest<ProductDetailBloc, ProductDetailState>(
    'emits [loading, error] when LoadProductDetail throws',
    build: () {
      when(() => mockGetProductDetail(1))
          .thenThrow(Exception('not found'));
      return ProductDetailBloc(mockGetProductDetail);
    },
    act: (bloc) => bloc.add(const LoadProductDetail(1)),
    expect: () => [
      ProductDetailLoading(),
      isA<ProductDetailError>(),
    ],
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/products/presentation/bloc/product_detail_bloc_test.dart
```

Expected: FAIL — bloc files not found.

- [ ] **Step 3: Create events**

Create `lib/features/products/presentation/bloc/product_detail_event.dart`:

```dart
import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProductDetail extends ProductDetailEvent {
  final int id;
  const LoadProductDetail(this.id);

  @override
  List<Object?> get props => [id];
}
```

- [ ] **Step 4: Create states**

Create `lib/features/products/presentation/bloc/product_detail_state.dart`:

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';

abstract class ProductDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoading extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final Product product;
  const ProductDetailLoaded({required this.product});

  @override
  List<Object?> get props => [product];
}

class ProductDetailError extends ProductDetailState {
  final String message;
  const ProductDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
```

- [ ] **Step 5: Create the Bloc**

Create `lib/features/products/presentation/bloc/product_detail_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_product_detail.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final GetProductDetail _getProductDetail;

  ProductDetailBloc(this._getProductDetail) : super(ProductDetailInitial()) {
    on<LoadProductDetail>((event, emit) async {
      emit(ProductDetailLoading());
      try {
        final product = await _getProductDetail(event.id);
        emit(ProductDetailLoaded(product: product));
      } catch (e) {
        emit(ProductDetailError(message: e.toString()));
      }
    });
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
flutter test test/features/products/presentation/bloc/product_detail_bloc_test.dart
```

Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/products/presentation/bloc/product_detail_bloc.dart lib/features/products/presentation/bloc/product_detail_event.dart lib/features/products/presentation/bloc/product_detail_state.dart test/features/products/presentation/bloc/product_detail_bloc_test.dart
git commit -m "feat: add ProductDetailBloc"
```

---

### Task 11: Presentation — Widgets and Pages

**Files:**
- Create: `lib/features/products/presentation/widgets/product_card.dart`
- Create: `lib/features/products/presentation/pages/product_list_page.dart`
- Create: `lib/features/products/presentation/pages/product_detail_page.dart`

- [ ] **Step 1: Create ProductCard widget**

Create `lib/features/products/presentation/widgets/product_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            product.thumbnail,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 56),
          ),
        ),
        title: Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
```

- [ ] **Step 2: Create ProductListPage**

Create `lib/features/products/presentation/pages/product_list_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_event.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_state.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_event.dart';
import 'package:flutter_playground/features/products/presentation/widgets/product_card.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          if (state is ProductListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductListError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is ProductListLoaded) {
            if (state.products.isEmpty) {
              return const Center(child: Text('No products found.'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProductListBloc>().add(RefreshProducts());
              },
              child: ListView.builder(
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      context
                          .read<ProductDetailBloc>()
                          .add(LoadProductDetail(product.id));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductDetailPage(),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Create ProductDetailPage**

Create `lib/features/products/presentation/pages/product_detail_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_state.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Detail'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is ProductDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductDetailError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is ProductDetailLoaded) {
            final product = state.product;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.thumbnail,
                        height: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 120),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/products/presentation/
git commit -m "feat: add ProductCard, ProductListPage, ProductDetailPage"
```

---

### Task 12: Wire up main.dart + final run

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Replace main.dart**

Replace the contents of `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_playground/core/database/app_database.dart';
import 'package:flutter_playground/core/network/dio_client.dart';
import 'package:flutter_playground/features/products/data/datasources/product_local_data_source.dart';
import 'package:flutter_playground/features/products/data/datasources/product_remote_data_source.dart';
import 'package:flutter_playground/features/products/data/repositories/product_repository_impl.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_product_detail.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_products.dart';
import 'package:flutter_playground/features/products/domain/usecases/sync_products.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_event.dart';
import 'package:flutter_playground/features/products/presentation/pages/product_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final dio = DioClient().dio;
  final db = AppDatabase();
  final remoteDS = ProductRemoteDataSource(dio);
  final localDS = ProductLocalDataSource(db);
  final repo = ProductRepositoryImpl(remoteDS, localDS);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ProductListBloc(GetProducts(repo), SyncProducts(repo))
                ..add(LoadProducts()),
        ),
        BlocProvider(
          create: (_) => ProductDetailBloc(GetProductDetail(repo)),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Products',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ProductListPage(),
    );
  }
}
```

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests PASS.

- [ ] **Step 3: Analyze for lint issues**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 4: Commit and push**

```bash
git add lib/main.dart
git commit -m "feat: wire up DI in main.dart and complete product list blueprint"
git push origin main
```

Expected: Push succeeds to `https://github.com/diegoalvis/flutter_playground`.
