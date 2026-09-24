/// Configuração de rótulos e campos por força/tipo de documento.
///
/// Para adicionar suporte a uma nova corporação ou layout, inclua um
/// [DocumentoTipoConfig] em [DocumentoCampoConfigRegistry.configs] —
/// a lógica de extração por âncoras permanece a mesma.
///
/// Plano B (não implementado): se a precisão continuar insatisfatória,
/// permitir recorte manual de cada campo relevante (ex.: image_cropper)
/// e rodar OCR apenas no recorte pequeno. Ver comentário em
/// [DocumentoAnchorExtractor].
library;

enum ValorPosicao {
  /// Valor na mesma linha, à direita do rótulo.
  direita,

  /// Valor na linha imediatamente abaixo do rótulo.
  abaixo,

  /// Várias linhas abaixo (ex.: Filiação).
  abaixoMultiplo,
}

enum CampoFinalidade {
  /// Extraído como dado estruturado para verificação.
  verificacao,

  /// Apenas identificado para ocultar na imagem — nunca extraído.
  sensivel,

  /// Usado só para identificar força/tipo do documento.
  identificacao,
}

enum CampoVerificacao {
  nome,
  matricula,
  cargo,
  forca,
}

class CampoConfig {
  final String id;
  final List<String> rotulos;
  final ValorPosicao posicao;
  final CampoFinalidade finalidade;
  final CampoVerificacao? extrairComo;
  final int linhasAbaixo;
  final String? validacaoPattern;

  const CampoConfig({
    required this.id,
    required this.rotulos,
    required this.posicao,
    required this.finalidade,
    this.extrairComo,
    this.linhasAbaixo = 1,
    this.validacaoPattern,
  });
}

class DocumentoTipoConfig {
  final String id;
  final String forcaSigla;
  final String tipoDocumento;
  final List<String> cabecalhosIdentificacao;
  final List<CampoConfig> campos;

  const DocumentoTipoConfig({
    required this.id,
    required this.forcaSigla,
    required this.tipoDocumento,
    required this.cabecalhosIdentificacao,
    required this.campos,
  });
}

class DocumentoCampoConfigRegistry {
  DocumentoCampoConfigRegistry._();

