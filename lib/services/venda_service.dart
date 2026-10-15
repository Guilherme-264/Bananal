import '../model/venda_model.dart';

class VendaService {
  static final List<Venda> _vendas = [];

  static List<Venda> listar() {
    return List<Venda>.from(_vendas);
  }

  static void adicionar(Venda venda) {
    _vendas.add(venda);
  }

  static void remover(Venda venda) {
    _vendas.remove(venda);
  }

  static void atualizar(Venda antiga, Venda nova) {
    final indice = _vendas.indexOf(antiga);
    if (indice != -1) {
      _vendas[indice] = nova;
    }
  }

  static num receita() {
    num receita = 0;
    for (final venda in _vendas) {
      receita += venda.valorTotal;
    }
    return receita;
  }
}