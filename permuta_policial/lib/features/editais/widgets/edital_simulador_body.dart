import 'package:flutter/material.dart';
import 'package:permuta_policial/core/config/app_styles.dart';
import 'package:permuta_policial/core/config/app_theme.dart';
import 'package:permuta_policial/core/models/analise_vaga.dart';
import 'package:permuta_policial/core/models/vaga_edital.dart';
import 'package:permuta_policial/features/editais/providers/edital_simulador_provider.dart';
import 'package:permuta_policial/shared/widgets/custom_dropdown_search.dart';

class EditalSimuladorBody extends StatelessWidget {
  final EditalSimuladorProvider provider;
  final Widget? header;

  const EditalSimuladorBody({
    super.key,
    required this.provider,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.status == EditalSimuladorStatus.loading) {
      return Column(
        children: [
          if (header != null) header!,
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (provider.status == EditalSimuladorStatus.error) {
      return Column(
        children: [
          if (header != null) header!,
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage ?? 'Erro ao carregar simulador'),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (header != null) header!,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildResumoCard(context, provider),
              const SizedBox(height: 20),
              Text('Minhas 3 opções de intenção', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'A análise carrega automaticamente ao selecionar cada vaga',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              _buildChoiceWithAnalysis(context, provider, 1, provider.selectedChoice1, provider.analise1, provider.isAnalyzing1),
              const SizedBox(height: 20),
              _buildChoiceWithAnalysis(context, provider, 2, provider.selectedChoice2, provider.analise2, provider.isAnalyzing2),
              const SizedBox(height: 20),
              _buildChoiceWithAnalysis(context, provider, 3, provider.selectedChoice3, provider.analise3, provider.isAnalyzing3),
              const SizedBox(height: 28),
              _buildSaveButton(context, provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoCard(BuildContext context, EditalSimuladorProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Sua classificação',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.minhaPosicao ?? '...'}º',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.how_to_vote_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${provider.totalIntencoesRegistradas} intenções registradas neste edital',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceWithAnalysis(
    BuildContext context,
    EditalSimuladorProvider provider,
    int choiceNumber,
    VagaEdital? selectedVaga,
    AnaliseVaga? analise,
    bool isAnalyzing,
  ) {
    final label = switch (choiceNumber) {
      1 => '1ª opção de lotação',
      2 => '2ª opção de lotação',
      3 => '3ª opção de lotação',
      _ => 'Opção',
    };

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CustomDropdownSearch<VagaEdital>(
              label: label,
              items: provider.vagasDisponiveis,
              selectedItem: selectedVaga,
              itemAsString: (vaga) => vaga.toString(),
              onChanged: (vaga) => provider.updateChoice(choiceNumber, vaga),
            ),
            if (selectedVaga != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              if (isAnalyzing)
                _buildAnalysisLoading()
              else if (analise != null)
                _buildCompactAnalysis(context, analise)
              else
                _buildAnalysisPlaceholder(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(height: 8),
            Text('Analisando vaga...', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text('Não foi possível carregar a análise', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ),
    );
  }

  Widget _buildCompactAnalysis(BuildContext context, AnaliseVaga analise) {
    final totalVagas = analise.vagaInfo.vagasDisponiveis;
    final totalInteressados = analise.competicao.totalInteressados;
    final maisAntigos = analise.competicao.maisAntigos;
    final maisModernos = analise.competicao.maisModernos;
    final competidores1 = analise.competicao.como1Opcao;
    final competidores2 = analise.competicao.como2Opcao;
    final competidores3 = analise.competicao.como3Opcao;

    late Color chanceColor;
    late String chanceText;
    late IconData chanceIcon;

    if (maisAntigos < totalVagas) {
      chanceColor = Colors.green;
      chanceText = 'BOA CHANCE';
      chanceIcon = Icons.check_circle;
    } else if (maisAntigos < totalVagas * 1.5) {
      chanceColor = Colors.orange;
      chanceText = 'COMPETITIVO';
      chanceIcon = Icons.warning;
    } else {
      chanceColor = Colors.red;
      chanceText = 'MUITO COMPETITIVO';
      chanceIcon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chanceColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: chanceColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chanceIcon, color: chanceColor, size: 20),
                const SizedBox(width: 8),
                Text(chanceText, style: TextStyle(color: chanceColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(icon: Icons.inventory_2_outlined, label: 'Vagas disponíveis', value: '$totalVagas'),
          const SizedBox(height: 8),
          _buildInfoRow(icon: Icons.military_tech_outlined, label: 'Sua classificação', value: '${analise.minhaPosicao}º'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  label: 'Interessados',
                  value: '$totalInteressados',
                  color: Colors.blueGrey.shade700,
                  bg: Colors.blueGrey.shade50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  label: 'Mais antigos',
                  value: '$maisAntigos',
                  color: Colors.brown.shade800,
                  bg: Colors.brown.shade50,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  label: 'Mais modernos',
                  value: '$maisModernos',
                  color: Colors.indigo.shade800,
                  bg: Colors.indigo.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Mais antigos que escolheram esta vaga:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
          const SizedBox(height: 8),
          _buildCompetitorRow('Como 1ª opção', competidores1, Colors.red[700]!),
          _buildCompetitorRow('Como 2ª opção', competidores2, Colors.orange[800]!),
          _buildCompetitorRow('Como 3ª opção', competidores3, Colors.blue[800]!),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCompetitorRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text('$count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, EditalSimuladorProvider provider) {
    final isLoading = provider.status == EditalSimuladorStatus.saving;
    return ElevatedButton(
      style: AppStyles.primaryButton,
      onPressed: isLoading
          ? null
          : () async {
              await provider.salvarIntencoes();
              if (!context.mounted) return;
              if (provider.status != EditalSimuladorStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppStyles.successSnackBar('Intenções salvas com sucesso!'),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  AppStyles.errorSnackBar(provider.errorMessage ?? 'Erro ao salvar'),
                );
              }
            },
      child: isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
          : const Text('SALVAR INTENÇÕES'),
    );
  }
}
