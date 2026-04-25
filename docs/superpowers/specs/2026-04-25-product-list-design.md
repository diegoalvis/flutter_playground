# Product List App — Design Spec

**Date:** 2026-04-25
**Status:** Approved

---

## Overview

A Flutter app that fetches a product list from a remote API, persists it in a local SQLite database (Drift), and displays it across two screens. Bloc manages UI state. No DI container — dependencies are wired manually in `main.dart`.

---

## Architecture: Clean Architecture with Domain Layer

Three layers with strict dependency direction: `presentation → domain ← data`.

```
lib/
├── core/
│   └── network/dio_client.dart          # Dio instance, base URL, interceptors
│
└── features/products/
    ├── data/
    │   ├── datasources/
    │   │   ├── product_remote_datasource.dart   # Dio → dummyjson API
    │   │   └── product_local_datasource.dart    # Drift CRUD + stream
    │   ├── models/
    │   │   └── product_model.dart               # JSON ↔ Product entity mapping
    │   └── repositories/
    │       └── product_repository_impl.dart     # implements domain interface
    │
    ├── domain/
    │   ├── entities/
    │   │   └── product.dart                     # pure Dart, no framework deps
    │   ├── repositories/
    │   │   └── product_repository.dart          # abstract interface
    │   └── usecases/
    │       ├── get_products.dart
    │       └── get_product_detail.dart
    │
    └── presentation/
        ├── bloc/
        │   ├── product_list_bloc.dart
        │   └── product_detail_bloc.dart
        ├── pages/
        │   ├── product_list_page.dart
        │   └── product_detail_page.dart
        └── widgets/
            └── product_card.dart
```

---

## Domain Layer

### Entity: `Product`

Pure Dart class — no JSON, no Drift, no framework dependencies.

```
id: int
title: String
price: double
description: String
thumbnail: String  // image URL
```

### Repository Interface: `ProductRepository`

```dart
abstract class ProductRepository {
  Stream<List<Product>> getProducts();   // triggers sync internally, returns Drift stream
  Future<Product> getProductDetail(int id);
}
```

### Use Cases

- `GetProducts` — returns `Stream<List<Product>>` from repository
- `GetProductDetail(int id)` — returns `Future<Product>` from repository

---

## Data Layer

### Remote Data Source

- Uses `Dio` with base URL `https://dummyjson.com`
- `GET /products?limit=10&skip=0&select=id,title,price,description,thumbnail`
- Returns list of `ProductModel` (parsed from JSON)

### Local Data Source

- Drift table: `Products` with columns matching the entity fields
- Exposes `Stream<List<ProductModel>> watchAll()` — reactive, auto-emits on DB change
- `Future<void> insertAll(List<ProductModel>)` — upsert on conflict by id
- `Future<ProductModel> getById(int id)`

### ProductModel

- Extends or wraps the domain `Product` entity
- `fromJson(Map<String, dynamic>)` for remote parsing
- `fromDrift(ProductsData)` for local mapping
- `toCompanion()` for Drift inserts

### RepositoryImpl: `ProductRepositoryImpl`

```
syncProducts():
  1. Fetch from RemoteDataSource
  2. Save all to LocalDataSource (upsert)

getProducts():
  1. Trigger syncProducts() in background (fire-and-forget)
  2. Return LocalDataSource.watchAll() stream

getProductDetail(id):
  Return LocalDataSource.getById(id)
```

---

## Presentation Layer

### Screens

**ProductListPage**
- On init: dispatches `LoadProducts` event
- Pull-to-refresh: dispatches `RefreshProducts` event
- Shows `ListView` of `ProductCard` widgets
- Tapping a card navigates to `ProductDetailPage(id)`

**ProductDetailPage**
- Receives product `id` via route argument
- On init: dispatches `LoadProductDetail(id)` event
- Shows full product info: thumbnail, title, price, description

### Bloc: `ProductListBloc`

Events: `LoadProducts`, `RefreshProducts`
States: `ProductListInitial`, `ProductListLoading`, `ProductListLoaded(List<Product>)`, `ProductListError(String)`

On `LoadProducts`:
1. Emit `ProductListLoading`
2. Subscribe to `GetProducts()` stream
3. On data → emit `ProductListLoaded`
4. On error → emit `ProductListError`

On `RefreshProducts`:
1. Call `RepositoryImpl.syncProducts()` directly — Drift stream auto-emits the updated data to the active subscription

### Bloc: `ProductDetailBloc`

Events: `LoadProductDetail(int id)`
States: `ProductDetailInitial`, `ProductDetailLoading`, `ProductDetailLoaded(Product)`, `ProductDetailError(String)`

On `LoadProductDetail(id)`:
1. Emit `ProductDetailLoading`
2. Await `GetProductDetail(id)`
3. Emit `ProductDetailLoaded` or `ProductDetailError`

---

## Dependency Wiring (`main.dart`)

```dart
void main() {
  final dio = DioClient().dio;
  final remoteDS = ProductRemoteDataSource(dio);
  final localDS = ProductLocalDataSource(AppDatabase());
  final repo = ProductRepositoryImpl(remoteDS, localDS);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ProductListBloc(GetProducts(repo), repo)),
        BlocProvider(create: (_) => ProductDetailBloc(GetProductDetail(repo))),
      ],
      child: MyApp(),
    ),
  );
}
```

---

## Key Packages

| Purpose | Package |
|---|---|
| State management | `flutter_bloc` |
| Local DB | `drift` + `drift_flutter` |
| HTTP client | `dio` |
| Code generation | `build_runner`, `drift_dev` |

---

## Git & GitHub

- Initialize a git repo at project root
- Create a `.gitignore` appropriate for Flutter
- Create a new public GitHub repo and push `main` branch

---

## Out of Scope

- Pagination (fixed 10 products from API)
- Product creation / editing / deletion
- Authentication
- Error retry logic beyond showing an error state
