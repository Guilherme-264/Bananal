import 'package:flutter/material.dart';
import 'venda/Vendas.dart';
import '../services/despesa_service.dart';
import '../services/venda_service.dart';
import '../model/venda_model.dart';
import '../model/despesa_model.dart';
import 'venda/cadastrarVenda.dart';
import '../widgets/cabecalho.dart';
import '../widgets/menu.dart';
import 'despesa/Despesa.dart';
import 'package:intl/intl.dart';

/// Um item da lista "Atividades Recentes" (pode ser venda ou despesa)
class _Atividade {
  final String titulo;
  final String subtitulo;
  final num valor;
  final DateTime data;
  final bool receita; // true = venda (verde), false = despesa (vermelho)

  _Atividade({
    required this.titulo,
    required this.subtitulo,
    required this.valor,
    required this.data,
    required this.receita,
  });
}

class TelaHome extends StatefulWidget {
  @override
  _TelaHomeState createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  // Período do filtro: começa no dia 1 do mês atual até hoje
  DateTimeRange _periodo = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  // ---------- Formatação ----------
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _data = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // redesenha a Home sempre que vendas/despesas mudarem no Firestore
    VendaService.vendas.addListener(_atualizar);
    DespesaService.despesas.addListener(_atualizar);
  }

  @override
  void dispose() {
    VendaService.vendas.removeListener(_atualizar);
    DespesaService.despesas.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  //------direcionar para venda---------
  void verVendas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaVendas()),
    ).then((_) {
      setState(() {});
    });
  }

  void verDespesas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaDespesas()),
    ).then((_) {
      setState(() {});
    });
  }

  // ---------- Período ----------
  /// Diz se uma data está dentro do período escolhido
  bool _noPeriodo(DateTime d) {
    final inicio = DateTime(
        _periodo.start.year, _periodo.start.month, _periodo.start.day);
    final fim = DateTime(
        _periodo.end.year, _periodo.end.month, _periodo.end.day, 23, 59, 59);
    return !d.isBefore(inicio) && !d.isAfter(fim);
  }

  Future<void> _escolherPeriodo() async {
    final escolhido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _periodo,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.green.shade800),
        ),
        child: child!,
      ),
    );
    if (escolhido != null) {
      setState(() => _periodo = escolhido);
    }
  }

  // ---------- Atividades recentes ----------
  /// Junta vendas e despesas, ordena da mais recente para a mais antiga
  /// e devolve só as primeiras [limite].
  List<_Atividade> _ultimasAtividades(
      List<Venda> vendas,
      List<Despesa> despesas, {
        int limite = 5,
      }) {
    final lista = <_Atividade>[
      for (final v in vendas)
        _Atividade(
          titulo: 'Receber: ${v.comprador}',
          subtitulo: '${_data.format(v.data)}  •  ${v.totalCaixas} caixas',
          valor: v.valorTotal,
          data: v.data,
          receita: true,
        ),
      for (final d in despesas)
        _Atividade(
          titulo: 'Pagar: ${d.nome}',
          subtitulo: d.descricao.isEmpty
              ? _data.format(d.data)
              : '${_data.format(d.data)}  •  ${d.descricao}',
          valor: d.valor,
          data: d.data,
          receita: false,
        ),
    ];

    lista.sort((a, b) => b.data.compareTo(a.data));
    return lista.take(limite).toList();
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    // só o que está dentro do período escolhido
    final vendas =
    VendaService.listar().where((v) => _noPeriodo(v.data)).toList();
    final despesas =
    DespesaService.listar().where((d) => _noPeriodo(d.data)).toList();

    final num receita = vendas.fold<num>(0, (soma, v) => soma + v.valorTotal);
    final num despesa = despesas.fold<num>(0, (soma, d) => soma + d.valor);
    final num saldo = receita - despesa;

    final atividades = _ultimasAtividades(vendas, despesas);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _filtroPeriodo(),
                const SizedBox(height: 16),
                _cardSaldo(saldo),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _cardReceita(receita)),
                    const SizedBox(width: 12),
                    Expanded(child: _cardDespesa(despesa)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Atividades Recentes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (atividades.isEmpty)
                  _semAtividades()
                else
                  for (final atividade in atividades) ...[
                    _cardAtividade(atividade),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: menu(
        itemAtivo: 0,
        onAdicionarPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TelaCadastroVenda()),
          ).then((_) {
            setState(() {});
          });
        },
      ),
    );
  }

  // ---------- Filtro de período ----------
  Widget _filtroPeriodo() {
    return InkWell(
      onTap: _escolherPeriodo,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Período: ${_data.format(_periodo.start)} - ${_data.format(_periodo.end)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  // ---------- Cards de resumo ----------
  Widget _cardSaldo(num saldo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SALDO DISPONÍVEL",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            _moeda.format(saldo),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _cardReceita(num receita) {
    return _cardIndicador(
      onTap: () => verVendas(),
      titulo: "Receita",
      valor: _moeda.format(receita),
      cor: Colors.green,
      icone: Icons.arrow_upward,
    );
  }

  Widget _cardDespesa(num despesa) {
    return _cardIndicador(
      onTap: () => verDespesas(),
      titulo: "Despesa",
      valor: _moeda.format(despesa),
      cor: Colors.red,
      icone: Icons.arrow_downward,
    );
  }

  Widget _cardIndicador({
    required String titulo,
    required String valor,
    required Color cor,
    required IconData icone,
    VoidCallback? onTap,
  }) {
    return Material(
      color: cor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icone, color: cor),
                  const SizedBox(width: 4),
                  Text(titulo, style: TextStyle(color: cor)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: TextStyle(
                  color: cor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Card de atividade recente ----------
  Widget _cardAtividade(_Atividade a) {
    final corTexto = a.receita ? Colors.green.shade800 : Colors.red.shade700;
    final corFundo = a.receita ? Colors.green.shade50 : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: corFundo,
              shape: BoxShape.circle,
            ),
            child: Icon(
              a.receita ? Icons.trending_up : Icons.credit_card_outlined,
              color: corTexto,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  a.subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _moeda.format(a.valor),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: corTexto,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Sem atividades ----------
  Widget _semAtividades() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Nenhuma atividade neste período',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}