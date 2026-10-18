import 'package:cloud_firestore/cloud_firestore.dart';

class Atividade {
  String ? id;
  final String nome;
  final String descricao;
  final DateTime data;
  final bool concluida;
  final String horario;


  Atividade({
    this.id,
    required this.nome,
    required this.descricao,
    required this.data,
    required this.concluida,
    required this.horario,
  });

  Map <String, dynamic> toMap(){
    return {
      'nome': nome,
      'descricao': descricao,
      'data': Timestamp.fromDate(data),
      'concluida': concluida,
      'horario': horario,
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
    );
  }
}