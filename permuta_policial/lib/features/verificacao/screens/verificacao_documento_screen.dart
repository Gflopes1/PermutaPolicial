import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/api/repositories/verificacao_ocr_repository.dart';
import '../../../core/lifecycle/web_resume_bridge.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/utils/admin_access.dart';
import '../../../core/services/documento_faces_image.dart';
import '../../../core/services/documento_quality_exception.dart';
import '../../../core/services/documento_field_match.dart';
import '../../../core/services/documento_fields_merge.dart';
import '../../../core/services/documento_ocr_corpus.dart';
import '../../../core/services/verificacao_ocr_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../widgets/verificacao_admin_debug_panel.dart';
import '../widgets/verificacao_metodo_buttons.dart';

/// Uma captura já processada (OCR) de uma das faces do documento.
class _FaceCapturada {
  final Uint8List auditBytes;
  final DocumentoOcrResult result;

  const _FaceCapturada({required this.auditBytes, required this.result});

  ExtractedVerificationFields get fields => result.fields;
}

class VerificacaoDocumentoScreen extends StatefulWidget {
  const VerificacaoDocumentoScreen({super.key});

  @override
  State<VerificacaoDocumentoScreen> createState() => _VerificacaoDocumentoScreenState();
}

class _VerificacaoDocumentoScreenState extends State<VerificacaoDocumentoScreen> {
  String? _tipoDocumento;
  bool _processing = false;
  bool _submitting = false;
  String? _error;
  String? _progressMessage;
  double _progressValue = 0;
  DateTime? _lastProgressUiUpdate;
  final List<_FaceCapturada> _faces = [];

  DocumentoOcrResult? get _lastResult => _faces.isEmpty ? null : _faces.last.result;

  /// Nome e posto ficam na face vertical; o Id. funcional, na horizontal — por
  /// isso os campos são acumulados entre as capturas.
  ExtractedVerificationFields? _mergedFields(UserProfile? user) {
    if (_faces.isEmpty) return null;
    return DocumentoFieldsMerge.merge(
      _faces.map((f) => f.fields).toList(),
      forcaSigla: user?.forcaSigla,
      nomeCadastrado: user?.nome,
      matriculaCadastrada: user?.idFuncional,
    );
  }

  _VerificationChecks _checks(UserProfile? user, ExtractedVerificationFields? fields) {
    final corpus = DocumentoOcrCorpus.forSubmit(
      results: _faces.map((f) => f.result),
      mergedFields: fields,
    );
    return _VerificationChecks(
      nome: DocumentoFieldMatch.nomePresent(
        expected: user?.nome,
        extracted: fields?.nome,
        ocrCorpus: corpus,
      ),
      matricula: DocumentoFieldMatch.matriculaPresent(
        expected: user?.idFuncional,
        extracted: fields?.matricula,
        ocrCorpus: corpus,
      ),
      forca: DocumentoFieldMatch.forcaPresent(
        expected: user?.forcaSigla,
        extracted: fields?.forca,
        ocrCorpus: corpus,
      ),
      cargo: DocumentoFieldMatch.cargoPresent(
        extracted: fields?.cargo,
        ocrCorpus: corpus,
      ),
    );
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    if (_tipoDocumento == null) {
      setState(() => _error = 'Selecione o tipo de documento primeiro.');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
      _progressMessage = 'Preparando leitura do documento (Google Vision)...';
      _progressValue = 0;
    });

    try {
      if (kIsWeb) {
        suppressWebResumeReload(duration: const Duration(minutes: 3));
      }

      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 92);
      if (file == null) {
        if (kIsWeb) setWebOcrInProgress(false);
        setState(() => _processing = false);
        return;
      }

      if (kIsWeb) {
        suppressWebResumeReload(duration: const Duration(minutes: 3));
        setWebOcrInProgress(true);
      }

      final imageBytes = await file.readAsBytes();
      await Future<void>.delayed(Duration.zero);

      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      final visionRepo = context.read<VerificacaoOcrRepository>();
      final service = DocumentoOcrService.create(visionRepository: visionRepo);

      final result = await service.processarDocumento(
        imageBytes: imageBytes,
        filePath: kIsWeb ? null : file.path,
        forcaSigla: user?.forcaSigla,
        tipoDocumento: _tipoDocumento,
        nomeCadastrado: user?.nome,
        matriculaCadastrada: user?.idFuncional,
        onProgress: _reportOcrProgress,
      );

