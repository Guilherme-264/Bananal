import '../model/despesa_model.dart';
class DespesaService{
  static final List<Despesa> _despesas = [];

  static List<Despesa> listar(){
    return List<Despesa>.from(_despesas);
  }

  static void adicionar(Despesa despesa){
    _despesas.add(despesa);
  }

  static void remover(Despesa despesa){
    _despesas.remove(despesa);
  }

  static void atualizar(Despesa antiga, Despesa nova) {
    final indice = _despesas.indexOf(antiga);
    if (indice != -1) {
      _despesas[indice] = nova;
    }
  }

  static num total() {
    num total = 0;
    for (final despesa in _despesas) {
      total += despesa.valor;
    }
    return total;
  }

}