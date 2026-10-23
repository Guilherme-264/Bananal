import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/atividade_service.dart';
import '../../services/area_service.dart';
import '../../model/atividade_model.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/menu.dart';
import 'cadastrarAtividade.dart';
import 'verAtividade.dart';

class TelaAgenda extends StatefulWidget {
  @override
  _TelaAgendaState createState() => _TelaAgendaState();
}

class _TelaAgendaState extends State<TelaAgenda> {
  final _dataCurta = DateFormat('dd/MM');

  // quantas concluídas aparecem antes de "Ver histórico completo"
  static const int _limiteConcluidas = 3;
  bool _mostrarTodasConcluidas = false;

  @override
  void initState() {
    super.initState();
    // redesenha a tela sempre que as atividades mudarem no Firestore
    AtividadeService.atividades.addListener(_atualizar);
  }

  @override
  void dispose() {
    AtividadeService.atividades.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  // ---------- Datas e ordenação ----------
  /// Só o dia, sem a hora (para comparar "é hoje?", "é amanhã?")
  DateTime _soData(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Ordena por data e, no mesmo dia, pelo horário ("08:00" vem antes de "14:00")
  int _porDataEHorario(Atividade a, Atividade b) {
    final porData = _soData(a.data).compareTo(_soData(b.data));
    if (porData != 0) return porData;
    return a.horario.compareTo(b.horario);
  }

  // ---------- Ações ----------
  void _abrirCadastro([Atividade? atividade]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroAtividade(atividade: atividade),
      ),
    );
  }

  /// Nome da área de uma atividade (null se ela não tiver área)
  String? _nomeDaArea(String? id) {
    if (id == null) return null;
    for (final area in AreaService.listar()) {
      if (area.id == id) return area.nome;
    }
    return null;
  }

  /// "Talhão A  •  08:00" (o nome da área só aparece se a atividade tiver uma)
  String _localEHorario(Atividade a) {
    final area = _nomeDaArea(a.areaId);
    return area == null ? a.horario : '$area  •  ${a.horario}';
  }

