import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/atividade_service.dart';
import '../../services/area_service.dart';
import '../../model/atividade_model.dart';
import '../../model/tipoManejo_model.dart';
import '../../widgets/cabecalho.dart';

class TelaCadastroAtividade extends StatefulWidget {
  final Atividade? atividade; // se vier preenchida, a tela funciona como EDIÇÃO

  const TelaCadastroAtividade({super.key, this.atividade});

  @override
  _TelaCadastroAtividadeState createState() => _TelaCadastroAtividadeState();
}

class _TelaCadastroAtividadeState extends State<TelaCadastroAtividade> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final _formatoData = DateFormat('dd/MM/yyyy');

  DateTime _data = DateTime.now();
  TimeOfDay _horario = const TimeOfDay(hour: 8, minute: 0);
  String _tipo = TipoManejo.adubacao.nome;
  String? _areaId; // null = sem área

  @override
  void initState() {
    super.initState();
    final a = widget.atividade;
    if (a != null) {
      // edição: preenche os campos com os dados da atividade
      _nomeController.text = a.nome;
      _descricaoController.text = a.descricao;
      _data = a.data;
      _areaId = a.areaId;

      // se o tipo guardado não existir mais na lista, vira "Outro"
      _tipo = TipoManejo.todos.any((t) => t.nome == a.tipo)
          ? a.tipo
          : TipoManejo.outro.nome;

      // o horário é guardado como texto "08:00"
      final partes = a.horario.split(':');
      if (partes.length == 2) {
        final hora = int.tryParse(partes[0]);
        final minuto = int.tryParse(partes[1]);
        if (hora != null && minuto != null) {
          _horario = TimeOfDay(hour: hora, minute: minuto);
        }
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // ---------- Formatação ----------
  /// TimeOfDay -> texto "08:00"
  String _horarioTexto(TimeOfDay h) {
    return '${h.hour.toString().padLeft(2, '0')}:'
        '${h.minute.toString().padLeft(2, '0')}';
  }

  // ---------- Ações ----------
  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
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
      setState(() => _data = escolhida);
    }
  }

  Future<void> _escolherHorario() async {
    final escolhido = await showTimePicker(
      context: context,
      initialTime: _horario,
      builder: (context, child) => MediaQuery(
        // relógio de 24 horas
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Colors.green.shade800),
          ),
          child: child!,
        ),
      ),
    );
    if (escolhido != null) {
      setState(() => _horario = escolhido);
    }
  }

  void _salvar() {
    // se o nome ficar vazio, usa o próprio tipo ("Adubação")
    final digitado = _nomeController.text.trim();
    final nome = digitado.isEmpty ? _tipo : digitado;

    // se a área escolhida foi apagada, a atividade fica sem área
    final areaId = AreaService.listar().any((a) => a.id == _areaId)
        ? _areaId
        : null;

    final nova = Atividade(
      nome: nome,
      descricao: _descricaoController.text.trim(),
      data: _data,
      horario: _horarioTexto(_horario),
      // na edição, mantém o estado atual (pendente ou concluída)
      concluida: widget.atividade?.concluida ?? false,
      tipo: _tipo,
      areaId: areaId,
    );

    if (widget.atividade != null) {
      AtividadeService.atualizar(widget.atividade!, nova); // edição
    } else {
      AtividadeService.adicionar(nova); // cadastro novo
    }
    Navigator.pop(context, nova);
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    final areas = AreaService.listar();

    // só mostra como escolhida uma área que ainda existe
    final areaValida = areas.any((a) => a.id == _areaId) ? _areaId : null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Cabecalho(mostrarVoltar: true),
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
                          "Detalhes da Atividade",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        _label("Tipo de manejo"),
                        _dropdown<String>(
                          value: _tipo,
                          onChanged: (novo) {
                            if (novo != null) setState(() => _tipo = novo);
                          },
                          items: [
                            for (final tipo in TipoManejo.todos)
                              DropdownMenuItem<String>(
                                value: tipo.nome,
                                child: Row(
                                  children: [
                                    Icon(tipo.icone,
                                        size: 20,
                                        color: Colors.green.shade800),
                                    const SizedBox(width: 10),
                                    Text(tipo.nome),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _label("Nome da atividade"),
                        TextField(
                          controller: _nomeController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                              dica: "Opcional (se vazio, usa o tipo)"),
                        ),
                        const SizedBox(height: 16),

                        _label("Área"),
                        _dropdown<String?>(
                          value: areaValida,
                          onChanged: (novo) => setState(() => _areaId = novo),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text("Sem área"),
                            ),
                            for (final area in areas)
                              DropdownMenuItem<String?>(
                                value: area.id,
                                child: Text(area.nome),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Data e horário lado a lado
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Data"),
                                  _campoSelecao(
                                    texto: _formatoData.format(_data),
                                    icone: Icons.calendar_today_outlined,
                                    onTap: _escolherData,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Horário"),
                                  _campoSelecao(
                                    texto: _horarioTexto(_horario),
                                    icone: Icons.access_time,
                                    onTap: _escolherHorario,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _label("Descrição"),
                        TextField(
                          controller: _descricaoController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                              dica: "Detalhes da atividade (opcional)"),
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
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.atividade != null
                        ? "Salvar Alterações"
                        : "Cadastrar Atividade",
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

  /// Lista suspensa no mesmo estilo dos campos de texto
  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  /// Caixinha clicável que mostra a data ou o horário escolhido
  Widget _campoSelecao({
    required String texto,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(texto, style: const TextStyle(fontSize: 16)),
            Icon(icone, size: 20, color: Colors.grey.shade600),
          ],
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

  InputDecoration _inputDecoration({String? dica}) {
    return InputDecoration(
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