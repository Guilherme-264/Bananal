class Despesa{
  String? id;
  final String nome;
  final double valor;
  final String descricao;
  final DateTime data;

  Despesa({
    required this.nome,
    required this.valor,
    required this.descricao,
    required this.data
  });
}