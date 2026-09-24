// /lib/shared/widgets/app_bar_helper.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'relatar_problema_dialog.dart';

class AppBarHelper {
  /// Obtém o nome amigável da página atual baseado na rota
  static String getNomePagina(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    
    // Mapeamento de rotas para nomes amigáveis
    final Map<String, String> rotasNomes = {
      '/marketplace': 'Marketplace',
      '/permutas': 'Permutas',
      '/permutas-inteligentes': 'Permutas',
      '/mapa': 'Mapa',
      '/notificacoes': 'Notificações',
      '/meus-dados': 'Meus Dados',
      '/calendar': 'Calendário',
      '/questions': 'Questões',
      '/questions/detail': 'Detalhes da Questão',
      '/questions/comments': 'Comentários',
      '/simulado/create': 'Criar Simulado',
      '/simulado/play': 'Simulado',
      '/simulado/result': 'Resultado do Simulado',
      '/practice': 'Modo Prática',
      '/practice/history': 'Histórico de Prática',
      '/questions/admin': 'Administração de Questões',
      '/questions/list-all': 'Todas as Questões',
      '/chat/conversa': 'Conversa',
      '/forum/topico': 'Tópico do Fórum',
      '/forum/moderacao': 'Moderação do Fórum',
      '/forum/create-topico': 'Criar Tópico',
      '/admin': 'Administração',
      '/completar-perfil': 'Completar Perfil',
      '/editais': 'Hub de Editais',
    };

    // Tenta encontrar correspondência exata primeiro
    if (rotasNomes.containsKey(location)) {
      return rotasNomes[location]!;
    }

    // Tenta encontrar correspondência parcial (para rotas com parâmetros)
    for (final entry in rotasNomes.entries) {
      if (location.startsWith(entry.key)) {
        return entry.value;
      }
    }

    // Se não encontrar, retorna o nome da rota formatado
    return _formatarNomeRota(location);
  }

  /// Formata o nome da rota para um nome mais amigável
  static String _formatarNomeRota(String rota) {
    if (rota == '/' || rota.isEmpty) {
      return 'Página Inicial';
    }
    
    // Remove a barra inicial e formata
    String nome = rota.replaceFirst('/', '');
    nome = nome.replaceAll('/', ' > ');
    nome = nome.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
    
    return nome.isEmpty ? 'Página Desconhecida' : nome;
  }

  /// Adiciona o botão "Relatar Problema" nas actions da AppBar
  static List<Widget> adicionarBotaoRelatarProblema(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.bug_report_outlined),
        tooltip: 'Relatar Problema',
        onPressed: () {
          final nomePagina = getNomePagina(context);
          RelatarProblemaDialog.show(context, nomePagina);
        },
      ),
    ];
  }
}
