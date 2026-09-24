// /lib/shared/widgets/custom_dropdown_search.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../core/config/app_theme.dart';

class CustomDropdownSearch<T> extends StatelessWidget {
  final String label;
  final bool enabled;
  final T? selectedItem;
  final void Function(T? item) onChanged;
  final String Function(T item) itemAsString;
  
  final List<T> items; // CORREÇÃO: Não pode ser nulo
  final Future<List<T>> Function(String filter)? asyncItems;
  /// Quando definido, substitui "Nenhum item encontrado" por botão de sugerir unidade.
  final VoidCallback? onSuggestUnidade;
  final String? suggestUnidadeEmptyLabel;

  const CustomDropdownSearch({
    super.key,
    required this.label,
    required this.onChanged,
    required this.itemAsString,
    this.items = const [], // CORREÇÃO: Valor padrão lista vazia
    this.asyncItems,
    this.selectedItem,
    this.enabled = true,
    this.onSuggestUnidade,
    this.suggestUnidadeEmptyLabel,
  });

  static const String defaultSuggestUnidadeEmptyLabel =
      'Não foi encontrada nenhuma unidade desta força nesse município, '
      'clique aqui para sugerir a adição de uma unidade';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // CORREÇÃO: Lógica simplificada para decidir entre items e asyncItems
    final bool useAsyncItems = asyncItems != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.transparent,
        ),
      ),
      child: DropdownSearch<T>(
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
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              labelText: 'Pesquisar',
              filled: theme.inputDecorationTheme.filled,
              fillColor: theme.inputDecorationTheme.fillColor,
            ),
          ),
          loadingBuilder: (context, searchEntry) {
            return Container(
              padding: const EdgeInsets.all(16),
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                ),
              ),
            );
          },
          emptyBuilder: (context, searchEntry) {
            if (onSuggestUnidade != null) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: theme.scaffoldBackgroundColor,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSuggestUnidade!();
                  },
                  child: Text(
                    suggestUnidadeEmptyLabel ?? defaultSuggestUnidadeEmptyLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryLight,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryLight,
                    ),
                  ),
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.all(16),
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: Text(
                  'Nenhum item encontrado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),
            );
          },
        ),

        dropdownDecoratorProps: DropDownDecoratorProps(
          baseStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          dropdownSearchDecoration: InputDecoration(
            labelText: label,
            filled: theme.inputDecorationTheme.filled,
            fillColor: theme.inputDecorationTheme.fillColor,
            border: theme.inputDecorationTheme.border,
            enabledBorder: theme.inputDecorationTheme.enabledBorder,
            focusedBorder: theme.inputDecorationTheme.focusedBorder,
            contentPadding: theme.inputDecorationTheme.contentPadding,
            labelStyle: theme.inputDecorationTheme.labelStyle,
            errorBorder: theme.inputDecorationTheme.errorBorder,
            focusedErrorBorder: theme.inputDecorationTheme.focusedErrorBorder,
            disabledBorder: theme.inputDecorationTheme.disabledBorder,
          ),
        ),
      ),
    );
  }
}

// Função de preview para o Flutter Widget Preview
Widget previewCustomDropdownSearch() {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomDropdownSearch<String>(
                label: 'Estado',
                items: const ['São Paulo', 'Rio de Janeiro', 'Minas Gerais', 'Bahia'],
                selectedItem: 'São Paulo',
                itemAsString: (item) => item,
                onChanged: (value) {},
              ),
              const SizedBox(height: 24),
              CustomDropdownSearch<String>(
                label: 'Força Policial',
                items: const ['PM', 'PC', 'PF', 'PRF'],
                itemAsString: (item) => item,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
}