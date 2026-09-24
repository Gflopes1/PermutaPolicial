# 📄 Landing Pages HTML Estático

## ✅ Vantagens

- ✅ **Sem build** - Não precisa de Node.js, npm, ou compilação
- ✅ **Sem problemas de memória** - Não usa recursos do servidor
- ✅ **Super rápido** - Carrega instantaneamente
- ✅ **Fácil de manter** - Apenas HTML puro
- ✅ **CDN TailwindCSS** - Sem necessidade de build de CSS

## 🚀 Gerar Todos os Arquivos HTML

Execute o script de geração:

```bash
cd landings/html
node generate-html.js
```

Isso vai gerar:
- `pm.html` - Polícia Militar
- `bm.html` - Bombeiros Militares
- `pc.html` - Polícia Civil
- `prf.html` - Polícia Rodoviária Federal
- `pf.html` - Polícia Federal
- `gm.html` - Guarda Municipal

## 📁 Deploy

### Opção 1: Copiar para pasta pública

```bash
# Copiar arquivos HTML para a pasta pública
cp landings/html/*.html /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/app/
```

### Opção 2: Configurar nginx

Adicione ao nginx (substituindo o proxy do Next.js):

```nginx
# Servir HTML estático das landing pages
location ~ ^/app/(pm|bm|pc|prf|pf|gm)\.html$ {
    alias /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/html/$1.html;
}

# Redirecionar /app/pm para /app/pm.html
location ~ ^/app/(pm|bm|pc|prf|pf|gm)$ {
    return 301 /app/$1.html;
}
```

## 📝 URLs Finais

- `https://br.permutapolicial.com.br/app/pm.html`
- `https://br.permutapolicial.com.br/app/bm.html`
- `https://br.permutapolicial.com.br/app/pc.html`
- `https://br.permutapolicial.com.br/app/prf.html`
- `https://br.permutapolicial.com.br/app/pf.html`
- `https://br.permutapolicial.com.br/app/gm.html`

## 🎨 Personalização

Cada arquivo HTML tem as cores inline. Para alterar, edite diretamente o arquivo HTML ou modifique `generate-html.js` e gere novamente.

## ⚡ Performance

- **Tamanho**: ~15-20KB por página
- **Carregamento**: Instantâneo
- **CDN TailwindCSS**: Cache global
- **Sem JavaScript**: Apenas HTML + CSS

## 🔄 Atualização

Para atualizar conteúdo:

1. Edite `generate-html.js` (se necessário)
2. Execute `node generate-html.js`
3. Copie os arquivos para a pasta pública
4. Pronto! Sem build, sem restart

