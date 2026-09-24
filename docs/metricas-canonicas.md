# Contrato canônico de métricas de permuta (Fase G.1)

Objetivo: uma única semântica para contagens exibidas no **dashboard**, na tela **Permutas** e em futuros endpoints agregados, eliminando divergências entre motor **legado** (`/api/permutas/matches`) e **inteligente** (`/api/permutas-inteligentes/matches`).

## Motores

| Motor | Endpoint | `algorithm_version` |
|-------|----------|---------------------|
| Legado SQL | `GET /api/permutas/matches` | `legado_v1` |
| Inteligente (grafo) | `GET /api/permutas-inteligentes/matches` | `inteligente_v1` |
| Resumo PI (cache) | `GET /api/permutas-inteligentes/summary` | `inteligente_v1` |

A **visão unificada** (app) combina os dois motores com deduplicação: IDs presentes no resultado inteligente têm prioridade; entradas legadas duplicadas são omitidas nas buckets correspondentes (ver `PermutasUnificadasUtils` / `mergeUnifiedMetrics` no backend).

## Campos de métricas (`metricas`)

Objeto presente em `data.metricas` nas respostas de matches (por motor) e, quando aplicável, `data.metricas_unificadas` (somente cliente até endpoint dedicado existir).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `direct_matches` | int | Permutas diretas mútuas (exatas). |
| `proximity_matches` | int | Combinações por proximidade/raio (inclui `proximas` + triangulares por aproximação). |
| `interested_candidates` | int | Policiais interessados **na vaga atual** do usuário (bucket `interessados`). |
| `cycles` | int | Ciclos N≥4 (`ciclos_n` no inteligente; `0` no legado). |
| `total_unique_candidates` | int | Policiais distintos contabilizados nesta visão (motor isolado ou unificada). |

### Metadados (`metricas.meta`)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `computed_at` | ISO8601 \| null | Momento do cálculo (ou do cache). |
| `cache_hit` | boolean | Se a resposta veio de cache (PI). Legado: sempre `false`. |
| `algorithm_version` | string | `legado_v1` ou `inteligente_v1`. |
| `truncated` | boolean | `true` se alguma bucket atingiu limite `MAX_*` do motor inteligente. |
| `returned_count` | int | Soma de itens **retornados** nas listas (matches + ciclos como 1 item cada). |
| `available_count` | int \| null | Total antes do truncamento; `null` até instrumentação completa (G.2). |

## Regras de contagem unificada (app)

- **Interessados (hero dashboard):** `countInteressadosMatches(legado, PI)` — não usar só `legado.interessados.length`.
- **Matches compatíveis (hero):** `countCompativelDashboard` — diretas + triangulares exatas + ciclos N, com deduplicação legado/PI.
- **`getSummary` / `match_count`:** soma de **todas** as buckets retornadas do PI (inclui interessados, proximas, ciclos). **Não** equivale a interessados nem à contagem unificada de compatíveis.

## Causa conhecida: ~3 vs ~14 interessados

1. Dashboard (antes da G.1) lia apenas `GET /api/permutas/matches` → `interessados.length` (~3).
2. Tela Permutas unifica legado + PI → ~3 legados não deduplicados + ~11 do grafo ≈ **14**.
3. Motores usam critérios diferentes (SQL vs grafo/score); cache PI (TTL ~1h) pode atrasar alinhamento temporal.
4. `summary.total_matches` agrega **todas** as categorias PI, não interessados.

## Limites (motor inteligente)

Variáveis de ambiente: `PI_MAX_DIRECTAS`, `PI_MAX_INTERESSADOS`, `PI_MAX_CYCLES`, `PI_MAX_CYCLE_SIZE`. Quando `truncated === true`, `returned_count` ≤ `available_count` (quando disponível).

## Endpoint unificado (G.2)

`GET /api/permutas/metricas` (autenticado, rate limit igual a `/matches`):

- `data.metricas_unificadas` — `mergeUnifiedMetrics` no servidor (`unificado_v1`).
- `data.metricas_legado` / `data.metricas_inteligente` — motores isolados.
- `data.dashboard.interessados` e `data.dashboard.matches_compativeis` — hero do app.
- `data.cache_hit.legado` (sempre `false`) e `data.cache_hit.inteligente` (cache PI do usuário).

### Buckets PI (`metricas.meta.buckets`)

Por bucket (`diretas`, `proximas`, `interessados`, `triangulares`, `ciclos_n`): `returned_count`, `available_count` (antes do slice), `truncated`.

### Summary PI

`GET /api/permutas-inteligentes/summary` expõe `breakdown` canônico; `total_matches` mantido por compatibilidade (`total_matches_deprecated: true`).

## Exemplo (motor isolado)

```json
{
  "status": "success",
  "data": {
    "diretas": [],
    "interessados": [],
    "metricas": {
      "direct_matches": 0,
      "proximity_matches": 2,
      "interested_candidates": 3,
      "cycles": 0,
      "total_unique_candidates": 5,
      "meta": {
        "computed_at": "2026-03-24T12:00:00.000Z",
        "cache_hit": false,
        "algorithm_version": "legado_v1",
        "truncated": false,
        "returned_count": 5,
        "available_count": null
      }
    }
  }
}
```
