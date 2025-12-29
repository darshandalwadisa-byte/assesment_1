import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_assesment_1/features/home/models/product_model.dart';
import 'package:flutter_assesment_1/features/home/provider/product_provider.dart';
import 'package:flutter_assesment_1/features/home/widgets/product_card.dart';

class CategoryProductsPage extends ConsumerWidget {
  final Category category;

  const CategoryProductsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsByCategoryProvider(category.id));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: productsState.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No products found in ${category.name}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(product: products[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
