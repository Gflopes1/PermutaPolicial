# 🚀 Instalação do Módulo de Calendário + Salário

## Passo a Passo

### 1. Instalar Dependências do Backend

```bash
cd backend_js
npm install
```

Isso instalará:
- `luxon` - Para manipulação de datas/timezone
- `pdfkit` - Para geração de PDFs
- `node-cron` - Para jobs agendados

### 2. Aplicar Migration SQL

```bash
mysql -u seu_usuario -p nome_do_banco < database/migrations/add_work_days_intervals_salary_presets.sql
```

Ou execute o SQL manualmente no seu cliente MySQL.

### 3. Instalar Dependências do Frontend

```bash
cd permuta_policial
flutter pub get
```

Isso instalará:
- `table_calendar` - Para o widget de calendário

### 4. Reiniciar o Servidor

```bash
cd backend_js
npm start
# ou
npm run dev
```

### 5. Testar

1. Acesse a aplicação
2. Faça login
3. Navegue para `/calendar`
4. Teste criar um dia de trabalho
5. Aplique um preset
6. Verifique o preview de salário

## ✅ Verificação

Após a instalação, verifique:

- [ ] Migration aplicada sem erros
- [ ] Servidor inicia sem erros
- [ ] Endpoints respondem corretamente
- [ ] Calendário carrega no frontend
- [ ] Auto-save funciona ao editar dias

## 🐛 Troubleshooting

### Erro: "Cannot find module 'luxon'"
```bash
cd backend_js
npm install luxon pdfkit node-cron
```

### Erro: "Table 'work_days' doesn't exist"
Execute a migration SQL novamente.

### Erro: "Route '/calendar' not found"
Verifique se a rota foi adicionada em `app_routes.dart` e se o provider foi registrado em `main.dart`.


