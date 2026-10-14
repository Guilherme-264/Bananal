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
}

class Venda{
  String? id;
  final String comprador;
  final DateTime data;
  final List<Classificacao> classificacoes;



  Venda({
    required this.comprador,
    required this.classificacoes,
    DateTime? data,
  }) : data = data ?? DateTime.now();

  double get valorTotal =>
      classificacoes.fold<double>(0, (soma, c) => soma + c.valorTotal);

  int get totalCaixas =>
      classificacoes.fold<int>(0, (soma, c) => soma + c.quantidadeCaixa);
}