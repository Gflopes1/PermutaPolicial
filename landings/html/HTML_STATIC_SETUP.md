# 📄 Landing Pages HTML Estático

## ✅ Vantagens

- ✅ **Sem build** - Não precisa de Node.js, npm, ou compilação
- ✅ **Sem problemas de memória** - Não usa recursos do servidor
- ✅ **Super rápido** - Carrega instantaneamente
- ✅ **Fácil de manter** - Apenas HTML puro
- ✅ **CDN TailwindCSS** - Sem necessidade de build de CSS

## 📁 Estrutura

```
landings/html/
├── pm.html    - Polícia Militar
├── bm.html    - Bombeiros Militares
├── pc.html    - Polícia Civil
├── prf.html   - Polícia Rodoviária Federal
├── pf.html    - Polícia Federal
└── gm.html    - Guarda Municipal
```

## 🚀 Deploy

### Opção 1: Copiar para pasta pública do nginx

```bash
# Copiar arquivos HTML para a pasta pública
cp landings/html/*.html /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/app/
```

### Opção 2: Configurar nginx para servir HTML estático

Adicione ao nginx (substituindo o proxy do Next.js):

```nginx
# Servir HTML estático das landing pages
location /app/ {
    alias /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/html/;
    try_files $uri $uri/ =404;
    
    # Adicionar extensão .html se não tiver
    location ~ ^/app/(pm|bm|pc|prf|pf|gm)$ {
        return 301 /app/$1.html;
    }
}
```

### Opção 3: Usar como está (sem nginx especial)

Se os arquivos estiverem em `/public_html/app/pm.html`, acesse:
- `https://br.permutapolicial.com.br/app/pm.html`
- `https://br.permutapolicial.com.br/app/bm.html`
- etc.

## 🔧 Configuração Nginx Simplificada

Remova o proxy do Next.js e adicione:

```nginx
# Landing Pages HTML Estático
location ~ ^/app/(pm|bm|pc|prf|pf|gm)\.html$ {
    alias /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/html/$1.html;
}

# Redirecionar /app/pm para /app/pm.html
location ~ ^/app/(pm|bm|pc|prf|pf|gm)$ {
    return 301 /app/$1.html;
}
```

## 📝 URLs Finais

- `https://br.permutapolicial.com.br/app/pm.html` (ou `/app/pm` com redirect)
- `https://br.permutapolicial.com.br/app/bm.html`
- `https://br.permutapolicial.com.br/app/pc.html`
- `https://br.permutapolicial.com.br/app/prf.html`
- `https://br.permutapolicial.com.br/app/pf.html`
- `https://br.permutapolicial.com.br/app/gm.html`

## 🎨 Personalização

Cada arquivo HTML tem as cores inline. Para alterar:

1. Abra o arquivo HTML (ex: `pm.html`)
2. Procure por `style="color: #1a365d"` ou `background-color: #1a365d`
3. Substitua pelas cores desejadas

Cores por força estão em `landings/config/colors.ts` (referência).

## ⚡ Performance

- **Tamanho**: ~15-20KB por página (sem imagens)
- **Carregamento**: Instantâneo (HTML estático)
- **CDN TailwindCSS**: Carregado do CDN (cache global)
- **Sem JavaScript**: Apenas HTML + CSS

## 🔄 Atualização

Para atualizar conteúdo:

1. Edite o arquivo HTML diretamente
2. Salve
3. Pronto! Sem build, sem restart, sem nada

## 📚 Próximos Passos

1. Criar os outros arquivos HTML (bm.html, pc.html, etc.)
2. Copiar para a pasta pública
3. Configurar nginx (se necessário)
4. Atualizar sitemap

