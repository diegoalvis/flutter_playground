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
