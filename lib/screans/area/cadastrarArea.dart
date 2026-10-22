import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../model/area_model.dart';
import '../../services/area_service.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/mapa_area.dart';

class TelaCadastroArea extends StatefulWidget {
  final Area? area; // se vier preenchida, a tela funciona como EDIÇÃO

  const TelaCadastroArea({super.key, this.area});

  @override
  _TelaCadastroAreaState createState() => _TelaCadastroAreaState();
}

class _TelaCadastroAreaState extends State<TelaCadastroArea> {
  final TextEditingController _nomeController = TextEditingController();
  final _formatoHectares = NumberFormat('#,##0.00', 'pt_BR');

  // Cantos marcados no mapa, na ordem em que foram tocados
  final List<LatLng> _pontos = [];

  // Cantos que a área já tinha (só para a câmera enquadrar na edição)
  late final List<LatLng> _pontosIniciais;

  @override
  void initState() {
    super.initState();
    final a = widget.area;
    _pontosIniciais = List<LatLng>.from(a?.pontos ?? []);

    if (a != null) {
      _nomeController.text = a.nome;
      _pontos.addAll(a.pontos);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  // ---------- Ações ----------
  void _adicionarPonto(LatLng ponto) {
    setState(() => _pontos.add(ponto));
  }

  void _desfazerUltimo() {
    if (_pontos.isEmpty) return;
    setState(() => _pontos.removeLast());
  }

  void _limpar() {
    setState(() => _pontos.clear());
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void _salvar() {
    final nome = _nomeController.text.trim();

    if (nome.isEmpty) {
      _aviso('Informe o nome da área');
      return;
    }
    if (_pontos.length < 3) {
      _aviso('Marque pelo menos 3 cantos da área no mapa');
      return;
    }

    final nova = Area(nome: nome, pontos: List<LatLng>.from(_pontos));

    if (widget.area != null) {
      AreaService.atualizar(widget.area!, nova); // edição
    } else {
      AreaService.adicionar(nova); // cadastro novo
    }
    Navigator.pop(context, nova);
  }

  // ---------- Desenho no mapa ----------
  Set<Polygon> get _poligonos {
    if (_pontos.length < 3) return {};
    return {
      Polygon(
        polygonId: const PolygonId('contorno'),
        points: List<LatLng>.from(_pontos),
        fillColor: Colors.green.withOpacity(0.25),
        strokeColor: Colors.white,
        strokeWidth: 3,
      ),
    };
  }

  Set<Marker> get _marcadores {
    return {
      for (int i = 0; i < _pontos.length; i++)
        Marker(
          markerId: MarkerId('ponto$i'),
          position: _pontos[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Canto ${i + 1}'),
          // segurar e arrastar o pino ajusta o canto
          draggable: true,
          onDragEnd: (novaPosicao) {
            setState(() => _pontos[i] = novaPosicao);
          },
        ),
    };
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    final hectares = Area.calcularHectares(_pontos);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Cabecalho(mostrarVoltar: true),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Detalhes da Área",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        _label("Nome da área"),
                        TextField(
                          controller: _nomeController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                              dica: "Ex.: Área de Cultivo 1"),
                        ),
                        const SizedBox(height: 20),

                        _label("Contorno no mapa"),
                        Text(
                          'Dê zoom até a propriedade e toque nos cantos, em '
                              'ordem. Segure e arraste um pino para ajustar.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),

                        MapaArea(
                          altura: 360,
                          centro: widget.area?.centro ??
                              const LatLng(-14.235, -51.925),
                          zoom: widget.area != null ? 16 : 4,
                          pontosParaEnquadrar: _pontosIniciais,
                          poligonos: _poligonos,
                          marcadores: _marcadores,
                          onTap: _adicionarPonto,
                          controlesDeZoom: true,
                        ),
                        const SizedBox(height: 12),

                        // Resumo: quantos cantos e quantos hectares
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_pontos.length} '
                                    '${_pontos.length == 1 ? 'canto' : 'cantos'}',
                                style: TextStyle(color: Colors.green.shade800),
                              ),
                              Text(
                                _pontos.length < 3
                                    ? 'Marque ao menos 3 cantos'
                                    : '${_formatoHectares.format(hectares)} ha',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                _pontos.isEmpty ? null : _desfazerUltimo,
                                icon: const Icon(Icons.undo, size: 18),
                                label: const Text('Desfazer'),
                                style: _estiloBotaoSecundario(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pontos.isEmpty ? null : _limpar,
                                icon: const Icon(Icons.delete_outline,
                                    size: 18),
                                label: const Text('Limpar'),
                                style: _estiloBotaoSecundario(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.area != null ? "Salvar Alterações" : "Salvar Área",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _estiloBotaoSecundario() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.green.shade800,
      padding: const EdgeInsets.symmetric(vertical: 12),
      side: BorderSide(color: Colors.grey.shade300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _label(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(texto,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
    );
  }

  InputDecoration _inputDecoration({String? dica}) {
    return InputDecoration(
      hintText: dica,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}