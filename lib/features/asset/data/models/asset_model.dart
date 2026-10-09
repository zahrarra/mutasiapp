// lib/features/asset/data/models/asset_model.dart
//
// Model data Aset untuk serialisasi dan deserialisasi JSON API Laravel.

import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/asset_status.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.id,
    required super.assetCode,
    required super.name,
    required super.category,
    required super.location,
    required super.pic,
    required super.status,
    required super.condition,
    super.serialNumber,
    required super.acquisitionYear,
    super.estimatedValue,
    super.hasActiveMutation,
    super.activeMutationTicket,
    super.history,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    // 1. Ekstraksi kategori
    final catMap = json['category'] as Map<String, dynamic>?;
    final category = AssetCategory(
      id:
          catMap?['id']?.toString() ??
          json['asset_category_id']?.toString() ??
          'cat_1',
      code: catMap?['code']?.toString() ?? 'TI',
      name: catMap?['name']?.toString() ?? 'Aset TI',
    );

    // 2. Ekstraksi lokasi
    final locMap = json['location'] as Map<String, dynamic>?;
    final location =
        locMap?['name']?.toString() ??
        (json['location'] is String ? json['location'] as String : null) ??
        'Kantor Pusat';

    // 3. Ekstraksi PIC
    final picObj = json['pic'] as Map<String, dynamic>?;
    final pic =
        picObj?['name']?.toString() ??
        (json['pic'] is String ? json['pic'] as String : null) ??
        '-';

    // 4. Ekstraksi status
    AssetStatus status = AssetStatus.available;
    final rawStatus = json['status']?.toString().toLowerCase();
    if (rawStatus != null) {
      if (rawStatus.contains('mutation') || rawStatus.contains('mutasi')) {
        status = AssetStatus.inMutation;
      } else if (rawStatus.contains('maintenance') ||
          rawStatus.contains('rusak')) {
        status = AssetStatus.maintenance;
      } else if (rawStatus.contains('disposed') ||
          rawStatus.contains('hapus')) {
        status = AssetStatus.disposed;
      }
    } else if (json['is_active'] == false) {
      status = AssetStatus.maintenance;
    }

    final acqYear =
        int.tryParse(
          json['acquisition_year']?.toString() ??
              json['acquisitionYear']?.toString() ??
              '',
        ) ??
        DateTime.now().year;

    final estValue = double.tryParse(
      json['estimated_value']?.toString() ??
          json['estimatedValue']?.toString() ??
          '',
    );

    return AssetModel(
      id: json['id']?.toString() ?? '',
      assetCode:
          json['asset_code']?.toString() ??
          json['assetCode']?.toString() ??
          '-',
      name: json['name']?.toString() ?? 'Aset',
      category: category,
      location: location,
      pic: pic,
      status: status,
      condition: json['condition']?.toString() ?? 'Baik',
      serialNumber: json['serial_number']?.toString(),
      acquisitionYear: acqYear,
      estimatedValue: estValue,
      hasActiveMutation: json['has_active_mutation'] as bool? ?? false,
      activeMutationTicket: json['active_mutation_ticket']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_code': assetCode,
      'name': name,
      'category': {
        'id': category.id,
        'code': category.code,
        'name': category.name,
      },
      'location': location,
      'pic': pic,
      'status': status.name,
      'condition': condition,
      'serial_number': serialNumber,
      'acquisition_year': acquisitionYear,
      'estimated_value': estimatedValue,
      'has_active_mutation': hasActiveMutation,
      'active_mutation_ticket': activeMutationTicket,
    };
  }
}
