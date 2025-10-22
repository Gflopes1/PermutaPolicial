// /src/config/db.js

const mysql = require('mysql2/promise');

// O 'require('dotenv').config()' já foi chamado no server.js,
// então as variáveis de process.env já estão disponíveis aqui.

// Cria um "pool" de conexões. É mais eficiente que criar uma nova conexão a cada consulta.
const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10, // Número de conexões que o pool pode manter
    queueLimit: 0
});

module.exports = pool;