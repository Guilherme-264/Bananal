import '../model/venda_model.dart';

class VendaService {

  static List<Venda> _venda = [];

  static List<Venda> listar(){
    final num valorReceita = receita();
    return _venda;
  }

  static void adicionar(Venda venda){
    _venda.add(venda);
  }

  static void remover(Venda venda){
    _venda.remove(venda);
  }

  static num receita(){
    num receita = 0;
    for(int i = 0; i < _venda.length; i++){
      receita += _venda[i].valorCaixa * _venda[i].quantidadeCaixa;
    }
    return receita;
  }
}

