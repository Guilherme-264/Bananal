/// Texto em português para um código de condição do tempo da OpenWeather
String descricaoDaCondicao(int id, {bool noite = false}) {
  if (id >= 200 && id < 300) return 'Tempestade';
  if (id >= 300 && id < 400) return 'Garoa';

  switch (id) {
    case 500:
      return 'Chuva leve';
    case 501:
      return 'Chuva moderada';
    case 502:
    case 503:
    case 504:
      return 'Chuva forte';
    case 511:
      return 'Chuva congelante';
    case 520:
      return 'Pancadas leves';
    case 521:
      return 'Pancadas de chuva';
    case 522:
    case 531:
      return 'Pancadas fortes';
  }

  if (id >= 600 && id < 700) return 'Neve';
  if (id >= 700 && id < 800) return 'Neblina';
  if (id == 800) return noite ? 'Céu limpo' : 'Ensolarado';
  if (id == 801 || id == 802) return 'Parcialmente nublado';
  return 'Nublado';
}

/// Previsão para um intervalo de 3 horas (é o que a API entrega)
class SlotClima {
  /// Horário no relógio local da cidade
  /// (é um DateTime "utc" só por convenção; use hour, day, month...)
  final DateTime hora;
  final int condicaoId;
  final bool noite;
  final double temp;
  final double tempMin;
  final double tempMax;
  final double chuvaProb; // 0 a 1
  final double chuvaMm;
  final double ventoKmh;
  final double rajadaKmh;
  final int umidade;

  const SlotClima({
    required this.hora,
    required this.condicaoId,
    required this.noite,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.chuvaProb,
    required this.chuvaMm,
    required this.ventoKmh,
    required this.rajadaKmh,
    required this.umidade,
  });

  int get chuvaPercentual => (chuvaProb * 100).round();
  String get descricao => descricaoDaCondicao(condicaoId, noite: noite);
}

/// Manhã, tarde ou noite de hoje
class PeriodoClima {
  final String nome;
  final String faixa; // "06h - 11h"
  final bool temDados;
  final bool encerrado; // o período já passou (a API só prevê o futuro)
  final int condicaoId;
  final bool noite;
  final double temp;
  final double tempMin;
  final double tempMax;
  final int chuvaProb; // 0 a 100
  final double chuvaMm;
  final double ventoKmh;
  final int umidade;

  const PeriodoClima({
    required this.nome,
    required this.faixa,
    required this.condicaoId,
    required this.noite,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.chuvaProb,
    required this.chuvaMm,
    required this.ventoKmh,
    required this.umidade,
  })  : temDados = true,
        encerrado = false;

  const PeriodoClima.vazio({
    required this.nome,
    required this.faixa,
    required this.encerrado,
  })  : temDados = false,
        condicaoId = 800,
        noite = false,
        temp = 0,
        tempMin = 0,
        tempMax = 0,
        chuvaProb = 0,
        chuvaMm = 0,
        ventoKmh = 0,
        umidade = 0;

  String get descricao => descricaoDaCondicao(condicaoId, noite: noite);
}

/// Resumo de um dia (usado na lista "Próximos 5 dias")
class DiaClima {
  final DateTime data;
  final int condicaoId;
  final double tempMin;
  final double tempMax;
  final int chuvaProb; // 0 a 100
  final double chuvaMm;
  final List<SlotClima> slots; // os intervalos de 3 horas desse dia

  const DiaClima({
    required this.data,
    required this.condicaoId,
    required this.tempMin,
    required this.tempMax,
    required this.chuvaProb,
    required this.chuvaMm,
    required this.slots,
  });

  String get descricao => descricaoDaCondicao(condicaoId);
}

enum TipoAlerta { chuva, vento, frio, calor }

class AlertaClima {
  final TipoAlerta tipo;
  final String subtitulo;
  final String mensagem;

  const AlertaClima({
    required this.tipo,
    required this.subtitulo,
    required this.mensagem,
  });
}

class PrevisaoClima {
  final DateTime hoje; // dia de hoje na cidade
  final List<PeriodoClima> periodos; // manhã, tarde e noite
  final bool hojeTemDados;
  final double minHoje;
  final double maxHoje;
  final int umidadeHoje;
  final List<DiaClima> proximosDias;
  final List<AlertaClima> alertas;

  const PrevisaoClima({
    required this.hoje,
    required this.periodos,
    required this.hojeTemDados,
    required this.minHoje,
    required this.maxHoje,
    required this.umidadeHoje,
    required this.proximosDias,
    required this.alertas,
  });
}