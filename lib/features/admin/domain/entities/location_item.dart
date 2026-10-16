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
  final bool? isAssignmentUnitExplicit;

  const LocationItem({
    required this.id,
    required this.name,
    this.description,
    this.isBranch = false,
    this.isActive = true,
    this.isAssignmentUnitExplicit,
  });

  /// Menentukan apakah lokasi ini merupakan unit penugasan resmi (divisi atau cabang),
  /// dan BUKAN fasilitas fisik aset (toilet, parkiran, lobby, lantai, ruang tunggu, dll.).
  bool get isAssignmentUnit {
    if (isAssignmentUnitExplicit != null) {
      return isAssignmentUnitExplicit!;
    }

    final code = (description ?? '').toUpperCase();
    final n = name.toLowerCase();

    // Eksklusi kode fasilitas umum, lantai gedung, dan dummy audit
    if (code.startsWith('UMUM-') || code.startsWith('LT-') || code.startsWith('AUD_')) {
      return false;
    }

    const physicalKeywords = [
      'toilet',
      'parkir',
      'lobby',
      'lantai',
      'ruang tunggu',
      'teller',
      'atm',
      'pantry',
      'mushola',
      'musholla',
      'ruang rapat',
      'gudang',
      'ruang server',
      'kantin',
      'pos satpam',
      'koridor',
      'taman',
    ];

    for (final kw in physicalKeywords) {
      if (n.contains(kw)) return false;
    }

    // Whitelist cabang atau divisi
    if (isBranch || code.startsWith('CAB-') || code.startsWith('RG-') || code.startsWith('DIV-')) {
      return true;
    }

    return n.contains('divisi') ||
        n.contains('cabang') ||
        n.contains('kcu') ||
        n.contains('siber');
  }

  LocationItem copyWith({
    String? id,
    String? name,
    String? description,
    bool? isBranch,
    bool? isActive,
    bool? isAssignmentUnitExplicit,
  }) {
    return LocationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isBranch: isBranch ?? this.isBranch,
      isActive: isActive ?? this.isActive,
      isAssignmentUnitExplicit:
          isAssignmentUnitExplicit ?? this.isAssignmentUnitExplicit,
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
