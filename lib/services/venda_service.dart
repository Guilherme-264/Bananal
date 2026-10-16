import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/venda_model.dart';
import 'auth_service.dart';

/// Guarda as vendas no Firestore, em: usuarios/{uid}/vendas
/// Cada usuário só enxerga as próprias vendas.
class VendaService {
  /// Lista de vendas do usuário logado. O Firestore atualiza ela sozinho;
  /// as telas "escutam" este notificador para se redesenhar.
  static final ValueNotifier<List<Venda>> vendas =
  ValueNotifier<List<Venda>>([]);

  static StreamSubscription? _assinaturaAuth;
  static StreamSubscription? _assinaturaVendas;

  /// Chame UMA vez no main(), depois do Firebase.initializeApp().
  /// Quando alguém entra na conta, começa a acompanhar as vendas dela.
  /// Quando sai, para e limpa a lista.
  static void iniciar() {
    _assinaturaAuth?.cancel();
    _assinaturaAuth = AuthService.estadoAutenticacao.listen((usuario) {
      _assinaturaVendas?.cancel();
      _assinaturaVendas = null;

      if (usuario == null) {
        vendas.value = [];
        return;
      }

      _assinaturaVendas = _colecao(usuario.uid)
          .orderBy('data', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
          vendas.value = snapshot.docs
              .map((doc) => Venda.fromMap(doc.data(), doc.id))
              .toList();
        },
        onError: (erro) => debugPrint('Erro ao ler vendas: $erro'),
      );
    });
  }

  static CollectionReference<Map<String, dynamic>> _colecao(String uid) {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('vendas');
  }

  /// Coleção do usuário logado agora (null se ninguém estiver logado)
  static CollectionReference<Map<String, dynamic>>? get _colecaoAtual {
    final uid = AuthService.usuarioAtual?.uid;
    return uid == null ? null : _colecao(uid);
  }

  /// Devolve uma cópia da lista atual de vendas
  static List<Venda> listar() {
    return List<Venda>.from(vendas.value);
  }

  static Future<void> adicionar(Venda venda) async {
    final colecao = _colecaoAtual;
    if (colecao == null) return;
    await colecao.add(venda.toMap());
  }

  static Future<void> remover(Venda venda) async {
    final colecao = _colecaoAtual;
    if (colecao == null || venda.id == null) return;
    await colecao.doc(venda.id).delete();
  }

  /// Troca uma venda existente pela versão editada
  static Future<void> atualizar(Venda antiga, Venda nova) async {
    // a nova venda herda o id da antiga (precisa vir antes de qualquer await)
    nova.id = antiga.id;

    final colecao = _colecaoAtual;
    if (colecao == null || antiga.id == null) return;
    await colecao.doc(antiga.id).set(nova.toMap());
  }

  /// Soma o valor total de todas as vendas (todas as classificações)
  static num receita() {
    num receita = 0;
    for (final venda in vendas.value) {
      receita += venda.valorTotal;
    }
    return receita;
  }
}