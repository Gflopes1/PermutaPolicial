// /lib/core/models/marketplace_item.dart

class MarketplaceItem {
  final int id;
  final String titulo;
  final String descricao;
  final double valor;
  final String tipo; // 'armas', 'veiculos', 'equipamentos'
  final List<String> fotos;
  final int policialId;
  final String? policialNome;
  final String? policialEmail;
  final String? policialTelefone; // Telefone do vendedor (qso)
  final String status; // 'PENDENTE', 'APROVADO', 'REJEITADO'
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  MarketplaceItem({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.fotos,
    required this.policialId,
    this.policialNome,
    this.policialEmail,
    this.policialTelefone,
    required this.status,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    // Função auxiliar para converter valor (pode vir como String ou num)
    double parseValor(dynamic valor) {
      if (valor is num) return valor.toDouble();
      if (valor is String) return double.parse(valor);
      return 0.0;
    }

    // Função auxiliar para converter fotos (pode vir como String JSON ou List)
    List<String> parseFotos(dynamic fotos) {
      if (fotos is List) {
        return fotos.map((e) => e.toString()).toList();
      }
      return [];
    }

    return MarketplaceItem(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      valor: parseValor(json['valor']),
      tipo: json['tipo'] as String,
      fotos: parseFotos(json['fotos']),
      policialId: json['policial_id'] as int,
      policialNome: json['policial_nome'] as String?,
      policialEmail: json['policial_email'] as String?,
      policialTelefone: json['policial_telefone'] as String?, // Novo campo
      status: json['status'] as String,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: json['atualizado_em'] != null 
          ? DateTime.parse(json['atualizado_em'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'fotos': fotos,
      'policial_id': policialId,
      'policial_nome': policialNome,
      'policial_email': policialEmail,
      'policial_telefone': policialTelefone,
      'status': status,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }

  String get tipoLabel {
    switch (tipo) {
      case 'armas':
        return 'Armas';
      case 'veiculos':
        return 'Veículos';
      case 'equipamentos':
        return 'Equipamentos';
      default:
        return tipo;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'PENDENTE':
        return 'Pendente';
      case 'APROVADO':
        return 'Aprovado';
      case 'REJEITADO':
        return 'Rejeitado';
      default:
        return status;
    }
  }

  MarketplaceItem copyWith({
    int? id,
    String? titulo,
    String? descricao,
    double? valor,
    String? tipo,
    List<String>? fotos,
    int? policialId,
    String? policialNome,
    String? policialEmail,
    String? policialTelefone,
    String? status,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return MarketplaceItem(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      fotos: fotos ?? this.fotos,
      policialId: policialId ?? this.policialId,
      policialNome: policialNome ?? this.policialNome,
      policialEmail: policialEmail ?? this.policialEmail,
      policialTelefone: policialTelefone ?? this.policialTelefone,
      status: status ?? this.status,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  @override
  String toString() {
    return 'MarketplaceItem(id: $id, titulo: $titulo, valor: $valor, tipo: $tipo, status: $status)';
  }
}