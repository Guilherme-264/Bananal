import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../model/area_model.dart';
import '../../services/area_service.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/menu.dart';
import '../../widgets/mapa_area.dart';
import 'cadastrarArea.dart';

class TelaAreas extends StatefulWidget {
  @override
  _TelaAreasState createState() => _TelaAreasState();
}

class _TelaAreasState extends State<TelaAreas> {
  final _formatoHectares = NumberFormat('#,##0.00', 'pt_BR');

  // Área que está sendo mostrada (se null, mostra a primeira da lista)
  String? _areaSelecionadaId;

  @override
  void initState() {
    super.initState();
    // redesenha a tela sempre que as áreas mudarem no Firestore
    AreaService.areas.addListener(_atualizar);
  }

  @override
  void dispose() {
    AreaService.areas.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  /// Área que deve aparecer agora (null se não houver nenhuma)
  Area? _areaAtual(List<Area> areas) {
    if (areas.isEmpty) return null;
    for (final a in areas) {
      if (a.id == _areaSelecionadaId) return a;
    }
    return areas.first;
  }

  // ---------- Ações ----------
  Future<void> _abrirCadastro([Area? area]) async {
    final resultado = await Navigator.push<Area>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroArea(area: area),
      ),
    );

    // depois de salvar, mostra a área que acabou de ser criada/editada
    if (resultado?.id != null && mounted) {
      setState(() => _areaSelecionadaId = resultado!.id);
    }
  }

  Future<void> _confirmarExclusao(Area area) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir área'),
        content: Text('Tem certeza que deseja excluir "${area.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      AreaService.remover(area);
      setState(() => _areaSelecionadaId = null);
    }
  }

  /// "Ver outra área": lista as áreas e o atalho para criar uma nova
  void _verOutraArea(List<Area> areas, Area atual) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Suas áreas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final a in areas)
                    ListTile(
                      leading: Icon(
                        a.id == atual.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: Colors.green.shade800,
                      ),
                      title: Text(a.nome),
                      subtitle: Text('${_formatoHectares.format(a.hectares)} ha'),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _areaSelecionadaId = a.id);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
              Icon(Icons.add_circle_outline, color: Colors.green.shade800),
              title: const Text('Nova área'),
              onTap: () {
                Navigator.pop(context);
                _abrirCadastro();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    final areas = AreaService.listar();
    final area = _areaAtual(areas);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: area == null
                  ? _semAreas()
                  : _conteudoDaArea(areas, area),
            ),
          ),
        ],
      ),
      bottomNavigationBar: menu(itemAtivo: 2),
    );
  }

  // ---------- Quando já existe uma área ----------
  List<Widget> _conteudoDaArea(List<Area> areas, Area area) {
    final contorno = Polygon(
      polygonId: PolygonId(area.id ?? 'area'),
      points: area.pontos,
      fillColor: Colors.green.withOpacity(0.25),
      strokeColor: Colors.white,
      strokeWidth: 3,
    );

    return [
      MapaArea(
        altura: 240,
        centro: area.centro,
        zoom: 16,
        pontosParaEnquadrar: area.pontos,
        poligonos: {contorno},
      ),
      const SizedBox(height: 16),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatoHectares.format(area.hectares)} ha',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _verOutraArea(areas, area),
            child: Text(
              'Ver outra área',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (valor) {
              if (valor == 'editar') _abrirCadastro(area);
              if (valor == 'excluir') _confirmarExclusao(area);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'editar', child: Text('Editar área')),
              PopupMenuItem(
                value: 'excluir',
                child: Text('Excluir área',
                    style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
          ),
        ],
      ),

      // TODO: "Resumo do Manejo" e "Próxima atividade" entram na próxima etapa.
    ];
  }

  // ---------- Quando ainda não existe nenhuma área ----------
  List<Widget> _semAreas() {
    return [
      const MapaArea(altura: 240),
      const SizedBox(height: 24),
      Icon(Icons.crop_free, size: 48, color: Colors.grey.shade400),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'Nenhuma área cadastrada',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => _abrirCadastro(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          '+ Cadastrar área',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }
}