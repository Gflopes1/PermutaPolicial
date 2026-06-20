import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Busca rota OSRM (driving) entre dois pontos. Retorna lista vazia se falhar.
Future<List<LatLng>> fetchOsrmRoute({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) async {
  try {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$fromLng,$fromLat;$toLng,$toLat'
      '?overview=full&geometries=geojson',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return [];

    final geometry = routes.first['geometry'] as Map<String, dynamic>?;
    final coords = geometry?['coordinates'] as List<dynamic>?;
    if (coords == null) return [];

    return coords
        .map((c) {
          final pair = c as List<dynamic>;
          return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
        })
        .toList();
  } catch (_) {
    return [];
  }
}

Future<bool> openExternalNavigation({
  required double lat,
  required double lng,
  required String label,
  bool preferWaze = false,
}) async {
  final wazeUri = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');
  final googleUri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$label',
  );

  final primary = preferWaze ? wazeUri : googleUri;
  final fallback = preferWaze ? googleUri : wazeUri;

  if (await canLaunchUrl(primary)) {
    return launchUrl(primary, mode: LaunchMode.externalApplication);
  }
  if (await canLaunchUrl(fallback)) {
    return launchUrl(fallback, mode: LaunchMode.externalApplication);
  }
  return false;
}

Future<void> showNavigationChooser(
  BuildContext context, {
  required double lat,
  required double lng,
  required String label,
  double? fromLat,
  double? fromLng,
  void Function(List<LatLng> route)? onRouteLoaded,
}) async {
  // ignore: use_build_context_synchronously
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fromLat != null && fromLng != null && onRouteLoaded != null)
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Rota no mapa (OSRM)'),
              onTap: () async {
                Navigator.pop(ctx);
                final route = await fetchOsrmRoute(
                  fromLat: fromLat,
                  fromLng: fromLng,
                  toLat: lat,
                  toLng: lng,
                );
                if (route.isNotEmpty) {
                  onRouteLoaded(route);
                }
              },
            ),
          ListTile(
            leading: const Icon(Icons.navigation),
            title: const Text('Waze'),
            onTap: () async {
              Navigator.pop(ctx);
              await openExternalNavigation(lat: lat, lng: lng, label: label, preferWaze: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Google Maps'),
            onTap: () async {
              Navigator.pop(ctx);
              await openExternalNavigation(lat: lat, lng: lng, label: label, preferWaze: false);
            },
          ),
        ],
      ),
    ),
  );
}
