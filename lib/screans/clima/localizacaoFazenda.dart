// TODO Implement this library.
import 'package:flutter/material.dart';
import '../../model/estados.dart';
import '../../model/localizacao_model.dart';
import '../../services/clima_service.dart';
import '../../services/localizacao_service.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/menu.dart';

/// Tela onde o agricultor informa a cidade e o estado da fazenda.
/// Enquanto ele não fizer isso, a aba Clima mostra só esta tela.
class TelaLocalizacao extends StatefulWidget {
  /// true  = aberta pelo "trocar cidade" (tem seta de voltar e fecha ao salvar)
  /// false = primeira vez, ocupando a aba Clima
  final bool alterando;

  const TelaLocalizacao({super.key, this.alterando = false});

  @override
  State<TelaLocalizacao> createState() => _TelaLocalizacaoState();
}

class _TelaLocalizacaoState extends State<TelaLocalizacao> {
  final TextEditingController _cidadeController = TextEditingController();
  String? _uf; // sigla do estado escolhido
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    // ao trocar de cidade, já vem preenchida com a atual
    final atual = LocalizacaoService.localizacao.value;
    if (atual != null) {
      _cidadeController.text = atual.cidade;
      _uf = estadosBrasil.containsKey(atual.estado) ? atual.estado : null;
    }
  }

  @override
  void dispose() {
    _cidadeController.dispose();
    super.dispose();
  }

  // ---------- Comparação de nomes de estado ----------
  /// minúsculas, sem acento e sem "state of " (a API às vezes escreve assim)
  String _normalizar(String texto) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucn';

    var resultado = texto.toLowerCase();
    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    return resultado.replaceAll('state of ', '').trim();
  }

  bool _mesmoEstado(String? nomeDaApi, String uf) {
    if (nomeDaApi == null) return false;
    final a = _normalizar(nomeDaApi);
    if (uf == 'DF' && a == 'federal district') return true;
    return a == _normalizar(estadosBrasil[uf] ?? '');
  }

  /// "Rio Grande do Sul" -> "RS" (null se não reconhecer)
  String? _ufDoNome(String? nomeDaApi) {
    if (nomeDaApi == null) return null;
    for (final item in estadosBrasil.entries) {
      if (_mesmoEstado(nomeDaApi, item.key)) return item.key;
    }
    return null;
  }

  // ---------- Ações ----------
  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _buscarESalvar() async {
    final uf = _uf;
    final cidade = _cidadeController.text.trim();

    if (uf == null) {
      _aviso('Escolha o estado');
      return;
    }
    if (cidade.isEmpty) {
      _aviso('Digite o nome da cidade');
      return;
    }

    setState(() => _buscando = true);

    List<CidadeEncontrada> resultados = [];
    String? erro;
    try {
      resultados = await ClimaService.buscarCidades(cidade);
    } on ClimaException catch (e) {
      erro = e.mensagem;
    } catch (_) {
      erro = 'Não foi possível buscar a cidade agora.';
    }

    if (!mounted) return;
    setState(() => _buscando = false);

    if (erro != null) {
      _aviso(erro);
      return;
    }

    final noEstado = resultados.where((c) => _mesmoEstado(c.estado, uf)).toList();

    if (noEstado.length == 1) {
      _confirmar(noEstado.first);
    } else if (noEstado.length > 1) {
      final escolhida = await _escolher(
        noEstado,
        'Mais de uma cidade com esse nome. Qual é a sua?',
      );
      if (escolhida != null) _confirmar(escolhida);
    } else if (resultados.isNotEmpty) {
      // achou o nome, mas em outro estado: deixa o usuário decidir
      final escolhida = await _escolher(
        resultados,
        'Não encontrei essa cidade em ${estadosBrasil[uf]}. Você quis dizer:',
      );
      if (escolhida != null) _confirmar(escolhida);
    } else {
      _aviso('Cidade não encontrada. Confira a grafia, com acentos.');
    }
  }

  Future<CidadeEncontrada?> _escolher(
      List<CidadeEncontrada> opcoes,
      String titulo,
      ) {
    return showModalBottomSheet<CidadeEncontrada>(
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
                  titulo,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            for (final c in opcoes)
              ListTile(
                leading: Icon(Icons.location_on_outlined,
                    color: Colors.green.shade800),
                title: Text(c.nome),
                subtitle: Text(c.estado ?? 'Estado não informado'),
                onTap: () => Navigator.pop(context, c),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmar(CidadeEncontrada cidade) {
    final uf = _ufDoNome(cidade.estado) ?? _uf ?? '';

    LocalizacaoService.salvar(Localizacao(
      cidade: cidade.nome,
      estado: uf,
      latitude: cidade.latitude,
      longitude: cidade.longitude,
    ));

    // Na primeira vez a aba Clima troca sozinha para a previsão.
    // Ao trocar de cidade, esta tela fecha.
    if (widget.alterando && mounted) Navigator.pop(context);
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Cabecalho(mostrarVoltar: widget.alterando),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.location_on,
                            size: 28, color: Colors.green.shade800),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.alterando
                            ? 'Trocar a cidade da fazenda'
                            : 'Onde fica a sua fazenda?',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Informe a cidade e o estado para o app mostrar a '
                            'previsão do tempo do lugar certo.',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),

                      _label('Estado'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _uf,
                            isExpanded: true,
                            hint: const Text('Selecione o estado'),
                            borderRadius: BorderRadius.circular(12),
                            icon: Icon(Icons.keyboard_arrow_down,
                                color: Colors.grey.shade600),
                            items: [
                              for (final item in estadosBrasil.entries)
                                DropdownMenuItem<String>(
                                  value: item.key,
                                  child: Text('${item.value} (${item.key})'),
                                ),
                            ],
                            onChanged: (novo) => setState(() => _uf = novo),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _label('Cidade'),
                      TextField(
                        controller: _cidadeController,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _buscarESalvar(),
                        decoration: InputDecoration(
                          hintText: 'Ex.: Morrinhos do Sul',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _buscando ? null : _buscarESalvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _buscando
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Salvar localização',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: menu(itemAtivo: 3),
    );
  }

  Widget _label(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(texto,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
    );
  }
}