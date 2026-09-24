import 'package:flutter/material.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/utils/admin_access.dart';
import '../../../core/services/documento_ocr_corpus.dart';
import '../../../core/services/documento_ocr_types.dart';
import '../../../core/services/documento_preprocess_debug.dart';
import '../../../core/services/verificacao_ocr_redaction.dart';

/// Painel visível apenas para admin — mostra o que o OCR extraiu por campo.
class VerificacaoAdminDebugPanel extends StatelessWidget {
  final UserProfile user;
  final ExtractedVerificationFields? fields;
  final bool nomeOk;
  final bool matriculaOk;
  final bool forcaOk;
  final bool cargoOk;
  final List<DocumentoOcrResult> faceResults;

  const VerificacaoAdminDebugPanel({
    super.key,
    required this.user,
    required this.fields,
    required this.nomeOk,
    required this.matriculaOk,
    required this.forcaOk,
    required this.cargoOk,
    required this.faceResults,
  });

  static bool isAdmin(UserProfile? user) => AdminAccess.isAdmin(user);

  @override
  Widget build(BuildContext context) {
    final corpus = DocumentoOcrCorpus.forSubmit(
      results: faceResults,
      mergedFields: fields,
    );

    return Card(
      color: const Color(0xFFFFF8E1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFFB300)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report_outlined, color: Colors.orange.shade900, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Admin — leitura OCR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Valores que o app extraiu e comparou com o cadastro.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
            const SizedBox(height: 12),
            _DebugFieldRow(
              label: 'Nome completo',
              expected: user.nome,
              read: fields?.nome,
              passed: nomeOk,
            ),
            _DebugFieldRow(
              label: 'Matrícula / Id. funcional',
              expected: user.idFuncional,
              read: fields?.matricula,
              passed: matriculaOk,
            ),
            _DebugFieldRow(
              label: 'Força policial',
              expected: user.forcaSigla,
              read: fields?.forca,
              passed: forcaOk,
            ),
            _DebugFieldRow(
              label: 'Posto / graduação / cargo',
              expected: '(texto ≥ 3 caracteres)',
              read: fields?.cargo,
              passed: cargoOk,
            ),
            const Divider(height: 24),
            for (var i = 0; i < faceResults.length; i++)
              if (faceResults[i].preprocessSteps.isNotEmpty)
                _PreprocessPipelineSection(
                  faceIndex: faceResults.length > 1 ? i + 1 : null,
                  steps: faceResults[i].preprocessSteps,
                ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Por face (${faceResults.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                  fontSize: 14,
                ),
              ),
              children: [
                for (var i = 0; i < faceResults.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _faceSummary(i + 1, faceResults[i].fields),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Blocos OCR (${_blockCount()} blocos)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                  fontSize: 14,
                ),
              ),
              children: [
                for (var i = 0; i < faceResults.length; i++) ...[
                  if (faceResults.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Text(
                        'Face ${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  for (final block in faceResults[i].blocks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '[${_categoryLabel(block.category)}] ${block.text}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Corpus usado na comparação',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                  fontSize: 14,
                ),
              ),
              children: [
                SelectableText(
                  corpus.isEmpty ? '(vazio)' : corpus,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _blockCount() => faceResults.fold(0, (sum, r) => sum + r.blocks.length);

  String _faceSummary(int index, ExtractedVerificationFields f) {
    return 'Face $index → '
        'nome=${_fmt(f.nome)} | '
        'mat=${_fmt(f.matricula)} | '
        'força=${_fmt(f.forca)} | '
        'cargo=${_fmt(f.cargo)}';
  }

  String _fmt(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? '—' : t;
  }

  String _categoryLabel(OcrBlockCategory c) => switch (c) {
        OcrBlockCategory.nome => 'nome',
        OcrBlockCategory.matricula => 'matrícula',
        OcrBlockCategory.cargo => 'cargo',
        OcrBlockCategory.forca => 'força',
        OcrBlockCategory.sensitive => 'sensível',
        OcrBlockCategory.other => 'outro',
      };
}

class _DebugFieldRow extends StatelessWidget {
  final String label;
  final String? expected;
  final String? read;
  final bool passed;

  const _DebugFieldRow({
    required this.label,
    required this.expected,
    required this.read,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final readText = read?.trim();
    final hasRead = readText != null && readText.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel_outlined,
                size: 18,
                color: passed ? Colors.green.shade700 : Colors.red.shade700,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cadastro: ${_display(expected)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
          Text(
            'Lido: ${_display(hasRead ? readText : null)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: hasRead ? Colors.black87 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _display(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return '—';
    return t;
  }
}

class _PreprocessPipelineSection extends StatelessWidget {
  final int? faceIndex;
  final List<DocumentoPreprocessStep> steps;

  const _PreprocessPipelineSection({
    required this.faceIndex,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final title = faceIndex == null
        ? 'Pipeline de imagem (${steps.length} etapas)'
        : 'Pipeline de imagem — Face $faceIndex';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade900,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Foto após cada tratamento antes do Google Vision.',
          style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
        ),
        children: [
          for (final step in steps) _PreprocessStepTile(step: step),
        ],
      ),
    );
  }
}

class _PreprocessStepTile extends StatelessWidget {
  final DocumentoPreprocessStep step;

  const _PreprocessStepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          if (step.detail != null && step.detail!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              step.detail!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.grey.shade200,
              width: double.infinity,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.memory(
                  step.jpegBytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