  static const List<DocumentoTipoConfig> configs = [
    DocumentoTipoConfig(
      id: 'bmrs_funcional',
      forcaSigla: 'BMRS',
      tipoDocumento: 'funcional',
      cabecalhosIdentificacao: [
        'BRIGADA MILITAR',
        'CARTEIRA DE IDENTIDADE FUNCIONAL',
        'ESTADO DO RIO GRANDE DO SUL',
      ],
      campos: [
        CampoConfig(
          id: 'forca_cabecalho',
          rotulos: ['BRIGADA MILITAR'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.identificacao,
          extrairComo: CampoVerificacao.forca,
        ),
        CampoConfig(
          id: 'numero',
          rotulos: ['Número', 'Numero'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'valido_ate',
          rotulos: ['Válido até', 'Valido ate', 'Valido até'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'nome',
          rotulos: ['Portador'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.nome,
        ),
        CampoConfig(
          id: 'cargo',
          rotulos: [
            'Posto/Graduação',
            'Posto Graduação',
            'Posto/Graduacao',
            'Posto Graduacao',
          ],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.cargo,
        ),
        CampoConfig(
          id: 'filiacao',
          rotulos: ['Filiação', 'Filiacao'],
          posicao: ValorPosicao.abaixoMultiplo,
          linhasAbaixo: 2,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'rg',
          rotulos: ['RG'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'data_nasc',
          rotulos: ['Data de Nasc', 'Data Nasc', 'Data de Nascimento'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'cpf',
          rotulos: ['CPF'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
          validacaoPattern: r'\d{3}\.\d{3}\.\d{3}-\d{2}',
        ),
        CampoConfig(
          id: 'tipo_sangue',
          rotulos: [
            'G. Sang/Fator Rh',
            'G Sang/Fator Rh',
            'G. Sang',
            'Fator Rh',
            'Tipo Sanguíneo',
          ],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'naturalidade',
          rotulos: ['Naturalidade'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'cor_olhos',
          rotulos: ['Cor dos Olhos', 'Cor Olhos'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'emissao',
          rotulos: [
            'Local e Data de Emissão',
            'Local e Data de Emissao',
            'Local e Data Emissão',
          ],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'altura',
          rotulos: ['Altura'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'matricula',
          rotulos: [
            'Id. Funcional',
            'Id Funcional',
            'ld. Funcional',
            'ld Funcional',
            'Identidade Funcional',
          ],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.matricula,
          validacaoPattern: r'^[\dA-Za-z.\-/]{4,20}$',
        ),
      ],
    ),
    DocumentoTipoConfig(
      id: 'pmesp_funcional',
      forcaSigla: 'PMESP',
      tipoDocumento: 'funcional',
      cabecalhosIdentificacao: [
        'POLÍCIA MILITAR',
        'POLICIA MILITAR',
        'PMESP',
        'SÃO PAULO',
        'SAO PAULO',
        'CARTEIRA FUNCIONAL',
      ],
      campos: [
        CampoConfig(
          id: 'forca_cabecalho',
          rotulos: ['POLÍCIA MILITAR', 'POLICIA MILITAR', 'PMESP'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.identificacao,
          extrairComo: CampoVerificacao.forca,
        ),
        CampoConfig(
          id: 'nome',
          rotulos: ['Nome', 'Portador', 'Nome Completo'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.nome,
        ),
        CampoConfig(
          id: 'matricula',
          rotulos: ['Matrícula', 'Matricula', 'Registro', 'Id Funcional'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.matricula,
          validacaoPattern: r'^\d{6,8}$',
        ),
        CampoConfig(
          id: 'cargo',
          rotulos: ['Posto', 'Graduação', 'Graduacao', 'Posto/Graduação'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.cargo,
        ),
        CampoConfig(
          id: 'cpf',
          rotulos: ['CPF'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
          validacaoPattern: r'\d{3}\.\d{3}\.\d{3}-\d{2}',
        ),
        CampoConfig(
          id: 'rg',
          rotulos: ['RG'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'data_nasc',
          rotulos: ['Data de Nascimento', 'Data Nasc', 'Nascimento'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
        ),
      ],
    ),
    DocumentoTipoConfig(
      id: 'contracheque_generico',
      forcaSigla: '',
      tipoDocumento: 'contracheque',
      cabecalhosIdentificacao: [
        'CONTRACHEQUE',
        'HOLERITE',
        'DEMONSTRATIVO DE PAGAMENTO',
        'FOLHA DE PAGAMENTO',
      ],
      campos: [
        CampoConfig(
          id: 'nome',
          rotulos: ['Nome', 'Servidor', 'Funcionário', 'Funcionario', 'Empregado'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.nome,
        ),
        CampoConfig(
          id: 'matricula',
          rotulos: [
            'Matrícula',
            'Matricula',
            'Id Funcional',
            'Id. Funcional',
            'Registro',
          ],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.matricula,
        ),
        CampoConfig(
          id: 'cargo',
          rotulos: ['Cargo', 'Função', 'Funcao', 'Posto', 'Graduação'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.cargo,
        ),
        CampoConfig(
          id: 'orgao',
          rotulos: ['Órgão', 'Orgao', 'Secretaria', 'Lotação', 'Lotacao'],
          posicao: ValorPosicao.abaixo,
          finalidade: CampoFinalidade.verificacao,
          extrairComo: CampoVerificacao.forca,
        ),
        CampoConfig(
          id: 'cpf',
          rotulos: ['CPF'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
          validacaoPattern: r'\d{3}\.\d{3}\.\d{3}-\d{2}',
        ),
        CampoConfig(
          id: 'salario',
          rotulos: [
            'Salário',
            'Salario',
            'Salário Líquido',
            'Salario Liquido',
            'Vencimentos',
            'Total Líquido',
          ],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
        ),
        CampoConfig(
          id: 'conta',
          rotulos: ['Conta', 'Agência', 'Agencia', 'Banco', 'Pix', 'PIX'],
          posicao: ValorPosicao.direita,
          finalidade: CampoFinalidade.sensivel,
        ),
      ],
    ),
  ];

  static DocumentoTipoConfig? resolve({
    required List<({String text, dynamic rect})> lines,
    String? forcaSigla,
    String? tipoDocumento,
  }) {
    final sigla = (forcaSigla ?? '').trim().toUpperCase();
    final tipo = (tipoDocumento ?? '').trim().toLowerCase();

    if (sigla.isNotEmpty && tipo.isNotEmpty) {
      final exact = configs.where(
        (c) =>
            c.forcaSigla.toUpperCase() == sigla &&
            c.tipoDocumento.toLowerCase() == tipo,
      );
      if (exact.isNotEmpty) return exact.first;
    }

    if (tipo.isNotEmpty) {
      final byTipo = configs.where((c) => c.tipoDocumento.toLowerCase() == tipo);
      final detected = _detectByHeaders(lines, byTipo.toList());
      if (detected != null) return detected;
      if (byTipo.length == 1) return byTipo.first;
      final generic = byTipo.where((c) => c.forcaSigla.isEmpty);
      if (generic.isNotEmpty) return generic.first;
    }

    final detectedAny = _detectByHeaders(lines, configs);
    if (detectedAny != null) return detectedAny;

    if (sigla.isNotEmpty) {
      final byForca = configs.where((c) => c.forcaSigla.toUpperCase() == sigla);
      if (byForca.isNotEmpty) return byForca.first;
    }

    return null;
  }

  static DocumentoTipoConfig? _detectByHeaders(
    List<({String text, dynamic rect})> lines,
    List<DocumentoTipoConfig> candidates,
  ) {
    DocumentoTipoConfig? best;
    var bestScore = 0;

    for (final config in candidates) {
      var score = 0;
      for (final line in lines) {
        final normalized = _normalizeHeader(line.text);
        for (final header in config.cabecalhosIdentificacao) {
          if (normalized.contains(_normalizeHeader(header))) {
            score++;
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = config;
      }
    }

    return bestScore > 0 ? best : null;
  }

  static String _normalizeHeader(String value) {
    return value
        .toUpperCase()
        .replaceAll(RegExp(r'[ÁÀÂÃÄ]'), 'A')
        .replaceAll(RegExp(r'[ÉÈÊË]'), 'E')
        .replaceAll(RegExp(r'[ÍÌÎÏ]'), 'I')
        .replaceAll(RegExp(r'[ÓÒÔÕÖ]'), 'O')
        .replaceAll(RegExp(r'[ÚÙÛÜ]'), 'U')
        .replaceAll(RegExp(r'[Ç]'), 'C')
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
