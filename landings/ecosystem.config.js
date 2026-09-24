// Configuração PM2 para Next.js Landing Pages
module.exports = {
  apps: [
    {
      name: 'landings-nextjs',
      script: 'npm',
      args: 'run start:prod',
      cwd: '/www/wwwroot/br_permutapolicial/br.permutapolicial.com/public_html/landings',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: '/www/wwwlogs/landings-nextjs-error.log',
      out_file: '/www/wwwlogs/landings-nextjs-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
    }
  ]
};

