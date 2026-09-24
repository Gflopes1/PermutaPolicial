// /lib/core/utils/dropdown_helpers.dart

mixin DropdownHelpers {
  String getItemDisplay(dynamic item, {String? field}) {
    if (item == null) return 'N/A';
    
    if (item is Map) {
      return field != null ? (item[field]?.toString() ?? 'N/A') : item.toString();
    }
    
    // Abordagem segura sem dart:mirrors
    // Se precisar acessar propriedades dinâmicas de objetos, implemente toMap() ou toString() neles
    try {
      // Tenta usar o método toJson se existir (comum em models)
      if (item is Function) return item.toString(); // Proteção
      
      // Se for um dos seus models conhecidos, faça o cast (opcional, mas recomendado se tiver muitos)
      // Exemplo genérico:
      return item.toString();
    } catch (e) {
      return 'N/A';
    }
  }
  
  int? getItemId(dynamic item) {
    if (item == null) return null;
    
    if (item is Map) return item['id'] as int?;
    
    // Tenta acessar a propriedade .id dinamicamente se o objeto permitir
    try {
      return (item as dynamic).id;
    } catch (e) {
      return null;
    }
  }
}
