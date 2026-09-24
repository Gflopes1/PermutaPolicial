# 🔧 Correção de Erros de Build

## Problemas Corrigidos

1. ✅ **ESLint não instalado** - Adicionado ao `package.json`
2. ✅ **getForceColors não exportado** - Adicionado re-export no `content.ts`

## Passos para Resolver

### 1. Instalar Dependências

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings
npm install
```

### 2. Verificar se o Build Funciona

```bash
npm run build
```

### 3. Se ainda houver erros de ESLint

Você pode temporariamente desabilitar o ESLint durante o build editando `next.config.js`:

```javascript
eslint: {
  ignoreDuringBuilds: true, // Temporariamente
},
```

**⚠️ IMPORTANTE**: Reative depois de corrigir os erros!

### 4. Se ainda houver erros de TypeScript

Você pode temporariamente desabilitar a verificação de tipos:

```javascript
typescript: {
  ignoreBuildErrors: true, // Temporariamente
},
```

**⚠️ IMPORTANTE**: Reative depois de corrigir os erros!

## Mudanças Realizadas

1. **`config/content.ts`**: Adicionado re-export de `getForceColors` e `ForceColors` de `colors.ts`
2. **`package.json`**: Adicionado `eslint` e `eslint-config-next` nas devDependencies
3. **`next.config.js`**: Adicionado configurações de ESLint e TypeScript (comentadas para referência)

## Verificação

Após instalar as dependências, o build deve funcionar:

```bash
npm install
npm run build
```

Se tudo estiver OK, você verá:
```
✓ Compiled successfully
```

