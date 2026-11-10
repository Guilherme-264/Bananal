import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screans/authGate.dart';

/// Um item da ajuda: ícone, título curto e explicação
class ItemAjuda {
  final IconData icone;
  final String titulo;
  final String texto;

  const ItemAjuda(this.icone, this.titulo, this.texto);
}

class Cabecalho extends StatelessWidget {
  final bool mostrarVoltar; // mostra o botão de voltar (padrão: não)
  final VoidCallback? onVoltar; // o que fazer ao tocar (padrão: voltar à tela anterior)

  /// Ajuda da tela. Se vier preenchida, aparece o "?" no cabeçalho
  /// e, ao tocar, abre a explicação de como usar a tela.
  final String? tituloAjuda;
  final List<ItemAjuda> ajuda;

  Cabecalho({
    super.key,
    this.mostrarVoltar = false,
    this.onVoltar,
    this.tituloAjuda,
    this.ajuda = const [],
  });

  void _abrirAjuda(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // alça da folha
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tituloAjuda ?? 'Como usar esta tela',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final item in ajuda)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icone,
                          size: 20, color: Colors.green.shade800),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titulo,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.texto,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Entendi',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // o espaço da barra de notificações é somado aqui; nas telas que já
      // usam SafeArea esse valor chega zerado, então não duplica
      padding: EdgeInsets.fromLTRB(
        16,
        12 + MediaQuery.of(context).padding.top,
        16,
        12,
      ),
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
          // Botão "?" (só aparece quando a tela tem ajuda)
          if (ajuda.isNotEmpty) ...[
            InkWell(
              onTap: () => _abrirAjuda(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.question_mark,
                    size: 22, color: Colors.green.shade800),
              ),
            ),
            SizedBox(width: 12),
          ],
          // Avatar com menu da conta (mostra o e-mail e o botão Sair)
          PopupMenuButton<String>(
            tooltip: 'Conta',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (valor) async {
              if (valor == 'sair') {
                await AuthService.sair();
                if (!context.mounted) return;
                // recomeça a pilha de telas pelo AuthGate, que mostra o Login
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AuthGate()),
                      (route) => false,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  AuthService.usuarioAtual?.email ?? 'Conta',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'sair',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    const Text('Sair'),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/images/avatar.png'),
            ),
          ),
        ],
      ),
    );
  }
}