      if (!mounted) return;
      setState(() {
        _faces.add(
          _FaceCapturada(auditBytes: result.auditBytes, result: result),
        );
        _processing = false;
        _progressMessage = null;
      });
    } on DocumentoQualityException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.quality.userMessage;
        _processing = false;
        _progressMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _processing = false;
        _progressMessage = null;
      });
    } finally {
      if (kIsWeb) setWebOcrInProgress(false);
    }
  }

  void _reportOcrProgress(String status, double progress) {
    if (!mounted) return;
    final now = DateTime.now();
    final last = _lastProgressUiUpdate;
    final shouldUpdate = last == null ||
        now.difference(last) >= const Duration(milliseconds: 120) ||
        progress >= 1 ||
        progress <= 0.05;
    if (!shouldUpdate) return;

    _lastProgressUiUpdate = now;
    setState(() {
      _progressValue = progress.clamp(0, 1);
      _progressMessage = _humanizeProgress(status, progress);
    });
  }

  String _humanizeProgress(String status, double progress) {
    final normalized = status.toLowerCase();
    if (normalized.contains('checking quality')) {
      return 'Verificando qualidade da foto...';
    }
    if (normalized.contains('detecting orientation')) {
      return 'Detectando orientação do documento...';
    }
    if (normalized.contains('cropping')) {
      return 'Enquadrando documento...';
    }
    if (normalized.contains('enhancing') || normalized.contains('preprocessing')) {
      return 'Otimizando imagem...';
    }
    if (normalized.contains('google vision') || normalized.contains('recognizing')) {
      return 'Lendo documento com Google Vision (${(progress * 100).round()}%)...';
    }
    if (normalized.contains('merging orientations')) {
      return 'Analisando campos do documento...';
    }
    if (normalized.contains('done')) {
      return 'Finalizando...';
    }
    return 'Processando documento (${(progress * 100).round()}%)...';
  }

  Future<void> _submit() async {
    final fields = _mergedFields(context.read<AuthProvider>().user);
    final tipo = _tipoDocumento;
    if (_faces.isEmpty || fields == null || tipo == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repo = context.read<VerificacaoOcrRepository>();
      final imagemFinal = DocumentoFacesImage.stackVertically(
        _faces.map((f) => f.auditBytes).toList(),
      );
      final payload = fields.toPayload(tipo);
      final ocrCorpus = DocumentoOcrCorpus.forSubmit(
        results: _faces.map((f) => f.result),
        mergedFields: fields,
      ).trim();
      if (ocrCorpus.isNotEmpty) {
        payload['ocr_raw_text'] = ocrCorpus.length > 50000
            ? ocrCorpus.substring(0, 50000)
            : ocrCorpus;
      }

      final result = await repo.submitRedactedDocument(
        redactedBytes: imagemFinal,
        fields: payload,
      );

      if (!mounted) return;

      await context.read<AuthProvider>().refreshProfile();
      if (context.mounted) {
        await context.read<DashboardProvider>().fetchInitialData();
      }

      if (!mounted) return;

      final agenteVerificado = context.read<AuthProvider>().user?.agenteVerificado ?? false;

      if (result.verificadoAutomaticamente && agenteVerificado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta verificada automaticamente!')),
        );
        Navigator.of(context).pop(true);
        return;
      }

      final mensagem = result.verificadoAutomaticamente && !agenteVerificado
          ? 'Os dados foram reconhecidos, mas a verificação automática não pôde ser concluída. Seu documento foi enviado para revisão manual.'
          : 'Documento enviado para revisão manual. Você será notificado quando aprovado.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
      Navigator.of(context).pop(agenteVerificado);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _submitting = false;
      });
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (_processing || _submitting) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              subtitle: kIsWeb ? const Text('Abre o seletor de arquivos do navegador') : null,
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickAndProcess(source);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final dashboardUser = context.watch<DashboardProvider>().userData;
    final user = AdminAccess.resolveProfile(
      authUser: authUser,
      dashboardUser: dashboardUser,
    );
    final isAdmin = AdminAccess.hasAdminAccess(
      authUser: authUser,
      dashboardUser: dashboardUser,
    );
    final fields = _mergedFields(user);
    final checks = _checks(user, fields);

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Verificar com documento'),
            const SizedBox(width: 8),
            const BetaBadge(),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Envie uma foto da carteira funcional ou do contracheque/holerite. '
            'A imagem é salva para auditoria e comparada com seu cadastro.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          _RequiredFieldsCard(
            tipoDocumento: _tipoDocumento,
            userNome: user?.nome,
            userMatricula: user?.idFuncional,
            userForca: user?.forcaSigla,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _tipoDocumento,
            decoration: const InputDecoration(
              labelText: 'Tipo de documento',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'funcional', child: Text('Carteira funcional')),
              DropdownMenuItem(value: 'contracheque', child: Text('Contracheque / Holerite')),
            ],
            onChanged: _processing || _submitting
                ? null
                : (value) => setState(() => _tipoDocumento = value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_processing || _submitting) ? null : _showImageSourceSheet,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(
                _faces.isEmpty
                    ? 'Selecionar documento (foto ou galeria)'
                    : 'Adicionar outra face do documento',
              ),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          if (_lastResult?.imageWasCompressed == true) ...[
            const SizedBox(height: 8),
            Text(
              'Imagem otimizada automaticamente (${_lastResult!.originalImageSizeLabel} → tamanho reduzido para OCR).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_faces.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              _faces.length == 1
                  ? '1 face capturada'
                  : '${_faces.length} faces capturadas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _faces.length; i++)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                  title: Text('Face ${i + 1} processada'),
                  subtitle: const Text('Foto salva para auditoria'),
                  trailing: IconButton(
                    tooltip: 'Remover esta face',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: (_processing || _submitting)
                        ? null
                        : () => setState(() => _faces.removeAt(i)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Conferência com seu cadastro',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _FieldCheckTile(label: 'Nome completo', required: true, passed: checks.nome),
            _FieldCheckTile(label: 'Matrícula / Id. funcional', required: true, passed: checks.matricula),
            _FieldCheckTile(label: 'Força policial', required: false, passed: checks.forca),
            _FieldCheckTile(label: 'Posto / graduação / cargo', required: false, passed: checks.cargo),
            if (isAdmin && user != null) ...[
              const SizedBox(height: 16),
              VerificacaoAdminDebugPanel(
                user: user,
                fields: fields,
                nomeOk: checks.nome,
                matriculaOk: checks.matricula,
                forcaOk: checks.forca,
                cargoOk: checks.cargo,
                faceResults: _faces.map((f) => f.result).toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Enviando...' : 'Confirmar e enviar documento'),
              ),
            ),
          ],
        ],
      ),
        ),
        if (_processing || _submitting)
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.35),
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _progressMessage ??
                            (_submitting
                                ? 'Enviando documento...'
                                : 'Processando documento...'),
                        textAlign: TextAlign.center,
                      ),
                      if (_processing && _progressValue > 0) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 220,
                          child: LinearProgressIndicator(value: _progressValue),
                        ),
                      ],
                      if (_processing && kIsWeb)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'OCR pode levar alguns segundos. A página não recarregará.',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RequiredFieldsCard extends StatelessWidget {
  final String? tipoDocumento;
  final String? userNome;
  final String? userMatricula;
  final String? userForca;

  const _RequiredFieldsCard({
    required this.tipoDocumento,
    this.userNome,
    this.userMatricula,
    this.userForca,
  });

  @override
  Widget build(BuildContext context) {
    final docLabel = switch (tipoDocumento) {
      'funcional' => 'Carteira funcional',
      'contracheque' => 'Contracheque / holerite',
      _ => 'Selecione o tipo de documento',
    };

    final labels = switch (tipoDocumento) {
      'funcional' => 'Procure no documento: Portador (nome), Id. Funcional (matrícula), Posto/Graduação. '
          'Na carteira funcional esses dados ficam em faces diferentes — fotografe a frente e o verso, '
          'um por vez, mesmo que uma face esteja na vertical e a outra na horizontal.',
      'contracheque' => 'Procure no documento: Nome do servidor, Matrícula/Id. Funcional, Cargo/Função.',
      _ => 'Selecione o tipo para ver quais rótulos procurar na foto.',
    };

    return Card(
      color: const Color(0xFF0D47A1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF42A5F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O que precisamos ler ($docLabel)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labels,
              style: const TextStyle(color: Color(0xFFE3F2FD), height: 1.35),
            ),
            if (userNome != null || userMatricula != null) ...[
              const SizedBox(height: 10),
              const Text(
                'Seu cadastro (para conferência automática):',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBBDEFB),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              if (userNome?.trim().isNotEmpty == true)
                Text('Nome: ${userNome!.trim()}', style: const TextStyle(color: Colors.white)),
              if (userMatricula?.trim().isNotEmpty == true)
                Text(
                  'Matrícula: ${userMatricula!.trim()}',
                  style: const TextStyle(color: Colors.white),
                ),
              if (userForca?.trim().isNotEmpty == true)
                Text('Força: ${userForca!.trim()}', style: const TextStyle(color: Colors.white)),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerificationChecks {
  final bool nome;
  final bool matricula;
  final bool forca;
  final bool cargo;

  const _VerificationChecks({
    required this.nome,
    required this.matricula,
    required this.forca,
    required this.cargo,
  });
}

class _FieldCheckTile extends StatelessWidget {
  final String label;
  final bool required;
  final bool passed;

  const _FieldCheckTile({
    required this.label,
    required this.required,
    required this.passed,
  });

  @override
  Widget build(BuildContext context) {
    final icon = passed ? Icons.check_circle : Icons.cancel_outlined;
    final iconColor = passed ? Colors.green.shade700 : Theme.of(context).colorScheme.error;
    final status = passed ? 'Reconhecido' : (required ? 'Não reconhecido' : 'Não identificado');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          required ? '$label *' : label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          status,
          style: TextStyle(
            color: passed ? Colors.green.shade800 : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
