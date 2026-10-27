import 'package:flutter/material.dart';

/// Ícone colorido do tempo (sol, nuvens, chuva...) montado com ícones do
/// Material, escolhido pelo código de condição da OpenWeather.
class ClimaIcone extends StatelessWidget {
  final int condicaoId;
  final bool noite;
  final double tamanho;

  const ClimaIcone({
    super.key,
    required this.condicaoId,
    this.noite = false,
    this.tamanho = 40,
  });

  @override
  Widget build(BuildContext context) {
    final t = tamanho;

    final nuvemClara = Colors.blueGrey.shade200;
    final nuvemMedia = Colors.blueGrey.shade300;
    final nuvemEscura = Colors.blueGrey.shade400;
    final astro = noite ? Icons.nightlight_round : Icons.wb_sunny;
    final corAstro = noite ? Colors.indigo.shade200 : Colors.orange;

    // posição e tamanho em proporção do tamanho total
    Widget peca(IconData icone, Color cor,
        {required double x, required double y, required double s}) {
      return Positioned(
        left: x * t,
        top: y * t,
        child: Icon(icone, color: cor, size: s * t),
      );
    }

    final List<Widget> camadas;

    if (condicaoId >= 200 && condicaoId < 300) {
      // tempestade: nuvem escura + raio
      camadas = [
        peca(Icons.cloud, nuvemEscura, x: 0.05, y: 0.02, s: 0.9),
        peca(Icons.bolt, Colors.amber, x: 0.27, y: 0.42, s: 0.5),
      ];
    } else if (condicaoId >= 300 && condicaoId < 600) {
      // garoa e chuva: nuvem + três gotas
      camadas = [
        peca(Icons.cloud, nuvemEscura, x: 0.05, y: 0.0, s: 0.9),
        peca(Icons.water_drop, Colors.blue, x: 0.18, y: 0.66, s: 0.22),
        peca(Icons.water_drop, Colors.blue, x: 0.40, y: 0.72, s: 0.22),
        peca(Icons.water_drop, Colors.blue, x: 0.62, y: 0.66, s: 0.22),
      ];
    } else if (condicaoId >= 600 && condicaoId < 700) {
      // neve
      camadas = [
        peca(Icons.cloud, nuvemMedia, x: 0.05, y: 0.0, s: 0.9),
        peca(Icons.ac_unit, Colors.lightBlue, x: 0.34, y: 0.58, s: 0.32),
      ];
    } else if (condicaoId >= 700 && condicaoId < 800) {
      // neblina
      camadas = [
        peca(Icons.blur_on, nuvemMedia, x: 0.0, y: 0.0, s: 1.0),
      ];
    } else if (condicaoId == 800) {
      // céu limpo
      camadas = [
        peca(astro, corAstro, x: 0.05, y: 0.05, s: 0.9),
      ];
    } else if (condicaoId == 801 || condicaoId == 802) {
      // parcialmente nublado: sol (ou lua) atrás de uma nuvem
      camadas = [
        peca(astro, corAstro, x: 0.38, y: 0.0, s: 0.62),
        peca(Icons.cloud, nuvemClara, x: 0.0, y: 0.28, s: 0.82),
      ];
    } else {
      // nublado: duas nuvens
      camadas = [
        peca(Icons.cloud, nuvemMedia, x: 0.34, y: 0.0, s: 0.64),
        peca(Icons.cloud, nuvemClara, x: 0.0, y: 0.24, s: 0.86),
      ];
    }

    return SizedBox(
      width: t,
      height: t,
      child: Stack(children: camadas),
    );
  }
}