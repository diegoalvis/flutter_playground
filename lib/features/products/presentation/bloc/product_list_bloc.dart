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
