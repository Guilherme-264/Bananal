import 'package:flutter/material.dart';
import '../../services/venda_service.dart';
import '../../model/venda_model.dart';
import '../../widgets/cabecalho.dart';
import 'cadastrarVenda.dart';
import 'package:intl/intl.dart';

class TelaVerVenda extends StatefulWidget {
  final Venda venda;

  const TelaVerVenda({super.key, required this.venda});

  @override
  _TelaVerVendaState createState() => _TelaVerVendaState();
}

class _TelaVerVendaState extends State<TelaVerVenda> {
  // Cópia local da venda: se o usuário editar, ela é trocada pela nova
  late Venda _venda = widget.venda;

  // ---------- Formatação ----------
  final _data = DateFormat('dd/MM/yyyy');
  final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // ---------- Ações ----------
  Future<void> _editar() async {
    // A tela de cadastro devolve a venda nova quando o usuário salva
    final resultado = await Navigator.push<Venda>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaCadastroVenda(venda: _venda),
      ),
    );

    if (resultado != null) {
      setState(() => _venda = resultado);
    }
  }

  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir venda'),
        content: Text(
          'Tem certeza que deseja excluir a venda de ${_venda.comprador}? '
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
      VendaService.remover(_venda);
      if (mounted) Navigator.pop(context);
    }
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    final classificacoes = _venda.classificacoes;

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
                          'Detalhes da Venda',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _linha('Comprador', _venda.comprador),
                        _linha('Data da venda', _data.format(_venda.data)),

                        // Um bloco para cada classificação
                        for (int i = 0; i < classificacoes.length; i++)
                          _blocoClassificacao(
                            i,
                            classificacoes[i],
                            mostrarTitulo: classificacoes.length > 1,
                          ),

                        const SizedBox(height: 4),
                        _resumoTotal(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _editar,
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text(
                    'Editar Venda',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _excluir,
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.red.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    'Excluir Venda',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Bloco de UMA classificação ----------
  Widget _blocoClassificacao(
      int indice,
      Classificacao c, {
        required bool mostrarTitulo,
      }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mostrarTitulo) ...[
            Text(
              'Classificação ${indice + 1}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _linhaDupla('Peso da caixa', '${c.pesoCaixa} kg', 'Quantidade',
              '${c.quantidadeCaixa} caixas'),
          const SizedBox(height: 12),
          _linhaDupla('Valor por caixa', _moeda.format(c.valorCaixa), 'Subtotal',
              _moeda.format(c.valorTotal)),
        ],
      ),
    );
  }

  // ---------- Resumo no final: total de caixas e valor total ----------
  Widget _resumoTotal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total de caixas',
                style: TextStyle(color: Colors.green.shade800),
              ),
              Text(
                '${_venda.totalCaixas}',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor Total',
                style: TextStyle(color: Colors.green.shade800),
              ),
              Text(
                _moeda.format(_venda.valorTotal),
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Uma linha "rótulo em cima, valor embaixo"
  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Dois itens lado a lado (usado dentro do bloco de classificação)
  Widget _linhaDupla(
      String rotulo1, String valor1, String rotulo2, String valor2) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _item(rotulo1, valor1)),
        const SizedBox(width: 12),
        Expanded(child: _item(rotulo2, valor2)),
      ],
    );
  }

  Widget _item(String rotulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}