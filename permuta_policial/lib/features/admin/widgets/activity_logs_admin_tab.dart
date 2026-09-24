import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';

class ActivityLogsAdminTab extends StatefulWidget {
  const ActivityLogsAdminTab({super.key});

  @override
  State<ActivityLogsAdminTab> createState() => _ActivityLogsAdminTabState();
}

class _ActivityLogsAdminTabState extends State<ActivityLogsAdminTab> {
  bool _initialized = false;
  String? _tipoFiltro;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (!_initialized &&
            provider.activityLogs.isEmpty &&
            !provider.isLoadingActivityLogs) {
          _initialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) provider.loadActivityLogs();
          });
        }

        final formatter = DateFormat('dd/MM/yyyy HH:mm');

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _tipoFiltro,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de ação',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todas')),
                        DropdownMenuItem(value: 'LOGIN', child: Text('Login')),
                        DropdownMenuItem(value: 'INTENCAO_PERMUTA', child: Text('Intenção de permuta')),
                        DropdownMenuItem(value: 'INTENCAO_EDITAL', child: Text('Intenção de edital')),
                        DropdownMenuItem(value: 'MENSAGEM', child: Text('Envio de mensagem')),
                      ],
                      onChanged: (value) {
                        setState(() => _tipoFiltro = value);
                        provider.loadActivityLogs(tipo: value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Atualizar',
                    onPressed: () => provider.loadActivityLogs(tipo: _tipoFiltro),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            if (provider.activityLogsTotal > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${provider.activityLogsTotal} ações encontradas',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.loadActivityLogs(tipo: _tipoFiltro),
                child: provider.isLoadingActivityLogs && provider.activityLogs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.activityLogsError != null
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                              const SizedBox(height: 16),
                              Center(child: Text(provider.activityLogsError!)),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => provider.loadActivityLogs(tipo: _tipoFiltro),
                                  child: const Text('Tentar novamente'),
                                ),
                              ),
                            ],
                          )
                        : provider.activityLogs.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(child: Text('Nenhuma ação registrada ainda.')),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: provider.activityLogs.length +
                                    (provider.hasMoreActivityLogs ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  if (index >= provider.activityLogs.length) {
                                    return Center(
                                      child: TextButton(
                                        onPressed: provider.isLoadingActivityLogs
                                            ? null
                                            : () => provider.loadMoreActivityLogs(),
                                        child: provider.isLoadingActivityLogs
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Text('Carregar mais'),
                                      ),
                                    );
                                  }

                                  final log = provider.activityLogs[index];
                                  final tipo = log['tipo']?.toString() ?? '';
                                  final nome = log['policial_nome']?.toString() ?? 'Usuário';
                                  final email = log['policial_email']?.toString() ?? '';
                                  final idFuncional = log['id_funcional']?.toString();
                                  final detalhe = log['detalhe']?.toString() ?? '';
                                  final ocorridoRaw = log['ocorrido_em']?.toString();
                                  DateTime? ocorrido;
                                  if (ocorridoRaw != null) {
                                    ocorrido = DateTime.tryParse(ocorridoRaw);
                                  }

                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _tipoColor(tipo).withValues(alpha: 0.15),
                                        child: Icon(_tipoIcon(tipo), color: _tipoColor(tipo), size: 20),
                                      ),
                                      title: Text(
                                        _tipoLabel(tipo),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              nome,
                                              if (idFuncional != null && idFuncional.isNotEmpty)
                                                'ID $idFuncional',
                                              if (email.isNotEmpty) email,
                                            ].join(' · '),
                                          ),
                                          if (detalhe.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(detalhe, maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                          if (ocorrido != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              formatter.format(ocorrido.toLocal()),
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ],
                                      ),
                                      isThreeLine: true,
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _tipoLabel(String tipo) {
    return switch (tipo) {
      'LOGIN' => 'Login',
      'INTENCAO_PERMUTA' => 'Intenção de permuta',
      'INTENCAO_EDITAL' => 'Intenção de edital',
      'MENSAGEM' => 'Envio de mensagem',
      _ => tipo,
    };
  }

  IconData _tipoIcon(String tipo) {
    return switch (tipo) {
      'LOGIN' => Icons.login,
      'INTENCAO_PERMUTA' => Icons.swap_horiz,
      'INTENCAO_EDITAL' => Icons.description_outlined,
      'MENSAGEM' => Icons.chat_bubble_outline,
      _ => Icons.history,
    };
  }

  Color _tipoColor(String tipo) {
    return switch (tipo) {
      'LOGIN' => Colors.green.shade700,
      'INTENCAO_PERMUTA' => Colors.blue.shade700,
      'INTENCAO_EDITAL' => Colors.deepPurple.shade700,
      'MENSAGEM' => Colors.teal.shade700,
      _ => Colors.grey.shade700,
    };
  }
}
