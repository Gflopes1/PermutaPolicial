import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

import '../../../core/config/app_styles.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/utils/file_export.dart';
import '../providers/admin_provider.dart';

class AdminAnalyticsTab extends StatefulWidget {
  const AdminAnalyticsTab({super.key});

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab> {
  bool _tabelaCrescimentoExpandida = false;
  bool _exportando = false;

  static const _periodos = {
    '7d': 7,
    '30d': 30,
    '90d': 90,
    '365d': 365,
  };

  Future<void> _aplicarPeriodo(String key) async {
    final provider = context.read<AdminProvider>();
    if (key == 'tudo') {
      await provider.loadAnalytics(limparPeriodo: true);
      return;
    }
    if (key == 'custom') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        ),
      );
      if (range == null || !mounted) return;
      await provider.loadAnalytics(
        dataInicio: _fmtDate(range.start),
        dataFim: _fmtDate(range.end),
      );
      return;
    }
    final dias = _periodos[key] ?? 30;
    final fim = DateTime.now();
    final inicio = fim.subtract(Duration(days: dias));
    await provider.loadAnalytics(
      dataInicio: _fmtDate(inicio),
      dataFim: _fmtDate(fim),
    );
  }

  String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _exportarJson(AdminProvider provider) async {
    setState(() => _exportando = true);
    try {
      final data = await provider.exportMediaKitJson();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await exportTextFile('permuta_media_kit_$timestamp.json', jsonStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON exportado com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar JSON: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _exportarPdf(AdminProvider provider) async {
    setState(() => _exportando = true);
    try {
      final data = await provider.exportMediaKitJson();
      final doc = _buildMediaKitPdf(data);
      final bytes = await doc.save();
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      await exportBytesFile(
        'permuta_media_kit_$timestamp.pdf',
        bytes,
        mimeType: 'application/pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  pw.Document _buildMediaKitPdf(Map<String, dynamic> data) {
    final doc = pw.Document();
    final funil = Map<String, dynamic>.from(data['funil_permuta'] ?? {});
    final resumo = Map<String, dynamic>.from(data['resumo'] ?? {});
    final estados = (data['usuarios_por_estado'] as List?) ?? [];
    final forcas = (data['usuarios_por_forca'] as List?) ?? [];
    final crescimento = Map<String, dynamic>.from(data['crescimento'] ?? {});
    final cumulativo = (crescimento['cumulativo_mes'] as List?) ?? [];
    final contasAtivas = (data['contas_ativas'] as List?) ?? [];
    final engajamento = Map<String, dynamic>.from(data['engajamento'] ?? {});

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Permuta Policial — Media Kit Analytics',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Gerado em: ${data['gerado_em'] ?? DateTime.now().toIso8601String()}'),
          pw.SizedBox(height: 16),
          pw.Text('Resumo Geral', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: 'Total de contas: ${funil['total_contas'] ?? 0}'),
          pw.Bullet(text: 'Verificados: ${funil['verificados'] ?? 0}'),
          pw.Bullet(text: 'Com intenções: ${funil['com_intencoes'] ?? 0}'),
          pw.Bullet(text: 'Premium ativos: ${funil['premium_ativos'] ?? 0}'),
          pw.Bullet(text: 'Permutas concluídas: ${funil['permutas_concluidas'] ?? 0}'),
          pw.Bullet(text: 'Page views (período): ${resumo['total_page_views'] ?? 0}'),
          pw.Bullet(text: 'Usuários únicos (período): ${resumo['usuarios_unicos'] ?? 0}'),
          pw.Bullet(text: 'Views permuta/mapa: ${engajamento['page_views_permuta'] ?? 0}'),
          pw.SizedBox(height: 16),
          pw.Text('Crescimento (cumulativo mensal)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ...cumulativo.take(12).map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            return pw.Text('${m['data']}: ${m['total']} usuários');
          }),
          pw.SizedBox(height: 16),
          pw.Text('Contas ativas (mensal)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ...contasAtivas.take(12).map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            return pw.Text('${m['data']}: ${m['usuarios_ativos']} ativos');
          }),
          pw.SizedBox(height: 16),
          pw.Text('Usuários por Estado (UF)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: ['UF', 'Total', 'Verificados', 'Com intenções'],
            data: estados.take(27).map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return [
                m['sigla']?.toString() ?? '',
                '${m['total'] ?? 0}',
                '${m['verificados'] ?? 0}',
                '${m['com_intencoes'] ?? 0}',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Usuários por Força Policial', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: ['Força', 'Total', 'Verificados', 'Com intenções'],
            data: forcas.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return [
                m['sigla']?.toString() ?? '',
                '${m['total'] ?? 0}',
                '${m['verificados'] ?? 0}',
                '${m['com_intencoes'] ?? 0}',
              ];
            }).toList(),
          ),
        ],
      ),
    );
    return doc;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingAnalytics && provider.analyticsEstatisticas == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.analyticsErrorMessage != null && provider.analyticsEstatisticas == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                AppStyles.spacingSmall,
                Text(provider.analyticsErrorMessage!, textAlign: TextAlign.center),
                AppStyles.spacingMedium,
                ElevatedButton(
                  onPressed: () => provider.loadAnalytics(),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadAnalytics(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return ListView(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                children: [
                  if (provider.analyticsErrorMessage != null)
                    _warningBanner(provider.analyticsErrorMessage!),
                  _buildToolbar(provider, isMobile),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildResumoCards(provider, isMobile),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildGranularidadeSelector(provider, isMobile),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildCrescimentoChart(provider, isMobile),
                  _buildTabelaCrescimento(provider, isMobile),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildContasAtivasChart(provider, isMobile),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildUsuariosPorEstado(provider, isMobile),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildUsuariosPorForca(provider, isMobile),
                  SizedBox(height: isMobile ? 12 : 16),
                  _buildFunilPermuta(provider, isMobile),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _warningBanner(String msg) {
    return Card(
      color: AppTheme.error.withAlpha(20),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.warning, color: AppTheme.error, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(AdminProvider provider, bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics & Media Kit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _periodChip('7 dias', '7d'),
                _periodChip('30 dias', '30d'),
                _periodChip('90 dias', '90d'),
                _periodChip('1 ano', '365d'),
                _periodChip('Tudo', 'tudo'),
                _periodChip('Personalizado', 'custom'),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: provider.isLoadingAnalytics ? null : () => provider.loadAnalytics(),
                  icon: provider.isLoadingAnalytics
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _exportando ? null : () => _exportarJson(provider),
                  icon: const Icon(Icons.data_object, size: 18),
                  label: const Text('Exportar JSON'),
                ),
                OutlinedButton.icon(
                  onPressed: _exportando ? null : () => _exportarPdf(provider),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Exportar PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label, String key) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => _aplicarPeriodo(key),
    );
  }

  Widget _buildResumoCards(AdminProvider provider, bool isMobile) {
    final stats = provider.analyticsEstatisticas ?? {};
    final funil = provider.funilPermuta ?? {};
    final sessoes = provider.sessoesStats ?? {};

    final cards = [
      _statCard('Contas totais', '${funil['total_contas'] ?? 0}', Icons.people),
      _statCard('Verificados', '${funil['verificados'] ?? 0}', Icons.verified),
      _statCard('Com intenções', '${funil['com_intencoes'] ?? 0}', Icons.swap_horiz),
      _statCard('Premium', '${funil['premium_ativos'] ?? 0}', Icons.star),
      _statCard('Page views', '${stats['total_page_views'] ?? 0}', Icons.visibility),
      _statCard('Usuários únicos', '${stats['usuarios_unicos'] ?? 0}', Icons.person),
      _statCard('Sessões', '${stats['total_sessoes'] ?? 0}', Icons.access_time),
      _statCard(
        'Duração média',
        sessoes['duracao_media_segundos'] != null
            ? '${(sessoes['duracao_media_segundos'] as num).toStringAsFixed(0)}s'
            : 'N/A',
        Icons.timer,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: cards,
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGranularidadeSelector(AdminProvider provider, bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Granularidade do crescimento', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final g in ['dia', 'semana', 'mes', 'ano'])
                  ChoiceChip(
                    label: Text(g[0].toUpperCase() + g.substring(1)),
                    selected: provider.crescimentoGranularidade == g,
                    onSelected: provider.isLoadingAnalytics
                        ? null
                        : (_) => provider.loadAnalytics(granularidade: g),
                  ),
                FilterChip(
                  label: const Text('Cumulativo'),
                  selected: provider.crescimentoCumulativo,
                  onSelected: provider.isLoadingAnalytics
                      ? null
                      : (v) => provider.loadAnalytics(cumulativo: v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrescimentoChart(AdminProvider provider, bool isMobile) {
    final data = provider.crescimentoUsuarios;
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.crescimentoCumulativo
                  ? 'Crescimento cumulativo de usuários'
                  : 'Novos usuários por período',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            SizedBox(
              height: isMobile ? 200 : 260,
              child: _lineChart(data, isMobile: isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaCrescimento(AdminProvider provider, bool isMobile) {
    final data = provider.crescimentoUsuarios;
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: ExpansionTile(
        initiallyExpanded: _tabelaCrescimentoExpandida,
        onExpansionChanged: (v) => setState(() => _tabelaCrescimentoExpandida = v),
        title: Text(
          'Tabela de crescimento (${data.length} períodos)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: const Text('Clique para expandir/ocultar'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: isMobile
                ? Column(
                    children: data.map((item) {
                      final m = Map<String, dynamic>.from(item as Map);
                      return ListTile(
                        dense: true,
                        title: Text('${m['data']}'),
                        trailing: Text(
                          provider.crescimentoCumulativo
                              ? '${m['total']} (cum.)'
                              : '${m['novos'] ?? m['total']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Período')),
                        DataColumn(
                          label: Text(provider.crescimentoCumulativo ? 'Total cumulativo' : 'Novos'),
                          numeric: true,
                        ),
                      ],
                      rows: data.map((item) {
                        final m = Map<String, dynamic>.from(item as Map);
                        return DataRow(cells: [
                          DataCell(Text('${m['data']}')),
                          DataCell(Text('${m['total']}')),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContasAtivasChart(AdminProvider provider, bool isMobile) {
    final data = provider.contasAtivas;
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contas ativas (usuários com page views)', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: isMobile ? 12 : 16),
            SizedBox(
              height: isMobile ? 180 : 220,
              child: _lineChart(
                data,
                valueKey: 'usuarios_ativos',
                isMobile: isMobile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuariosPorEstado(AdminProvider provider, bool isMobile) {
    final estados = provider.usuariosPorEstado;
    if (estados.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuários por Estado (UF)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...estados.map((item) => _SegmentoExpansivel(
              key: ValueKey('estado_${item['estado_id']}_${provider.crescimentoGranularidade}_${provider.crescimentoCumulativo}'),
              titulo: '${item['sigla']} — ${item['total']} usuários',
              subtitulo: 'Verificados: ${item['verificados']} · Intenções: ${item['com_intencoes']}',
              segmentoId: item['estado_id'] as int,
              tipo: _SegmentoTipo.estado,
              provider: provider,
              isMobile: isMobile,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuariosPorForca(AdminProvider provider, bool isMobile) {
    final forcas = provider.usuariosPorForca;
    if (forcas.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuários por Força Policial', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...forcas.map((item) => _SegmentoExpansivel(
              key: ValueKey('forca_${item['forca_id']}_${provider.crescimentoGranularidade}_${provider.crescimentoCumulativo}'),
              titulo: '${item['sigla']} — ${item['total']} usuários',
              subtitulo: 'Verificados: ${item['verificados']} · Intenções: ${item['com_intencoes']}',
              segmentoId: item['forca_id'] as int,
              tipo: _SegmentoTipo.forca,
              provider: provider,
              isMobile: isMobile,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFunilPermuta(AdminProvider provider, bool isMobile) {
    final funil = provider.funilPermuta ?? {};
    final engajamento = provider.engajamentoPermuta ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Funil & Engajamento', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _miniStat('Em destaque', '${funil['em_destaque'] ?? 0}'),
                _miniStat('Alertas ativos', '${funil['alertas_ativos'] ?? 0}'),
                _miniStat('Solic. contato', '${funil['solicitacoes_contato'] ?? 0}'),
                _miniStat('Contatos OK', '${funil['contatos_aceitos'] ?? 0}'),
                _miniStat('Alertas match', '${funil['alertas_match_notificacoes'] ?? 0}'),
                _miniStat('Permutas OK', '${funil['permutas_concluidas'] ?? 0}'),
                _miniStat('Views permuta', '${engajamento['page_views_permuta'] ?? 0}'),
                _miniStat('Views mapa', '${engajamento['page_views_mapa'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _lineChart(List data, {String valueKey = 'total', bool isMobile = false}) {
    if (data.isEmpty) {
      return const Center(child: Text('Sem dados'));
    }

    final spots = data.asMap().entries.map((entry) {
      final m = Map<String, dynamic>.from(entry.value as Map);
      return FlSpot(entry.key.toDouble(), (m[valueKey] ?? 0).toDouble());
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.15 : 10,
        gridData: FlGridData(show: true, drawVerticalLine: !isMobile),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isMobile ? 35 : 42,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(fontSize: isMobile ? 9 : 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isMobile ? 28 : 32,
              interval: (data.length / (isMobile ? 4 : 8)).clamp(1, data.length).toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final m = Map<String, dynamic>.from(data[i] as Map);
                final label = '${m['data']}';
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label.length > 8 ? label.substring(0, 8) : label,
                    style: TextStyle(fontSize: isMobile ? 8 : 9),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: isMobile ? 2.5 : 3,
            dotData: FlDotData(show: data.length <= 31),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withAlpha(40),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SegmentoTipo { estado, forca }

class _SegmentoExpansivel extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final int segmentoId;
  final _SegmentoTipo tipo;
  final AdminProvider provider;
  final bool isMobile;

  const _SegmentoExpansivel({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.segmentoId,
    required this.tipo,
    required this.provider,
    required this.isMobile,
  });

  @override
  State<_SegmentoExpansivel> createState() => _SegmentoExpansivelState();
}

class _SegmentoExpansivelState extends State<_SegmentoExpansivel> {
  bool _loading = false;
  List<dynamic>? _dados;

  Future<void> _carregar() async {
    if (_dados != null) return;
    setState(() => _loading = true);
    try {
      if (widget.tipo == _SegmentoTipo.estado) {
        _dados = await widget.provider.loadCrescimentoEstado(widget.segmentoId);
      } else {
        _dados = await widget.provider.loadCrescimentoForca(widget.segmentoId);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(widget.titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(widget.subtitulo, style: const TextStyle(fontSize: 11)),
      onExpansionChanged: (expanded) {
        if (expanded) _carregar();
      },
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_dados == null || _dados!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sem dados de crescimento para este segmento.'),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: SizedBox(
              height: widget.isMobile ? 160 : 200,
              child: _SegmentoChart(data: _dados!, isMobile: widget.isMobile),
            ),
          ),
      ],
    );
  }
}

class _SegmentoChart extends StatelessWidget {
  final List<dynamic> data;
  final bool isMobile;

  const _SegmentoChart({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((entry) {
      final m = Map<String, dynamic>.from(entry.value as Map);
      return FlSpot(entry.key.toDouble(), (m['total'] ?? 0).toDouble());
    }).toList();
    final maxY = spots.isEmpty ? 10.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY > 0 ? maxY * 1.15 : 10,
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9)),
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.secondary,
            barWidth: 2,
            dotData: FlDotData(show: data.length <= 20),
          ),
        ],
      ),
    );
  }
}
