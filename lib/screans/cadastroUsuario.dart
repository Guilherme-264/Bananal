import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'authGate.dart';

class TelaCadastroUsuario extends StatefulWidget {
  @override
  _TelaCadastroUsuarioState createState() => _TelaCadastroUsuarioState();
}

class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();

  bool _senhaVisivel = false;
  bool _carregando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _criarConta() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _senhaController.text;
    final confirmar = _confirmarController.text;

    if (nome.isEmpty) {
      _aviso('Informe seu nome');
      return;
    }
    if (!email.contains('@')) {
      _aviso('Informe um e-mail válido');
      return;
    }
    if (senha.length < 6) {
      _aviso('A senha precisa ter pelo menos 6 caracteres');
      return;
    }
    if (senha != confirmar) {
      _aviso('As senhas não são iguais');
      return;
    }

    setState(() => _carregando = true);
    final erro = await AuthService.criarConta(
      nome: nome,
      email: email,
      senha: senha,
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    if (erro != null) {
      _aviso(erro);
      return;
    }

    // Conta criada (e já logada): recomeça a pilha de telas pelo AuthGate,
    // que vai mostrar a Home.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AuthGate()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.green.shade800,
        elevation: 0,
        title: const Text(
          'Criar conta',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
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
                _label('Nome'),
                TextField(
                  controller: _nomeController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

                _label('Confirmar senha'),
                TextField(
                  controller: _confirmarController,
                  obscureText: !_senhaVisivel,
                  onSubmitted: (_) => _criarConta(),
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _carregando ? null : _criarConta,
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
                      'Criar conta',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
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