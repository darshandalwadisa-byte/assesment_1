import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_assesment_1/core/utils/app_logger.dart';
import 'package:flutter_assesment_1/core/network/api_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/product_filter_model.dart';
import '../models/product_model.dart';

final productFilterProvider = StateProvider<ProductFilter>((ref) {
  return const ProductFilter();
});

class ProductNotifier extends AsyncNotifier<List<Product>> {
  int _offset = 0;
  final int _limit = 10;
  bool _hasMore = true;
  bool _isFetching = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<Product>> build() async {
    // Watch filter changes to auto-refresh and reset pagination
    final filter = ref.watch(productFilterProvider);
    _offset = 0;
    _hasMore = true;
    _isFetching = false;
    return _fetchProducts(filter, isInitialLoad: true);
  }

  Future<void> fetchNextPage() async {
    // Prevent multiple concurrent fetches or fetching when done/loading
    if (!_hasMore || state.isLoading || state.isRefreshing || _isFetching) {
      return;
    }

    _isFetching = true;
    final filter = ref.read(productFilterProvider);
    final nextOffset = _offset + _limit;

    try {
      // Pass a callback or just check return value to know if we hit end of server data
      final result = await _fetchProductsResult(filter, offset: nextOffset);

      final newProducts = result.products;
      final serverCount = result.serverCount;

      // If server returned fewer items than limit, we are at the end
      if (serverCount < _limit) {
        _hasMore = false;
      }

      if (newProducts.isEmpty && serverCount == 0) {
        _hasMore = false;
        _isFetching = false;
        return;
      }

      // Only update offset if we actually got data or moved forward (even if filtered out)
      // Actually we must update offset regardless if we got data from server, to avoid loop.
      _offset = nextOffset;

      if (newProducts.isNotEmpty) {
        final currentList = state.value ?? [];
        // Deduplicate just in case
        final currentIds = currentList.map((e) => e.id).toSet();
        final uniqueNew = newProducts
            .where((p) => !currentIds.contains(p.id))
            .toList();

        state = AsyncValue.data([...currentList, ...uniqueNew]);
      }
    } catch (e, stack) {
      AppLogger.error('Error fetching next page', e, stack);
    } finally {
      _isFetching = false;
    }
  }

  // Refactored to return metadata for pagination logic
  Future<({List<Product> products, int serverCount})> _fetchProductsResult(
    ProductFilter filter, {
    int? offset,
    bool isInitialLoad = false,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      const path = 'products/';
      final currentOffset = offset ?? _offset;

      final pagedFilter = filter.copyWith(offset: currentOffset, limit: _limit);

      final queryParams = pagedFilter.toQueryParameters();
      AppLogger.info(
        'Fetching products (offset: $currentOffset, limit: $_limit) with params: $queryParams',
      );

      final List<dynamic> data = await apiClient.get(
        path,
        queryParameters: queryParams,
      );
      var products = data.map((json) => Product.fromJson(json)).toList();

      // Client-side filtering check removed to rely on API parameters
      // if (filter.minPrice != null) { ... }

      return (products: products, serverCount: data.length);
    } catch (e, stack) {
      AppLogger.error('Error fetching products', e, stack);
      rethrow;
    }
  }

  // Legacy method for build() compatibility
  Future<List<Product>> _fetchProducts(
    ProductFilter filter, {
    int? offset,
    bool isInitialLoad = false,
  }) async {
    final result = await _fetchProductsResult(
      filter,
      offset: offset,
      isInitialLoad: isInitialLoad,
    );
    // For initial load, we also need to set _hasMore logic
    if (result.serverCount < _limit) {
      _hasMore = false;
    }
    return result.products;
  }

  Future<String?> uploadImage(String filePath) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      const path = 'files/upload';
      AppLogger.info('Uploading image: $filePath');

      final dynamic responseData = await apiClient.upload(
        path,
        filePath: filePath,
      );

      if (responseData != null) {
        AppLogger.info(
          'Image uploaded successfully: ${responseData['location']}',
        );
        return responseData['location'] as String?;
      }
    } catch (e, stack) {
      AppLogger.error('Image Upload Failed', e, stack);
    }
    return null;
  }

  Future<void> addProduct({
    required String title,
    required double price,
    required String description,
    required int categoryId,
    List<String>? images,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      const path = 'products/';
      final body = {
        "title": title,
        "price": price,
        "description": description,
        "categoryId": categoryId,
        "images": images ?? ["https://placehold.co/600x400"],
      };

      AppLogger.info('Adding product: $body');
      final dynamic responseData = await apiClient.post(path, data: body);

      AppLogger.info('Product added successfully: $responseData');
      // Refresh list to include new product (resets to page 1)
      await refresh();
    } catch (e, stack) {
      AppLogger.error('Error adding product', e, stack);
      rethrow;
    }
  }

  Future<void> updateProduct({
    required int id,
    required Map<String, dynamic> updates,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final path = 'products/$id';
      AppLogger.info('Updating product $id with: $updates');

      final dynamic responseData = await apiClient.put(path, data: updates);
      AppLogger.info('Product updated successfully: $responseData');

      // We could optimistically update state here, but simple refresh is safer
      // for guaranteeing consistency with server (e.g. if server modifies other fields)
      await refresh();
    } catch (e, stack) {
      AppLogger.error('Error updating product', e, stack);
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    final apiClient = ref.read(apiClientProvider);
    try {
      final path = 'products/$id';
      AppLogger.info('Deleting product $id');

      await apiClient.delete(path);
      AppLogger.info('Product deleted successfully');

      // Optimistic removal or refresh
      // Removing locally is faster and feels better
      if (state.value != null) {
        final currentList = state.value!;
        final newList = currentList.where((p) => p.id != id).toList();
        state = AsyncValue.data(newList);
      } else {
        await refresh();
      }
    } catch (e, stack) {
      if (e.toString().contains('EntityNotFoundError')) {
        AppLogger.warning('Product already deleted, removing locally');
        // Treat as success
        if (state.value != null) {
          final currentList = state.value!;
          final newList = currentList.where((p) => p.id != id).toList();
          state = AsyncValue.data(newList);
        }
        return;
      }
      AppLogger.error('Error deleting product', e, stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    // Reset to initial state
    _offset = 0;
    _hasMore = true;
    _isFetching = false;
    state = const AsyncValue.loading();
    final filter = ref.read(productFilterProvider);
    state = await AsyncValue.guard(
      () => _fetchProducts(filter, isInitialLoad: true),
    );
  }
}

final productProvider = AsyncNotifierProvider<ProductNotifier, List<Product>>(
  () {
    return ProductNotifier();
  },
);

final productsByCategoryProvider = FutureProvider.family<List<Product>, int>((
  ref,
  categoryId,
) async {
  final apiClient = ref.read(apiClientProvider);
  try {
    final path = 'categories/$categoryId/products';
    AppLogger.info('Fetching products for category $categoryId from: $path');

    final List<dynamic> data = await apiClient.get(path);
    return data.map((json) => Product.fromJson(json)).toList();
  } catch (e, stack) {
    AppLogger.error('Error fetching products by category', e, stack);
    rethrow;
  }
});
