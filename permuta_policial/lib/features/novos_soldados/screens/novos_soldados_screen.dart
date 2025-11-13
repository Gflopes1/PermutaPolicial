import 'package:flutter/material.dart';
import 'package:permuta_policial/core/models/vaga_edital.dart';
import 'package:permuta_policial/features/novos_soldados/providers/novos_soldados_provider.dart';
import 'package:permuta_policial/shared/widgets/custom_dropdown_search.dart';
import 'package:provider/provider.dart';

class NovosSoldadosScreen extends StatefulWidget {
  const NovosSoldadosScreen({Key? key}) : super(key: key);

  @override
  State<NovosSoldadosScreen> createState() => _NovosSoldadosScreenState();
}

class _NovosSoldadosScreenState extends State<NovosSoldadosScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NovosSoldadosProvider>(context, listen: false).loadDadosTela();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NovosSoldadosProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Simulador de Escolha'),
          ),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NovosSoldadosProvider provider) {
    if (provider.status == SoldadoScreenStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == SoldadoScreenStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar dados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'Erro desconhecido',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(provider),
          const SizedBox(height: 24),
          Text(
            'Minhas 3 Opções de Intenção',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'A análise é carregada automaticamente ao selecionar cada vaga',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          _buildChoiceWithAnalysis(
            context, 
            provider, 
            1,
            provider.selectedChoice1,
            provider.analise1,
            provider.isAnalyzing1,
          ),
          const SizedBox(height: 24),
          
          _buildChoiceWithAnalysis(
            context, 
            provider, 
            2,
            provider.selectedChoice2,
            provider.analise2,
            provider.isAnalyzing2,
          ),
          const SizedBox(height: 24),
          
          _buildChoiceWithAnalysis(
            context, 
            provider, 
            3,
            provider.selectedChoice3,
            provider.analise3,
            provider.isAnalyzing3,
          ),
          
          const SizedBox(height: 32),
          _buildSaveButton(provider),
        ],
      ),
    );
  }

  Widget _buildInfoCard(NovosSoldadosProvider provider) {
    return Card(
      elevation: 2,
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Sua Classificação: ${provider.minhaPosicao ?? '...'}º',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildChoiceWithAnalysis(
    BuildContext context,
    NovosSoldadosProvider provider,
    int choiceNumber,
    VagaEdital? selectedVaga,
    analise,
    bool isAnalyzing,
  ) {
    String label;
    switch (choiceNumber) {
      case 1: label = '1ª Opção de Lotação'; break;
      case 2: label = '2ª Opção de Lotação'; break;
      case 3: label = '3ª Opção de Lotação'; break;
      default: label = 'Opção';
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            CustomDropdownSearch<VagaEdital>(
              label: label,
              items: provider.vagasDisponiveis,
              selectedItem: selectedVaga,
              itemAsString: (vaga) => vaga.toString(),
              onChanged: (vaga) {
                provider.updateChoice(choiceNumber, vaga);
              },
            ),
            
            // Mostra análise ou loading
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
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 8),
            Text(
              'Analisando vaga...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          'Não foi possível carregar a análise',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildCompactAnalysis(BuildContext context, analise) {
    // Calcula a "chance" baseada na competição
    final totalVagas = analise.vagaInfo.vagasDisponiveis;
    final competidores1 = analise.competicao.como1Opcao;
    final competidores2 = analise.competicao.como2Opcao;
    final competidores3 = analise.competicao.como3Opcao;
    
    // Lógica simples: compara total de competidores melhor classificados vs vagas
    final totalCompetidores = competidores1 + competidores2 + competidores3;
    
    Color chanceColor;
    String chanceText;
    IconData chanceIcon;
    
    if (totalCompetidores < totalVagas) {
      chanceColor = Colors.green;
      chanceText = 'BOA CHANCE';
      chanceIcon = Icons.check_circle;
    } else if (totalCompetidores < totalVagas * 1.5) {
      chanceColor = Colors.orange;
      chanceText = 'COMPETITIVO';
      chanceIcon = Icons.warning;
    } else {
      chanceColor = Colors.red;
      chanceText = 'MUITO COMPETITIVO';
      chanceIcon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador visual de chance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chanceColor.withAlpha(12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: chanceColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chanceIcon, color: chanceColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  chanceText,
                  style: TextStyle(
                    color: chanceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Info compacta
          _buildInfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'Vagas disponíveis',
            value: '$totalVagas',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Sua posição',
            value: '${analise.minhaPosicao}º',
          ),
          const SizedBox(height: 12),
          
          Text(
            'Competidores melhor classificados:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          _buildCompetitorRow('1ª opção', competidores1, Colors.red[700]!),
          _buildCompetitorRow('2ª opção', competidores2, Colors.orange[700]!),
          _buildCompetitorRow('3ª opção', competidores3, Colors.blue[700]!),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitorRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(NovosSoldadosProvider provider) {
    bool isLoading = provider.status == SoldadoScreenStatus.saving;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
      onPressed: isLoading
          ? null
          : () async {
              try {
                await provider.salvarIntencoes();
                
                if (!mounted) return; 
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Intenções salvas com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              
              } catch (e) {
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao salvar: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : const Text('SALVAR INTENÇÕES'),
    );
  }
}