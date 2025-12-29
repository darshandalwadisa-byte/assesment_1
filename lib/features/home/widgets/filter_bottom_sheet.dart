import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_assesment_1/features/home/models/product_filter_model.dart';
import 'package:flutter_assesment_1/features/home/provider/product_provider.dart';
import 'package:flutter_assesment_1/features/home/provider/category_provider.dart';
import 'package:flutter_assesment_1/features/home/models/product_model.dart'; // For Category model

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  final _titleController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final currentfilter = ref.read(productFilterProvider);
    _titleController.text = currentfilter.title ?? '';
    _minPriceController.text = currentfilter.minPrice?.toString() ?? '';
    _maxPriceController.text = currentfilter.maxPrice?.toString() ?? '';
    _selectedCategoryId = currentfilter.categoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final title = _titleController.text.trim().isEmpty
        ? null
        : _titleController.text.trim();
    final minPrice = double.tryParse(_minPriceController.text.trim());
    final maxPrice = double.tryParse(_maxPriceController.text.trim());

    final newFilter = ProductFilter(
      title: title,
      minPrice: minPrice,
      maxPrice: maxPrice,
      categoryId: _selectedCategoryId,
    );

    ref.read(productFilterProvider.notifier).state = newFilter;
    Navigator.pop(context);
  }

  void _clearFilter() {
    ref.read(productFilterProvider.notifier).state = const ProductFilter();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearFilter,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Search by Title',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Price',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Price',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          categoryState.when(
            data: (categories) {
              return DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map((Category category) {
                    return DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }),
                ],
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedCategoryId = newValue;
                  });
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _applyFilter,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
