# Sitemap — Cloudflare / SEO

Domínio base: `https://br.permutapolicial.com.br`

## Estrutura (sitemap index)

| Arquivo | Conteúdo |
|---------|----------|
| `sitemap.xml` | Índice — aponta para os sub-sitemaps |
| `sitemap-static.xml` | Home, auth, landing, mapa visitante, **help.html**, **termos.html** |
| `sitemap-landings.xml` | 6 landing pages HTML (`/app/*.html`) |
| `robots.txt` | Regras de crawl + referência ao sitemap |

## Landing pages

| Corporação | URL | Prioridade |
|------------|-----|------------|
| Polícia Militar | `/app/pm.html` | 0.9 |
| Bombeiros Militares | `/app/bm.html` | 0.9 |
| Polícia Civil | `/app/pc.html` | 0.9 |
| PRF | `/app/prf.html` | 0.9 |
| Polícia Federal | `/app/pf.html` | 0.9 |
| Guarda Municipal | `/app/gm.html` | 0.9 |

## Páginas estáticas públicas

| Página | URL |
|--------|-----|
| Central de Ajuda (HTML) | `/help.html` |
| Central de Ajuda (Markdown) | `/help.md` |
| Termos de Uso (HTML) | `/termos.html` |
| Termos de Uso (Markdown) | `/termos.md` |
| Política de Privacidade (HTML) | `/privacidade.html` |
| Política de Privacidade (Markdown) | `/privacidade.md` |
| LLMs (índice para IA) | `/llms.txt` |
| Mapa visitante | `/mapa/visitante` |
| Autenticação | `/auth` |

## Gerar / atualizar

```bash
node landings/scripts/generate-sitemap.js
```

## Deploy no Cloudflare

Copie para a raiz do site (junto com o Flutter Web):

```bash
# Sitemaps e robots
cp landings/public/sitemap*.xml /caminho/public_html/
cp landings/public/robots.txt /caminho/public_html/

# Páginas estáticas
cp help.html help.md /caminho/public_html/
cp termos.html termos.md privacidade.html privacidade.md /caminho/public_html/
cp llms.txt /caminho/public_html/
cp landings/public/assets/logo_tatico.png /caminho/public_html/assets/

# Landings
cp landings/html/*.html /caminho/public_html/app/
```

### Cloudflare Dashboard

1. **Caching** → purgar cache de `/sitemap.xml`, `/robots.txt` após deploy
2. **SSL/TLS** → Full (strict)
3. **Speed** → Auto Minify desligado para `.xml` (opcional)
4. **Search Engine Optimization** → enviar `https://br.permutapolicial.com.br/sitemap.xml` no Google Search Console / Bing

## Localização dos arquivos no repositório

- `landings/public/sitemap.xml`
- `landings/public/sitemap-static.xml`
- `landings/public/sitemap-landings.xml`
- `landings/public/robots.txt`
- `help.html` / `help.md` (fonte; cópias em `landings/public/`)
- `termos.html` / `termos.md` (fonte; cópias em `landings/public/`)
- `privacidade.html` / `privacidade.md` (fonte; cópias em `landings/public/`)
- `llms.txt` (fonte; cópia de deploy em `landings/public/llms.txt`)
- `landings/scripts/generate-sitemap.js`
