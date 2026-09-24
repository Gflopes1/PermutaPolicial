# 🚀 Configuração PM2 para Backend API

Este guia explica como configurar o PM2 para gerenciar o servidor Node.js principal com auto-restart e auto-start no boot.

## 📋 Pré-requisitos

- Node.js instalado
- PM2 instalado globalmente: `npm install -g pm2`
- Servidor rodando Linux/Unix

## ⚡ Instalação Rápida

### 1. Instalar PM2 (se ainda não tiver)

```bash
npm install -g pm2
```

### 2. Iniciar o servidor com PM2

```bash
cd /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/backend_js
pm2 start ecosystem.config.js
```

### 3. Salvar configuração e configurar auto-start

```bash
# Salvar a lista de processos PM2
pm2 save

# Configurar PM2 para iniciar automaticamente no boot do sistema
pm2 startup
```

O comando `pm2 startup` vai gerar um comando específico para o seu sistema. Execute o comando que ele mostrar.

## 🔧 Comandos Úteis do PM2

### Gerenciamento Básico

```bash
# Listar todos os processos
pm2 list

# Ver logs em tempo real
pm2 logs permuta-api

# Ver apenas erros
pm2 logs permuta-api --err

# Ver apenas output
pm2 logs permuta-api --out

# Parar o servidor
pm2 stop permuta-api

# Reiniciar o servidor
pm2 restart permuta-api

# Recarregar o servidor (zero-downtime restart)
pm2 reload permuta-api

# Deletar o processo do PM2
pm2 delete permuta-api

# Ver informações detalhadas
pm2 show permuta-api

# Monitorar em tempo real (CPU, memória, etc)
pm2 monit
```

### Logs

```bash
# Ver últimos 100 linhas de log
pm2 logs permuta-api --lines 100

# Limpar logs
pm2 flush

# Ver logs de erro
tail -f /www/wwwlogs/permuta-api-error.log

# Ver logs de output
tail -f /www/wwwlogs/permuta-api-out.log
```

### Informações e Status

```bash
# Ver status detalhado
pm2 status

# Ver informações de uso de recursos
pm2 describe permuta-api

# Ver estatísticas
pm2 stats
```

## 🔄 Auto-Restart Configurado

O `ecosystem.config.js` já está configurado com:

- ✅ **Auto-restart**: Reinicia automaticamente se o processo crashar
- ✅ **Max memory restart**: Reinicia se usar mais de 1GB de RAM
- ✅ **Max restarts**: Limita a 10 restarts por minuto (evita loop infinito)
- ✅ **Restart delay**: Aguarda 4 segundos entre restarts
- ✅ **Min uptime**: Considera estável após 10 segundos de execução

## 🚨 Troubleshooting

### Servidor não inicia

```bash
# Ver logs de erro
pm2 logs permuta-api --err

# Verificar se a porta está em uso
netstat -tulpn | grep 3000

# Verificar permissões
ls -la /www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/backend_js
```

### Servidor reinicia constantemente

```bash
# Ver logs para identificar o erro
pm2 logs permuta-api --lines 200

# Verificar uso de memória
pm2 monit

# Verificar se há erro no código
pm2 describe permuta-api
```

### PM2 não inicia no boot

```bash
# Reconfigurar startup
pm2 unstartup
pm2 startup
# Execute o comando que aparecer
pm2 save
```

### Verificar se PM2 está rodando

```bash
# Ver status
pm2 status

# Ver processos do sistema
ps aux | grep node

# Ver processos PM2
ps aux | grep PM2
```

## 📊 Monitoramento

### Dashboard Web (Opcional)

```bash
# Instalar PM2 Plus (opcional, requer conta)
pm2 link [secret] [public]

# Ou usar o dashboard local
pm2 web
```

### Alertas por Email (Opcional)

Configure no `ecosystem.config.js`:

```javascript
pm2: {
  // Configurações de notificação
}
```

## 🔐 Segurança

- Os logs são salvos em `/www/wwwlogs/` (ajuste conforme necessário)
- Certifique-se de que as permissões estão corretas
- Não exponha o PM2 web interface publicamente

## 📝 Notas Importantes

1. **Graceful Shutdown**: O `server.js` já tem tratamento de SIGTERM/SIGINT para encerramento gracioso
2. **Porta 3000**: Certifique-se de que a porta 3000 está livre
3. **Banco de Dados**: O servidor tenta conectar ao banco na inicialização
4. **Socket.IO**: O servidor inicializa Socket.IO junto com o Express

## 🔄 Atualização

Para atualizar o código:

```bash
# 1. Parar o servidor
pm2 stop permuta-api

# 2. Atualizar código (git pull, etc)

# 3. Instalar dependências (se necessário)
npm install

# 4. Reiniciar
pm2 restart permuta-api

# Ou usar reload para zero-downtime
pm2 reload permuta-api
```

## 📚 Recursos

- [Documentação PM2](https://pm2.keymetrics.io/docs/usage/quick-start/)
- [PM2 Ecosystem File](https://pm2.keymetrics.io/docs/usage/application-declaration/)

