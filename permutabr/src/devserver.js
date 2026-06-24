require('dotenv').config({ path: '.env.dev' });

const logger = require('./src/core/utils/logger');
const { validateConfig } = require('./src/core/config/config.validator');

// Valida configuração antes de iniciar
try {
    validateConfig();
} catch (error) {
    logger.critical('Falha na validação de configuração', { error: error.message });
    process.exit(1);
}

// ✅ Logs iniciais para desenvolvimento
logger.log('═══════════════════════════════════════');
logger.log('🚀 Iniciando servidor de DESENVOLVIMENTO/HOMOLOGAÇÃO...');
logger.log('📍 Ambiente: DEVELOPMENT');
logger.log('📍 Base URL:', process.env.BASE_URL || 'https://dev.br.permutapolicial.com.br');
logger.log('═══════════════════════════════════════');

// 2. Dependências
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const passport = require('passport');
const db = require('./src/config/db');
const apiRoutes = require('./src/api');
const { initializeSocket } = require('./src/config/socket');
const session = require('express-session');
const { configurePassport } = require('./src/config/passport.config');

function parseOriginList(value) {
    if (!value) return [];
    return value
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean);
}

// 3. Configuração do Passport (OAuth) - Permite HTTP em desenvolvimento
configurePassport({ allowHttpForRedirectUrl: true });
logger.log('✅ Passport configurado (DEV)');

// 5. App Express
const app = express();
app.set('trust proxy', 1);
const isHttpsBaseUrl = (process.env.BASE_URL || '').startsWith('https://');
const forceSecureCookie = process.env.COOKIE_SECURE;
const useSecureCookie = forceSecureCookie != null
    ? forceSecureCookie === 'true'
    : isHttpsBaseUrl;
const sameSitePolicy = useSecureCookie ? 'none' : 'lax';

// ✅ SEGURANÇA: Headers de segurança HTTP (Helmet)
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", "data:", "https:"],
        },
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,        
        preload: true
    }
}));

// ✅ SEGURANÇA: Rate Limiting
// Rate limit geral para API
const apiLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minuto
    max: 100, // 100 requisições por minuto
    message: 'Muitas requisições. Tente novamente em alguns instantes.',
    standardHeaders: true,
    legacyHeaders: false,
});

// Aplicar rate limit geral em todas as rotas da API
// Nota: Rate limit específico para login está em auth.routes.js
app.use('/api/', apiLimiter);

// 6. Middlewares
// ✅ SEGURANÇA: Lista explícita de origins permitidos (incluindo produção para permitir testes)
const corsOptions = {
    origin: function (origin, callback) {
        const extraAllowedOrigins = parseOriginList(process.env.FRONTEND_DEV_ORIGINS);
        const allowedOrigins = [
            process.env.FRONTEND_URL || 'https://dev.br.permutapolicial.com.br',
            'http://dev.br.permutapolicial.com.br',
            'https://dev.br.permutapolicial.com.br',
            'https://br.permutapolicial.com.br', // ✅ Permitir requisições do frontend de produção
            'https://login.microsoftonline.com',
            'https://www.mercadopago.com.br',
            'https://mercadopago.com.br',
            // Apenas localhost em desenvolvimento
            ...(process.env.NODE_ENV === 'development' 
                ? ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:5000']
                : []),
            ...extraAllowedOrigins
        ];

        // Permite requisições sem origin em casos específicos:
        // 1. Em desenvolvimento
        // 2. Para webhooks e requisições de servidor para servidor
        if (!origin) {
            // Permite requisições sem Origin (alguns proxies/load balancers removem)
            // Isso é necessário para funcionar em alguns ambientes
            return callback(null, true);
        }

        if (allowedOrigins.includes(origin)) {
            return callback(null, true);
        }

        // Permite localhost apenas em desenvolvimento
        if (process.env.NODE_ENV === 'development' && 
            (
                origin.startsWith('http://localhost:') ||
                origin.startsWith('http://127.0.0.1:') ||
                origin.startsWith('http://192.168.') ||
                origin.startsWith('http://10.') ||
                origin.startsWith('http://172.')
            )) {
            return callback(null, true);
        }
        
        callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'x-signature', 'x-mercadopago-signature', 'x-request-id']
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

// ===== MIDDLEWARE PARA FORÇAR RECARREGAMENTO (NO-CACHE) =====
app.use((req, res, next) => {
    const path = req.path.toLowerCase();
    
    // 1. index.html e service-worker: NUNCA cachear (garante que o usuário receba a versão nova)
    if (path === '/' || path.endsWith('index.html') || path.endsWith('flutter_service_worker.js')) {
        res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
    } 
    // 2. Assets estáticos pesados (JS, WASM, Fontes, Imagens): CACHEAR agressivamente
    else if (path.match(/\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|wasm)$/)) {
        // Cache por 1 ano. O Flutter Web gera hashes nos nomes dos arquivos em release,
        // então se você atualizar o app, o index.html pedirá um main.dart.js novo.
        res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    }
    
    next();
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.set('trust proxy', 1); // <--- CRÍTICO: Sem isso, secure: true falha atrás de proxies (Cloudflare/Nginx)

app.use(session({
    secret: process.env.SESSION_SECRET || 'dev-secret-key-change-in-production',
    resave: false,
    saveUninitialized: false, // Recomendado false para evitar criar sessões vazias inúteis
    cookie: {
        // Em HTTPS usa cookie seguro + SameSite none (OAuth cross-site).
        // Em HTTP local cai para sameSite lax para facilitar testes.
        secure: useSecureCookie,
        sameSite: sameSitePolicy,
        
        httpOnly: true,
        maxAge: 30 * 60 * 1000,
        path: '/'
    },
    name: 'permuta.dev.sid'
}));
app.use(passport.initialize());
app.use(passport.session());

logger.debug('Middlewares configurados');
logger.log('✅ Middlewares configurados (DEV)');

// 7. Rota de Health Check
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        environment: 'development',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
        port: process.env.PORT || 3001
    });
});

