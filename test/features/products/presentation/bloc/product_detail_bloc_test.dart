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
