import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../model/area_model.dart';
import '../../model/atividade_model.dart';
import '../../model/tipoManejo_model.dart';
import '../../services/area_service.dart';
import '../../services/atividade_service.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/menu.dart';
import '../../widgets/mapa_area.dart';
import 'cadastrarArea.dart';
import 'historicoManejo.dart';

class TelaAreas extends StatefulWidget {
  @override
  _TelaAreasState createState() => _TelaAreasState();
}

class _TelaAreasState extends State<TelaAreas> {
  final _formatoHectares = NumberFormat('#,##0.00', 'pt_BR');
  final _formatoData = DateFormat('dd/MM/yyyy');

  // Área que está sendo mostrada (se null, mostra a primeira da lista)
  String? _areaSelecionadaId;

  @override
  void initState() {
    super.initState();
    // redesenha a tela sempre que as áreas mudarem no Firestore
    AreaService.areas.addListener(_atualizar);
    AtividadeService.atividades.addListener(_atualizar);
  }

  @override
  void dispose() {
    AreaService.areas.removeListener(_atualizar);
    AtividadeService.atividades.removeListener(_atualizar);
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

      const SizedBox(height: 16),
      _cardResumoManejo(area),
    ];
  }

  // ---------- Resumo do manejo ----------
  Widget _cardResumoManejo(Area area) {
    // só as atividades desta área
    final atividades =
    AtividadeService.listar().where((a) => a.areaId == area.id).toList();

    DateTime soData(DateTime d) => DateTime(d.year, d.month, d.day);

    // última vez que cada tipo foi feito (só conta atividade concluída)
    DateTime? ultimaVez(TipoManejo tipo) {
      DateTime? ultima;
      for (final a in atividades) {
        if (a.concluida && a.tipo == tipo.nome) {
          if (ultima == null || a.data.isAfter(ultima)) ultima = a.data;
        }
      }
      return ultima;
    }

    // próxima atividade: a pendente mais cedo, de hoje em diante
    final hoje = soData(DateTime.now());
    final proximas = atividades
        .where((a) => !a.concluida && !a.data.isBefore(hoje))
        .toList()
      ..sort((a, b) {
        final porData = soData(a.data).compareTo(soData(b.data));
        return porData != 0 ? porData : a.horario.compareTo(b.horario);
      });
    final proxima = proximas.isEmpty ? null : proximas.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey.shade700, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Resumo do Manejo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),

          for (int i = 0; i < TipoManejo.resumo.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
            _linhaManejo(
              TipoManejo.resumo[i],
              ultimaVez(TipoManejo.resumo[i]),
            ),
          ],

          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TelaHistoricoManejo(area: area),
                ),
              );
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver histórico completo',
                  style: TextStyle(color: Colors.green.shade800, fontSize: 13),
                ),
                Icon(Icons.chevron_right,
                    size: 18, color: Colors.green.shade800),
              ],
            ),
          ),
          const SizedBox(height: 8),

          _caixaProximaAtividade(proxima),
        ],
      ),
    );
  }

  Widget _linhaManejo(TipoManejo tipo, DateTime? data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(tipo.icone, size: 16, color: Colors.green.shade800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(tipo.nome, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            data == null ? '—' : _formatoData.format(data),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: data == null ? Colors.grey.shade400 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _caixaProximaAtividade(Atividade? a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRÓXIMA ATIVIDADE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          if (a == null)
            Text(
              'Nenhuma atividade agendada para esta área',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            )
          else ...[
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(TipoManejo.iconeDe(a.tipo),
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_formatoData.format(a.data)}  •  ${a.horario}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
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