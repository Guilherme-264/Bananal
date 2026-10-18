import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/atividade_service.dart';
import '../../model/atividade_model.dart';
import '../../widgets/cabecalho.dart';
import '../../widgets/menu.dart';
import 'cadastrarAtividade.dart';

class TelaVerAtividade extends StatefulWidget {
  final Atividade atividade;

  const TelaVerAtividade({super.key, required this.atividade});

  @override
  _TelaVerAtividadeState createState() => _TelaVerAtividadeState();
}

class _TelaVerAtividadeState extends State<TelaVerAtividade> {
  // Cópia local da atividade: é trocada pela versão nova quando ela
  // muda no Firestore (por exemplo, depois de editar ou concluir)
  late Atividade _atividade = widget.atividade;

  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    AtividadeService.atividades.addListener(_atualizar);
  }

  @override
  void dispose() {
    AtividadeService.atividades.removeListener(_atualizar);
    super.dispose();
  }

  /// Procura a versão mais nova desta atividade (pelo id) e redesenha
  void _atualizar() {
    final id = _atividade.id;
    if (id == null || !mounted) return;

    for (final a in AtividadeService.atividades.value) {
      if (a.id == id) {
        setState(() => _atividade = a);
        return;
      }
    }
  }

  // ---------- Ações ----------
  void _editar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroAtividade(atividade: _atividade),
      ),
    );
  }

  void _alternarConclusao() {
    AtividadeService.alternarConclusao(_atividade);
  }

  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir atividade'),
        content: Text(
          'Tem certeza que deseja excluir "${_atividade.nome}"? '
              'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Excluir',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      AtividadeService.remover(_atividade);
      if (mounted) Navigator.pop(context);
    }
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
            Cabecalho(mostrarVoltar: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _cardInformacoes(),
                    const SizedBox(height: 16),
                    _cardDescricao(),
                  ],
                ),
              ),
            ),
            _botoes(),
          ],
        ),
      ),
      bottomNavigationBar: menu(itemAtivo: 4),
    );
  }

  // ---------- Card "Informações da Atividade" ----------
  Widget _cardInformacoes() {
    final concluida = _atividade.concluida;

    return Container(
      width: double.infinity,
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
            'Informações da Atividade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _linhaInfo('Atividade', _atividade.nome),
          _linhaInfo('Data', _formatoData.format(_atividade.data)),
          _linhaInfo('Horário', _atividade.horario),
          const SizedBox(height: 4),

          // Estado: Pendente (verde) ou Concluída (cinza)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: concluida ? Colors.grey.shade100 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado',
                  style: TextStyle(
                    color:
                    concluida ? Colors.grey.shade700 : Colors.green.shade800,
                  ),
                ),
                Text(
                  concluida ? 'Concluída' : 'Pendente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                    concluida ? Colors.grey.shade700 : Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Uma linha "rótulo à esquerda, valor em negrito à direita"
  Widget _linhaInfo(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rotulo,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Card "Descrição" ----------
  Widget _cardDescricao() {
    final temDescricao = _atividade.descricao.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descrição',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            temDescricao ? _atividade.descricao : 'Sem descrição',
            style: TextStyle(
              fontSize: 14,
              color: temDescricao ? Colors.grey.shade800 : Colors.grey.shade500,
              fontStyle: temDescricao ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Botões de ação ----------
  Widget _botoes() {
    final concluida = _atividade.concluida;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Concluir (pendente) ou Reabrir (concluída)
          SizedBox(
            width: double.infinity,
            child: concluida
                ? OutlinedButton.icon(
              onPressed: _alternarConclusao,
              icon: Icon(Icons.undo, color: Colors.green.shade800),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.green.shade800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: Text(
                'Reabrir Atividade',
                style: TextStyle(
                    color: Colors.green.shade800, fontSize: 15),
              ),
            )
                : ElevatedButton.icon(
              onPressed: _alternarConclusao,
              icon: const Icon(Icons.check_circle_outline,
                  color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              label: const Text(
                'Marcar como Concluída',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Editar e Excluir lado a lado
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editar,
                  icon: Icon(Icons.edit_outlined, color: Colors.grey.shade800),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    'Editar',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _excluir,
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    'Excluir',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}