// /src/config/socket.js

const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const chatRepository = require('../modules/chat/chat.repository');

let io;

function initializeSocket(server) {
  // ✅ SEGURANÇA: Lista explícita de origins permitidos para Socket.IO
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

  // Middleware de autenticação para Socket.IO
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
      
      if (!token) {
        return next(new Error('Token não fornecido'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      // O JWT usa 'policial_id' como campo (ver auth.service.js)
      socket.userId = decoded.policial_id || decoded.id;
      socket.user = decoded;
      next();
    } catch (error) {
      next(new Error('Token inválido'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`✅ Usuário conectado: ${socket.userId}`);

    // Adiciona o usuário a uma sala com seu ID
    socket.join(`user_${socket.userId}`);

    // Evento: Entrar em uma conversa
    socket.on('join_conversa', async (conversaId) => {
      try {
        // Verifica se o usuário pertence à conversa
        const isParticipante = await chatRepository.verificarParticipante(conversaId, socket.userId);
        if (isParticipante) {
          socket.join(`conversa_${conversaId}`);
          console.log(`👤 Usuário ${socket.userId} entrou na conversa ${conversaId}`);
        } else {
          socket.emit('error', { message: 'Você não tem permissão para acessar esta conversa.' });
        }
      } catch (error) {
        console.error('Erro ao entrar na conversa:', error);
        socket.emit('error', { message: 'Erro ao entrar na conversa.' });
      }
    });

    // Evento: Sair de uma conversa
    socket.on('leave_conversa', (conversaId) => {
      socket.leave(`conversa_${conversaId}`);
      console.log(`👋 Usuário ${socket.userId} saiu da conversa ${conversaId}`);
    });

    // Evento: Nova mensagem (recebido do cliente)
    socket.on('nova_mensagem', async (data) => {
      try {
        const { conversaId, mensagem } = data;

        // Verifica se o usuário pertence à conversa
        const isParticipante = await chatRepository.verificarParticipante(conversaId, socket.userId);
        if (!isParticipante) {
          socket.emit('error', { message: 'Você não tem permissão para enviar mensagens nesta conversa.' });
          return;
        }

        // Cria a mensagem no banco
        const mensagemCriada = await chatRepository.createMensagem(conversaId, socket.userId, mensagem);

        // Busca informações do outro participante
        const conversa = await chatRepository.findConversaById(conversaId);
        const outroUsuarioId = conversa.usuario1_id === socket.userId 
          ? conversa.usuario2_id 
          : conversa.usuario1_id;

        // Envia a mensagem para todos na sala da conversa
        io.to(`conversa_${conversaId}`).emit('mensagem_recebida', mensagemCriada);

        // ✅ Cria notificação no banco de dados para o destinatário
        try {
          const notificacoesRepository = require('../modules/notificacoes/notificacoes.repository');
          const db = require('../config/db');
          
          // Busca nome do remetente
          const [policiais] = await db.execute('SELECT nome FROM policiais WHERE id = ?', [socket.userId]);
          const remetenteNome = policiais[0]?.nome || 'Usuário';
          
          await notificacoesRepository.create({
            usuario_id: outroUsuarioId,
            tipo: 'NOVA_MENSAGEM',
            referencia_id: conversaId,
            titulo: 'Nova mensagem',
            mensagem: `${remetenteNome} enviou uma mensagem`,
          });
        } catch (notifError) {
          console.error('Erro ao criar notificação de mensagem:', notifError);
          // Não interrompe o fluxo se falhar ao criar notificação
        }

        // Notifica o outro usuário se ele não estiver na conversa
        io.to(`user_${outroUsuarioId}`).emit('nova_mensagem_notificacao', {
          conversaId,
          mensagem: mensagemCriada,
        });
      } catch (error) {
        console.error('Erro ao processar nova mensagem:', error);
        socket.emit('error', { message: 'Erro ao enviar mensagem.' });
      }
    });

    // Evento: Marcar mensagens como lidas
    socket.on('marcar_lidas', async (conversaId) => {
      try {
        await chatRepository.marcarMensagensComoLidas(conversaId, socket.userId);
        
        // Notifica outros participantes que as mensagens foram lidas
        socket.to(`conversa_${conversaId}`).emit('mensagens_lidas', {
          conversaId,
          usuarioId: socket.userId,
        });
      } catch (error) {
        console.error('Erro ao marcar mensagens como lidas:', error);
      }
    });

    // Evento: Usuário digitando
    socket.on('typing', (data) => {
      const { conversaId } = data;
      socket.to(`conversa_${conversaId}`).emit('user_typing', {
        conversaId,
        usuarioId: socket.userId,
        usuarioNome: socket.user.nome,
      });
    });

    // Evento: Usuário parou de digitar
    socket.on('stop_typing', (data) => {
      const { conversaId } = data;
      socket.to(`conversa_${conversaId}`).emit('user_stop_typing', {
        conversaId,
        usuarioId: socket.userId,
      });
    });

    // Evento: Desconexão
    socket.on('disconnect', () => {
      console.log(`❌ Usuário desconectado: ${socket.userId}`);
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




