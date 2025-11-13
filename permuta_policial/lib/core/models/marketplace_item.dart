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
    required this.status,
    required this.criadoEm,
    this.atualizadoEm,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      valor: (json['valor'] as num).toDouble(),
      tipo: json['tipo'] as String,
      fotos: json['fotos'] is List ? (json['fotos'] as List).map((e) => e.toString()).toList() : [],
      policialId: json['policial_id'] as int,
      policialNome: json['policial_nome'] as String?,
      policialEmail: json['policial_email'] as String?,
      status: json['status'] as String,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: json['atualizado_em'] != null ? DateTime.parse(json['atualizado_em'] as String) : null,
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
}

