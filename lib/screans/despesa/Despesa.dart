import 'package:flutter/material.dart';
import '../../services/despesa_service.dart';
import '../../model/despesa_model.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/menu.dart';
import 'cadastrarDespesa.dart';
import 'package:intl/intl.dart';


class TelaDespesas extends StatefulWidget {
  @override
  _TelaDespesasState createState() => _TelaDespesasState();
}

class _TelaDespesasState extends State<TelaDespesas> {
  // Período do filtro: começa no dia 1 do mês atual até hoje
  DateTimeRange _periodo = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  // ---------- Dados ----------
  List<Despesa> _despesasFiltradas() {
    final List<Despesa> todas = DespesaService.listar();

    final inicio = DateTime(
        _periodo.start.year, _periodo.start.month, _periodo.start.day);
    final fim = DateTime(
        _periodo.end.year, _periodo.end.month, _periodo.end.day, 23, 59, 59);

    final filtradas = todas
        .where((d) => !d.data.isBefore(inicio) && !d.data.isAfter(fim))
        .toList();

    // mais recentes primeiro
    filtradas.sort((a, b) => b.data.compareTo(a.data));
    return filtradas;
  }

  // ---------- Formatação ----------
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final _data = DateFormat('dd/MM/yyyy');

  // ---------- Ações ----------
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

  void _abrirCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaCadastroDespesa()),
    ).then((_) {
      setState(() {});
    });
  }

  void _editarDespesa(Despesa despesa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroDespesa(despesa: despesa),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    final despesas = _despesasFiltradas();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(mostrarVoltar: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _botaoNovaDespesa(),
                const SizedBox(height: 16),
                _filtroPeriodo(),
                const SizedBox(height: 16),
                if (despesas.isEmpty)
                  _semDespesas()
                else
                  for (final despesa in despesas) ...[
                    _cardDespesa(despesa),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: menu(
        itemAtivo: 0, // despesa faz parte do Financeiro
        onAdicionarPressed: _abrirCadastro,
      ),
    );
  }

  // ---------- Botão ----------
  Widget _botaoNovaDespesa() {
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
        onPressed: _abrirCadastro,
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
          '+ Nova Despesa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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

  // ---------- Card de despesa ----------
  Widget _cardDespesa(Despesa despesa) {
    // linha de baixo: data + descrição (se tiver)
    final detalhe = despesa.descricao.isEmpty
        ? _data.format(despesa.data)
        : '${_data.format(despesa.data)}  •  ${despesa.descricao}';

    return InkWell(
      onTap: () => _editarDespesa(despesa),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined,
                  color: Colors.red.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    despesa.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
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
            const SizedBox(width: 8),
            Text(
              _moeda.format(despesa.valor),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.red.shade700,
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.red.shade700),
          ],
        ),
      ),
    );
  }

  // ---------- Lista vazia ----------
  Widget _semDespesas() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Nenhuma despesa neste período',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}