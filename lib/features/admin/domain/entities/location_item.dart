// lib/features/admin/domain/entities/location_item.dart
//
// Entity domain: Lokasi & Unit Kerja Master.
// Sumber: PRD.md §5, ROLE-FLOW.md §2.

class LocationItem {
  final String id;
  final String name;
  final String? description;
  final bool isBranch;
  final bool isActive;

  const LocationItem({
    required this.id,
    required this.name,
    this.description,
    this.isBranch = false,
    this.isActive = true,
  });

  LocationItem copyWith({
    String? id,
    String? name,
    String? description,
    bool? isBranch,
    bool? isActive,
  }) {
    return LocationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isBranch: isBranch ?? this.isBranch,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          isBranch == other.isBranch &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      isBranch.hashCode ^
      isActive.hashCode;

  @override
  String toString() =>
      'LocationItem(id: $id, name: $name, isBranch: $isBranch, active: $isActive)';
}
