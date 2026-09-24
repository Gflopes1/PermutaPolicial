// /lib/features/calendar/widgets/salary_preview_panel.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';

class SalaryPreviewPanel extends StatelessWidget {
  final int month;
  final int year;

  const SalaryPreviewPanel({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final preview = provider.monthPreview;
        if (preview == null) {
          return const Center(child: Text('Carregando preview...'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            const SizedBox(height: 8),
            // Resumo de horas
            _buildSectionTitle(context, 'RESUMO DE HORAS'),
            _buildInfoCard(
              context,
              'Horas Totais',
              '${_formatNumber(preview['total_horas'])}h',
            ),
            _buildInfoCard(
              context,
              'Carga Horária do Mês',
              '${_formatNumber(preview['carga_horaria_mes'])}h',
            ),
            if (_toDouble(preview['horas_abatimento'] ?? 0) > 0)
              _buildInfoCard(
                context,
                'Horas de Abatimento',
                '${_formatNumber(preview['horas_abatimento'])}h',
              ),
            _buildInfoCard(
              context,
              'Horas Extras',
              '${_formatNumber(preview['horas_extras'])}h',
            ),
            _buildInfoCard(
              context,
              'Etapas',
              '${preview['total_etapas'] ?? 0}',
            ),
            _buildInfoCard(
              context,
              'Dias Trabalhados',
              '${preview['dias_trabalhados'] ?? 0}',
            ),
            if ((preview['dias_ferias'] ?? 0) > 0)
              _buildInfoCard(
                context,
                'Dias de Férias',
                '${preview['dias_ferias'] ?? 0}',
              ),
            const Divider(),
            _buildSectionTitle(context, 'VANTAGENS'),
            _buildInfoCard(
              context,
              'Salário Base',
              'R\$ ${_formatCurrency(preview['salario_base'] ?? 0)}',
            ),
            _buildInfoCard(
              context,
              'Horas Extras',
              'R\$ ${_formatCurrency(preview['valor_horas_extras'])}',
            ),
            _buildInfoCard(
              context,
              'Etapas',
              'R\$ ${_formatCurrency(preview['valor_etapas'])}',
            ),
            if (_toDouble(preview['outras_vantagens']) > 0)
              _buildInfoCard(
                context,
                'Outras Vantagens (ex: substituição)',
                'R\$ ${_formatCurrency(preview['outras_vantagens'])}',
              ),
            _buildInfoCard(
              context,
              'Salário Bruto (sem VA)',
              'R\$ ${_formatCurrency(preview['salario_bruto'])}',
              isHighlight: true,
              color: Colors.blue.shade700,
            ),
            _buildInfoCard(
              context,
              'Vale Alimentação',
              'R\$ ${_formatCurrency(preview['vale_alimentacao'])}',
            ),
            _buildInfoCard(
              context,
              'Total Recebimentos',
              'R\$ ${_formatCurrency(preview['total_recebimentos'] ?? _toDouble(preview['salario_bruto']) + _toDouble(preview['vale_alimentacao']))}',
              isHighlight: true,
              color: Colors.blue.shade900,
            ),
            const Divider(),
            _buildSectionTitle(context, 'DESCONTOS'),
            _buildInfoCard(
              context,
              'Previdência',
              'R\$ ${_formatCurrency(preview['desconto_previdencia'])}',
              color: Colors.red.shade700,
            ),
            _buildInfoCard(
              context,
              'IRPF',
              'R\$ ${_formatCurrency(preview['desconto_irpf'] ?? 0)}',
              color: Colors.red.shade700,
            ),
            if (_toDouble(preview['base_irpf'] ?? 0) > 0)
              _buildInfoCard(
                context,
                'Base IRPF',
                'R\$ ${_formatCurrency(preview['base_irpf'])}',
                color: Colors.red.shade400,
              ),
            if (_toDouble(preview['desconto_consignados'] ?? 0) > 0)
              _buildInfoCard(
                context,
                'Consignados',
                'R\$ ${_formatCurrency(preview['desconto_consignados'])}',
                color: Colors.red.shade700,
              ),
            if (_toDouble(preview['outros_descontos'] ?? 0) > 0)
              _buildInfoCard(
                context,
                'Outros Descontos em Folha',
                'R\$ ${_formatCurrency(preview['outros_descontos'])}',
                color: Colors.red.shade700,
              ),
            _buildInfoCard(
              context,
              'Total de Descontos',
              'R\$ ${_formatCurrency(
                _toDouble(preview['desconto_previdencia']) +
                _toDouble(preview['desconto_irpf']) +
                _toDouble(preview['desconto_consignados'] ?? 0) +
                _toDouble(preview['outros_descontos'] ?? 0)
              )}',
              isHighlight: true,
              color: Colors.red.shade900,
            ),
            const Divider(),
            _buildSectionTitle(context, 'LÍQUIDO'),
            _buildInfoCard(
              context,
              'Salário Líquido (folha)',
              'R\$ ${_formatCurrency(preview['salario_liquido_folha'] ?? preview['salario_liquido'])}',
              isHighlight: true,
              color: Colors.green.shade700,
            ),
            _buildInfoCard(
              context,
              'VA + Etapas',
              'R\$ ${_formatCurrency(preview['va_mais_etapas'] ?? (_toDouble(preview['vale_alimentacao']) + _toDouble(preview['valor_etapas'])))}',
              isHighlight: true,
              color: Colors.teal.shade700,
            ),
            _buildInfoCard(
              context,
              'Total Líquido',
              'R\$ ${_formatCurrency(preview['salario_liquido'])}',
              isHighlight: true,
              color: Colors.green.shade900,
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatNumber(dynamic value) {
    return _toDouble(value).toStringAsFixed(2);
  }

  String _formatCurrency(dynamic value) {
    return _toDouble(value).toStringAsFixed(2);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isHighlight ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

