import 'package:firebase_auth/firebase_auth.dart';

/// Cuida de tudo que é login/cadastro com o Firebase Authentication.
///
/// Os métodos que podem falhar devolvem uma mensagem de erro em português
/// (String) ou null quando deu certo. Assim as telas não precisam conhecer
/// o Firebase.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Usuário logado agora (null se ninguém estiver logado)
  static User? get usuarioAtual => _auth.currentUser;

  /// Avisa sempre que alguém entra ou sai da conta
  static Stream<User?> get estadoAutenticacao => _auth.authStateChanges();

  static Future<String?> entrar({
    required String email,
    required String senha,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    } catch (_) {
      return 'Não foi possível entrar. Tente novamente.';
    }
  }

  static Future<String?> criarConta({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      await credencial.user?.updateDisplayName(nome.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    } catch (_) {
      return 'Não foi possível criar a conta. Tente novamente.';
    }
  }

  static Future<String?> recuperarSenha({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    } catch (_) {
      return 'Não foi possível enviar o e-mail. Tente novamente.';
    }
  }

  static Future<void> sair() => _auth.signOut();

  /// Transforma o código de erro do Firebase em mensagem para o usuário
  static String _traduzirErro(String codigo) {
    switch (codigo) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'operation-not-allowed':
        return 'Login por e-mail não está ativado no Firebase.';
      default:
        return 'Erro ao autenticar ($codigo).';
    }
  }
}