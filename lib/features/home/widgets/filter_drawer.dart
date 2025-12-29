import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_assesment_1/features/home/models/product_filter_model.dart';
import 'package:flutter_assesment_1/features/home/provider/product_provider.dart';
import 'package:flutter_assesment_1/features/home/provider/category_provider.dart';

class FilterDrawer extends ConsumerStatefulWidget {
  const FilterDrawer({super.key});

  @override
  ConsumerState<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends ConsumerState<FilterDrawer> {
  int? _selectedCategoryId;
  RangeValues _currentPriceRange = const RangeValues(0, 1000);
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  // Max price constraint for the slider (could be dynamic based on products, but static for now)
  static const double _maxSliderValue = 1000;

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(productFilterProvider);
    _selectedCategoryId = currentFilter.categoryId;

    double min = currentFilter.minPrice ?? 0;
    double max = currentFilter.maxPrice ?? _maxSliderValue;

    // Ensure values are within range
    if (min < 0) min = 0;
    if (max > _maxSliderValue) max = _maxSliderValue;
    if (min > max) min = max;

    _currentPriceRange = RangeValues(min, max);
    _minPriceController.text = min.toStringAsFixed(0);
    _maxPriceController.text = max.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final newFilter = ProductFilter(
      categoryId: _selectedCategoryId,
      minPrice: _currentPriceRange.start,
      maxPrice: _currentPriceRange.end,
      // Preserve title search if implemented elsewhere or add title field here too
      title: ref.read(productFilterProvider).title,
    );

    ref.read(productFilterProvider.notifier).state = newFilter;
    Navigator.pop(context); // Close drawer
  }

  void _resetFilter() {
    setState(() {
      _selectedCategoryId = null;
      _currentPriceRange = const RangeValues(0, _maxSliderValue);
      _minPriceController.text = '0';
      _maxPriceController.text = _maxSliderValue.toStringAsFixed(0);
    });

    // Apply reset immediately or wait for explicit Apply? Amazon usually allows explicit reset.
    // Let's just reset local state for now, user needs to click Apply.
    // Or we can reset global state too.
    // Let's reset purely local UI state first.
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _resetFilter,
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Price Range Section
                  const Text(
                    'Price Range',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _currentPriceRange,
                    min: 0,
                    max: _maxSliderValue,
                    divisions: 1000,
                    labels: RangeLabels(
                      '\$${_currentPriceRange.start.round()}',
                      '\$${_currentPriceRange.end.round()}',
                    ),
                    activeColor: Colors.black,
                    inactiveColor: Colors.grey[300],
                    onChanged: (RangeValues values) {
                      setState(() {
                        _currentPriceRange = values;
                        _minPriceController.text = values.start
                            .round()
                            .toString();
                        _maxPriceController.text = values.end
                            .round()
                            .toString();
                      });
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            prefixText: '\$',
                          ),
                          readOnly: true, // Controlled by slider for now
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('to'),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _maxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            prefixText: '\$',
                          ),
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Categories Section
                  const Text(
                    'Department',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  categoryState.when(
                    data: (categories) {
                      return Column(
                        children: [
                          RadioListTile<int?>(
                            value: null,
                            groupValue: _selectedCategoryId,
                            title: const Text('All Departments'),
                            activeColor: Colors.black,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setState(() {
                                _selectedCategoryId = val;
                              });
                            },
                          ),
                          ...categories.map((category) {
                            return RadioListTile<int?>(
                              value: category.id,
                              groupValue: _selectedCategoryId,
                              title: Text(category.name),
                              activeColor: Colors.black,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategoryId = val;
                                });
                              },
                            );
                          }),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (err, stack) =>
                        Text('Error loading categories: $err'),
                  ),
                ],
              ),
            ),

            // Footer with Apply Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _applyFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber, // Amazon-ish yellow/orange
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Show Results',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
