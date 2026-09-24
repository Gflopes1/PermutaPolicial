// Configuração PM2 Completa - Backend API + Landing Pages
// Gerencia ambas as aplicações Node.js do projeto Permuta Policial
// 
// USO:
//   pm2 start ecosystem-completo.config.js
//   pm2 save
//   pm2 startup
//
// IMPORTANTE: Ajuste os caminhos (cwd) conforme sua instalação!

const path = require('path');

// Ajuste estes caminhos conforme sua instalação
const BASE_PATH = '/www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html';
const BACKEND_PATH = path.join(BASE_PATH, 'backend_js');
const LANDINGS_PATH = path.join(BASE_PATH, 'landings');

module.exports = {
  apps: [
    // ============================================
    // 1. BACKEND API (Porta 3000)
    // ============================================
    {
      name: 'permuta-api',
      script: 'server.js',
      cwd: BACKEND_PATH,
      
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      
      // Auto-restart e resiliência
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      
      // Configurações de restart
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000,
      
      // Logs
      error_file: '/www/wwwlogs/permuta-api-error.log',
      out_file: '/www/wwwlogs/permuta-api-out.log',
      log_file: '/www/wwwlogs/permuta-api-combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      
      // Configurações avançadas
      kill_timeout: 5000,
      wait_ready: true,
      listen_timeout: 10000,
      exec_mode: 'fork'
    },
    
    // ============================================
    // 2. LANDING PAGES NEXT.JS (Porta 3001)
    // ============================================
    {
      name: 'landings-nextjs',
      script: 'npm',
      args: 'run start:prod',
      cwd: LANDINGS_PATH,
      
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      
      // Auto-restart e resiliência
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      
      // Configurações de restart
      min_uptime: '10s',
      max_restarts: 10,
      restart_delay: 4000,
      
      // Logs
      error_file: '/www/wwwlogs/landings-nextjs-error.log',
      out_file: '/www/wwwlogs/landings-nextjs-out.log',
      log_file: '/www/wwwlogs/landings-nextjs-combined.log',
      time: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      
      // Configurações avançadas
      kill_timeout: 5000,
      exec_mode: 'fork'
    }
  ]
};
