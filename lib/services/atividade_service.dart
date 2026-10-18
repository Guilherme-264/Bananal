import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/atividade_model.dart';
import 'auth_service.dart';

/// Guarda as atividades da agenda no Firestore, em: usuarios/{uid}/atividades
/// Cada usuário só enxerga as próprias atividades.
class AtividadeService {
  /// Lista de atividades do usuário logado. O Firestore atualiza ela sozinho;
  /// as telas "escutam" este notificador para se redesenhar.
  static final ValueNotifier<List<Atividade>> atividades =
  ValueNotifier<List<Atividade>>([]);

  static StreamSubscription? _assinaturaAuth;
  static StreamSubscription? _assinaturaAtividades;

  /// Chame UMA vez no main(), depois do Firebase.initializeApp().
  static void iniciar() {
    _assinaturaAuth?.cancel();
    _assinaturaAuth = AuthService.estadoAutenticacao.listen((usuario) {
      _assinaturaAtividades?.cancel();
      _assinaturaAtividades = null;

      if (usuario == null) {
        atividades.value = [];
        return;
      }

      _assinaturaAtividades = _colecao(usuario.uid)
          .orderBy('data')
          .snapshots()
          .listen(
            (snapshot) {
          atividades.value = snapshot.docs
              .map((doc) => Atividade.fromMap(doc.data(), doc.id))
              .toList();
        },
        onError: (erro) => debugPrint('Erro ao ler atividades: $erro'),
      );
    });
  }

  static CollectionReference<Map<String, dynamic>> _colecao(String uid) {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('atividades');
  }

  /// Coleção do usuário logado agora (null se ninguém estiver logado)
  static CollectionReference<Map<String, dynamic>>? get _colecaoAtual {
    final uid = AuthService.usuarioAtual?.uid;
    return uid == null ? null : _colecao(uid);
  }

  /// Devolve uma cópia da lista atual de atividades
  static List<Atividade> listar() {
    return List<Atividade>.from(atividades.value);
  }

  static Future<void> adicionar(Atividade atividade) async {
    final colecao = _colecaoAtual;
    if (colecao == null) return;
    await colecao.add(atividade.toMap());
  }

  static Future<void> remover(Atividade atividade) async {
    final colecao = _colecaoAtual;
    if (colecao == null || atividade.id == null) return;
    await colecao.doc(atividade.id).delete();
  }

  /// Troca uma atividade existente pela versão editada
  static Future<void> atualizar(Atividade antiga, Atividade nova) async {
    // a nova atividade herda o id da antiga (precisa vir antes de qualquer await)
    nova.id = antiga.id;

    final colecao = _colecaoAtual;
    if (colecao == null || antiga.id == null) return;
    await colecao.doc(antiga.id).set(nova.toMap());
  }

  /// Marca como concluída (ou reabre, se já estava concluída).
  /// Muda só o campo "concluida", sem mexer no resto.
  static Future<void> alternarConclusao(Atividade atividade) async {
    final colecao = _colecaoAtual;
    if (colecao == null || atividade.id == null) return;
    await colecao.doc(atividade.id).update({'concluida': !atividade.concluida});
  }
}