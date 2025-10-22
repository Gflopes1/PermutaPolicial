// ecosystem.config.js
module.exports = {
    apps: [{
        name: 'permuta-api',
        script: './server.js', // ✅ Continua sendo server.js
        instances: 1,
        exec_mode: 'fork',
        watch: false,
        max_memory_restart: '500M',
        autorestart: true,
        max_restarts: 10,
        min_uptime: '10s',
        env: {
            NODE_ENV: 'production',
            PORT: 3000,
            HOST: '127.0.0.1'
        },
        error_file: './logs/pm2-error.log',
        out_file: './logs/pm2-out.log',
        log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
        merge_logs: true,
        kill_timeout: 5000,
        wait_ready: true,
        listen_timeout: 10000
    }]
};