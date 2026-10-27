import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../model/localizacao_model.dart';
import 'auth_service.dart';

/// Guarda a localização da fazenda no Firestore, em:
/// usuarios/{uid}/configuracoes/localizacao
class LocalizacaoService {
  /// Localização do usuário logado (null se ele ainda não informou)
  static final ValueNotifier<Localizacao?> localizacao =
  ValueNotifier<Localizacao?>(null);

  /// false até o Firestore responder pela primeira vez. Serve para
  /// diferenciar "ainda carregando" de "o usuário nunca informou".
  static final ValueNotifier<bool> carregada = ValueNotifier<bool>(false);

  static StreamSubscription? _assinaturaAuth;
  static StreamSubscription? _assinaturaDocumento;

  /// Chame UMA vez no main(), depois do Firebase.initializeApp().
  static void iniciar() {
    _assinaturaAuth?.cancel();
    _assinaturaAuth = AuthService.estadoAutenticacao.listen((usuario) {
      _assinaturaDocumento?.cancel();
      _assinaturaDocumento = null;

      if (usuario == null) {
        localizacao.value = null;
        carregada.value = false;
        return;
      }

      _assinaturaDocumento = _referencia(usuario.uid).snapshots().listen(
            (snapshot) {
          final dados = snapshot.data();
          localizacao.value = dados == null ? null : Localizacao.fromMap(dados);
          carregada.value = true;
        },
        onError: (erro) => debugPrint('Erro ao ler localização: $erro'),
      );
    });
  }

  static DocumentReference<Map<String, dynamic>> _referencia(String uid) {
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('configuracoes')
        .doc('localizacao');
  }

  static Future<void> salvar(Localizacao nova) async {
    final uid = AuthService.usuarioAtual?.uid;
    if (uid == null) return;
    await _referencia(uid).set(nova.toMap());
  }
}