import 'package:flutter/material.dart';
import '../services/venda_service.dart';
import '../model/venda_model.dart';
import 'cadastrarVenda.dart';
import '../widgets/cabecalho.dart';
import '../widgets/menu.dart';

class TelaHome extends StatefulWidget {
  @override
  _TelaHomeState createState() => _TelaHomeState();


}

class _TelaHomeState extends State<TelaHome> {
  @override
  Widget build(BuildContext context) {
    num receita = VendaService.receita();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cardSaldo(receita),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _cardReceita(receita)),
                      SizedBox(width: 12),
                      Expanded(child: _cardDespesa(receita)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: menu(
        onAdicionarPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TelaCadastroVenda()),
          ).then((_) {
            setState(() {});
          });
        },
      ),
    );
  }

  Widget _cardSaldo(num receita){
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("SALDO DISPONÍVEL",style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 8,),
          Text("R\$ $receita", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

        ],
      ),
    );

  }

  Widget _cardReceita(num receita){
    return _cardIndicador(
      titulo: "Receita",
      valor: "R\$ $receita",
      cor: Colors.green,
      icone: Icons.arrow_upward,
    );
  }

  Widget _cardDespesa(num receita){
    return _cardIndicador(
      titulo: "Despesa",
      valor: "R\$ 0",
      cor: Colors.red,
      icone: Icons.arrow_downward,
    );
  }

  Widget _cardIndicador({
    required String titulo,
    required String valor,
    required Color cor,
    required IconData icone
  })
  {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor),
              SizedBox(width: 4),
              Text(titulo, style: TextStyle(color: cor)),
            ],
          ),
          SizedBox(height: 8),
          Text(valor, style: TextStyle(color: cor ,fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),

    );

  }
}