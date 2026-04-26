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
