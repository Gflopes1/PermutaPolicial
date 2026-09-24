// Configuração PM2 para Backend API (Permuta Policial)
// Este arquivo configura o PM2 para gerenciar o servidor Node.js principal
// com auto-restart, auto-start no boot, e monitoramento

module.exports = {
  apps: [
    {
      name: 'permuta-api',
      script: 'server.js',
      cwd: '/www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/backend_js',
      
      // Configurações de ambiente
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      
      // Auto-restart e resiliência
      instances: 1,                    // Número de instâncias (1 para single instance)
      autorestart: true,               // Reinicia automaticamente se crashar
      watch: false,                    // Não observa mudanças de arquivo (desligado em produção)
      max_memory_restart: '1G',        // Reinicia se usar mais de 1GB de RAM
      
      // Configurações de restart
      min_uptime: '10s',               // Tempo mínimo de execução para considerar "estável"
      max_restarts: 10,                // Máximo de restarts em 1 minuto
      restart_delay: 4000,             // Delay entre restarts (4 segundos)
      
      // Tratamento de erros
      error_file: '/www/wwwlogs/permuta-api-error.log',
      out_file: '/www/wwwlogs/permuta-api-out.log',
      log_file: '/www/wwwlogs/permuta-api-combined.log',
      time: true,                      // Adiciona timestamp nos logs
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,                // Mescla logs de todas as instâncias
      
      // Configurações avançadas
      kill_timeout: 5000,              // Tempo para encerrar graciosamente (5 segundos)
      wait_ready: true,                // Espera o servidor estar pronto antes de considerar iniciado
      listen_timeout: 10000,           // Timeout para aguardar o servidor iniciar (10 segundos)
      
      // Health check (opcional - descomente se implementar endpoint de health)
      // health_check_grace_period: 3000,
      
      // Configurações de CPU
      exec_mode: 'fork',               // Modo fork (single instance)
      
      // Variáveis de ambiente adicionais (ajuste conforme necessário)
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      env_development: {
        NODE_ENV: 'development',
        PORT: 3000
      }
    }
  ]
};