  /// Abre a tela de detalhes da atividade
  void _abrirDetalhes(Atividade atividade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaVerAtividade(atividade: atividade),
      ),
    );
  }

  Future<void> _confirmarExclusao(Atividade a) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir atividade'),
        content: Text('Tem certeza que deseja excluir "${a.nome}"?'),
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
      AtividadeService.remover(a);
    }
  }

  /// Menu que abre ao tocar numa atividade: concluir/reabrir, editar, excluir
  void _abrirOpcoes(Atividade a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  a.nome,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                a.concluida ? Icons.undo : Icons.check_circle_outline,
                color: Colors.green.shade800,
              ),
              title: Text(
                  a.concluida ? 'Reabrir atividade' : 'Marcar como concluída'),
              onTap: () {
                Navigator.pop(context);
                AtividadeService.alternarConclusao(a);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: Colors.grey.shade700),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _abrirCadastro(a);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
              title:
              Text('Excluir', style: TextStyle(color: Colors.red.shade700)),
              onTap: () {
                Navigator.pop(context);
                _confirmarExclusao(a);
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
    final todas = AtividadeService.listar();

    final hoje = _soData(DateTime.now());
    final fimProximos = DateTime(hoje.year, hoje.month, hoje.day + 2);

    final pendentes = todas.where((a) => !a.concluida).toList();

    // pendentes de dias que já passaram
    final atrasadas = pendentes
        .where((a) => _soData(a.data).isBefore(hoje))
        .toList()
      ..sort(_porDataEHorario);

    final deHoje = pendentes.where((a) => _soData(a.data) == hoje).toList()
      ..sort(_porDataEHorario);

    // amanhã e depois de amanhã
    final proximos = pendentes
        .where((a) =>
    _soData(a.data).isAfter(hoje) &&
        !_soData(a.data).isAfter(fimProximos))
        .toList()
      ..sort(_porDataEHorario);

    // mais de 2 dias à frente (para nada ficar escondido)
    final adiante = pendentes
        .where((a) => _soData(a.data).isAfter(fimProximos))
        .toList()
      ..sort(_porDataEHorario);

    // concluídas: as mais recentes primeiro
    final concluidas = todas.where((a) => a.concluida).toList()
      ..sort((a, b) => _porDataEHorario(b, a));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _botaoNovaAtividade(),
                const SizedBox(height: 20),

                if (todas.isEmpty)
                  _semAtividades()
                else ...[
                  if (atrasadas.isNotEmpty) ...[
                    _titulo('Atrasadas', cor: Colors.red.shade700),
                    const SizedBox(height: 8),
                    _cardAgrupado(atrasadas),
                    const SizedBox(height: 20),
                  ],

                  _titulo('Hoje'),
                  const SizedBox(height: 8),
                  if (deHoje.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhuma atividade para hoje',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  else
                    for (final a in deHoje) ...[
                      _cardHoje(a),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 8),

                  if (proximos.isNotEmpty) ...[
                    _titulo('Próximos 2 dias'),
                    const SizedBox(height: 8),
                    _cardAgrupado(proximos),
                    const SizedBox(height: 20),
                  ],

                  if (adiante.isNotEmpty) ...[
                    _titulo('Mais adiante'),
                    const SizedBox(height: 8),
                    _cardAgrupado(adiante),
                    const SizedBox(height: 20),
                  ],

                  if (concluidas.isNotEmpty) ..._secaoConcluidas(concluidas),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: menu(
        itemAtivo: 4,
        onAdicionarPressed: () => _abrirCadastro(),
      ),
    );
  }

  // ---------- Botão ----------
  Widget _botaoNovaAtividade() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade800.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _abrirCadastro(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          '+ Nova atividade',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _titulo(String texto, {Color? cor}) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: cor ?? Colors.black87,
      ),
    );
  }

  // ---------- Card grande (atividades de hoje) ----------
  Widget _cardHoje(Atividade a) {
    return InkWell(
      onTap: () => _abrirDetalhes(a),
      onLongPress: () => _abrirOpcoes(a), // atalho: segurar abre o menu rápido
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                _selo('Pendente'),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _localEHorario(a),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (a.descricao.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                a.descricao,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selo(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  // ---------- Card com várias atividades (próximos dias, atrasadas...) ----------
  Widget _cardAgrupado(List<Atividade> lista) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (int i = 0; i < lista.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
              _linhaAgrupada(lista[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linhaAgrupada(Atividade a) {
    // "14:00" ou "14:00 • descrição"
    final detalhe =
    a.descricao.isEmpty
        ? _localEHorario(a)
        : '${_localEHorario(a)}  •  ${a.descricao}';

    return InkWell(
      onTap: () => _abrirDetalhes(a),
      onLongPress: () => _abrirOpcoes(a), // atalho: segurar abre o menu rápido
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_dataCurta.format(a.data)} — ${a.nome}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                detalhe,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Concluídas ----------
  List<Widget> _secaoConcluidas(List<Atividade> concluidas) {
    final visiveis = _mostrarTodasConcluidas
        ? concluidas
        : concluidas.take(_limiteConcluidas).toList();

    return [
      _titulo('Concluídas', cor: Colors.grey.shade600),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              for (int i = 0; i < visiveis.length; i++) ...[
                if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                _linhaConcluida(visiveis[i]),
              ],
            ],
          ),
        ),
      ),
      if (concluidas.length > _limiteConcluidas)
        Center(
          child: TextButton(
            onPressed: () => setState(
                    () => _mostrarTodasConcluidas = !_mostrarTodasConcluidas),
            child: Text(
              _mostrarTodasConcluidas
                  ? 'Mostrar menos'
                  : 'Ver histórico completo',
              style: TextStyle(color: Colors.green.shade800, fontSize: 13),
            ),
          ),
        ),
      const SizedBox(height: 8),
    ];
  }

  Widget _linhaConcluida(Atividade a) {
    final detalhe = a.descricao.isEmpty
        ? _dataCurta.format(a.data)
        : '${_dataCurta.format(a.data)}  •  ${a.descricao}';

    return InkWell(
      onTap: () => _abrirDetalhes(a),
      onLongPress: () => _abrirOpcoes(a), // atalho: segurar abre o menu rápido
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                detalhe,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Agenda vazia ----------
  Widget _semAtividades() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.event_note_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Nenhuma atividade cadastrada',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}