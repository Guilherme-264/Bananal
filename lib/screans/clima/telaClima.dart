import 'package:flutter/material.dart';
import '../../model/clima_model.dart';
import '../../model/localizacao_model.dart';
import '../../services/clima_service.dart';
import '../../services/localizacao_service.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/clima.dart';
import '../../widgets/menu.dart';
import 'localizacaoFazenda.dart';

class TelaClima extends StatefulWidget {
  @override
  _TelaClimaState createState() => _TelaClimaState();
}

class _TelaClimaState extends State<TelaClima> {
  PrevisaoClima? _previsao;
  String? _erro;

  // localização usada na última busca
  Localizacao? _localAtual;

  @override
  void initState() {
    super.initState();

    _localAtual = LocalizacaoService.localizacao.value;
    if (_localAtual != null) _buscar(_localAtual!);

    LocalizacaoService.localizacao.addListener(_aoMudarLocalizacao);
    LocalizacaoService.carregada.addListener(_atualizar);
  }

  @override
  void dispose() {
    LocalizacaoService.localizacao.removeListener(_aoMudarLocalizacao);
    LocalizacaoService.carregada.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  /// Quando o agricultor informa ou troca a cidade, busca o clima de novo
  void _aoMudarLocalizacao() {
    final nova = LocalizacaoService.localizacao.value;

    if (nova != _localAtual) {
      _localAtual = nova;
      _previsao = null;
      _erro = null;
      if (nova != null) _buscar(nova);
    }
    _atualizar();
  }

  Future<void> _buscar(Localizacao local, {bool forcar = false}) async {
    PrevisaoClima? previsao;
    String? erro;

    try {
      previsao = await ClimaService.buscarPrevisao(local, forcar: forcar);
    } on ClimaException catch (e) {
      erro = e.mensagem;
    } catch (_) {
      erro = 'Não foi possível carregar o clima agora.';
    }

    // saiu da tela ou trocou de cidade no meio da busca: ignora
    if (!mounted || local != _localAtual) return;

    if (previsao != null) {
      setState(() {
        _previsao = previsao;
        _erro = null;
      });
    } else if (_previsao != null) {
      // já tinha dados na tela: mantém e só avisa
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro ?? 'Não foi possível atualizar.')),
      );
    } else {
      setState(() => _erro = erro);
    }
  }

  void _tentarDeNovo(Localizacao local) {
    setState(() => _erro = null);
    _buscar(local, forcar: true);
  }

  void _alterarLocalizacao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TelaLocalizacao(alterando: true),
      ),
    );
  }

  // ---------- Formatação ----------
  String _doisDigitos(int n) => n.toString().padLeft(2, '0');

  String _diaMes(DateTime d) => '${_doisDigitos(d.day)}/${_doisDigitos(d.month)}';

  String _dataCompleta(DateTime d) => '${_diaMes(d)}/${d.year}';

  String _diaSemana(DateTime d) =>
      const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][d.weekday - 1];

  String _mm(double mm) {
    if (mm < 0.05) return '0';
    if (mm >= 10) return mm.round().toString();
    final texto = mm.toStringAsFixed(1);
    final semZero =
    texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto;
    return semZero.replaceAll('.', ',');
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    // ainda descobrindo se o agricultor já informou a cidade
    if (!LocalizacaoService.carregada.value) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Column(
          children: [
            Cabecalho(),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.green.shade800),
              ),
            ),
          ],
        ),
        bottomNavigationBar: menu(itemAtivo: 3),
      );
    }

    final local = LocalizacaoService.localizacao.value;

    // primeira vez: precisa informar a cidade antes de ver o clima
    if (local == null) {
      return const TelaLocalizacao();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          Cabecalho(),
          Expanded(
            child: RefreshIndicator(
              color: Colors.green.shade800,
              onRefresh: () => _buscar(local, forcar: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: _conteudo(local),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: menu(itemAtivo: 3),
    );
  }

  List<Widget> _conteudo(Localizacao local) {
    final previsao = _previsao;

    if (previsao == null) {
      return [
        _linhaTitulo(local, DateTime.now()),
        const SizedBox(height: 16),
        if (_erro != null)
          _cardErro(local)
        else
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: CircularProgressIndicator(color: Colors.green.shade800),
            ),
          ),
      ];
    }

    return [
      _linhaTitulo(local, previsao.hoje),
      const SizedBox(height: 16),

      for (final alerta in previsao.alertas) ...[
        _cardAlerta(alerta),
        const SizedBox(height: 12),
      ],

      const SizedBox(height: 4),
      const Text(
        'Hoje',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            _dataCompleta(previsao.hoje),
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
      const SizedBox(height: 12),

      _periodosDeHoje(previsao.periodos),
      const SizedBox(height: 12),

      _resumoDoDia(previsao),
      const SizedBox(height: 24),

      const Text(
        'Próximos 5 dias',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      _listaDeDias(previsao.proximosDias),

      const SizedBox(height: 16),
      Center(
        child: Text(
          'Dados meteorológicos: OpenWeather',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  // ---------- "Clima na Fazenda" + data + cidade ----------
  Widget _linhaTitulo(Localizacao local, DateTime hoje) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Clima na Fazenda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        // tocar aqui abre a troca de cidade
        InkWell(
          onTap: _alterarLocalizacao,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Hoje, ${_dataCompleta(hoje)}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.green.shade800),
                    const SizedBox(width: 3),
                    Text(
                      local.rotulo,
                      style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.edit_outlined,
                        size: 12, color: Colors.grey.shade500),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Alerta ----------
  IconData _iconeDoAlerta(TipoAlerta tipo) {
    switch (tipo) {
      case TipoAlerta.chuva:
        return Icons.umbrella;
      case TipoAlerta.vento:
        return Icons.air;
      case TipoAlerta.frio:
        return Icons.ac_unit;
      case TipoAlerta.calor:
        return Icons.wb_sunny;
    }
  }

  Widget _cardAlerta(AlertaClima alerta) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade600, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              shape: BoxShape.circle,
            ),
            child: Icon(_iconeDoAlerta(alerta.tipo),
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerta de Clima',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alerta.subtitulo,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  alerta.mensagem,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Manhã, tarde e noite ----------
  Widget _periodosDeHoje(List<PeriodoClima> periodos) {
    const fundos = [Color(0xFFEAF4FF), Color(0xFFFFF8E6), Color(0xFFEEF0FF)];
    const bordas = [Color(0xFFD3E8FB), Color(0xFFFBEBC4), Color(0xFFDCE0FA)];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < periodos.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _cardPeriodo(periodos[i], fundos[i], bordas[i])),
          ],
        ],
      ),
    );
  }

  Widget _cardPeriodo(PeriodoClima p, Color fundo, Color borda) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borda),
      ),
      child: Column(
        children: [
          Text(p.nome,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(p.faixa,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          if (!p.temDados)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_empty,
                        size: 28, color: Colors.grey.shade400),
                    const SizedBox(height: 6),
                    Text(
                      p.encerrado ? 'Período encerrado' : 'Sem dados',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ClimaIcone(condicaoId: p.condicaoId, noite: p.noite, tamanho: 44),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(
                  p.descricao,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${p.temp.round()}°C',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _metrica(Icons.umbrella, '${p.chuvaProb}% (${_mm(p.chuvaMm)}mm)'),
            _metrica(Icons.thermostat,
                '${p.tempMin.round()}° / ${p.tempMax.round()}°'),
            _metrica(Icons.air, '${p.ventoKmh.round()} km/h'),
            _metrica(Icons.water_drop_outlined, '${p.umidade}%'),
          ],
        ],
      ),
    );
  }

  Widget _metrica(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icone, size: 15, color: Colors.blueGrey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(texto, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Temperatura e umidade do dia ----------
  Widget _resumoDoDia(PrevisaoClima p) {
    final temperatura = p.hojeTemDados
        ? '${p.minHoje.round()}°C / ${p.maxHoje.round()}°C'
        : '—';
    final umidade = p.hojeTemDados ? '${p.umidadeHoje}% UR' : '—';

    return Row(
      children: [
        Expanded(
          child: _cardInfo(
            icone: Icons.thermostat,
            titulo: 'Temperatura',
            valor: temperatura,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardInfo(
            icone: Icons.water_drop_outlined,
            titulo: 'Umidade do Ar',
            valor: umidade,
          ),
        ),
      ],
    );
  }

  Widget _cardInfo({
    required IconData icone,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: Colors.blue.shade600, size: 26),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valor,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Próximos 5 dias ----------
  Widget _listaDeDias(List<DiaClima> dias) {
    if (dias.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Sem previsão para os próximos dias.',
            style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            for (int i = 0; i < dias.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
              _linhaDoDia(dias[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _linhaDoDia(DiaClima d) {
    return InkWell(
      onTap: () => _detalhesDoDia(d),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                '${_diaSemana(d.data)}, ${_diaMes(d.data)}',
                style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            ClimaIcone(condicaoId: d.condicaoId, tamanho: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                d.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${d.tempMin.round()}°C',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                  const TextSpan(text: ' / '),
                  TextSpan(
                    text: '${d.tempMax.round()}°C',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.water_drop_outlined,
                size: 14, color: Colors.blue.shade600),
            const SizedBox(width: 2),
            Text('${d.chuvaProb}%', style: const TextStyle(fontSize: 12)),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  /// Ao tocar num dia: mostra o tempo de 3 em 3 horas
  void _detalhesDoDia(DiaClima d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_diaSemana(d.data)}, ${_dataCompleta(d.data)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chuva prevista no dia: ${_mm(d.chuvaMm)}mm',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                for (final s in d.slots) ...[
                  Divider(height: 1, color: Colors.grey.shade200),
                  _linhaDoHorario(s),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _linhaDoHorario(SlotClima s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '${_doisDigitos(s.hora.hour)}h',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          ClimaIcone(condicaoId: s.condicaoId, noite: s.noite, tamanho: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(s.descricao, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            '${s.temp.round()}°C',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Icon(Icons.water_drop_outlined, size: 14, color: Colors.blue.shade600),
          const SizedBox(width: 2),
          SizedBox(
            width: 68,
            child: Text(
              '${s.chuvaPercentual}% (${_mm(s.chuvaMm)}mm)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Erro ----------
  Widget _cardErro(Localizacao local) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            _erro ?? 'Não foi possível carregar o clima.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _tentarDeNovo(local),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}