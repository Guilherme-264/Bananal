import 'package:cloud_firestore/cloud_firestore.dart';

class Atividade {
  String? id;
  final String nome;
  final String descricao;
  final DateTime data;
  final bool concluida;
  final String horario;

  /// Tipo de manejo: Adubação, Pulverização, Poda, Ensacamento ou Outro
  final String tipo;

  /// Id da área onde a atividade acontece (opcional)
  final String? areaId;

  Atividade({
    this.id,
    required this.nome,
    required this.descricao,
    required this.data,
    required this.concluida,
    required this.horario,
    this.tipo = 'Outro',
    this.areaId,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'data': Timestamp.fromDate(data),
      'concluida': concluida,
      'horario': horario,
      'tipo': tipo,
      'areaId': areaId,
    };
  }

  factory Atividade.fromMap(Map<String, dynamic> map, String id) {
    return Atividade(
      id: id,
      nome: map['nome'] as String? ?? '',
      descricao: map['descricao'] as String? ?? '',
      data: (map['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      concluida: map['concluida'] as bool? ?? false,
      horario: map['horario'] as String? ?? '',
      // atividades antigas não têm tipo nem área
      tipo: map['tipo'] as String? ?? 'Outro',
      areaId: map['areaId'] as String?,
    );
  }
}