import 'package:flutter/material.dart';

import '../models/map_point.dart';



Color markerColorForType(String type) {

  switch (type) {

    case 'ocorrencia_recente':

    case 'suspeito':

      return Colors.red;

    case 'local_interesse':

      return Colors.amber;

    case 'restaurante':

      return Colors.green;

    case 'padaria':

      return Colors.brown;

    case 'base':

      return Colors.blue;

    case 'hospital_trauma':

      return Colors.red.shade700;

    case 'hospital':

    case 'ubs':

    case 'upa':

      return Colors.white;

    case 'delegacia':

      return Colors.indigo;

    case 'posto_combustivel':

      return Colors.orange;

    case 'clube_tiro':

      return Colors.blueGrey;

    case 'unidade_pm':

      return Colors.teal;

    case 'estabelecimento_parceiro':

      return Colors.purple;

    default:

      return Colors.grey;

  }

}



Color markerColorForPointType(MapPoint p) => markerColorForType(p.type);



String markerEmojiForType(String type) {

  switch (type) {

    case 'suspeito':

      return '🏃';

    case 'ocorrencia_recente':

      return '❗';

    case 'local_interesse':

      return '📍';

    case 'restaurante':

      return '🍽';

    case 'padaria':

      return '🥖';

    case 'base':

      return '🛡';

    case 'hospital_trauma':

    case 'hospital':

    case 'ubs':

    case 'upa':

      return '➕';

    case 'delegacia':

      return '🏛';

    case 'posto_combustivel':

      return '⛽';

    case 'clube_tiro':

      return '🎯';

    case 'unidade_pm':

      return '🚓';

    case 'estabelecimento_parceiro':

      return '🤝';

    default:

      return '📍';

  }

}



String markerEmojiForPointType(MapPoint p) => markerEmojiForType(p.type);



String pointTypeLabel(String type) {

  switch (type) {

    case 'ocorrencia_recente':

      return 'Ocorrência Recente';

    case 'suspeito':

      return 'Suspeito';

    case 'local_interesse':

      return 'Local de Interesse';

    case 'restaurante':

      return 'Restaurante';

    case 'padaria':

      return 'Padaria';

    case 'base':

      return 'Base';

    case 'hospital_trauma':

      return 'Hospital — Trauma';

    case 'hospital':

      return 'Hospital';

    case 'ubs':

      return 'UBS';

    case 'upa':

      return 'UPA';

    case 'delegacia':

      return 'Delegacia';

    case 'posto_combustivel':

      return 'Posto de combustível autorizado';

    case 'clube_tiro':

      return 'Clube de tiro';

    case 'unidade_pm':

      return 'Unidade PM';

    case 'estabelecimento_parceiro':

      return 'Estabelecimento parceiro';

    default:

      return type;

  }

}



bool isPointExpiringSoon(MapPoint point, {Duration within = const Duration(hours: 24)}) {

  final expires = point.expiresAt;

  if (expires == null) return false;

  final now = DateTime.now();

  if (expires.isBefore(now)) return false;

  return expires.difference(now) <= within;

}



String formatExpiresLabel(DateTime? expiresAt) {

  if (expiresAt == null) return '';

  final now = DateTime.now();

  if (expiresAt.isBefore(now)) return 'Expirado';

  final diff = expiresAt.difference(now);

  if (diff.inDays > 0) return 'Expira em ${diff.inDays} dia(s)';

  if (diff.inHours > 0) return 'Expira em ${diff.inHours} h';

  return 'Expira em ${diff.inMinutes} min';

}