// 8. Rota raiz
app.get('/', (req, res) => {
    res.json({
        message: 'API Permuta Policial - Ambiente de DESENVOLVIMENTO/HOMOLOGAÇÃO',
        status: '✅',
        environment: 'development',
        timestamp: new Date().toISOString(),
        version: '2.0.0-dev'
    });
});

// 9. Servir arquivos estáticos (uploads) - SEM CACHE
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
    maxAge: 0,
    etag: false,
    lastModified: false,
    setHeaders: (res) => {
        res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
        res.setHeader('Pragma', 'no-cache');
        res.setHeader('Expires', '0');
    }
}));

// 10. Rotas da API
logger.debug('Carregando rotas da API...');
logger.log('📦 Carregando rotas da API...');
app.use('/api', apiRoutes);
logger.debug('Rotas da API carregadas');
logger.log('✅ Rotas da API carregadas (DEV)');

// 11. 404 Handler
app.use((req, res, next) => {
    res.status(404).json({
        error: 'Rota não encontrada',
        path: req.path,
        method: req.method,
        environment: 'development'
    });
});

// 12. Error Handler
const errorHandler = require('./src/core/middlewares/errorHandler');
app.use(errorHandler);

// ===== INICIALIZAÇÃO PARA PASSENGER (DEV) =====
// Nota: Em desenvolvimento, geralmente não usa Passenger, mas mantemos compatibilidade
const isPassenger = process.env.PASSENGER_INSTANCE_REGISTRY_DIR !== undefined;

if (isPassenger) {
    logger.info('MODO PASSENGER DETECTADO (DEV) - O Passenger gerenciará o servidor');
    logger.log('⚠️  MODO PASSENGER DETECTADO (DEV)');

    db.getConnection()
        .then(connection => {
            logger.debug('Banco de dados conectado');
            logger.log('✅ Banco de dados conectado (DEV)');
            connection.release();
        })
        .catch(error => {
            logger.error('ERRO ao conectar ao banco', { error: error.message });
            console.error('❌ ERRO ao conectar ao banco (DEV):', error.message);
        });

    module.exports = app;

} else {
    // Modo standalone (PM2, nodemon, etc) - Padrão para desenvolvimento
    const PORT = process.env.PORT || 3001;
    const HOST = process.env.HOST || '127.0.0.1';

    async function startServer() {
        try {
            const connection = await db.getConnection();
            logger.debug('Banco de dados conectado');
            logger.log('✅ Banco de dados conectado (DEV)');
            connection.release();

            const server = app.listen(PORT, HOST, () => {
                logger.info('Servidor rodando (DEV)', { host: HOST, port: PORT });
                logger.log('═══════════════════════════════════════');
                logger.log('🚀 Servidor DEV rodando');
                logger.log(`📍 Endereço: ${HOST}:${PORT}`);
                logger.log(`📍 Ambiente: DEVELOPMENT/HOMOLOGAÇÃO`);
                logger.log(`📍 URL: ${process.env.BASE_URL || 'https://dev.br.permutapolicial.com.br'}`);
                logger.log('═══════════════════════════════════════');
                
                // Inicia job de processamento de salários (apenas se habilitado explicitamente)
                // Em dev, por padrão está desabilitado, mas pode ser habilitado para testes
                if (process.env.ENABLE_SALARY_JOB === 'true') {
                    const salaryJob = require('./src/modules/work/salary.job');
                    salaryJob.startSalaryJob();
                    logger.debug('Job de processamento de salários iniciado (DEV)');
                    logger.log('✅ Job de processamento de salários iniciado (DEV)');
                } else {
                    logger.log('⚠️  Job de processamento de salários desabilitado em DEV');
                }
            });
            
            initializeSocket(server);
            logger.debug('Socket.IO inicializado');
            logger.log('✅ Socket.IO inicializado (DEV)');

            const cleanupService = require('./src/core/services/cleanup_service');
            const cleanupInterval = 24 * 60 * 60 * 1000; // 24 horas
            setInterval(async () => {
                try {
                    await cleanupService.runCleanup();
                    logger.debug('Limpeza automática executada');
                    logger.log('✅ Limpeza automática executada (DEV)');
                } catch (error) {
                    logger.error('Erro na limpeza automática', { error: error.message });
                    console.error('❌ Erro na limpeza automática (DEV):', error.message);
                }
            }, cleanupInterval);
            
            logger.debug('Serviço de limpeza automática inicializado (executa a cada 24h)');
            logger.log('✅ Serviço de limpeza automática inicializado (executa a cada 24h) (DEV)');

            const shutdown = (signal) => {
                logger.info(`${signal} recebido. Encerrando servidor DEV...`);
                logger.log(`\n📴 ${signal} recebido. Encerrando servidor DEV...`);
                server.close(async () => {
                    await db.end();
                    logger.log('✅ Servidor DEV encerrado com sucesso');
                    process.exit(0);
                });
            };

            process.on('SIGTERM', () => shutdown('SIGTERM'));
            process.on('SIGINT', () => shutdown('SIGINT'));

        } catch (error) {
            logger.critical('FALHA ao iniciar servidor DEV', { 
                error: error.message, 
                stack: error.stack 
            });
            console.error('💥 FALHA ao iniciar servidor DEV:', error);
            process.exit(1);
        }
    }

    startServer();
}

