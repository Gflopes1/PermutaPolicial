// /lib/features/admin/widgets/usuarios_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_display_widget.dart';
import '../../../core/models/policial_admin.dart';

class UsuariosTab extends StatefulWidget {
  final AdminProvider provider;

  const UsuariosTab({super.key, required this.provider});

  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    widget.provider.loadPoliciais(page: 1, search: query);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMD),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar por nome, email ou ID funcional',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
            ),
            onSubmitted: _performSearch,
            onChanged: (value) {
              if (value.isEmpty) {
                _performSearch('');
              }
            },
          ),
        ),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.policiais.isEmpty) {
                return const LoadingWidget();
              }

              if (provider.errorMessage != null &&
                  provider.policiais.isEmpty) {
                return ErrorDisplayWidget(
                  customMessage: provider.errorMessage!,
                  customTitle: 'Erro ao carregar usuários',
                  onRetry: () => provider.loadPoliciais(),
                );
              }

              if (provider.policiais.isEmpty) {
                return const Center(
                  child: Text('Nenhum usuário encontrado'),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => provider.loadPoliciais(
                        page: provider.currentPage,
                        search: provider.searchQuery,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMD,
                        ),
                        itemCount: provider.policiais.length,
                        itemBuilder: (context, index) {
                          final policial = provider.policiais[index];
                          return _buildPolicialCard(context, policial);
                        },
                      ),
                    ),
                  ),
                  if (provider.totalPages > 1)
                    _buildPagination(context, provider),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPolicialCard(
      BuildContext context, PolicialAdmin policial) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSM),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.spacingMD),
        title: Text(
          policial.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Email: ${policial.email}'),
            if (policial.idFuncional != null)
              Text('ID Funcional: ${policial.idFuncional}'),
            if (policial.forcaSigla != null)
              Text('Força: ${policial.forcaSigla}'),
            if (policial.unidadeAtualNome != null)
              Text(
                'Lotação: ${policial.unidadeAtualNome}${policial.municipioAtualNome != null ? ' - ${policial.municipioAtualNome}' : ''}${policial.estadoAtualSigla != null ? '/${policial.estadoAtualSigla}' : ''}',
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(policial.statusVerificacao),
                if (policial.isEmbaixador) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Admin'),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _showDetalhesUsuario(context, policial);
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'VERIFICADO':
        color = Colors.green;
        break;
      case 'PENDENTE':
        color = Colors.orange;
        break;
      case 'REJEITADO':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status == 'VERIFICADO'
            ? 'Verificado'
            : status == 'PENDENTE'
                ? 'Pendente'
                : status == 'REJEITADO'
                    ? 'Rejeitado'
                    : status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showDetalhesUsuario(BuildContext context, PolicialAdmin policial) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                policial.nome,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.email, 'Email', policial.email),
              if (policial.idFuncional != null)
                _buildDetailRow(Icons.badge, 'ID Funcional', policial.idFuncional!),
              if (policial.qso != null)
                _buildDetailRow(Icons.phone, 'QSO / Telefone', policial.qso!),
              if (policial.forcaSigla != null)
                _buildDetailRow(Icons.shield, 'Força', '${policial.forcaSigla}${policial.forcaNome != null ? ' - ${policial.forcaNome}' : ''}'),
              if (policial.postoGraduacaoNome != null)
                _buildDetailRow(Icons.military_tech, 'Posto/Graduação', policial.postoGraduacaoNome!),
              if (policial.unidadeAtualNome != null)
                _buildDetailRow(
                  Icons.business,
                  'Lotação',
                  '${policial.unidadeAtualNome}${policial.municipioAtualNome != null ? ' - ${policial.municipioAtualNome}' : ''}${policial.estadoAtualSigla != null ? '/${policial.estadoAtualSigla}' : ''}',
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.info, 'Status', policial.statusVerificacaoLabel),
              _buildDetailRow(
                Icons.calendar_today,
                'Cadastrado em',
                '${policial.criadoEm.day}/${policial.criadoEm.month}/${policial.criadoEm.year}',
              ),
              if (policial.isEmbaixador)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Administrador',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, AdminProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Página ${provider.currentPage} de ${provider.totalPages}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: provider.currentPage > 1
                    ? () => provider.loadPoliciais(
                          page: provider.currentPage - 1,
                          search: provider.searchQuery,
                        )
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: provider.currentPage < provider.totalPages
                    ? () => provider.loadPoliciais(
                          page: provider.currentPage + 1,
                          search: provider.searchQuery,
                        )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

