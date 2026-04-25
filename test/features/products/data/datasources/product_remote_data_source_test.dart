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
