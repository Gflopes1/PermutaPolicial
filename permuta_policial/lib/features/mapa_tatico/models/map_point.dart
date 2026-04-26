// /lib/features/mapa_tatico/models/map_point.dart

enum MapType { operational, logistics }

enum PointType {
  ocorrenciaRecent,
  suspeito,
  localInteresse,
  restaurante,
  padaria,
  base,
}

MapType mapTypeFromString(String s) {
  return s.toUpperCase() == 'LOGISTICS' ? MapType.logistics : MapType.operational;
}

extension MapTypeExtension on MapType {
  String get value {
    switch (this) {
      case MapType.operational:
        return 'OPERATIONAL';
      case MapType.logistics:
        return 'LOGISTICS';
    }
  }
}

PointType pointTypeFromString(String s) {
  switch (s) {
    case 'ocorrencia_recente':
      return PointType.ocorrenciaRecent;
    case 'suspeito':
      return PointType.suspeito;
    case 'local_interesse':
      return PointType.localInteresse;
    case 'restaurante':
      return PointType.restaurante;
    case 'padaria':
      return PointType.padaria;
    case 'base':
      return PointType.base;
    default:
      return PointType.localInteresse;
  }
}

extension PointTypeExtension on PointType {
  String get value {
    switch (this) {
      case PointType.ocorrenciaRecent:
        return 'ocorrencia_recente';
      case PointType.suspeito:
        return 'suspeito';
      case PointType.localInteresse:
        return 'local_interesse';
      case PointType.restaurante:
        return 'restaurante';
      case PointType.padaria:
        return 'padaria';
      case PointType.base:
        return 'base';
    }
  }

  String get label {
    switch (this) {
      case PointType.ocorrenciaRecent:
        return 'Ocorrência Recente';
      case PointType.suspeito:
        return 'Suspeito';
      case PointType.localInteresse:
        return 'Local de Interesse';
      case PointType.restaurante:
        return 'Restaurante';
      case PointType.padaria:
        return 'Padaria';
      case PointType.base:
        return 'Base';
    }
  }

}

class MapPoint {
  final int id;
  final int groupId;
  final int creatorId;
  final String title;
  final String? address;
  final double lat;
  final double lng;
  final String type;
  final String mapType;
  final DateTime? expiresAt;
  final String? photoUrl;
  final DateTime createdAt;
  final String? creatorNomeGuerra;
  final String? creatorNome;

  MapPoint({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.title,
    this.address,
    required this.lat,
    required this.lng,
    required this.type,
    required this.mapType,
    this.expiresAt,
    this.photoUrl,
    required this.createdAt,
    this.creatorNomeGuerra,
    this.creatorNome,
  });

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return MapPoint(
      id: parseInt(json['id']),
      groupId: parseInt(json['group_id']),
      creatorId: parseInt(json['creator_id']),
      title: json['title'] as String,
      address: json['address'] as String?,
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      type: json['type'] as String,
      mapType: json['map_type'] as String,
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      creatorNomeGuerra: json['creator_nome_guerra'] as String?,
      creatorNome: json['creator_nome'] as String?,
    );
  }

  PointType get pointType => pointTypeFromString(type);
  MapType get mapTypeEnum => mapTypeFromString(mapType);

  String get creatorDisplay => creatorNomeGuerra ?? creatorNome ?? 'Desconhecido';
}
