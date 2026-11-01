import 'package:cloud_firestore/cloud_firestore.dart';

class Classificacao {
  final int pesoCaixa;
  final int quantidadeCaixa;
  final double valorCaixa;

  Classificacao({
    required this.pesoCaixa,
    required this.quantidadeCaixa,
    required this.valorCaixa,
  });

  // total só desta classificação
  double get valorTotal => quantidadeCaixa * valorCaixa;

  /// Objeto -> Map (formato que o Firestore guarda)
  Map<String, dynamic> toMap() {
    return {
      'pesoCaixa': pesoCaixa,
      'quantidadeCaixa': quantidadeCaixa,
      'valorCaixa': valorCaixa,
    };
  }

  /// Map (vindo do Firestore) -> objeto
  factory Classificacao.fromMap(Map<String, dynamic> map) {
    return Classificacao(
      pesoCaixa: (map['pesoCaixa'] as num? ?? 0).toInt(),
      quantidadeCaixa: (map['quantidadeCaixa'] as num? ?? 0).toInt(),
      valorCaixa: (map['valorCaixa'] as num? ?? 0).toDouble(),
    );
  }
}

class Venda {
  String? id; // id do documento no Firestore (null enquanto não foi salva)
  final String comprador;
  final DateTime data;
  final List<Classificacao> classificacoes;
  final List<String> areasIds; // ids das áreas de onde foi colhido (0 ou mais)

  Venda({
    this.id,
    required this.comprador,
    required this.classificacoes,
    this.areasIds = const [],
    DateTime? data,
  }) : data = data ?? DateTime.now();

  // soma de todas as classificações
  double get valorTotal =>
      classificacoes.fold<double>(0, (soma, c) => soma + c.valorTotal);

  int get totalCaixas =>
      classificacoes.fold<int>(0, (soma, c) => soma + c.quantidadeCaixa);

  /// Objeto -> Map (o id não entra: ele é o nome do documento)
  Map<String, dynamic> toMap() {
    return {
      'comprador': comprador,
      'data': Timestamp.fromDate(data),
      'classificacoes': classificacoes.map((c) => c.toMap()).toList(),
      'areasIds': areasIds,
    };
  }

  /// Map (vindo do Firestore) -> objeto
  factory Venda.fromMap(Map<String, dynamic> map, String id) {
    final lista = (map['classificacoes'] as List<dynamic>? ?? []);

    return Venda(
      id: id,
      comprador: map['comprador'] as String? ?? '',
      data: (map['data'] as Timestamp?)?.toDate(),
      // vendas antigas não têm esse campo: ficam sem áreas
      areasIds: List<String>.from(map['areasIds'] as List<dynamic>? ?? []),
      classificacoes: lista
          .map((c) => Classificacao.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList(),
    );
  }
}