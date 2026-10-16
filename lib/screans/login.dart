import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'cadastroUsuario.dart';

class TelaLogin extends StatefulWidget {
  @override
  _TelaLoginState createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _entrar() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _aviso('Preencha o e-mail e a senha');
      return;
    }

    setState(() => _carregando = true);
    final erro = await AuthService.entrar(email: email, senha: senha);

    // Se deu certo, o AuthGate já troca para a Home e esta tela some
    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      _aviso(erro);
    }
  }

  Future<void> _esqueciSenha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _aviso('Digite seu e-mail no campo acima primeiro');
      return;
    }

    final erro = await AuthService.recuperarSenha(email: email);
    if (!mounted) return;

    _aviso(erro ?? 'Enviamos um link para redefinir a senha no seu e-mail');
  }

  void _abrirCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaCadastroUsuario()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.eco, size: 40, color: Colors.green.shade800),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bananal',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entre na sua conta',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('E-mail'),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: _inputDecoration(),
                      ),
                      const SizedBox(height: 16),

                      _label('Senha'),
                      TextField(
                        controller: _senhaController,
                        obscureText: !_senhaVisivel,
                        onSubmitted: (_) => _entrar(),
                        decoration: _inputDecoration(
                          sufixo: IconButton(
                            icon: Icon(
                              _senhaVisivel
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () =>
                                setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _esqueciSenha,
                          child: Text(
                            'Esqueci minha senha',
                            style: TextStyle(color: Colors.green.shade800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _carregando ? null : _entrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _carregando
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Entrar',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem conta?',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: _abrirCadastro,
                      child: Text(
                        'Criar conta',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(texto,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
    );
  }

  InputDecoration _inputDecoration({Widget? sufixo}) {
    return InputDecoration(
      suffixIcon: sufixo,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}