class CategoryModel {
  final int id;
  final String name;
  final String image;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
  });

  /// Virtual "All" category representing an unfiltered product query.
  static const CategoryModel all = CategoryModel(id: 0, name: 'All', image: '');

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] as String?)?.trim() ?? 'Unknown',
      image: (json['image'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'image': image};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';
}
