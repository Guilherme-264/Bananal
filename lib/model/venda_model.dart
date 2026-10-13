class Venda{
  String? id;
  final String comprador;
  final int pesoCaixa;
  final int quantidadeCaixa;
  final double valorCaixa;
  final DateTime data;


  Venda({
    required this.comprador,
    required this.pesoCaixa,
    required this.quantidadeCaixa,
    required this.valorCaixa,
    DateTime? data,
  }) : data = data ?? DateTime.now();
  double get valorTotal => quantidadeCaixa * valorCaixa;

}