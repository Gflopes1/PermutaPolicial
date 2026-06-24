// /src/config/socket.js

const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const chatRepository = require('../modules/chat/chat.repository');
const mapaTaticoRepository = require('../modules/mapa-tatico/mapa-tatico.repository');
const { notifyNewChatMessage } = require('../modules/chat/chat.notifications');
const { groupRoom } = require('../modules/mapa-tatico/mapa-tatico.socket.constants');
const db = require('./db');
const logger = require('../core/utils/logger');

let io;

const MAX_MENSAGEM_LENGTH = 5000;
const MESSAGE_RATE_WINDOW_MS = 60 * 1000;
const MESSAGE_RATE_MAX = 30;
const messageRateMap = new Map();

function isRateLimited(userId) {
  const now = Date.now();
  const timestamps = (messageRateMap.get(userId) || []).filter((t) => now - t < MESSAGE_RATE_WINDOW_MS);
  if (timestamps.length >= MESSAGE_RATE_MAX) {
    messageRateMap.set(userId, timestamps);
    return true;
  }
  timestamps.push(now);
  messageRateMap.set(userId, timestamps);
  return false;
}

async function getPolicialNome(policialId) {
  const [rows] = await db.execute('SELECT nome FROM policiais WHERE id = ?', [policialId]);
  return rows[0]?.nome || 'Usuário';
}

