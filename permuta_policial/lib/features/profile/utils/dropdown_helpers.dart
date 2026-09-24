// lib/features/profile/utils/dropdown_helpers.dart

String getItemDisplay(dynamic item, {String? field}) {
  if (item == null) return 'N/A';
  if (item is Map) {
    return field != null ? (item[field]?.toString() ?? 'N/A') : item.toString();
  }
  try {
    if (field == 'sigla') return item.sigla?.toString() ?? 'N/A';
    if (field == 'nome') return item.nome?.toString() ?? 'N/A';
    if (field == 'id') return item.id?.toString() ?? 'N/A';
    return item.toString();
  } catch (_) {
    return 'N/A';
  }
}

int? getItemId(dynamic item) {
  if (item == null) return null;

  int? parse(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  if (item is Map) return parse(item['id']);
  try {
    return parse(item.id);
  } catch (_) {
    return null;
  }
}
