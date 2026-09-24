# Melhorias de UX - Dashboard Permuta Policial

Documento das mudanças de UX implementadas para melhorar a hierarquia de informação no dashboard.

## 🎯 Problema Identificado

### Antes
O dashboard tinha múltiplos CTAs competindo por atenção:
- Hero (matches compatíveis)
- Campo Minado (jogo casual)
- PIX Footer (doações)
- Ferramentas
- Comunidade

**Resultado:** Usuário não sabia qual era a ação principal.

## ✨ Solução Implementada

### Nova Hierarquia

```
1. Hero (Matches Compatíveis) ← Ação primária
2. Acesso Rápido (Criar Anúncio, Permutas, Editais)
3. Consultoria Jurídica (se disponível)
4. Matches Section (detalhamento)
5. Parceiros (se existentes)
6. Ferramentas (Mapa, Marketplace, etc)
7. Comunidade (Fórum, Questions)
8. Apoiar o Projeto ← Zona secundária
   └─ Campo Minado
   └─ PIX Footer
```

### Mudanças Específicas

#### Dashboard Desktop (2 colunas)
```dart
desktopColumn: [
  _buildHero(),
  _buildQuickAccess(),
  _buildToolsGrid(),
  _buildCommunityLinks(),
  _buildPermutasInteligentesCard(),
  _buildExtrasSection(), // ← NOVO: agrupa Campo Minado + PIX
]
```

#### Dashboard Mobile (1 coluna)
```dart
mobileColumn: [
  _buildHero(),
  ReferralDashboardCard(),
  _buildQuickAccess(),
  _buildMatchesSection(),
  _buildToolsGrid(),
  _buildCommunityLinks(),
  _buildPermutasInteligentesCard(),
  _buildExtrasSection(), // ← NOVO
]
```

## 🆕 Nova Seção: "Apoiar o Projeto"

### Implementação

Arquivo: `permuta_policial/lib/features/dashboard/screens/dashboard_screen_v3.dart`

```dart
Widget _buildExtrasSection(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header da seção
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(Icons.volunteer_activism, color: _muted, size: 16),
              const SizedBox(width: 8),
              Text('Apoiar o Projeto', style: TextStyle(...)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Conteúdo: Campo Minado + PIX
        _buildCampoMinadoCard(context),
        const SizedBox(height: 8),
        const DashboardPixFooter(),
      ],
    ),
  );
}
```

### Visual

```
┌─────────────────────────────────────┐
│ 🤝 Apoiar o Projeto                 │
├─────────────────────────────────────┤
│ ╔═════════════════════════════════╗ │
│ ║ 🎮 Campo Minado             ›   ║ │
│ ╚═════════════════════════════════╝ │
│                                     │
│ ╔═════════════════════════════════╗ │
│ ║ 💸 Apoie via PIX                ║ │
│ ║ [QR Code] [Copiar Chave]        ║ │
│ ╚═════════════════════════════════╝ │
└─────────────────────────────────────┘
```

## 📊 Impacto Esperado

### Métricas de Engajamento

**Antes (hipótese):**
- Usuários distraídos pelo jogo
- CTAs de permuta menos clicados
- Confusão sobre ação principal

**Depois (esperado):**
- Foco nos matches compatíveis
- Aumento de solicitações de contato
- Redução de bounce rate no dashboard

### Funcionalidades Mantidas

✅ Campo Minado ainda acessível  
✅ PIX Footer ainda visível  
✅ Embaixadores podem promover doações  
✅ Todas as ferramentas disponíveis  

## 🎨 Princípios de Design Aplicados

### 1. Hierarquia Visual
- **Primário:** Hero (grande, colorido, animado)
- **Secundário:** Ferramentas (ícones, grid)
- **Terciário:** Apoio (compacto, agrupado)

### 2. Progressive Disclosure
- Informações principais imediatas
- Ferramentas avançadas após scroll
- Apoio/extras no final

### 3. Consistência
- Layouts desktop/mobile seguem mesma ordem
- Cards mantêm estilo visual uniforme
- Ícones e cores do design system

## 🔄 Trabalho NÃO implementado

### Onboarding "Como usar"

**Motivo:** Requer provider + SharedPreferences para flag persistida.

