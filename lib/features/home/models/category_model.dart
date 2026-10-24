import '../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.image,
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

  CategoryEntity toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
