import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Uma área de cultivo: um nome e o contorno desenhado no mapa
/// (lista de cantos, em ordem).
class Area {
  String? id; // id do documento no Firestore (null enquanto não foi salva)
  final String nome;
  final List<LatLng> pontos;

  Area({
    this.id,
    required this.nome,
    required this.pontos,
  });

  /// Ponto central do contorno (média dos cantos)
  LatLng get centro {
    if (pontos.isEmpty) return const LatLng(-14.235, -51.925);

    double soma(double Function(LatLng) campo) =>
        pontos.map(campo).reduce((a, b) => a + b);

    return LatLng(
      soma((p) => p.latitude) / pontos.length,
      soma((p) => p.longitude) / pontos.length,
    );
  }

  double get hectares => calcularHectares(pontos);

  /// Área do contorno em hectares.
  /// Converte os cantos para metros ao redor do centro e usa a fórmula
  /// do polígono (shoelace). É uma aproximação ótima para o tamanho de
  /// uma propriedade rural.
  static double calcularHectares(List<LatLng> pontos) {
    if (pontos.length < 3) return 0;

    const raioTerra = 6371000.0; // metros
    final latMedia =
        pontos.map((p) => p.latitude).reduce((a, b) => a + b) / pontos.length;
    final cosLat = cos(latMedia * pi / 180);

    final xs = pontos
        .map((p) => raioTerra * (p.longitude * pi / 180) * cosLat)
        .toList();
    final ys = pontos.map((p) => raioTerra * (p.latitude * pi / 180)).toList();

    double soma = 0;
    for (int i = 0; i < pontos.length; i++) {
      final j = (i + 1) % pontos.length;
      soma += xs[i] * ys[j] - xs[j] * ys[i];
    }

    final metrosQuadrados = soma.abs() / 2;
    return metrosQuadrados / 10000; // 1 hectare = 10.000 m²
  }

  /// Objeto -> Map (o id não entra: ele é o nome do documento)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'pontos': pontos.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
      'hectares': hectares,
    };
  }

  /// Map (vindo do Firestore) -> objeto
  factory Area.fromMap(Map<String, dynamic> map, String id) {
    final lista = (map['pontos'] as List<dynamic>? ?? []);

    return Area(
      id: id,
      nome: map['nome'] as String? ?? '',
      pontos: lista.map((p) {
        final geo = p as GeoPoint;
        return LatLng(geo.latitude, geo.longitude);
      }).toList(),
    );
  }
}