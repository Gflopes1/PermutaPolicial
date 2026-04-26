// /src/modules/assistant/assistant.service.js

const { GoogleGenerativeAI } = require('@google/generative-ai');
const ApiError = require('../../core/utils/ApiError');
const assistantRepository = require('./assistant.repository');

class AssistantService {
  constructor() {
    this.apiKey = process.env.GOOGLE_GEMINI_API_KEY;
    if (!this.apiKey) {
      console.warn('⚠️ GOOGLE_GEMINI_API_KEY não configurada. O serviço de assistente não funcionará.');
    }
    
    this.genAI = this.apiKey ? new GoogleGenerativeAI(this.apiKey) : null;
    this.model = null;
    
    // System instruction básico
    this.systemInstruction = `Você é o ASSISTENTE PM, especializado em produzir BOLETINS DE ATENDIMENTO (BA) e BOLETINS DE OCORRÊNCIA (BO), além de orientar procedimentos policiais.
REGRAS GERAIS
TODA A NARRATIVA DEVE SER ESCRITA 100% EM MAIÚSCULO.
Linguagem operacional, objetiva, impessoal e neutra, sem juízo de valor.
Priorize fatos, contatos realizados, informações obtidas, providências, resultado final.
Sempre respeite legalidade, proporcionalidade, normas institucionais.
Não invente dados pessoais.
Não forneça técnicas sigilosas.
Se houver qualquer dúvida factual, use placeholders.
MODELOS DE REDAÇÃO (REFERÊNCIA)
Use como estilo base:
“GUARNIÇÃO DESPACHADA PARA AVERIGUAÇÃO REFERENTE A 3 INDIVÍDUOS… NO LOCAL, FEITA A AVERIGUAÇÃO, A GUARNIÇÃO NÃO LOCALIZOU…”
“GUARNIÇÃO DESPACHADA VIA COPOM PARA SITUAÇÃO ONDE A PARTE SOLICITANTE…”
“TRATA-SE DE ORIENTAÇÃO DE PARTES.”
BOLETIM DE ATENDIMENTO (BA)
Não exige relato formal detalhado da vítima.
Foco: atendimento, orientação, averiguação, contato, diligências, negativa de fatos, encaminhamentos.
Quando nada constatado → **“TÍTULO DEVE SER: ‘DESPACHADA PARA SUPOSTA *’”
BOLETIM DE OCORRÊNCIA (BO)
OBRIGATÓRIO:
Relato da vítima/solicitante;
Relato do acusado apenas se quiser falar;
Se o acusado disser que só fala em juízo → registrar: “O ACUSADO INFORMOU QUE SOMENTE SE MANIFESTARÁ EM JUÍZO.”
Se houver uso de algema → citar:
“ALGEMAS EMPREGADAS NOS TERMOS DA SÚMULA 11 DO STF.”
REDAÇÃO PADRÃO
Sempre registrar:
LOCAL
CONTATO COM PARTES
RELATOS
AVERIGUAÇÃO / PROVIDÊNCIAS
RESULTADO
PASTA / BA / BO (se fornecidos)
TOM
Direto
Funcional
Texto curto, claro e copiável
Sem floreios
Apenas fatos
USER TEMPLATE
Sempre interpretar a entrada assim:
Copiar código

O USUÁRIO É UM POLICIAL MILITAR E SOLICITA MODELO, REDAÇÃO OU ORIENTAÇÃO.

[MENSAGEM_DO_USUÁRIO]`;
  }

  /**
   * Inicializa o modelo Gemini com o prompt básico
   */
  async initialize() {
    if (!this.genAI) {
      throw new ApiError(500, 'Serviço de IA não configurado. Verifique GOOGLE_GEMINI_API_KEY.');
    }

    try {
      console.log('🔄 Inicializando Assistente PM...');

      // Inicializa o modelo com o system instruction básico
      this.model = this.genAI.getGenerativeModel({
        model: 'gemini-2.5-flash',
        systemInstruction: this.systemInstruction,
      });

      console.log('✅ Assistente PM inicializado com sucesso.');
      return { message: 'Assistente PM inicializado com sucesso.' };
    } catch (error) {
      console.error('❌ Erro ao inicializar assistente:', error);
      throw new ApiError(500, `Erro ao inicializar assistente: ${error.message}`);
    }
  }