**Implementação sugerida:**
```dart
// 1. Provider
class OnboardingProvider extends ChangeNotifier {
  bool _dashboardOnboardingShown = false;
  
  Future<void> loadFlags() async {
    final prefs = await SharedPreferences.getInstance();
    _dashboardOnboardingShown = prefs.getBool('dashboard_onboarding_shown') ?? false;
  }
  
  Future<void> markDashboardOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dashboard_onboarding_shown', true);
    _dashboardOnboardingShown = true;
    notifyListeners();
  }
}

// 2. No dashboard
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final onboarding = context.read<OnboardingProvider>();
    if (!onboarding.dashboardOnboardingShown) {
      _showOnboarding();
      onboarding.markDashboardOnboardingShown();
    }
  });
}
```

### Notificações Agregadas

**Motivo:** Requer mudança no backend de notificações.

**Implementação sugerida:**
```sql
-- Nova coluna
ALTER TABLE notificacoes ADD COLUMN aggregation_key VARCHAR(100);
ALTER TABLE notificacoes ADD COLUMN aggregated_count INT DEFAULT 1;

-- Lógica de agregação
-- Ao criar notificação "NOVO_MATCH", verificar se existe outra 
-- não lida com mesmo aggregation_key nas últimas 24h
-- Se sim: incrementar aggregated_count ao invés de inserir nova
```

### Privacy Consistency

**Análise necessária:**
- Interessados: visível para todos
- Proximidade: visível para verificados
- Motivo: proteger unidades sensíveis

**Recomendação:** Manter política atual, melhorar documentação no help.

## 🐛 Bugs Conhecidos (Não Corrigidos)

### 1. Histórico de Questions - Spinner Infinito

**Sintoma:** Ao voltar da tela de histórico, spinner não para.

**Causa provável:** Provider não cancela request anterior.

**Solução sugerida:**
```dart
class QuestionsProvider {
  CancelToken? _currentRequest;
  
  Future<void> fetchHistorico() async {
    _currentRequest?.cancel();
    _currentRequest = CancelToken();
    
    try {
      final response = await api.get('/questions/historico', 
        cancelToken: _currentRequest);
      // ...
    } catch (e) {
      if (e is! CancelledException) {
        // tratar erro
      }
    }
  }
}
```

### 2. Mapa Visitor - "Sessão Expirou"

**Sintoma:** Visitante clica em marker, vê "Sua sessão expirou".

**Análise:** Código atual parece correto (`_showLoginPrompt`).

**Recomendação:** Reproduzir com debug para identificar caminho exato.

### 3. Profile 100% vs Gate de Marketplace

**Sintoma:** Usuário vê "Perfil 100%" mas não pode criar anúncio.

**Solução sugerida:**
```dart
Widget _buildProfileCompletion() {
  final isVerified = authProvider.user?.agenteVerificado == true;
  final canCreateAd = profileCompletion >= 100 && isVerified;
  
  return Column(
    children: [
      Text('Perfil: $profileCompletion%'),
      if (profileCompletion >= 100 && !isVerified)
        Text('⚠️ Verificação de agente pendente para criar anúncios',
          style: TextStyle(fontSize: 12, color: Colors.amber)),
    ],
  );
}
```

## 📱 Responsividade

### Breakpoints

```dart
const kDashboardDesktopBreakpoint = 900.0;

// Layout automático
Widget build(BuildContext context) {
  final isDesktop = MediaQuery.sizeOf(context).width >= kDashboardDesktopBreakpoint;
  
  return isDesktop 
    ? DashboardDesktopLayout(...)
    : SingleChildScrollView(...);
}
```

### Testado em:
- ✅ iPhone SE (375px)
- ✅ Android 6" (393px)
- ✅ Tablet 10" (768px)
- ✅ Desktop 1920x1080

## 🚀 Próximos Passos (UX)

1. **A/B Test**
   - Versão A: Dashboard atual
   - Versão B: Dashboard com "Apoiar" no rodapé
   - Métrica: Taxa de solicitação de contato

2. **Onboarding Contextual**
   - Tooltip na primeira visita
   - Tour guiado opcional
   - Video explicativo curto

3. **Personalização**
   - Usuário escolhe ordem dos widgets
   - Ocultar seções não usadas
   - Temas (claro/escuro)

4. **Acessibilidade**
   - Tamanhos de fonte ajustáveis
   - Alto contraste
   - Screen reader labels

## 📚 Referências

- [Material Design - Navigation](https://m3.material.io/components/navigation-drawer)
- [Flutter Layout Guide](https://docs.flutter.dev/ui/layout)
- [UX Best Practices - Nielsen Norman](https://www.nngroup.com/articles/information-scent/)
