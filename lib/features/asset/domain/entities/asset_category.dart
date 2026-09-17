// lib/features/asset/domain/entities/asset_category.dart
//
// Entity domain: AssetCategory.
// Sumber: PROJECT-SETUP.md, TECHNICAL-DESIGN.md.

class AssetCategory {
  final String id;
  final String code;
  final String name;
  final String? description;

  const AssetCategory({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ code.hashCode ^ name.hashCode;
}
