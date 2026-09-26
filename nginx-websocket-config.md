# Configuração Nginx para WebSocket Socket.IO

Adicione este bloco ao arquivo de configuração do site (geralmente em `/etc/nginx/sites-available/dev.br.permutapolicial.com.br`):

```nginx
# WebSocket Socket.IO - proxy para porta 3001
location /socket.io/ {
    proxy_pass http://127.0.0.1:3001;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Timeouts para conexão WebSocket
    proxy_connect_timeout 7d;
    proxy_send_timeout 7d;
    proxy_read_timeout 7d;
}
```

Após adicionar o bloco, recarregue o Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Verificação

Para verificar se o WebSocket está funcionando:

```bash
# Verificar se o processo na porta 3001 está rodando
sudo netstat -tulpn | grep 3001

# Ou via lsof
sudo lsof -i :3001

# Testar WebSocket via curl (deve retornar 101 Switching Protocols)
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: test" https://dev.br.permutapolicial.com.br/socket.io/
```
