import 'package:flutter/material.dart';

import '../../../../core/models/user_profile.dart';
import '../edit_lotacao_modal.dart';
import '../section_card.dart';

class ForcaPostoSection extends StatelessWidget {
  final UserProfile userProfile;

  const ForcaPostoSection({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      label: 'Força e posto',
      action: TextButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => EditLotacaoModal(userProfile: userProfile),
        ),
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('Editar'),
      ),
      children: [
        ProfileReadField(
          label: 'Força policial',
          value: userProfile.forcaSigla ?? 'Não informada',
        ),
        ProfileReadField(
          label: 'Posto / Graduação',
          value: userProfile.postoGraduacaoNome ?? 'Não informado',
        ),
      ],
    );
  }
}
