import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/despesa_model.dart';
import 'auth_service.dart';

/// Guarda as despesas no Firestore, em: usuarios/{uid}/despesas
/// Cada usuário só enxerga as próprias despesas.
class DespesaService {
  /// Lista de despesas do usuário logado. O Firestore atualiza ela sozinho;
  /// as telas "escutam" este notificador para se redesenhar.
  static final ValueNotifier<List<Despesa>> despesas =
  ValueNotifier<List<Despesa>>([]);

  static StreamSubscription? _assinaturaAuth;
  static StreamSubscription? _assinaturaDespesas;

  /// Chame UMA vez no main(), depois do Firebase.initializeApp().
  static void iniciar() {
    _assinaturaAuth?.cancel();
    _assinaturaAuth = AuthService.estadoAutenticacao.listen((usuario) {
      _assinaturaDespesas?.cancel();
      _assinaturaDespesas = null;

      if (usuario == null) {
        despesas.value = [];
        return;
      }

      _assinaturaDespesas = _colecao(usuario.uid)
          .orderBy('data', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
          despesas.value = snapshot.docs
              .map((doc) => Despesa.fromMap(doc.data(), doc.id))
              .toList();
        },
        onError: (erro) => debugPrint('Erro ao ler despesas: $erro'),
      );
    });
  }

  static CollectionReference<Map<String, dynamic>> _colecao(String uid) {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('despesas');
  }

  /// Coleção do usuário logado agora (null se ninguém estiver logado)
  static CollectionReference<Map<String, dynamic>>? get _colecaoAtual {
    final uid = AuthService.usuarioAtual?.uid;
    return uid == null ? null : _colecao(uid);
  }

  /// Devolve uma cópia da lista atual de despesas
  static List<Despesa> listar() {
    return List<Despesa>.from(despesas.value);
  }

  static Future<void> adicionar(Despesa despesa) async {
    final colecao = _colecaoAtual;
    if (colecao == null) return;
    await colecao.add(despesa.toMap());
  }

  static Future<void> remover(Despesa despesa) async {
    final colecao = _colecaoAtual;
    if (colecao == null || despesa.id == null) return;
    await colecao.doc(despesa.id).delete();
  }

  /// Troca uma despesa existente pela versão editada
  static Future<void> atualizar(Despesa antiga, Despesa nova) async {
    // a nova despesa herda o id da antiga (precisa vir antes de qualquer await)
    nova.id = antiga.id;

    final colecao = _colecaoAtual;
    if (colecao == null || antiga.id == null) return;
    await colecao.doc(antiga.id).set(nova.toMap());
  }

  /// Soma o valor de todas as despesas
  static num total() {
    num total = 0;
    for (final despesa in despesas.value) {
      total += despesa.valor;
    }
    return total;
  }
}