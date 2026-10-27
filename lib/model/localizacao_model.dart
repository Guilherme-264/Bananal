/// Onde fica a fazenda: cidade, estado (sigla) e as coordenadas
/// que a API de clima usa para buscar a previsão.
class Localizacao {
  final String cidade;
  final String estado; // sigla, ex.: RS
  final double latitude;
  final double longitude;

  const Localizacao({
    required this.cidade,
    required this.estado,
    required this.latitude,
    required this.longitude,
  });

  /// "Morrinhos do Sul - RS"
  String get rotulo => '$cidade - $estado';

  Map<String, dynamic> toMap() {
    return {
      'cidade': cidade,
      'estado': estado,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Localizacao.fromMap(Map<String, dynamic> map) {
    return Localizacao(
      cidade: map['cidade'] as String? ?? '',
      estado: map['estado'] as String? ?? '',
      latitude: (map['latitude'] as num? ?? 0).toDouble(),
      longitude: (map['longitude'] as num? ?? 0).toDouble(),
    );
  }

  // Comparar por valor evita recarregar o clima sem necessidade
  @override
  bool operator ==(Object other) {
    return other is Localizacao &&
        other.cidade == cidade &&
        other.estado == estado &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(cidade, estado, latitude, longitude);
}