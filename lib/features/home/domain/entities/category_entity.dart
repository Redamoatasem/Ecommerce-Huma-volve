class CategoryEntity {
  final int id;
  final String name;
  final String image;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.image,
  });

  /// Virtual "All" category representing an unfiltered product query.
  static const CategoryEntity all = CategoryEntity(
    id: 0,
    name: 'All',
    image: '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryEntity(id: $id, name: $name)';
}
