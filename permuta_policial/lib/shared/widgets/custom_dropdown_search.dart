// /lib/shared/widgets/custom_dropdown_search.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CustomDropdownSearch<T> extends StatelessWidget {
  final String label;
  final bool enabled;
  final T? selectedItem;
  final void Function(T? item) onChanged;
  final String Function(T item) itemAsString;
  
  final List<T> items; // CORREÇÃO: Não pode ser nulo
  final Future<List<T>> Function(String filter)? asyncItems;

  const CustomDropdownSearch({
    super.key,
    required this.label,
    required this.onChanged,
    required this.itemAsString,
    this.items = const [], // CORREÇÃO: Valor padrão lista vazia
    this.asyncItems,
    this.selectedItem,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // CORREÇÃO: Lógica simplificada para decidir entre items e asyncItems
    final bool useAsyncItems = asyncItems != null;

    return DropdownSearch<T>(
      enabled: enabled,
      selectedItem: selectedItem,
      onChanged: onChanged,
      itemAsString: itemAsString,
      
      // CORREÇÃO: Sempre passar uma lista, mesmo que vazia
      items: useAsyncItems ? [] : items,
      asyncItems: useAsyncItems ? asyncItems : null,

      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        modalBottomSheetProps: ModalBottomSheetProps(
          backgroundColor: theme.scaffoldBackgroundColor,
        ),
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            labelText: 'Pesquisar',
          ),
        ),
      ),

      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }
}