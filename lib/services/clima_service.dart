import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../config/chaves.dart';
import '../model/clima_model.dart';
import '../model/localizacao_model.dart';

/// Erro com mensagem pronta para mostrar ao usuário
class ClimaException implements Exception {
  final String mensagem;
  ClimaException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Uma cidade devolvida pela busca por nome
class CidadeEncontrada {
  final String nome;
  final String? estado; // nome completo do estado, como a API devolve
  final double latitude;
  final double longitude;

  const CidadeEncontrada({
    required this.nome,
    required this.estado,
    required this.latitude,
    required this.longitude,
  });
}

class _ItemCache {
  final PrevisaoClima previsao;
  final DateTime quando;
  _ItemCache(this.previsao, this.quando);
}

/// Conversa com a API da OpenWeather (plano gratuito):
/// busca de cidade (geocoding) e previsão de 5 dias em passos de 3 horas.
class ClimaService {
  static const String _base = 'https://api.openweathermap.org';

  // ---- Limites dos alertas (mude aqui se quiser) ----
  static const double alertaChuvaAltaMm = 50; // "Alto nível de chuva"
  static const double alertaChuvaForteMm = 25; // "Chuva forte"
  static const double alertaVentoKmh = 40;
  static const double alertaFrioC = 4;
  static const double alertaCalorC = 35;

  // Guarda a última previsão por 15 minutos, para não consultar a API
  // toda vez que o usuário troca de aba.
  static final Map<String, _ItemCache> _cache = {};
  static const Duration _validadeCache = Duration(minutes: 15);

