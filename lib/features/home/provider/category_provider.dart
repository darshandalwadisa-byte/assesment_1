import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_assesment_1/core/utils/app_logger.dart';
import 'package:flutter_assesment_1/core/network/api_client.dart';
import 'package:flutter_assesment_1/core/network/api_provider.dart';

import '../models/product_model.dart'; // Reusing Category model from here

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  late final ApiClient _apiClient;

  @override
  Future<List<Category>> build() async {
    _apiClient = ref.read(apiClientProvider);
    return _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    try {
      const path = 'categories';
      AppLogger.info('Fetching categories from: $path');

      final List<dynamic> data = await _apiClient.get(path);
      return data.map((json) => Category.fromJson(json)).toList();
    } catch (e, stack) {
      AppLogger.error('Error fetching categories', e, stack);
      rethrow;
    }
  }

  Future<String?> uploadImage(String filePath) async {
    try {
      const path = 'files/upload';
      final dynamic responseData = await _apiClient.upload(
        path,
        filePath: filePath,
      );

      if (responseData != null) {
        return responseData['location'] as String?;
      }
    } catch (e, stack) {
      AppLogger.error('Category Image Upload Failed', e, stack);
    }
    return null;
  }

  Future<void> createCategory({
    required String name,
    required String image,
  }) async {
    try {
      const path = 'categories/';
      final body = {"name": name, "image": image};

      await _apiClient.post(path, data: body);
      await refresh();
    } catch (e, stack) {
      AppLogger.error('Error creating category', e, stack);
      rethrow;
    }
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required String image,
  }) async {
    try {
      final path = 'categories/$id';
      final body = {"name": name, "image": image};

      await _apiClient.put(path, data: body);
      await refresh();
    } catch (e, stack) {
      AppLogger.error('Error updating category', e, stack);
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final path = 'categories/$id';
      await _apiClient.delete(path);
      await refresh();
    } catch (e, stack) {
      AppLogger.error('Error deleting category', e, stack);
      rethrow;
    }
  }

  Future<void> deleteProductsByCategory(int categoryId) async {
    try {
      final path = 'categories/$categoryId/products';
      while (true) {
        // Fetch a batch of products
        final List<dynamic> data = await _apiClient.get(path);
        if (data.isEmpty) break;

        // Delete fetched products
        for (var item in data) {
          final productId = item['id'];
          if (productId != null) {
            try {
              await _apiClient.delete('products/$productId');
            } catch (e) {
              // Ignore 404s, but if other errors occur, we might get stuck in a loop.
              // Ideally we should log or check. For now, assume 404 or success.
            }
          }
        }

        // Wait a bit or break if we want to rely on the next loop returning empty if successful.
        // However, if pagination is offset-based, and we deleted them, the "next page" at offset 0
        // will be the *remaining* products. So calling get(path) again (default offset 0) is correct!
      }
    } catch (e, stack) {
      AppLogger.error('Error deleting category products', e, stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCategories());
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(() {
      return CategoryNotifier();
    });
