# Refatoração do Dashboard - Permuta Policial

**Data:** 24/09/2026  
**Branch:** `cursor/security-ux-improvements-1b81`  
**Commit:** `d0e2a90`  
**PR:** [#1](https://github.com/Gflopes1/PermutaPolicial/pull/1)

---

## 📋 Contexto

Feedback do proprietário após revisão do staging:
- Campo Minado ainda visível no dashboard
- Botão "Apoiar"/PIX aparecia cinza/morto quando chave PIX não configurada no banco
- Hierarquia do dashboard não seguia recomendações de UX

---

## ✅ Mudanças Implementadas

### 1. Campo Minado Removido do Dashboard

**Antes:**
- Widget `_buildCampoMinadoCard()` renderizado na seção "Extras"
- Import de `minesweeper_game.dart` no dashboard
- Entry point visível para todos os usuários

**Depois:**
- ✅ Entry point removido do dashboard
- ✅ Widget `MinesweeperGame` preservado em `lib/features/dashboard/widgets/minesweeper_game.dart`
- ✅ Import removido de `dashboard_screen_v3.dart`
- ✅ Função `_buildCampoMinadoCard()` removida
- ✅ Função `_buildExtrasSection()` removida (não mais necessária)

**Arquivos modificados:**
```dart
// dashboard_screen_v3.dart
- import '../widgets/minesweeper_game.dart';  // REMOVIDO
- Widget _buildCampoMinadoCard() { ... }      // REMOVIDO
- Widget _buildExtrasSection() { ... }         // REMOVIDO
```

---

### 2. Hierarquia Reorganizada (Desktop + Mobile)

#### Nova Ordem (Ambos os Layouts)

1. **Hero** - Saudação + estatísticas primárias (interessados, matches)
2. **Matches compatíveis** - Preview de 3 matches, não enterrado
3. **Acesso rápido** - 4 ferramentas principais (grid 2x2 mobile, 4x1 desktop)
4. **Ferramentas** - Grid expandido com mais funcionalidades
5. **Comunidade** - Fórum + links administrativos
6. **Apoio** - Seção dedicada com título e PIX Footer

#### Desktop (≥900px, 2 colunas)

**Coluna Esquerda:**
```
┌─────────────────────────┐
│ Hero (saudação + stats) │
│ Matches compatíveis     │
│ Referral Card           │
│ Acesso rápido (grid)    │
│ Consultoria (se houver) │
└─────────────────────────┘
```

**Coluna Direita:**
```
┌─────────────────────────┐
│ Parceiros (se houver)   │
│ ─────────────────────── │
│ Ferramentas (grid)      │
│ ─────────────────────── │
│ Comunidade              │
│ Permutas Inteligentes   │
│ ─────────────────────── │
│ Apoio                   │
│ └─ PIX Footer           │
└─────────────────────────┘
```

#### Mobile (<900px, 1 coluna)

```
┌─────────────────────────┐
│ Hero                    │
│ Matches compatíveis     │
│ Referral Card           │
│ Acesso rápido           │
│ Consultoria (opcional)  │
│ Parceiros (opcional)    │
│ ─────────────────────── │
│ Ferramentas             │
│ ─────────────────────── │
│ Comunidade              │
│ Permutas Inteligentes   │
│ ─────────────────────── │
│ Apoio                   │
│ └─ PIX Footer           │
└─────────────────────────┘
```

---

### 3. Widget de Apoio (PIX) Sempre Visível

#### Problema Anterior

```dart
// dashboard_pix_footer.dart (ANTES)
@override
Widget build(BuildContext context) {
  if (_chavePix == null || _chavePix!.isEmpty) {
    return const SizedBox.shrink();  // ❌ Desaparecia completamente
  }
  // ... resto do widget
}
```

**Comportamento:** Quando `chave_pix` não estava configurada no banco, o widget retornava vazio (`SizedBox.shrink()`), fazendo a seção "Apoio" desaparecer ou parecer um controle cinza/quebrado.

#### Solução Implementada

```dart
// dashboard_pix_footer.dart (DEPOIS)
@override
Widget build(BuildContext context) {
  final bool hasPixKey = _chavePix != null && _chavePix!.isNotEmpty;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      // ... estilo mantido (verde, ícone coração)
      child: Row(
        children: [
          // Ícone + título sempre visíveis
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titulo),  // "Apoie o projeto via PIX"
                Text(
                  hasPixKey 
                    ? _mensagem  // Mensagem padrão
                    : 'Configure a chave PIX no painel',  // ✅ Estado vazio amigável
                ),
              ],
            ),
          ),
          // CTA condicional
          if (hasPixKey)
            TextButton(
              onPressed: () { /* copiar PIX */ },
              child: const Text('Copiar'),
            )
          else
            Container(
              // ✅ Badge "Em breve" (não um botão cinza morto)
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Em breve', style: TextStyle(color: Colors.white54)),
            ),
        ],
      ),
    ),
  );
}
```

**Comportamento:**
- ✅ Widget **sempre renderiza**
- ✅ Com PIX: botão "Copiar" funcional
- ✅ Sem PIX: badge "Em breve" + texto "Configure a chave PIX no painel"
- ✅ Não cria chaves falsas
- ✅ Não commita secrets
- ❌ Não requer mudanças no backend (usa API `getApoio()` existente)

---

## 📊 Estatísticas

```bash
2 arquivos modificados
47 inserções(+)
92 deleções(-)
```

**Arquivos:**
1. `permuta_policial/lib/features/dashboard/screens/dashboard_screen_v3.dart`
2. `permuta_policial/lib/features/dashboard/widgets/dashboard_pix_footer.dart`

**Removido:**
- Import `minesweeper_game.dart`
- Função `_buildCampoMinadoCard()`
- Função `_buildExtrasSection()`
- Seção "Extras" (substituída por seção "Apoio" dedicada)

**Mantido (intacto):**
- Widget `MinesweeperGame` (para uso futuro se necessário)
- Todas as outras funcionalidades do dashboard
- Sistema de métricas unificadas
- Grids com `mainAxisExtent` fixo (sem stretch vertical)

---

## 🧪 Validação

### Checklist Desktop (≥900px)

- [ ] Hero aparece no topo da coluna esquerda
- [ ] Matches aparecem logo após o Hero (não enterrados)
- [ ] Coluna direita termina com "Apoio" → PIX Footer
- [ ] Campo Minado **não** aparece em lugar algum
- [ ] Seção "Apoio" tem título próprio
- [ ] PIX Footer sempre visível:
  - **Com chave:** botão verde "Copiar"
  - **Sem chave:** badge "Em breve" + texto "Configure..."
- [ ] Grids de ferramentas não esticam verticalmente

### Checklist Mobile (<900px)

- [ ] Hero → Matches → Ferramentas → Comunidade → Apoio (ordem correta)
- [ ] Campo Minado **não** aparece
- [ ] Seção "Apoio" visível no final (antes do padding do FAB)
- [ ] PIX Footer sempre visível com estado apropriado
- [ ] FAB não sobrepõe conteúdo

### Checklist Backend/API

- [ ] Endpoint `getApoio()` retorna `chave_pix` ou `null`
- [ ] Nenhuma chave commitada no código
- [ ] Variável de ambiente `CHAVE_PIX` (se usada) documentada

---

## 📝 Notas de Implementação

### Por que não deletar `minesweeper_game.dart`?

- Widget pode ser reutilizado em contexto diferente (ex: seção "Jogos", página dedicada)
- Preserva trabalho já implementado
- Não há imports órfãos - widget não referenciado

### Por que não inventar uma chave PIX falsa?

- Segurança: chaves PIX reais devem vir apenas do backend
- Conformidade: não deve haver secrets no código frontend
- UX: melhor ser honesto ("Em breve") que mostrar dados falsos

### Layout responsivo

- Breakpoint: `900px` (constante `kDashboardDesktopBreakpoint`)
- Desktop: coluna esquerda flex 3, direita flex 2 (proporção 60/40)
- Mobile: coluna única com mesma hierarquia

### Spacing

- Entre seções principais: `16dp`
- Entre widgets relacionados: `12dp`
- Padding horizontal padrão: `12dp`
- Padding antes do FAB (mobile): `72dp`

---

## 🚀 Deploy

### Flutter (Staging Web)

```bash
cd /path/to/permuta_policial
git checkout cursor/security-ux-improvements-1b81
git pull origin cursor/security-ux-improvements-1b81

flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit

# Deploy (ajustar path conforme ambiente)
sudo cp -r build/web/* /var/www/permuta-staging/
sudo systemctl restart nginx

# Smoke test
curl -I https://staging.permutapolicial.com.br/
```

### Validação Pós-Deploy

1. **Abrir staging no desktop (≥900px):**
   - Verificar 2 colunas
   - Campo Minado ausente
   - Seção "Apoio" visível no final da coluna direita

2. **Abrir staging no mobile (<900px):**
   - Verificar 1 coluna
   - Hierarquia correta
   - Seção "Apoio" visível antes do FAB

3. **Console do navegador:**
   - Sem erros relacionados a widgets/imports faltando
   - Sem warnings de layout overflow

4. **Testar PIX Footer:**
   - Com chave configurada: botão "Copiar" funcional
   - Sem chave: badge "Em breve" visível

---

## 📚 Referências

- **PR:** https://github.com/Gflopes1/PermutaPolicial/pull/1
- **Commit:** `d0e2a90`
- **Branch:** `cursor/security-ux-improvements-1b81`
- **Documentação UX:** `docs/ux-improvements.md` (se existir no PR anterior)
- **Guia de Deploy:** `docs/DEPLOY-GUIDE.md` (se existir no PR anterior)

---

## ❓ FAQ

**Q: Por que o Campo Minado foi removido?**  
A: Feedback do proprietário indicou que não faz sentido no dashboard principal (contexto de trabalho sério - permutas policiais). Pode ser reintroduzido em contexto apropriado no futuro.

**Q: O widget de PIX sempre aparece agora?**  
A: Sim. Sempre renderiza com texto apropriado ("Configure..." ou mensagem padrão) e CTA apropriado (botão ou badge).

**Q: Posso testar localmente sem backend?**  
A: Sim, mas o PIX Footer vai mostrar o estado vazio ("Em breve") porque `getApoio()` retornará `chave_pix: null`.

**Q: As métricas de matches foram afetadas?**  
A: Não. O sistema de métricas unificadas (`permutas_canonical_metrics.dart`, `permutas-metricas.service.js`) permanece intacto e testado.

---

**Última atualização:** 24/09/2026  
**Autor:** Cursor Agent (Cloud)  
**Status:** ✅ Implementado e commitado
