// /lib/features/dashboard/widgets/match_triangular_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../core/models/match_results.dart';

class MatchTriangularCard extends StatelessWidget {
  final MatchTriangular match;
  const MatchTriangularCard({super.key, required this.match});

  void _showQsoDialog(BuildContext context, String nome, String? qso) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool hasQso = qso != null && qso.isNotEmpty;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(CupertinoIcons.person_fill, color: Theme.of(context).primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasQso) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(CupertinoIcons.phone_fill, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QSO / Contato',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              qso,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.info_circle, color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Este usuário não informou um número de contato.'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            if (hasQso)
              FilledButton.icon(
                icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                label: const Text('Copiar Número'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qso));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Número copiado!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
              ),
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com gradiente
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withAlpha(200),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.arrow_swap, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ciclo de Permuta Triangular',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.person_3_fill, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '3 pessoas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Policial B
                _buildPolicialInfo(
                  context,
                  nome: match.policialB.nome,
                  posto: match.policialB.postoGraduacaoNome,
                  forca: match.policialB.forcaSigla,
                  unidade: match.policialB.unidadeAtual,
                  municipio: match.policialB.municipioAtual,
                  estado: match.policialB.estadoAtual,
                  hasQso: match.policialB.qso != null && match.policialB.qso!.isNotEmpty,
                  onContactTap: () => _showQsoDialog(context, match.policialB.nome, match.policialB.qso),
                ),

                const SizedBox(height: 16),

                // Policial C
                _buildPolicialInfo(
                  context,
                  nome: match.policialC.nome,
                  posto: match.policialC.postoGraduacaoNome,
                  forca: match.policialC.forcaSigla,
                  unidade: match.policialC.unidadeAtual,
                  municipio: match.policialC.municipioAtual,
                  estado: match.policialC.estadoAtual,
                  hasQso: match.policialC.qso != null && match.policialC.qso!.isNotEmpty,
                  onContactTap: () => _showQsoDialog(context, match.policialC.nome, match.policialC.qso),
                ),

                const SizedBox(height: 20),

                // Fluxo da permuta
                _buildFluxoSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicialInfo(
    BuildContext context, {
    required String nome,
    required String? posto,
    required String forca,
    required String? unidade,
    required String? municipio,
    required String? estado,
    required bool hasQso,
    required VoidCallback onContactTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (posto != null && posto.isNotEmpty)
                      Text(
                        posto,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasQso)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onContactTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        CupertinoIcons.phone_fill,
                        size: 18,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Informações de força e localização
          Row(
            children: [
              Icon(
                CupertinoIcons.building_2_fill,
                size: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                forca,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              if ((municipio != null && municipio.isNotEmpty) || (estado != null && estado.isNotEmpty)) ...[
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.location_solid,
                  size: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${municipio ?? "N/I"} - ${estado ?? "N/I"}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          
          if (unidade != null && unidade.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.briefcase_fill,
                    size: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      unidade,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFluxoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_2_circlepath,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Fluxo da Permuta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFluxoRow(
            context,
            de: 'Você',
            para: match.policialB.nome,
            descricao: match.fluxo.aParaB,
            isFirst: true,
          ),
          _buildFluxoDivider(context),
          _buildFluxoRow(
            context,
            de: match.policialB.nome,
            para: match.policialC.nome,
            descricao: match.fluxo.bParaC,
          ),
          _buildFluxoDivider(context),
          _buildFluxoRow(
            context,
            de: match.policialC.nome,
            para: 'Você',
            descricao: match.fluxo.cParaA,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFluxoDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Container(
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withAlpha(50),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFluxoRow(
    BuildContext context, {
    required String de,
    required String para,
    required String descricao,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone de seta circular
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isFirst
                ? Theme.of(context).primaryColor.withAlpha(25)
                : isLast
                    ? Colors.green.withAlpha(25)
                    : Theme.of(context).colorScheme.secondary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            CupertinoIcons.arrow_right,
            size: 16,
            color: isFirst
                ? Theme.of(context).primaryColor
                : isLast
                    ? Colors.green
                    : Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    de,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    CupertinoIcons.arrow_right,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      para,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isLast ? Colors.green : Theme.of(context).primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                descricao,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}