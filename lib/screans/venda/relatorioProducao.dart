import 'dart:math';
import 'package:flutter/material.dart';
import '../../model/venda_model.dart';
import '../../services/venda_service.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/menu.dart';

/// Relatório de produção do ano: gráfico com o peso colhido em cada mês.
/// Os dados vêm das vendas (peso da caixa x quantidade de caixas).
/// Tocar em um mês mostra os números dele.
class TelaRelatorioProducao extends StatefulWidget {
  const TelaRelatorioProducao({super.key});

  @override
  State<TelaRelatorioProducao> createState() => _TelaRelatorioProducaoState();
}

class _TelaRelatorioProducaoState extends State<TelaRelatorioProducao> {
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
  }

  @override
  void dispose() {
    VendaService.vendas.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  // ---------- Formatação ----------
  String _numero(num v) {
    return v.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
    );
  }

  String _kg(num v) => '${_numero(v)} kg';

  String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ---------- Dados ----------
  /// Peso total das caixas de uma venda (peso da caixa x quantidade)
  double _pesoDaVenda(Venda v) {
    double total = 0;
    for (final c in v.classificacoes) {
      total += c.pesoCaixa * c.quantidadeCaixa;
    }
    return total;
  }

  /// Peso colhido e número de colheitas (vendas) de cada mês do ano
  ({List<double> pesos, List<int> colheitas}) _totaisDoAno() {
    final pesos = List<double>.filled(12, 0);
    final colheitas = List<int>.filled(12, 0);

    for (final v in VendaService.listar()) {
      if (v.data.year != _ano) continue;
      pesos[v.data.month - 1] += _pesoDaVenda(v);
      colheitas[v.data.month - 1] += 1;
    }
    return (pesos: pesos, colheitas: colheitas);
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

    final peso = totais.pesos[_mes - 1];
    final colheitas = totais.colheitas[_mes - 1];
    final media = colheitas == 0 ? 0.0 : peso / colheitas;

    final ultimoDia = DateTime(_ano, _mes + 1, 0).day;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(
            mostrarVoltar: true,
            tituloAjuda: 'Como usar a Produção',
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
                'Cada barra é o peso colhido em um mês, em quilos. O peso '
                    'vem das vendas: peso da caixa vezes a quantidade de '
                    'caixas.',
              ),
              ItemAjuda(
                Icons.touch_app_outlined,
                'Trocar o mês',
                'Toque em uma barra (ou no nome do mês) para ver o peso '
                    'total, a quantidade de colheitas e a média daquele mês.',
              ),
              ItemAjuda(
                Icons.info_outline,
                'O que é uma colheita',
                'Cada venda cadastrada conta como uma colheita. A média é o '
                    'peso total dividido pelo número de colheitas.',
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _seletorAno(),
                const SizedBox(height: 16),
                _cardGrafico(totais.pesos),
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
                _linhaValor('Peso total colhido (kg)', _kg(peso)),
                const SizedBox(height: 12),
                _linhaValor('Quantidade de colheitas', '$colheitas'),
                const SizedBox(height: 12),
                _linhaValor('Média de peso por colheita (kg)', _kg(media)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
      // a tela é aberta a partir de Vendas, então Vendas fica em destaque
      bottomNavigationBar: menu(itemAtivo: 1),
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

  Widget _cardGrafico(List<double> pesos) {
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
            'Produção mensal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Peso colhido (kg)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                  size: Size(restricoes.maxWidth, 190),
                  painter: _GraficoPainter(
                    valores: pesos,
                    selecionado: _mes - 1,
                    meses: _mesesCurtos,
                    corBarra: Colors.green.shade800,
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

  Widget _linhaValor(String rotulo, String valor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Desenha as barras do peso mensal, com linhas de grade, valores
/// no lado esquerdo e o nome dos meses embaixo.
class _GraficoPainter extends CustomPainter {
  static const double margemEsq = 44; // espaço para "8 mil"
  static const double _margemBaixo = 22; // espaço para "Jan, Fev..."

  final List<double> valores;
  final int selecionado; // 0 a 11
  final List<String> meses;
  final Color corBarra;
  final Color corDestaque;
  final Color corTexto;
  final Color corLinha;

  _GraficoPainter({
    required this.valores,
    required this.selecionado,
    required this.meses,
    required this.corBarra,
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
    if (v >= 1000) {
      final mil = v / 1000;
      final txt = mil == mil.roundToDouble()
          ? mil.toStringAsFixed(0)
          : mil.toStringAsFixed(1).replaceAll('.', ',');
      return '$txt mil';
    }
    return v.toStringAsFixed(0);
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

    var topo = _teto(valores.fold<double>(0, max));
    if (topo == 0) topo = 1000; // sem dados: escala fixa
    final escala = altura / topo;

    // destaque do mês escolhido
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margemEsq + coluna * selecionado, 0, coluna, altura),
        const Radius.circular(8),
      ),
      Paint()..color = corDestaque,
    );

    // linhas de grade e valores: 0, metade e topo
    final pincelLinha = Paint()
      ..color = corLinha
      ..strokeWidth = 1;
    for (final valor in [0.0, topo / 2, topo]) {
      final y = altura - valor * escala;
      canvas.drawLine(Offset(margemEsq, y), Offset(size.width, y), pincelLinha);
      _texto(canvas, _rotulo(valor), Offset(margemEsq - 6, y), direita: true);
    }

    // barras
    final larguraBarra = min(coluna * 0.45, 14.0);
    for (int i = 0; i < 12; i++) {
      final v = valores[i];
      final xCentro = margemEsq + coluna * i + coluna / 2;

      if (v > 0) {
        final altBarra = v * escala;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(xCentro - larguraBarra / 2, altura - altBarra,
                larguraBarra, altBarra),
            const Radius.circular(3),
          ),
          Paint()..color = corBarra,
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
      antigo.valores != valores || antigo.selecionado != selecionado;
}