import 'package:bananal/screans/atividade/atividade.dart';
import 'package:flutter/material.dart';
import '../screans/Home.dart';
import '../screans/venda/Vendas.dart';
import '../screans/telaEmDesenvolvimento.dart';
import '../screans/area/Area.dart';

class menu extends StatelessWidget {
  final VoidCallback? onAdicionarPressed;
  final int itemAtivo; // 0 Financeiro, 1 Vendas, 2 Áreas, 3 Clima, 4 Agenda

  const menu({
    super.key,
    this.onAdicionarPressed,
    this.itemAtivo = 0,
  });

  void _ir(BuildContext context, int indice) {
    if (indice == itemAtivo) return; // já está nessa tela

    Widget? tela;
    if (indice == 0) tela = TelaHome();
    if (indice == 1) tela = TelaVendas();
    if (indice == 2) tela = TelaAreas();
    if (indice == 3) tela = TelaEmDesenvolvimento(itemAtivo: 3, titulo: 'Clima');
    if (indice == 4) tela = TelaAgenda();


    if (tela == null) return;

    final destino = tela;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destino),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _itemMenu(context, 0, Icons.attach_money, 'Financeiro')),
          Expanded(child: _itemMenu(context, 1, Icons.local_shipping_outlined, 'Vendas')),
          Expanded(child: _itemMenu(context, 2, Icons.location_on_outlined, 'Áreas')),
          Expanded(child: _itemMenu(context, 3, Icons.cloud_outlined, 'Clima')),
          Expanded(child: _itemMenu(context, 4, Icons.format_list_bulleted, 'Agenda')),
        ],
      ),
    );
  }

  Widget _itemMenu(BuildContext context, int indice, IconData icone, String texto) {
    final ativo = indice == itemAtivo;
    final cor = ativo ? Colors.green.shade800 : Colors.grey.shade600;

    return InkWell(
      onTap: () => _ir(context, indice),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: cor),
          const SizedBox(height: 4),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}