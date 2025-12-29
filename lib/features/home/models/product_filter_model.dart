class ProductFilter {
  final String? title;
  final double? minPrice;
  final double? maxPrice;
  final int? categoryId;
  final int? offset;
  final int? limit;

  const ProductFilter({
    this.title,
    this.minPrice,
    this.maxPrice,
    this.categoryId,
    this.offset,
    this.limit,
  });

  ProductFilter copyWith({
    String? title,
    double? minPrice,
    double? maxPrice,
    int? categoryId,
    int? offset,
    int? limit,
  }) {
    return ProductFilter(
      title: title ?? this.title,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      categoryId: categoryId ?? this.categoryId,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};
    if (title != null && title!.isNotEmpty) params['title'] = title;
    if (minPrice != null) params['price_min'] = minPrice;
    if (maxPrice != null) params['price_max'] = maxPrice;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (offset != null) params['offset'] = offset;
    if (limit != null) params['limit'] = limit;
    return params;
  }
}
