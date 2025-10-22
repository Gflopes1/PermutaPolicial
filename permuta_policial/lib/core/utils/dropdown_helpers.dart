// /lib/core/utils/dropdown_helpers.dart
import 'dart:nativewrappers/_internal/vm/lib/mirrors_patch.dart';

mixin DropdownHelpers {
  String getItemDisplay(dynamic item, {String? field}) {
    if (item == null) return 'N/A';
    
    if (item is Map) {
      return field != null ? (item[field]?.toString() ?? 'N/A') : item.toString();
    }
    
    // Tenta acessar como objeto
    try {
      if (field != null) {
        final value = _getObjectField(item, field);
        return value?.toString() ?? 'N/A';
      }
      return item.toString();
    } catch (e) {
      return 'N/A';
    }
  }
  
  int? getItemId(dynamic item) {
    if (item == null) return null;
    
    if (item is Map) return item['id'] as int?;
    
    try {
      return _getObjectField(item, 'id') as int?;
    } catch (e) {
      return null;
    }
  }
  
  dynamic _getObjectField(dynamic obj, String field) {
    final mirror = reflect(obj);
    try {
      return mirror.getField(Symbol(field)).reflectee;
    } catch (e) {
      return null;
    }
  }
}