import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_event.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_list_state.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_bloc.dart';
import 'package:flutter_playground/features/products/presentation/bloc/product_detail_event.dart';
import 'package:flutter_playground/features/products/presentation/widgets/product_card.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          if (state is ProductListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductListError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is ProductListLoaded) {
            if (state.products.isEmpty) {
              return const Center(child: Text('No products found.'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProductListBloc>().add(RefreshProducts());
              },
              child: ListView.builder(
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      context
                          .read<ProductDetailBloc>()
                          .add(LoadProductDetail(product.id));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductDetailPage(),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
