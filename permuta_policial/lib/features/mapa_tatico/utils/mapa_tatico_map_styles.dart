enum MapaTaticoTileStyle {
  standard,
  dark,
  satellite,
}

extension MapaTaticoTileStyleX on MapaTaticoTileStyle {
  String get label {
    switch (this) {
      case MapaTaticoTileStyle.standard:
        return 'Padrão';
      case MapaTaticoTileStyle.dark:
        return 'Escuro';
      case MapaTaticoTileStyle.satellite:
        return 'Satélite';
    }
  }

  String get urlTemplate {
    switch (this) {
      case MapaTaticoTileStyle.standard:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapaTaticoTileStyle.dark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case MapaTaticoTileStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  List<String> get subdomains {
    if (this == MapaTaticoTileStyle.standard) {
      return const ['a', 'b', 'c'];
    }
    if (this == MapaTaticoTileStyle.dark) {
      return const ['a', 'b', 'c', 'd'];
    }
    return const [];
  }

  static MapaTaticoTileStyle fromStorage(String? value) {
    return MapaTaticoTileStyle.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MapaTaticoTileStyle.standard,
    );
  }
}
