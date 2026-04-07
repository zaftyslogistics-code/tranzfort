class LoadFilters {
  final String originCity;
  final String destinationCity;
  final String material;
  final String truckType;
  final String sortBy;

  const LoadFilters({
    this.originCity = '',
    this.destinationCity = '',
    this.material = '',
    this.truckType = '',
    this.sortBy = 'newest',
  });

  LoadFilters copyWith({
    String? originCity,
    String? destinationCity,
    String? material,
    String? truckType,
    String? sortBy,
  }) {
    return LoadFilters(
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      material: material ?? this.material,
      truckType: truckType ?? this.truckType,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  int get activeFilterCount {
    var count = 0;
    if (originCity.trim().isNotEmpty) count++;
    if (destinationCity.trim().isNotEmpty) count++;
    if (material.trim().isNotEmpty) count++;
    if (truckType.trim().isNotEmpty) count++;
    if (sortBy != 'newest') count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;
}
