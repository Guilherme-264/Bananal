import 'package:flutter/material.dart';

class Cabecalho extends StatelessWidget {
  final bool mostrarVoltar; // mostra o botão de voltar (padrão: não)
  final VoidCallback? onVoltar; // o que fazer ao tocar (padrão: voltar à tela anterior)

  Cabecalho({
    super.key,
    this.mostrarVoltar = false,
    this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Botão de voltar (só aparece quando mostrarVoltar = true)
          if (mostrarVoltar) ...[
            InkWell(
              onTap: onVoltar ?? () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back, color: Colors.green.shade800),
              ),
            ),
            SizedBox(width: 12),
          ],
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.eco, color: Colors.green.shade800),
          ),
          SizedBox(width: 12),
          Text(
            'Bananal',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/avatar.png'),
          ),
        ],
      ),
    );
  }
}