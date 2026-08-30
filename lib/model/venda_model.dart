class Venda{
  String? id;
  String comprador;
  int pesoCaixa;
  int quantidadeCaixa;
  num valorCaixa;

  Venda({
    this.id,
    required this.comprador,
    required this.pesoCaixa,
    required this.quantidadeCaixa,
    required this.valorCaixa,
  });
}