import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/cliente_model.dart';
import 'auth_service.dart';

/// Guarda os clientes no Firestore, em: usuarios/{uid}/clientes
/// Cada usuário só enxerga os próprios clientes.
class ClienteService {
  /// Lista de clientes do usuário logado, em ordem alfabética.
  /// O Firestore atualiza ela sozinho; as telas "escutam" este notificador.
  static final ValueNotifier<List<Cliente>> clientes =
  ValueNotifier<List<Cliente>>([]);

  static StreamSubscription? _assinaturaAuth;
  static StreamSubscription? _assinaturaClientes;

  /// Chame UMA vez no main(), depois do Firebase.initializeApp().
  static void iniciar() {
    _assinaturaAuth?.cancel();
    _assinaturaAuth = AuthService.estadoAutenticacao.listen((usuario) {
      _assinaturaClientes?.cancel();
      _assinaturaClientes = null;

      if (usuario == null) {
        clientes.value = [];
        return;
      }

      _assinaturaClientes = _colecao(usuario.uid).snapshots().listen(
            (snapshot) {
          final lista = snapshot.docs
              .map((doc) => Cliente.fromMap(doc.data(), doc.id))
              .toList();

          // ordem alfabética sem diferenciar maiúsculas de minúsculas
          // (feito aqui porque o Firestore põe "Zé" antes de "ana")
          lista.sort(
                (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
          );

          clientes.value = lista;
        },
        onError: (erro) => debugPrint('Erro ao ler clientes: $erro'),
      );
    });
  }

  static CollectionReference<Map<String, dynamic>> _colecao(String uid) {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('clientes');
  }

  /// Coleção do usuário logado agora (null se ninguém estiver logado)
  static CollectionReference<Map<String, dynamic>>? get _colecaoAtual {
    final uid = AuthService.usuarioAtual?.uid;
    return uid == null ? null : _colecao(uid);
  }

  /// Devolve uma cópia da lista atual de clientes
  static List<Cliente> listar() {
    return List<Cliente>.from(clientes.value);
  }

  static Future<void> adicionar(Cliente cliente) async {
    final colecao = _colecaoAtual;
    if (colecao == null) return;
    await colecao.add(cliente.toMap());
  }

  static Future<void> remover(Cliente cliente) async {
    final colecao = _colecaoAtual;
    if (colecao == null || cliente.id == null) return;
    await colecao.doc(cliente.id).delete();
  }

  /// Troca um cliente existente pela versão editada
  static Future<void> atualizar(Cliente antigo, Cliente novo) async {
    // o novo herda o id do antigo (precisa vir antes de qualquer await)
    novo.id = antigo.id;

    final colecao = _colecaoAtual;
    if (colecao == null || antigo.id == null) return;
    await colecao.doc(antigo.id).set(novo.toMap());
  }
}