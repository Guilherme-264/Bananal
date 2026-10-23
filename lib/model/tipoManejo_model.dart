import 'package:flutter/material.dart';

/// Os tipos de manejo que o app conhece.
/// Para criar um tipo novo, basta acrescentar uma linha em [todos]
/// (e em [resumo], se ele deve aparecer no Resumo do Manejo).
class TipoManejo {
  final String nome;
  final IconData icone;

  const TipoManejo(this.nome, this.icone);

  static const adubacao = TipoManejo('Adubação', Icons.water_drop_outlined);
  static const pulverizacao =
  TipoManejo('Pulverização', Icons.sanitizer_outlined);
  static const poda = TipoManejo('Poda', Icons.content_cut);
  static const ensacamento =
  TipoManejo('Ensacamento', Icons.inventory_2_outlined);
  static const outro = TipoManejo('Outro', Icons.task_alt_outlined);

  /// Todos os tipos que podem ser escolhidos numa atividade
  static const List<TipoManejo> todos = [
    adubacao,
    pulverizacao,
    poda,
    ensacamento,
    outro,
  ];

  /// Os que aparecem no "Resumo do Manejo" da área
  static const List<TipoManejo> resumo = [
    adubacao,
    pulverizacao,
    poda,
    ensacamento,
  ];

  /// Ícone de um tipo, a partir do nome guardado na atividade
  static IconData iconeDe(String nome) {
    for (final tipo in todos) {
      if (tipo.nome == nome) return tipo.icone;
    }
    return outro.icone;
  }
}