import 'dart:math';
import 'package:flutter/material.dart';
import '../../model/venda_model.dart';
import '../../model/despesa_model.dart';
import '../../services/venda_service.dart';
import '../../services/despesa_service.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/menu.dart';

/// Relatório financeiro do ano: gráfico com o resultado de cada mês
/// (receitas - despesas). Tocar em um mês mostra os números dele.
class TelaRelatorioFinanceiro extends StatefulWidget {
  const TelaRelatorioFinanceiro({super.key});

  @override
  State<TelaRelatorioFinanceiro> createState() =>
      _TelaRelatorioFinanceiroState();
}

class _TelaRelatorioFinanceiroState extends State<TelaRelatorioFinanceiro> {
  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  static const _mesesCurtos = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];
  static const int _primeiroAno = 2020;

  late int _ano = DateTime.now().year;
  late int _mes = DateTime.now().month; // 1 a 12

  @override
  void initState() {
    super.initState();
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

  // ---------- Formatação ----------
  String _moeda(num v) {
    final negativo = v < 0;
    final partes = v.abs().toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
    );
    return '${negativo ? '-' : ''}R\$ $inteiro,${partes[1]}';
  }

  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ---------- Dados ----------
  /// Receitas, despesas e resultado de cada mês do ano (índice 0 = janeiro)
  ({List<double> receitas, List<double> despesas}) _totaisDoAno() {
    final receitas = List<double>.filled(12, 0);
    final despesas = List<double>.filled(12, 0);

    for (final Venda v in VendaService.listar()) {
      if (v.data.year == _ano) receitas[v.data.month - 1] += v.valorTotal;
    }
    for (final Despesa d in DespesaService.listar()) {
      if (d.data.year == _ano) despesas[d.data.month - 1] += d.valor;
    }
    return (receitas: receitas, despesas: despesas);
  }

  void _mudarAno(int novo) {
    final hoje = DateTime.now();
    if (novo < _primeiroAno || novo > hoje.year) return;
    setState(() {
      _ano = novo;
      // ano atual: não deixa escolher um mês que ainda não chegou
      if (_ano == hoje.year && _mes > hoje.month) _mes = hoje.month;
    });
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    final totais = _totaisDoAno();
    final resultados = [
      for (int i = 0; i < 12; i++) totais.receitas[i] - totais.despesas[i],
    ];

    final receita = totais.receitas[_mes - 1];
    final despesa = totais.despesas[_mes - 1];
    final resultado = receita - despesa;

    final ultimoDia = DateTime(_ano, _mes + 1, 0).day;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(
            mostrarVoltar: true,
            tituloAjuda: 'Como usar o Relatório',
            ajuda: const [
              ItemAjuda(
                Icons.calendar_month_outlined,
                'Ano do relatório',
                'Use as setas ao lado do ano para ver anos anteriores. '
                    'Não é possível avançar além do ano atual.',
              ),
              ItemAjuda(
                Icons.bar_chart,
                'Gráfico',
                'Cada barra é o resultado de um mês: receitas (vendas) '
                    'menos despesas. Barras vermelhas indicam prejuízo.',
              ),
              ItemAjuda(
                Icons.touch_app_outlined,
                'Trocar o mês',
                'Toque em uma barra (ou no nome do mês) para ver as receitas, '
                    'despesas e o resultado daquele mês logo abaixo.',
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _seletorAno(),
                const SizedBox(height: 16),
                _cardGrafico(resultados),
                const SizedBox(height: 20),
                Text(
                  '${_meses[_mes - 1]} de $_ano',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_data(DateTime(_ano, _mes, 1))} a '
                      '${_data(DateTime(_ano, _mes, ultimoDia))}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                _linhaValor('Receitas', _moeda(receita), Colors.green.shade800),
                const SizedBox(height: 12),
                _linhaValor('Despesas', _moeda(despesa), Colors.red.shade700),
                const SizedBox(height: 12),
                _linhaValor(
                  'Resultado do período',
                  _moeda(resultado),
                  resultado < 0 ? Colors.red.shade700 : Colors.green.shade800,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: menu(itemAtivo: 0),
    );
  }

  Widget _seletorAno() {
    final hoje = DateTime.now();
    final podeVoltar = _ano > _primeiroAno;
    final podeAvancar = _ano < hoje.year;

    Widget seta(IconData icone, bool ativa, VoidCallback onTap) {
      return InkWell(
        onTap: ativa ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icone,
            size: 20,
            color: ativa ? Colors.green.shade800 : Colors.green.shade200,
          ),
        ),
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Ano do relatório',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Row(
            children: [
              seta(Icons.arrow_back, podeVoltar, () => _mudarAno(_ano - 1)),
              SizedBox(
                width: 70,
                child: Text(
                  '$_ano',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              seta(Icons.arrow_forward, podeAvancar,
                      () => _mudarAno(_ano + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardGrafico(List<double> resultados) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evolução financeira',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, restricoes) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (detalhes) {
                  // descobre em qual das 12 colunas o dedo tocou
                  final x = detalhes.localPosition.dx - _GraficoPainter.margemEsq;
                  final largura = restricoes.maxWidth - _GraficoPainter.margemEsq;
                  if (x < 0 || largura <= 0) return;
                  final indice = (x / (largura / 12)).floor().clamp(0, 11);
                  final hoje = DateTime.now();
                  // mês que ainda não chegou não pode ser escolhido
                  if (_ano == hoje.year && indice + 1 > hoje.month) return;
                  setState(() => _mes = indice + 1);
                },
                child: CustomPaint(
                  size: Size(restricoes.maxWidth, 200),
                  painter: _GraficoPainter(
                    resultados: resultados,
                    selecionado: _mes - 1,
                    meses: _mesesCurtos,
                    corPositiva: Colors.green.shade800,
                    corNegativa: Colors.red.shade600,
                    corDestaque: Colors.green.shade50,
                    corTexto: Colors.grey.shade600,
                    corLinha: Colors.grey.shade200,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em um mês para ver os indicadores',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _linhaValor(String rotulo, String valor, Color cor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rotulo,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            valor,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: cor),
          ),
        ],
      ),
    );
  }
}

/// Desenha as barras do resultado mensal, com linhas de grade, valores
/// no lado esquerdo e o nome dos meses embaixo.
class _GraficoPainter extends CustomPainter {
  static const double margemEsq = 44; // espaço para "20 mil"
  static const double _margemBaixo = 22; // espaço para "Jan, Fev..."

  final List<double> resultados;
  final int selecionado; // 0 a 11
  final List<String> meses;
  final Color corPositiva;
  final Color corNegativa;
  final Color corDestaque;
  final Color corTexto;
  final Color corLinha;

  _GraficoPainter({
    required this.resultados,
    required this.selecionado,
    required this.meses,
    required this.corPositiva,
    required this.corNegativa,
    required this.corDestaque,
    required this.corTexto,
    required this.corLinha,
  });

  /// Arredonda para cima num número "bonito" (1, 2, 5 ou 10 x potência de 10)
  double _teto(double valor) {
    if (valor <= 0) return 0;
    final grandeza = pow(10, (log(valor) / ln10).floor()).toDouble();
    final n = valor / grandeza;
    final bonito = n <= 1 ? 1 : (n <= 2 ? 2 : (n <= 5 ? 5 : 10));
    return bonito * grandeza;
  }

  String _rotulo(double v) {
    if (v == 0) return '0';
    final sinal = v < 0 ? '-' : '';
    final a = v.abs();
    if (a >= 1000) {
      final mil = a / 1000;
      final txt = mil == mil.roundToDouble()
          ? mil.toStringAsFixed(0)
          : mil.toStringAsFixed(1).replaceAll('.', ',');
      return '$sinal$txt mil';
    }
    return '$sinal${a.toStringAsFixed(0)}';
  }

  void _texto(Canvas canvas, String texto, Offset ponto,
      {bool direita = false, bool centro = false, bool negrito = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(
          fontSize: 11,
          color: corTexto,
          fontWeight: negrito ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double x = ponto.dx;
    if (direita) x -= tp.width;
    if (centro) x -= tp.width / 2;
    tp.paint(canvas, Offset(x, ponto.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final largura = size.width - margemEsq;
    final altura = size.height - _margemBaixo;
    final coluna = largura / 12;

    final maiorPositivo = resultados.fold<double>(0, max);
    final maiorNegativo = resultados.fold<double>(0, min).abs();

    var topo = _teto(maiorPositivo);
    var fundo = _teto(maiorNegativo);
    if (topo == 0 && fundo == 0) topo = 1000; // sem dados: escala fixa

    // a linha do zero fica mais embaixo quando existem resultados negativos
    final total = topo + fundo;
    final yZero = altura * (topo / total);
    final escala = altura / total;

    // linha de destaque do mês escolhido
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margemEsq + coluna * selecionado, 0, coluna, altura),
        const Radius.circular(8),
      ),
      Paint()..color = corDestaque,
    );

    // linhas de grade e valores: fundo, 0, metade e topo
    final linhas = <double>[
      if (fundo > 0) -fundo,
      0,
      topo / 2,
      topo,
    ];
    final pincelLinha = Paint()
      ..color = corLinha
      ..strokeWidth = 1;
    for (final valor in linhas) {
      final y = yZero - valor * escala;
      canvas.drawLine(Offset(margemEsq, y), Offset(size.width, y), pincelLinha);
      _texto(canvas, _rotulo(valor), Offset(margemEsq - 6, y), direita: true);
    }

    // barras
    final larguraBarra = min(coluna * 0.45, 14.0);
    for (int i = 0; i < 12; i++) {
      final v = resultados[i];
      final xCentro = margemEsq + coluna * i + coluna / 2;

      if (v != 0) {
        final altBarra = v.abs() * escala;
        final topoBarra = v > 0 ? yZero - altBarra : yZero;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                xCentro - larguraBarra / 2, topoBarra, larguraBarra, altBarra),
            const Radius.circular(3),
          ),
          Paint()..color = v > 0 ? corPositiva : corNegativa,
        );
      }

      _texto(
        canvas,
        meses[i],
        Offset(xCentro, size.height - _margemBaixo / 2 + 2),
        centro: true,
        negrito: i == selecionado,
      );
    }
  }

  @override
  bool shouldRepaint(_GraficoPainter antigo) =>
      antigo.resultados != resultados || antigo.selecionado != selecionado;
}