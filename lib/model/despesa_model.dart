import 'package:cloud_firestore/cloud_firestore.dart';

class Despesa {
  String? id;
  final String nome;
  final double valor;
  final String descricao;
  final DateTime data;

  Despesa({
    this.id,
    required this.nome,
    required this.valor,
    required this.descricao,
    required this.data,
  });

  /// Objeto -> Map (o id não entra: ele é o nome do documento)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'valor': valor,
      'descricao': descricao,
      'data': Timestamp.fromDate(data),
    };
  }

  /// Map (vindo do Firestore) -> objeto
  factory Despesa.fromMap(Map<String, dynamic> map, String id) {
    return Despesa(
      id: id,
      nome: map['nome'] as String? ?? '',
      valor: (map['valor'] as num? ?? 0).toDouble(),
      descricao: map['descricao'] as String? ?? '',
      data: (map['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}