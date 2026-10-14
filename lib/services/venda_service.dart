import '../model/venda_model.dart';

class VendaService {
  static final List<Venda> _vendas = [];

  /// Devolve uma cópia da lista de vendas
  static List<Venda> listar() {
    return List<Venda>.from(_vendas);
  }

  static void adicionar(Venda venda) {
    _vendas.add(venda);
  }

  static void remover(Venda venda) {
    _vendas.remove(venda);
  }

  /// Troca uma venda existente pela versão editada
  /// (os campos do model são final, então se troca o objeto inteiro)
  static void atualizar(Venda antiga, Venda nova) {
    final indice = _vendas.indexOf(antiga);
    if (indice != -1) {
      _vendas[indice] = nova;
    }
  }

  /// Soma o valor total de todas as vendas (todas as classificações)
  static num receita() {
    num receita = 0;
    for (final venda in _vendas) {
      receita += venda.valorTotal;
    }
    return receita;
  }
}