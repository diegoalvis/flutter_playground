import 'package:equatable/equatable.dart';

abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductDetail extends ProductDetailEvent {
  final int id;
  const LoadProductDetail(this.id);

  @override
  List<Object?> get props => [id];
}
