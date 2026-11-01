// TODO Implement this library./// Um cliente (comprador). Por enquanto guarda só o nome.
class Cliente {
  String? id; // id do documento no Firestore (null enquanto não foi salvo)
  final String nome;

  Cliente({
    this.id,
    required this.nome,
  });

  /// Objeto -> Map (o id não entra: ele é o nome do documento)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
    };
  }

  /// Map (vindo do Firestore) -> objeto
  factory Cliente.fromMap(Map<String, dynamic> map, String id) {
    return Cliente(
      id: id,
      nome: map['nome'] as String? ?? '',
    );
  }
}