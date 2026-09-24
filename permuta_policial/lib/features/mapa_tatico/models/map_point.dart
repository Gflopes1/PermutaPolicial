// /lib/features/mapa_tatico/models/map_point.dart

import '../models/map_suspect_profile.dart';
import 'map_point_photo.dart';

enum MapType { operational, logistics }

enum MapPointVisibility { group, private }

MapPointVisibility mapPointVisibilityFromString(String? s) {
  if (s != null && s.toUpperCase() == 'PRIVATE') {
    return MapPointVisibility.private;
  }
  return MapPointVisibility.group;
}

extension MapPointVisibilityExtension on MapPointVisibility {
  String get value {
    switch (this) {
      case MapPointVisibility.group:
        return 'GROUP';
      case MapPointVisibility.private:
        return 'PRIVATE';
    }
  }
}

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
  final String? description;
  final double lat;
  final double lng;
  final String type;
  final String mapType;
  final MapPointVisibility visibility;
  final DateTime? expiresAt;
  final String? photoUrl;
  final List<MapPointPhoto> photos;
  final MapSuspectProfile? suspectProfile;
  final DateTime createdAt;
  final String? creatorNomeGuerra;
  final String? creatorNome;

  MapPoint({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.title,
    this.address,
    this.description,
    required this.lat,
    required this.lng,
    required this.type,
    required this.mapType,
    this.visibility = MapPointVisibility.group,
    this.expiresAt,
    this.photoUrl,
    this.photos = const [],
    this.suspectProfile,
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

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return MapPoint(
      id: parseInt(json['id']),
      groupId: parseInt(json['group_id']),
      creatorId: parseInt(json['creator_id']),
      title: json['title']?.toString() ?? '',
      address: json['address'] as String?,
      description: json['description'] as String?,
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      type: json['type']?.toString() ?? 'local_interesse',
      mapType: json['map_type']?.toString() ?? 'OPERATIONAL',
      visibility: mapPointVisibilityFromString(json['visibility'] as String?),
      expiresAt: parseDateTime(json['expires_at']),
      photoUrl: json['photo_url'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => MapPointPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      suspectProfile: json['suspect_profile'] != null
          ? MapSuspectProfile.fromJson(json['suspect_profile'] as Map<String, dynamic>)
          : null,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      creatorNomeGuerra: json['creator_nome_guerra'] as String?,
      creatorNome: json['creator_nome'] as String?,
    );
  }

  PointType get pointType => pointTypeFromString(type);
  MapType get mapTypeEnum => mapTypeFromString(mapType);

  String get creatorDisplay => creatorNomeGuerra ?? creatorNome ?? 'Desconhecido';

  bool get isPrivate => visibility == MapPointVisibility.private;
}
