import 'package:flutter/material.dart';
import '../../services/despesa_service.dart';
import '../../model/despesa_model.dart';
import '../../widgets/cabecalho.dart';
class TelaCadastroDespesa extends StatefulWidget {
  final Despesa? despesa; // se vier preenchida, a tela funciona como EDIÇÃO

  const TelaCadastroDespesa({super.key, this.despesa});

  @override
  _TelaCadastroDespesaState createState() => _TelaCadastroDespesaState();
}

class _TelaCadastroDespesaState extends State<TelaCadastroDespesa> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  DateTime _dataDespesa = DateTime.now();

  @override
  void initState() {
    super.initState();
    final d = widget.despesa;
    if (d != null) {
      // edição: preenche os campos com os dados da despesa
      _nomeController.text = d.nome;
      _valorController.text = d.valor.toString();
      _descricaoController.text = d.descricao;
      _dataDespesa = d.data;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // ---------- Formatação ----------
  String _formatarData(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  // ---------- Ações ----------
  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataDespesa,
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
      setState(() => _dataDespesa = escolhida);
    }
  }

  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void _cadastrarDespesa() {
    final nome = _nomeController.text.trim();
    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));

    if (nome.isEmpty) {
      _aviso('Informe o nome da despesa');
      return;
    }
    if (valor == null || valor <= 0) {
      _aviso('Informe um valor válido');
      return;
    }

    final novaDespesa = Despesa(
      nome: nome,
      valor: valor,
      descricao: _descricaoController.text.trim(),
      data: _dataDespesa,
    );

    if (widget.despesa != null) {
      novaDespesa.id = widget.despesa!.id; // mantém o mesmo id na edição
      DespesaService.atualizar(widget.despesa!, novaDespesa);
    } else {
      DespesaService.adicionar(novaDespesa);
    }
    Navigator.pop(context, novaDespesa);
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
                          "Detalhes da Despesa",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        _label("Nome da despesa"),
                        TextField(
                          controller: _nomeController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(),
                        ),
                        const SizedBox(height: 16),

                        _label("Valor"),
                        TextField(
                          controller: _valorController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: _inputDecoration(prefixo: "R\$"),
                        ),
                        const SizedBox(height: 16),

                        _label("Data da despesa"),
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
                                  _formatarData(_dataDespesa),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Icon(Icons.calendar_today_outlined,
                                    size: 20, color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        _label("Descrição"),
                        TextField(
                          controller: _descricaoController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                              dica: "Detalhes da despesa (opcional)"),
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
                  onPressed: _cadastrarDespesa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.despesa != null
                        ? "Salvar Alterações"
                        : "Cadastrar Despesa",
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

  Widget _label(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(texto,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
    );
  }

  InputDecoration _inputDecoration({String? prefixo, String? dica}) {
    return InputDecoration(
      prefixText: prefixo != null ? "$prefixo  " : null,
      hintText: dica,
      hintStyle: TextStyle(color: Colors.grey.shade400),
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