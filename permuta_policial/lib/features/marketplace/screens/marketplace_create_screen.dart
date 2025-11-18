// /lib/features/marketplace/screens/marketplace_create_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/marketplace_item.dart';
import 'marketplace_photo_picker_screen.dart';
import 'marketplace_create_form_screen.dart';

/// Wrapper que gerencia criação e edição de anúncios do marketplace
class MarketplaceCreateScreen extends StatelessWidget {
  final MarketplaceItem? itemToEdit;

  const MarketplaceCreateScreen({
    super.key,
    this.itemToEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Se for edição, vai direto para o formulário (sem seleção de fotos)
    if (itemToEdit != null) {
      return MarketplaceCreateFormScreen(
        itemToEdit: itemToEdit,
      );
    }

    // Se for criação, começa pela seleção de fotos
    return const MarketplacePhotoPickerScreen();
  }
}

