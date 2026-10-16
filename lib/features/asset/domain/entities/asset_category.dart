// lib/features/asset/domain/entities/asset_category.dart
//
// Entity domain: AssetCategory.
// Sumber: PROJECT-SETUP.md, TECHNICAL-DESIGN.md.

class AssetCategory {
  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isActive;

  const AssetCategory({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.isActive = true,
  });

  AssetCategory copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    bool? isActive,
  }) {
    return AssetCategory(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^ code.hashCode ^ name.hashCode ^ isActive.hashCode;

  @override
  String toString() =>
      'AssetCategory(id: $id, code: $code, name: $name, active: $isActive)';
}
