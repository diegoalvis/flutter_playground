import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_products.dart';
import 'package:flutter_playground/features/products/domain/usecases/sync_products.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_product_detail.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_playground/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_playground/main.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  testWidgets('App smoke test — renders without crashing', (WidgetTester tester) async {
    final repo = MockProductRepository();

    when(() => repo.getProducts()).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => ProductListBloc(GetProducts(repo), SyncProducts(repo)),
          ),
          BlocProvider(
            create: (_) => ProductDetailBloc(GetProductDetail(repo)),
          ),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(MyApp), findsOneWidget);
  });
}
