import 'package:flutter/material.dart';

class menu extends StatelessWidget {
  final VoidCallback onAdicionarPressed;

  menu({required this.onAdicionarPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
          Expanded(child: _itemMenu(Icons.attach_money, 'Financeiro', ativo: true)),
          Expanded(child: _itemMenu(Icons.location_on_outlined, 'Localização')),

          GestureDetector(
            onTap: onAdicionarPressed,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
          Expanded(child: _itemMenu(Icons.cloud_outlined, "Clima")),
          Expanded(child: _itemMenu(Icons.people_outline, "Pessoas")),
        ],
      ),
    );



  }
  Widget _itemMenu(IconData icone, String texto, {bool ativo = false}) {
    final cor = ativo ? Colors.green.shade800 : Colors.grey.shade600;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icone, color: cor),
        SizedBox(height: 4),
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
    );
  }
}