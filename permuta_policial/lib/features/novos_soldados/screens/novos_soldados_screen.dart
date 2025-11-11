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
    // Assim que a tela é construída, chama o provider para carregar os dados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NovosSoldadosProvider>(context, listen: false).loadDadosTela();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usa o Consumer para ouvir as mudanças do provider
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

  // Constrói o corpo da tela baseado no estado do provider
  Widget _buildBody(BuildContext context, NovosSoldadosProvider provider) {
    // 1. Estado de Loading Inicial
    if (provider.status == SoldadoScreenStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Estado de Erro
    if (provider.status == SoldadoScreenStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Erro ao carregar dados: ${provider.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // 3. Estado Carregado (Idle, Saving, Analyzing)
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
          const SizedBox(height: 16),
          
          // Os 3 Dropdowns de Escolha
          _buildChoiceDropdown(
            context,
            provider,
            label: '1ª Opção de Lotação',
            choiceNumber: 1,
            selectedVaga: provider.selectedChoice1,
          ),
          _buildChoiceDropdown(
            context,
            provider,
            label: '2ª Opção de Lotação',
            choiceNumber: 2,
            selectedVaga: provider.selectedChoice2,
          ),
          _buildChoiceDropdown(
            context,
            provider,
            label: '3ª Opção de Lotação',
            choiceNumber: 3,
            selectedVaga: provider.selectedChoice3,
          ),
          
          const SizedBox(height: 24),
          
          // Botão Salvar
          _buildSaveButton(provider),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Card de Análise de Vaga
          _buildAnalysisResult(provider),
        ],
      ),
    );
  }

  // Card com a posição do usuário
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

  // Widget reutilizável para o Dropdown + Botão Analisar
  Widget _buildChoiceDropdown(
    BuildContext context,
    NovosSoldadosProvider provider, {
    required String label,
    required int choiceNumber,
    required VagaEdital? selectedVaga,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                // Reutiliza o teu widget de dropdown customizado
                child: CustomDropdownSearch<VagaEdital>(
                  label: label,
                  items: provider.vagasDisponiveis,
                  selectedItem: selectedVaga,
                  itemAsString: (vaga) => vaga.toString(), // Usa o VagaEdital.toString()
                  onChanged: (vaga) {
                    provider.updateChoice(choiceNumber, vaga);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Botão para analisar esta vaga específica
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                tooltip: 'Analisar chances desta vaga',
                onPressed: selectedVaga == null
                    ? null // Desabilitado se nenhuma vaga selecionada
                    : () {
                        provider.analisarVaga(selectedVaga.id);
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Botão de salvar
  Widget _buildSaveButton(NovosSoldadosProvider provider) {
    bool isLoading = provider.status == SoldadoScreenStatus.saving;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
      ),
      onPressed: isLoading
          ? null // Desabilitado enquanto salva
            : () async { // 1. Transforma a função anónima em 'async'
              try {
                // 2. Chama a API e 'await' (aguarda) a resposta
                await provider.salvarIntencoes();

                // 3. (A CORREÇÃO) Verifica se a tela ainda está "montada"
                if (!mounted) return; 
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Intenções salvas com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              
              } catch (e) {
                // 4. (A CORREÇÃO) Verifica também no 'catch'
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

  // Card que mostra o resultado da análise
  Widget _buildAnalysisResult(NovosSoldadosProvider provider) {
    // Se estiver analisando, mostra um loader
    if (provider.status == SoldadoScreenStatus.analyzing) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    // Se não houver resultado, não mostra nada
    final analise = provider.analiseResult;
    if (analise == null) {
      return const SizedBox.shrink();
    }

    // Mostra o Card com os dados da análise
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Análise: ${analise.vagaInfo.opm}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            ListTile(
              title: const Text('Vagas Totais no Edital'),
              trailing: Text(
                '${analise.vagaInfo.vagasDisponiveis}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              title: const Text('Sua Posição'),
              trailing: Text(
                '${analise.minhaPosicao}º',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16, right: 16),
              child: Text(
                'Competidores (Melhor Classificados):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              title: const Text('Como 1ª Opção'),
              trailing: Text(
                '${analise.competicao.como1Opcao}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              dense: true,
            ),
            ListTile(
              title: const Text('Como 2ª Opção'),
              trailing: Text(
                '${analise.competicao.como2Opcao}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              dense: true,
            ),
            ListTile(
              title: const Text('Como 3ª Opção'),
              trailing: Text(
                '${analise.competicao.como3Opcao}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}