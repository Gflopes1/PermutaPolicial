require('dotenv').config();

const logger = require('./src/core/utils/logger');
const { validateConfig } = require('./src/core/config/config.validator');

// Valida configuração antes de iniciar
try {
    validateConfig();
} catch (error) {
    logger.critical('Falha na validação de configuração', { error: error.message });
    process.exit(1);
}

// ✅ CORREÇÃO: Logs iniciais apenas em desenvolvimento
// Em produção, apenas log crítico de inicialização
if (process.env.NODE_ENV !== 'production') {
    console.log('═══════════════════════════════════════');
    console.log('🚀 Iniciando aplicação...');
    console.log('📍 Ambiente:', process.env.NODE_ENV || 'development');
    console.log('📍 Base URL:', process.env.BASE_URL);
    console.log('═══════════════════════════════════════');
} else {
    // Em produção, apenas log crítico
    logger.critical('Aplicação iniciada em modo produção', {
        baseUrl: process.env.BASE_URL || 'não configurado'
    });
}

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
const MySQLStore = require('express-mysql-session')(session);
const { configurePassport } = require('./src/config/passport.config');

// 3. Configuração do Passport (OAuth)
configurePassport();

// 5. App Express
const app = express();
app.set('trust proxy', 1);

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
// ✅ SEGURANÇA: Lista explícita de origins permitidos
const corsOptions = {
    origin: function (origin, callback) {
        const allowedOrigins = [
            process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br',
            'https://br.permutapolicial.com.br',
            'https://dev.br.permutapolicial.com.br',
            'https://login.microsoftonline.com',
            'https://www.mercadopago.com.br',
            'https://mercadopago.com.br',
            // Apenas localhost em desenvolvimento
            ...(process.env.NODE_ENV === 'development' 
                ? ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:5000'] 
                : [])
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
            (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:'))) {
            return callback(null, true);
        }
        
        callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
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

// ✅ PRODUÇÃO: Configuração do store MySQL para sessões (substitui MemoryStore)
// Em produção, usa MySQLStore; em desenvolvimento, pode usar MemoryStore se preferir
let sessionStore;
if (process.env.NODE_ENV === 'production') {
    // Usa MySQLStore em produção
    sessionStore = new MySQLStore({
        host: process.env.DB_HOST,
        port: process.env.DB_PORT || 3306,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        createDatabaseTable: false, // A tabela já foi criada via migration
        schema: {
            tableName: 'sessions',
            columnNames: {
                session_id: 'session_id',
                expires: 'expires',
                data: 'data'
            }
        }
    });

    // Tratamento de erros do store
    sessionStore.on('error', (error) => {
        logger.error('Erro no MySQL Session Store', { error: error.message });
    });
} else {
    // Em desenvolvimento, pode usar MemoryStore (mais simples para dev)
    sessionStore = undefined; // undefined = MemoryStore padrão
}

app.use(session({
    store: sessionStore,
    secret: process.env.SESSION_SECRET || 'um-segredo-muito-forte-de-fallback',
    resave: false,
    saveUninitialized: false, // Recomendado false para evitar criar sessões vazias inúteis
    // ✅ CORREÇÃO CRÍTICA: Configuração de cookies para produção HTTPS
    cookie: {
        // [CRÍTICO] Se o site é HTTPS, isso TEM que ser true. 
        // Se for false, o Chrome/Edge rejeita o cookie SameSite: 'none'.
        secure: process.env.NODE_ENV === 'production', // true em produção (HTTPS), false em desenvolvimento
        
        // [CRÍTICO] Permite que o cookie seja enviado no POST da Microsoft (cross-site)
        // Em produção, usa 'none' para OAuth funcionar corretamente
        sameSite: process.env.NODE_ENV === 'production' ? 'none' : 'lax',
        
        httpOnly: true, // Previne acesso via JavaScript (segurança)
        maxAge: 30 * 60 * 1000, // 30 minutos (tempo suficiente para completar OAuth)
        path: '/'
    },
    // ✅ CORREÇÃO: Nome personalizado para evitar conflitos
    name: 'permuta.sid'
}));
app.use(passport.initialize());
app.use(passport.session());

logger.debug('Middlewares configurados');

// 7. Rota de Health Check
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// 8. Rota raiz
app.get('/', (req, res) => {
    res.json({
        message: 'API Permuta Policial - Online',
        status: '✅',
        timestamp: new Date().toISOString(),
        version: '2.0.0'
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
app.use('/api', apiRoutes);
logger.debug('Rotas da API carregadas');

// 11. 404 Handler
app.use((req, res, next) => {
    res.status(404).json({
        error: 'Rota não encontrada',
        path: req.path,
        method: req.method
    });
});

// 12. Error Handler
const errorHandler = require('./src/core/middlewares/errorHandler');
app.use(errorHandler);

// ===== INICIALIZAÇÃO PARA PASSENGER =====
const isPassenger = process.env.PASSENGER_INSTANCE_REGISTRY_DIR !== undefined;

if (isPassenger) {
    if (process.env.NODE_ENV !== 'production') {
        logger.info('MODO PASSENGER DETECTADO - O Passenger gerenciará o servidor');
    }

    db.getConnection()
        .then(connection => {
            logger.debug('Banco de dados conectado');
            connection.release();
        })
        .catch(error => {
            logger.error('ERRO ao conectar ao banco', { error: error.message });
        });

    module.exports = app;

} else {
    // Modo standalone (PM2, nodemon, etc)
    const PORT = process.env.PORT || 3000;
    const HOST = '127.0.0.1';

    async function startServer() {
        try {
            const connection = await db.getConnection();
            logger.debug('Banco de dados conectado');
            connection.release();

            const server = app.listen(PORT, HOST, () => {
                if (process.env.NODE_ENV !== 'production') {
                    logger.info('Servidor rodando', { host: HOST, port: PORT });
                } else {
                    logger.critical('Servidor iniciado em produção', { host: HOST, port: PORT });
                }
                
                // Inicia job de processamento de salários
                if (process.env.ENABLE_SALARY_JOB !== 'false') {
                    const salaryJob = require('./src/modules/work/salary.job');
                    salaryJob.startSalaryJob();
                }
            });
            
            initializeSocket(server);
            logger.debug('Socket.IO inicializado');

            const cleanupService = require('./src/core/services/cleanup_service');
            const cleanupInterval = 24 * 60 * 60 * 1000;
            setInterval(async () => {
                try {
                    await cleanupService.runCleanup();
                } catch (error) {
                    logger.error('Erro na limpeza automática', { error: error.message });
                }
            }, cleanupInterval);
            
            logger.debug('Serviço de limpeza automática inicializado (executa a cada 24h)');

            const shutdown = (signal) => {
                logger.info(`${signal} recebido. Encerrando servidor...`);
                server.close(async () => {
                    await db.end();
                    process.exit(0);
                });
            };

            process.on('SIGTERM', () => shutdown('SIGTERM'));
            process.on('SIGINT', () => shutdown('SIGINT'));

        } catch (error) {
            logger.critical('FALHA ao iniciar servidor', { error: error.message, stack: error.stack });
            process.exit(1);
        }
    }

    startServer();
}