import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/area_model.dart';
import 'auth_service.dart';

/// Guarda as áreas de cultivo no Firestore, em: usuarios/{uid}/areas
/// Cada usuário só enxerga as próprias áreas.
class AreaService {
  /// Lista de áreas do usuário logado. O Firestore atualiza ela sozinho;
  /// as telas "escutam" este notificador para se redesenhar.
  static final ValueNotifier<List<Area>> areas = ValueNotifier<List<Area>>([]);

  static StreamSubscription? _assinaturaAuth;
  static StreamSubscription? _assinaturaAreas;

  /// Chame UMA vez no main(), depois do Firebase.initializeApp().
  static void iniciar() {
    _assinaturaAuth?.cancel();
    _assinaturaAuth = AuthService.estadoAutenticacao.listen((usuario) {
      _assinaturaAreas?.cancel();
      _assinaturaAreas = null;

      if (usuario == null) {
        areas.value = [];
        return;
      }

      _assinaturaAreas =
          _colecao(usuario.uid).orderBy('nome').snapshots().listen(
                (snapshot) {
              areas.value = snapshot.docs
                  .map((doc) => Area.fromMap(doc.data(), doc.id))
                  .toList();
            },
            onError: (erro) => debugPrint('Erro ao ler áreas: $erro'),
          );
    });
  }

  static CollectionReference<Map<String, dynamic>> _colecao(String uid) {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('areas');
  }

  /// Coleção do usuário logado agora (null se ninguém estiver logado)
  static CollectionReference<Map<String, dynamic>>? get _colecaoAtual {
    final uid = AuthService.usuarioAtual?.uid;
    return uid == null ? null : _colecao(uid);
  }

  /// Devolve uma cópia da lista atual de áreas
  static List<Area> listar() {
    return List<Area>.from(areas.value);
  }

  static Future<void> adicionar(Area area) async {
    final colecao = _colecaoAtual;
    if (colecao == null) return;

    // gera o documento antes de salvar para a área já ficar com id
    // (a tela usa isso para selecionar a área recém-criada)
    final referencia = colecao.doc();
    area.id = referencia.id;
    await referencia.set(area.toMap());
  }

  static Future<void> remover(Area area) async {
    final colecao = _colecaoAtual;
    if (colecao == null || area.id == null) return;
    await colecao.doc(area.id).delete();
  }

  /// Troca uma área existente pela versão editada
  static Future<void> atualizar(Area antiga, Area nova) async {
    // a nova área herda o id da antiga (precisa vir antes de qualquer await)
    nova.id = antiga.id;

    final colecao = _colecaoAtual;
    if (colecao == null || antiga.id == null) return;
    await colecao.doc(antiga.id).set(nova.toMap());
  }
}