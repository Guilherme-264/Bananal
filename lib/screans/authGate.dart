import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home.dart';
import 'login.dart';

/// "Porteiro" do app: decide qual tela mostrar.
/// Logado -> Home. Não logado -> Login.
/// Ele reage sozinho quando o usuário entra ou sai da conta.
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.estadoAutenticacao,
      builder: (context, snapshot) {
        // ainda descobrindo se tem alguém logado
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.grey.shade100,
            body: Center(
              child: CircularProgressIndicator(color: Colors.green.shade800),
            ),
          );
        }

        if (snapshot.hasData) {
          return TelaHome();
        }

        return TelaLogin();
      },
    );
  }
}