  // ---------- Requisição ----------
  static Future<dynamic> _get(Uri uri) async {
    if (openWeatherApiKey.isEmpty ||
        openWeatherApiKey == 'COLE_SUA_CHAVE_AQUI') {
      throw ClimaException(
          'Falta colocar a chave da OpenWeather em lib/config/chaves.dart.');
    }

    http.Response resposta;
    try {
      resposta = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ClimaException('Não foi possível conectar. Verifique a internet.');
    }

    if (resposta.statusCode == 401) {
      throw ClimaException(
          'Chave da OpenWeather inválida ou ainda não ativada. '
              'Chaves novas podem levar até 2 horas para funcionar.');
    }
    if (resposta.statusCode == 429) {
      throw ClimaException('Muitas consultas seguidas. Tente de novo em instantes.');
    }
    if (resposta.statusCode != 200) {
      throw ClimaException(
          'Erro ao buscar o clima (código ${resposta.statusCode}).');
    }

    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  // ---------- Busca de cidade ----------
  /// Procura cidades brasileiras com esse nome (até 5 resultados).
  /// Quem chama filtra pelo estado.
  static Future<List<CidadeEncontrada>> buscarCidades(String cidade) async {
    final uri = Uri.parse('$_base/geo/1.0/direct').replace(queryParameters: {
      'q': '$cidade,BR',
      'limit': '5',
      'appid': openWeatherApiKey,
    });

    final dados = await _get(uri) as List<dynamic>;

    return dados.map((item) {
      final mapa = item as Map<String, dynamic>;
      return CidadeEncontrada(
        nome: mapa['name'] as String? ?? cidade,
        estado: mapa['state'] as String?,
        latitude: (mapa['lat'] as num).toDouble(),
        longitude: (mapa['lon'] as num).toDouble(),
      );
    }).toList();
  }

  // ---------- Previsão ----------
  static Future<PrevisaoClima> buscarPrevisao(
      Localizacao local, {
        bool forcar = false,
      }) async {
    final chave =
        '${local.latitude.toStringAsFixed(3)},${local.longitude.toStringAsFixed(3)}';

    final guardado = _cache[chave];
    if (!forcar &&
        guardado != null &&
        DateTime.now().difference(guardado.quando) < _validadeCache) {
      return guardado.previsao;
    }

    final uri = Uri.parse('$_base/data/2.5/forecast').replace(queryParameters: {
      'lat': local.latitude.toString(),
      'lon': local.longitude.toString(),
      'units': 'metric',
      'lang': 'pt_br',
      'appid': openWeatherApiKey,
    });

    final dados = await _get(uri) as Map<String, dynamic>;

    // diferença do horário da cidade para o UTC, em segundos
    final cidade = (dados['city'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final fuso = (cidade['timezone'] as num?)?.toInt() ?? -10800;

    final lista = (dados['list'] as List<dynamic>?) ?? [];
    final slots = lista
        .map((item) => _lerSlot(item as Map<String, dynamic>, fuso))
        .toList();

    final previsao = _montarPrevisao(slots, fuso);
    _cache[chave] = _ItemCache(previsao, DateTime.now());
    return previsao;
  }

  static SlotClima _lerSlot(Map<String, dynamic> m, int fuso) {
    double n(dynamic v) => (v as num?)?.toDouble() ?? 0;

    final principal = (m['main'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final listaClima = (m['weather'] as List<dynamic>?) ?? [];
    final clima = listaClima.isNotEmpty
        ? listaClima.first as Map<String, dynamic>
        : <String, dynamic>{};
    final vento = (m['wind'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final chuva = (m['rain'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final neve = (m['snow'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final dt = (m['dt'] as num).toInt();
    final hora = DateTime.fromMillisecondsSinceEpoch(dt * 1000, isUtc: true)
        .add(Duration(seconds: fuso));

    final temp = n(principal['temp']);
    final velocidade = n(vento['speed']) * 3.6; // m/s -> km/h
    final rajada = vento['gust'] == null ? velocidade : n(vento['gust']) * 3.6;

    return SlotClima(
      hora: hora,
      condicaoId: (clima['id'] as num?)?.toInt() ?? 800,
      noite: ((clima['icon'] as String?) ?? '').endsWith('n'),
      temp: temp,
      tempMin: principal['temp_min'] == null ? temp : n(principal['temp_min']),
      tempMax: principal['temp_max'] == null ? temp : n(principal['temp_max']),
      chuvaProb: n(m['pop']),
      chuvaMm: n(chuva['3h']) + n(neve['3h']),
      ventoKmh: velocidade,
      rajadaKmh: rajada,
      umidade: (principal['humidity'] as num?)?.toInt() ?? 0,
    );
  }

  // ---------- Montagem da previsão ----------
  static bool _mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static PrevisaoClima _montarPrevisao(List<SlotClima> slots, int fuso) {
    // "agora" no relógio da cidade
    final agora = DateTime.now().toUtc().add(Duration(seconds: fuso));
    final hoje = DateTime.utc(agora.year, agora.month, agora.day);

    final slotsHoje = slots.where((s) => _mesmoDia(s.hora, hoje)).toList();

    final periodos = [
      _montarPeriodo('Manhã', '06h - 11h', 6, 12, slotsHoje, agora),
      _montarPeriodo('Tarde', '12h - 17h', 12, 18, slotsHoje, agora),
      _montarPeriodo('Noite', '18h - 23h', 18, 24, slotsHoje, agora),
    ];

    double minHoje = 0;
    double maxHoje = 0;
    int umidadeHoje = 0;
    if (slotsHoje.isNotEmpty) {
      minHoje = slotsHoje.map((s) => s.tempMin).reduce((a, b) => a < b ? a : b);
      maxHoje = slotsHoje.map((s) => s.tempMax).reduce((a, b) => a > b ? a : b);
      umidadeHoje = (slotsHoje.map((s) => s.umidade).reduce((a, b) => a + b) /
          slotsHoje.length)
          .round();
    }

    // os 5 dias seguintes (o último pode vir com menos horários)
    final dias = <DiaClima>[];
    for (int i = 1; i <= 5; i++) {
      final dia = hoje.add(Duration(days: i));
      final doDia = slots.where((s) => _mesmoDia(s.hora, dia)).toList();
      if (doDia.isNotEmpty) dias.add(_montarDia(dia, doDia));
    }

    return PrevisaoClima(
      hoje: hoje,
      periodos: periodos,
      hojeTemDados: slotsHoje.isNotEmpty,
      minHoje: minHoje,
      maxHoje: maxHoje,
      umidadeHoje: umidadeHoje,
      proximosDias: dias,
      alertas: _montarAlertas(slotsHoje),
    );
  }

  static PeriodoClima _montarPeriodo(
      String nome,
      String faixa,
      int horaInicio,
      int horaFim,
      List<SlotClima> slotsHoje,
      DateTime agora,
      ) {
    final slots = slotsHoje
        .where((s) => s.hora.hour >= horaInicio && s.hora.hour < horaFim)
        .toList();

    if (slots.isEmpty) {
      return PeriodoClima.vazio(
        nome: nome,
        faixa: faixa,
        encerrado: agora.hour >= horaFim,
      );
    }

    double media(double Function(SlotClima) campo) =>
        slots.map(campo).reduce((a, b) => a + b) / slots.length;

    return PeriodoClima(
      nome: nome,
      faixa: faixa,
      condicaoId: _condicaoRepresentativa(slots),
      noite: slots.every((s) => s.noite),
      temp: media((s) => s.temp),
      tempMin: slots.map((s) => s.tempMin).reduce((a, b) => a < b ? a : b),
      tempMax: slots.map((s) => s.tempMax).reduce((a, b) => a > b ? a : b),
      chuvaProb:
      (slots.map((s) => s.chuvaProb).reduce(math.max) * 100).round(),
      chuvaMm: slots.fold<double>(0, (soma, s) => soma + s.chuvaMm),
      ventoKmh: media((s) => s.ventoKmh),
      umidade: media((s) => s.umidade.toDouble()).round(),
    );
  }

  static DiaClima _montarDia(DateTime data, List<SlotClima> slots) {
    return DiaClima(
      data: data,
      condicaoId: _condicaoRepresentativa(slots),
      tempMin: slots.map((s) => s.tempMin).reduce((a, b) => a < b ? a : b),
      tempMax: slots.map((s) => s.tempMax).reduce((a, b) => a > b ? a : b),
      chuvaProb:
      (slots.map((s) => s.chuvaProb).reduce(math.max) * 100).round(),
      chuvaMm: slots.fold<double>(0, (soma, s) => soma + s.chuvaMm),
      slots: slots,
    );
  }

  /// Escolhe a condição que melhor resume vários horários:
  /// se há chuva com boa chance, ela manda; senão, vale a mais frequente.
  static int _condicaoRepresentativa(List<SlotClima> slots) {
    final chuvosos =
    slots.where((s) => s.condicaoId < 600 && s.chuvaProb >= 0.4).toList();

    if (chuvosos.isNotEmpty) {
      chuvosos.sort((a, b) {
        final porMm = b.chuvaMm.compareTo(a.chuvaMm);
        return porMm != 0 ? porMm : b.chuvaProb.compareTo(a.chuvaProb);
      });
      return chuvosos.first.condicaoId;
    }

    final contagem = <int, int>{};
    for (final s in slots) {
      contagem[s.condicaoId] = (contagem[s.condicaoId] ?? 0) + 1;
    }

    int melhor = slots.first.condicaoId;
    int maior = 0;
    contagem.forEach((id, quantidade) {
      if (quantidade > maior) {
        maior = quantidade;
        melhor = id;
      }
    });
    return melhor;
  }

  // ---------- Alertas ----------
  static List<AlertaClima> _montarAlertas(List<SlotClima> slotsHoje) {
    if (slotsHoje.isEmpty) return [];

    final alertas = <AlertaClima>[];

    final mm = slotsHoje.fold<double>(0, (soma, s) => soma + s.chuvaMm);
    final vento = slotsHoje.fold<double>(
      0,
          (maior, s) => math.max(maior, math.max(s.ventoKmh, s.rajadaKmh)),
    );
    final minima =
    slotsHoje.map((s) => s.tempMin).reduce((a, b) => a < b ? a : b);
    final maxima =
    slotsHoje.map((s) => s.tempMax).reduce((a, b) => a > b ? a : b);

    if (mm >= alertaChuvaAltaMm) {
      alertas.add(AlertaClima(
        tipo: TipoAlerta.chuva,
        subtitulo: 'Alto nível de chuva - ${mm.round()}mm de chuva',
        mensagem: 'Previsão de ${mm.round()}mm de chuva. Proteja as mudas e '
            'evite colheita em terrenos inclinados hoje.',
      ));
    } else if (mm >= alertaChuvaForteMm) {
      alertas.add(AlertaClima(
        tipo: TipoAlerta.chuva,
        subtitulo: 'Chuva forte - ${mm.round()}mm de chuva',
        mensagem: 'Previsão de ${mm.round()}mm de chuva. Evite aplicar adubo e '
            'defensivos e redobre a atenção em terrenos inclinados hoje.',
      ));
    }

    if (vento >= alertaVentoKmh) {
      alertas.add(AlertaClima(
        tipo: TipoAlerta.vento,
        subtitulo: 'Vento forte - até ${vento.round()} km/h',
        mensagem: 'Previsão de ventos de até ${vento.round()} km/h. '
            'Evite pulverizar e proteja as plantas mais altas.',
      ));
    }

    if (minima <= alertaFrioC) {
      alertas.add(AlertaClima(
        tipo: TipoAlerta.frio,
        subtitulo: 'Frio intenso - mínima de ${minima.round()}°C',
        mensagem: 'Mínima prevista de ${minima.round()}°C. '
            'Há risco de geada: proteja as mudas.',
      ));
    }

    if (maxima >= alertaCalorC) {
      alertas.add(AlertaClima(
        tipo: TipoAlerta.calor,
        subtitulo: 'Calor intenso - máxima de ${maxima.round()}°C',
        mensagem: 'Máxima prevista de ${maxima.round()}°C. Evite trabalho '
            'pesado nas horas mais quentes e cuide da irrigação.',
      ));
    }

    return alertas;
  }
}