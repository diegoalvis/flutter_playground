import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_playground/features/products/domain/usecases/get_product_detail.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final GetProductDetail _getProductDetail;

  ProductDetailBloc(this._getProductDetail) : super(const ProductDetailInitial()) {
    on<LoadProductDetail>((event, emit) async {
      emit(const ProductDetailLoading());
      try {
        final product = await _getProductDetail(event.id);
        emit(ProductDetailLoaded(product: product));
      } catch (e) {
        emit(ProductDetailError(message: e.toString()));
      }
    });
  }
}
