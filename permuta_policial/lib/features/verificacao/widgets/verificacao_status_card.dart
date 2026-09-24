import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/repositories/verificacao_ocr_repository.dart';
import '../../../core/config/app_router.dart';
import '../../../core/models/user_profile.dart';
import 'verificacao_metodo_buttons.dart';
import 'verificacao_whatsapp_helper.dart';

class VerificacaoStatusCard extends StatefulWidget {
  final UserProfile userProfile;

  const VerificacaoStatusCard({super.key, required this.userProfile});

  @override
  State<VerificacaoStatusCard> createState() => _VerificacaoStatusCardState();
}

class _VerificacaoStatusCardState extends State<VerificacaoStatusCard> {
  bool _openingWhatsapp = false;
  bool _loadingStatus = true;
  bool _ocrPendente = false;

  @override
  void initState() {
    super.initState();
    _loadOcrStatus();
  }

  @override
  void didUpdateWidget(covariant VerificacaoStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile.agenteVerificado != widget.userProfile.agenteVerificado) {
      _loadOcrStatus();
    }
  }

  Future<void> _loadOcrStatus() async {
    if (widget.userProfile.agenteVerificado) {
      setState(() {
        _loadingStatus = false;
        _ocrPendente = false;
      });
      return;
    }

    setState(() => _loadingStatus = true);
    try {
      final status = await context.read<VerificacaoOcrRepository>().getMyStatus();
      if (!mounted) return;
      setState(() {
        _ocrPendente = status['ocr_pendente'] == true || status['ocr_pendente'] == 1;
        _loadingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userProfile.agenteVerificado) {
      return Card(
        color: const Color(0xFF1B5E20),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
        ),
        child: const ListTile(
          iconColor: Color(0xFFA5D6A7),
          textColor: Colors.white,
          leading: Icon(Icons.verified, color: Color(0xFF81C784)),
          title: Text(
            'Agente verificado',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: Text(
            'Sua conta está verificada para recursos restritos.',
            style: TextStyle(color: Color(0xFFE8F5E9)),
          ),
        ),
      );
    }

    return Card(
      color: const Color(0xFF4A3800),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFFB300), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.pending_outlined, color: Color(0xFFFFCA28)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verificação de agente pendente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingStatus)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFFFFCA28),
                  backgroundColor: Color(0xFF6D4C00),
                ),
              )
            else if (_ocrPendente)
              const Text(
                'Seu documento já foi enviado e está aguardando revisão manual. '
                'Você pode enviar novamente se quiser atualizar a imagem.',
                style: TextStyle(color: Color(0xFFFFF8E1), height: 1.4),
              )
            else
              const Text(
                'Para acessar Marketplace (criar anúncios) e simuladores de editais, '
                'verifique sua conta via WhatsApp ou com documento.',
                style: TextStyle(color: Color(0xFFFFF8E1), height: 1.4),
              ),
            const SizedBox(height: 12),
            VerificacaoWhatsappButton(
              loading: _openingWhatsapp,
              onPressed: () async {
                setState(() => _openingWhatsapp = true);
                try {
                  await VerificacaoWhatsappHelper.openVerificationRequest(
                    nome: widget.userProfile.nome,
                    idFuncional: widget.userProfile.idFuncional ?? 'não informado',
                  );
                } finally {
                  if (mounted) setState(() => _openingWhatsapp = false);
                }
              },
            ),
            const SizedBox(height: 10),
            VerificacaoDocumentoButton(
              label: _ocrPendente
                  ? 'Reenviar documento (funcional ou contracheque)'
                  : 'Verificar com funcional ou contracheque',
              onPressed: () async {
                await context.push(AppRoutes.verificacaoDocumento);
                if (mounted) _loadOcrStatus();
              },
            ),
          ],
        ),
      ),
    );
  }
}
