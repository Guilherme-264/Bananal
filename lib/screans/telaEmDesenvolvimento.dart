import 'package:flutter/material.dart';
import '../widgets/cabecalho.dart';
import '../widgets/menu.dart';


class TelaEmDesenvolvimento extends StatelessWidget {
  final int itemAtivo; // 0 Financeiro, 1 Vendas, 2 Áreas, 3 Clima, 4 Agenda
  final String titulo; // nome da seção, ex: 'Áreas'

  const TelaEmDesenvolvimento({
    super.key,
    required this.itemAtivo,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.build_outlined, // chave de boca
                        size: 44,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Em desenvolvimento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Esta seção estará disponível em breve.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: menu(itemAtivo: itemAtivo),
    );
  }
}