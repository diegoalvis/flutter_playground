import 'package:equatable/equatable.dart';
import 'package:flutter_playground/features/products/domain/entities/product.dart';

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

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
