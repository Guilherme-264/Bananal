import 'package:flutter/material.dart';
import '../../services/venda_service.dart';
import '../../model/venda_model.dart';
import '../../widgets/cabecalho.dart';

/// Guarda os 3 campos de UMA classificação (peso, quantidade e valor da caixa).
class _CamposClassificacao {
  final TextEditingController peso = TextEditingController();
  final TextEditingController quantidade = TextEditingController();
  final TextEditingController valor = TextEditingController();

  void dispose() {
    peso.dispose();
    quantidade.dispose();
    valor.dispose();
  }
}

class TelaCadastroVenda extends StatefulWidget {
  final Venda? venda; // se vier preenchida, a tela funciona como EDIÇÃO

  const TelaCadastroVenda({super.key, this.venda});

  @override
  _TelaCadastroVendaState createState() => _TelaCadastroVendaState();
}

class _TelaCadastroVendaState extends State<TelaCadastroVenda> {
  final TextEditingController _compradorController = TextEditingController();
  DateTime _dataVenda = DateTime.now();

  // Lista de classificações do formulário (sempre começa com 1)
  final List<_CamposClassificacao> _grupos = [];

  @override
  void initState() {
    super.initState();
    final v = widget.venda;

    if (v != null) {
      // EDIÇÃO: preenche os campos com os dados da venda
      _compradorController.text = v.comprador;
      _dataVenda = v.data;

      for (final c in v.classificacoes) {
        final grupo = _CamposClassificacao();
        grupo.peso.text = c.pesoCaixa.toString();
        grupo.quantidade.text = c.quantidadeCaixa.toString();
        grupo.valor.text = c.valorCaixa.toString();
        _grupos.add(grupo);
      }
    }

    // cadastro novo (ou venda sem classificação): começa com 1 grupo vazio
    if (_grupos.isEmpty) {
      _grupos.add(_CamposClassificacao());
    }
  }

  @override
  void dispose() {
    _compradorController.dispose();
    for (final g in _grupos) {
      g.dispose();
    }
    super.dispose();
  }

  // ---------- Cálculos e formatação ----------
  /// Soma de todas as classificações (quantidade x valor da caixa)
  double get _valorTotal {
    double total = 0;
    for (final g in _grupos) {
      final quantidade = int.tryParse(g.quantidade.text) ?? 0;
      final valor = double.tryParse(g.valor.text.replaceAll(',', '.')) ?? 0;
      total += quantidade * valor;
    }
    return total;
  }

  String _formatarData(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  String _moeda(num v) {
    final partes = v.toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
    );
    return 'R\$ $inteiro,${partes[1]}';
  }

  // ---------- Ações ----------
  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataVenda,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.green.shade800),
        ),
        child: child!,
      ),
    );
    if (escolhida != null) {
      setState(() => _dataVenda = escolhida);
    }
  }

  void _adicionarClassificacao() {
    setState(() => _grupos.add(_CamposClassificacao()));
  }

  void _removerClassificacao(int indice) {
    if (_grupos.length <= 1) return; // sempre fica pelo menos uma
    final removido = _grupos[indice];
    setState(() => _grupos.removeAt(indice));
    // descarta os controllers só depois que a tela foi redesenhada
    WidgetsBinding.instance.addPostFrameCallback((_) => removido.dispose());
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void _cadastrarVenda() {
    final comprador = _compradorController.text.trim();
    if (comprador.isEmpty) {
      _aviso('Informe o comprador');
      return;
    }

    // monta uma Classificacao para cada grupo do formulário
    final classificacoes = <Classificacao>[];
    for (int i = 0; i < _grupos.length; i++) {
      final g = _grupos[i];
      final peso = int.tryParse(g.peso.text);
      final quantidade = int.tryParse(g.quantidade.text);
      final valor = double.tryParse(g.valor.text.replaceAll(',', '.'));

      if (peso == null || quantidade == null || valor == null) {
        _aviso('Preencha todos os campos da classificação ${i + 1}');
        return;
      }

      classificacoes.add(Classificacao(
        pesoCaixa: peso,
        quantidadeCaixa: quantidade,
        valorCaixa: valor,
      ));
    }

    final novaVenda = Venda(
      comprador: comprador,
      data: _dataVenda,
      classificacoes: classificacoes,
    );

    if (widget.venda != null) {
      VendaService.atualizar(widget.venda!, novaVenda); // edição
    } else {
      VendaService.adicionar(novaVenda); // cadastro novo
    }
    Navigator.pop(context, novaVenda);
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Cabecalho(),
              Expanded(
                child: SingleChildScrollView(
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
                        const Text(
                          "Detalhes da Venda",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        _label("Comprador"),
                        TextField(
                          controller: _compradorController,
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 16),

                        _label("Data da venda"),
                        InkWell(
                          onTap: _escolherData,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatarData(_dataVenda),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Icon(Icons.calendar_today_outlined,
                                    size: 20, color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Um bloco de campos para cada classificação
                        for (int i = 0; i < _grupos.length; i++)
                          _blocoClassificacao(i),

                        // Botão "Adicionar classificação"
                        Center(
                          child: TextButton(
                            onPressed: _adicionarClassificacao,
                            child: Text(
                              "Adicionar classificação",
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Total de todas as classificações
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Valor Total Estimado",
                                style: TextStyle(color: Colors.green.shade800),
                              ),
                              Text(
                                _moeda(_valorTotal),
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cadastrarVenda,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.venda != null
                        ? "Salvar Alterações"
                        : "Cadastrar Venda",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Bloco de UMA classificação (peso, quantidade, valor) ----------
  Widget _blocoClassificacao(int indice) {
    final grupo = _grupos[indice];
    final temVarias = _grupos.length > 1;

    return Column(
      key: ObjectKey(grupo),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho "Classificação 2" + botão remover (só quando há várias)
        if (temVarias) ...[
          if (indice > 0) ...[
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Classificação ${indice + 1}",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              IconButton(
                onPressed: () => _removerClassificacao(indice),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                tooltip: "Remover classificação",
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        _label("Peso da caixa"),
        TextField(
          controller: grupo.peso,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(sufixo: "kg"),
        ),
        const SizedBox(height: 16),

        _label("Quantidade de caixas"),
        TextField(
          controller: grupo.quantidade,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(),
          onChanged: (_) => setState(() {}), // recalcula o total
        ),
        const SizedBox(height: 16),

        _label("Valor por caixa"),
        TextField(
          controller: grupo.valor,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration(prefixo: "R\$"),
          onChanged: (_) => setState(() {}), // recalcula o total
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _label(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(texto,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
    );
  }

  InputDecoration _inputDecoration({String? prefixo, String? sufixo}) {
    return InputDecoration(
      prefixText: prefixo != null ? "$prefixo  " : null,
      suffixText: sufixo,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}