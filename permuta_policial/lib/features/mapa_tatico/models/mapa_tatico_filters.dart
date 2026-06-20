import '../utils/mapa_tatico_type_constants.dart';



class MapaTaticoFilters {

  final Set<String> types;

  final bool onlyMine;

  final double? maxDistanceMeters;

  final int? expiringWithinHours;



  const MapaTaticoFilters({

    this.types = const {},

    this.onlyMine = false,

    this.maxDistanceMeters,

    this.expiringWithinHours,

  });



  bool get hasActiveFilters =>

      types.isNotEmpty ||

      onlyMine ||

      maxDistanceMeters != null ||

      expiringWithinHours != null;



  MapaTaticoFilters copyWith({

    Set<String>? types,

    bool? onlyMine,

    double? maxDistanceMeters,

    bool clearMaxDistance = false,

    int? expiringWithinHours,

    bool clearExpiring = false,

  }) {

    return MapaTaticoFilters(

      types: types ?? this.types,

      onlyMine: onlyMine ?? this.onlyMine,

      maxDistanceMeters:

          clearMaxDistance ? null : (maxDistanceMeters ?? this.maxDistanceMeters),

      expiringWithinHours:

          clearExpiring ? null : (expiringWithinHours ?? this.expiringWithinHours),

    );

  }



  static Set<String> typesForMapTab(String mapType) {

    switch (mapType) {

      case 'LOGISTICS':

        return {...logisticsPointTypes, ...healthPointTypes};

      case 'NATIONAL':

        return nationalPointTypes.toSet();

      case 'OPERATIONAL':

      default:

        return {...operationalPointTypes, ...healthPointTypes};

    }

  }

}