function initializeSocket(server) {
  const allowedOrigins = [
    process.env.FRONTEND_URL || 'https://br.permutapolicial.com.br',
    'https://br.permutapolicial.com.br',
    'https://dev.br.permutapolicial.com.br',
    ...(process.env.NODE_ENV === 'development' 
      ? ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:5000'] 
      : [])
  ];

  io = new Server(server, {
    cors: {
      origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error('Not allowed by CORS'));
        }
      },
      methods: ['GET', 'POST'],
      credentials: true,
    },
  });

  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
      
      if (!token) {
        return next(new Error('Token não fornecido'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.policial_id || decoded.id;
      socket.user = decoded;
      next();
    } catch (error) {
      next(new Error('Token inválido'));
    }
  });

  io.on('connection', (socket) => {
    logger.log(`✅ Usuário conectado: ${socket.userId}`);

    socket.join(`user_${socket.userId}`);

    socket.on('join_conversa', async (conversaId) => {
      try {
        const isParticipante = await chatRepository.verificarParticipante(conversaId, socket.userId);
        if (isParticipante) {
          socket.join(`conversa_${conversaId}`);
          logger.log(`👤 Usuário ${socket.userId} entrou na conversa ${conversaId}`);
        } else {
          socket.emit('error', { message: 'Você não tem permissão para acessar esta conversa.' });
        }
      } catch (error) {
        console.error('Erro ao entrar na conversa:', error);
        socket.emit('error', { message: 'Erro ao entrar na conversa.' });
      }
    });

    socket.on('leave_conversa', (conversaId) => {
      socket.leave(`conversa_${conversaId}`);
      logger.log(`👋 Usuário ${socket.userId} saiu da conversa ${conversaId}`);
    });

    socket.on('join_mapa_tatico_group', async (groupId) => {
      try {
        const gid = parseInt(groupId, 10);
        if (!gid) {
          socket.emit('error', { message: 'Grupo inválido.' });
          return;
        }
        const member = await mapaTaticoRepository.findMember(gid, socket.userId);
        if (!member) {
          socket.emit('error', { message: 'Você não é membro deste grupo.' });
          return;
        }
        socket.join(groupRoom(gid));
        logger.log(`🗺️ Usuário ${socket.userId} entrou no mapa tático do grupo ${gid}`);
      } catch (error) {
        console.error('Erro ao entrar no grupo do mapa tático:', error);
        socket.emit('error', { message: 'Erro ao entrar no grupo do mapa tático.' });
      }
    });

    socket.on('leave_mapa_tatico_group', (groupId) => {
      const gid = parseInt(groupId, 10);
      if (!gid) return;
      socket.leave(groupRoom(gid));
      logger.log(`🗺️ Usuário ${socket.userId} saiu do mapa tático do grupo ${gid}`);
    });

    socket.on('nova_mensagem', async (data) => {
      try {
        const { conversaId, mensagem } = data;

        if (!mensagem || typeof mensagem !== 'string' || mensagem.trim().length === 0) {
          socket.emit('error', { message: 'A mensagem não pode estar vazia.' });
          return;
        }

        if (mensagem.trim().length > MAX_MENSAGEM_LENGTH) {
          socket.emit('error', { message: `A mensagem não pode ter mais de ${MAX_MENSAGEM_LENGTH} caracteres.` });
          return;
        }

        if (isRateLimited(socket.userId)) {
          socket.emit('error', { message: 'Muitas mensagens enviadas. Aguarde um momento.' });
          return;
        }

        const isParticipante = await chatRepository.verificarParticipante(conversaId, socket.userId);
        if (!isParticipante) {
          socket.emit('error', { message: 'Você não tem permissão para enviar mensagens nesta conversa.' });
          return;
        }

        const mensagemCriada = await chatRepository.createMensagem(conversaId, socket.userId, mensagem);
        const conversa = await chatRepository.findConversaById(conversaId);
        const participantes = [conversa.usuario1_id, conversa.usuario2_id];

        for (const participanteId of participantes) {
          if (participanteId === socket.userId) continue;
          const payload = chatRepository.filterMensagemForViewer(mensagemCriada, conversa, participanteId);
          io.to(`user_${participanteId}`).emit('mensagem_recebida', payload);
        }

        try {
          await notifyNewChatMessage(conversaId, socket.userId);
        } catch (notifError) {
          console.error('Erro ao criar notificação de mensagem:', notifError);
        }

        const outroUsuarioId = conversa.usuario1_id === socket.userId
          ? conversa.usuario2_id
          : conversa.usuario1_id;

        const payloadDestinatario = chatRepository.filterMensagemForViewer(
          mensagemCriada,
          conversa,
          outroUsuarioId
        );
        io.to(`user_${outroUsuarioId}`).emit('nova_mensagem_notificacao', {
          conversaId,
          mensagem: payloadDestinatario,
        });
      } catch (error) {
        console.error('Erro ao processar nova mensagem:', error);
        socket.emit('error', { message: 'Erro ao enviar mensagem.' });
      }
    });

    socket.on('marcar_lidas', async (conversaId) => {
      try {
        await chatRepository.marcarMensagensComoLidas(conversaId, socket.userId);
        
        socket.to(`conversa_${conversaId}`).emit('mensagens_lidas', {
          conversaId,
          usuarioId: socket.userId,
        });
      } catch (error) {
        console.error('Erro ao marcar mensagens como lidas:', error);
      }
    });

    socket.on('typing', async (data) => {
      try {
        const { conversaId } = data;
        const conversa = await chatRepository.findConversaById(conversaId);
        if (!conversa) return;

        const outroUsuarioId = conversa.usuario1_id === socket.userId
          ? conversa.usuario2_id
          : conversa.usuario1_id;

        const remetenteNome = await getPolicialNome(socket.userId);
        const nomeParaOutro = chatRepository.getParticipantDisplayName(
          conversa,
          socket.userId,
          outroUsuarioId,
          remetenteNome
        );

        io.to(`user_${outroUsuarioId}`).emit('user_typing', {
          conversaId,
          usuarioId: socket.userId,
          usuarioNome: nomeParaOutro,
        });
      } catch (error) {
        console.error('Erro no evento typing:', error);
      }
    });

    socket.on('stop_typing', (data) => {
      const { conversaId } = data;
      socket.to(`conversa_${conversaId}`).emit('user_stop_typing', {
        conversaId,
        usuarioId: socket.userId,
      });
    });

    socket.on('disconnect', () => {
      logger.log(`❌ Usuário desconectado: ${socket.userId}`);
    });
  });

  return io;
}

function getIO() {
  if (!io) {
    throw new Error('Socket.IO não foi inicializado. Chame initializeSocket primeiro.');
  }
  return io;
}

module.exports = { initializeSocket, getIO };