  /**
   * Consulta o assistente com uma dúvida sobre procedimentos
   * 
   * IMPORTANTE: Este método mantém o systemInstruction do modelo, garantindo que o assistente
   * sempre possa:
   * - Gerar boletins (BA/BO) quando solicitado
   * - Orientar procedimentos policiais
   * - Manter linguagem operacional em MAIÚSCULO
   * - Seguir todas as regras definidas no prompt
   * 
   * O histórico de chat é usado apenas para contexto da conversa, mas não substitui
   * as instruções do sistema.
   * 
   * @param {number} policialId - ID do policial
   * @param {string} texto - Texto da consulta
   * @param {string} sessionId - ID da sessão de chat (opcional)
   * @returns {Promise<Object>} Resposta do assistente
   */
  async consultar(policialId, texto, sessionId = null) {
    if (!this.model) {
      // Tenta inicializar se ainda não foi feito
      await this.initialize();
    }

    if (!texto || texto.trim().length === 0) {
      throw new ApiError(400, 'O texto da consulta é obrigatório.');
    }

    if (!policialId) {
      throw new ApiError(400, 'O ID do policial é obrigatório.');
    }

    try {
      // Gera sessionId se não fornecido (para manter compatibilidade)
      const finalSessionId = sessionId || `session-${policialId}-${Date.now()}`;

      // Busca o histórico de mensagens da sessão ANTES de salvar a nova mensagem
      const historicoMensagens = await assistantRepository.findMessagesBySession(
        policialId,
        finalSessionId,
        20
      );

      // Formata o histórico para o formato do Gemini
      const historicoFormatado = historicoMensagens
        .filter(msg => msg.role === 'user' || (msg.role === 'model' && msg.resposta))
        .map(msg => {
          if (msg.role === 'user') {
            return {
              role: 'user',
              parts: [{ text: msg.texto }]
            };
          } else {
            return {
              role: 'model',
              parts: [{ text: msg.resposta }]
            };
          }
        });

      // Inicializa o chat com histórico (se houver)
      // IMPORTANTE: O systemInstruction é mantido do modelo base, garantindo que
      // o assistente continue gerando boletins e orientando procedimentos corretamente
      let chat;
      if (historicoFormatado.length > 0) {
        chat = this.model.startChat({
          history: historicoFormatado
          // systemInstruction é herdado do modelo, não precisa ser redefinido
        });
      } else {
        chat = this.model.startChat();
      }

      // Salva a mensagem do usuário no banco
      await assistantRepository.createMessage(
        policialId,
        texto.trim(),
        'user',
        finalSessionId
      );

      // Envia a nova mensagem
      // O systemInstruction garante que o assistente sempre:
      // - Gere boletins (BA/BO) quando solicitado
      // - Oriente procedimentos policiais
      // - Mantenha linguagem operacional em MAIÚSCULO
      // - Siga as regras definidas no prompt
      const result = await chat.sendMessage(texto.trim());
      const response = await result.response;
      const resposta = response.text();

      // Salva a resposta da IA no banco
      await assistantRepository.createMessage(
        policialId,
        texto.trim(), // Mantém o texto original para referência
        'model',
        finalSessionId,
        resposta
      );

      return {
        resposta,
        sessionId: finalSessionId,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error('❌ Erro ao consultar assistente:', error);
      throw new ApiError(500, `Erro ao consultar assistente: ${error.message}`);
    }
  }

  /**
   * Gera uma narrativa de Boletim de Ocorrência baseada nos dados fornecidos
   * 
   * Este método usa o modelo diretamente (sem histórico de chat) para garantir
   * que o systemInstruction seja sempre respeitado na geração de boletins.
   */
  async gerarBoletim(dados) {
    if (!this.model) {
      await this.initialize();
    }

    if (!dados || typeof dados !== 'object') {
      throw new ApiError(400, 'Os dados do boletim são obrigatórios e devem ser um objeto JSON.');
    }

    try {
      // O system instruction já orienta o modelo sobre como gerar documentos
      // Usa generateContent diretamente (sem chat) para garantir que as regras sejam sempre seguidas
      const prompt = `Gere uma narrativa completa, clara e profissional para um Boletim de Ocorrência baseado nos seguintes dados:

DADOS DO OCORRÊNCIA:
${JSON.stringify(dados, null, 2)}

A narrativa deve:
1. Ser objetiva e clara
2. Seguir a estrutura padrão de BOs
3. Incluir todos os dados relevantes fornecidos
4. Usar linguagem técnica apropriada
5. Ser profissional, isenta, impessoal, sem juízo de valor
6. Garantir que não possa causar o entendimento de qualquer tipo de crime cometido pela guarnição ou polícia militar, como prevaricação ou deixar de cumprir algum regulamento

Gere apenas a narrativa, sem cabeçalhos ou formatação adicional.`;

      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const narrativa = response.text();

      return {
        narrativa,
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error('❌ Erro ao gerar boletim:', error);
      throw new ApiError(500, `Erro ao gerar boletim: ${error.message}`);
    }
  }
}

module.exports = new AssistantService();

