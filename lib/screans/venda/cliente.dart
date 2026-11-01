import 'package:flutter/material.dart';
import '../../model/cliente_model.dart';
import '../../services/cliente_service.dart';
import '../../widgets/cabecalho.dart';

class TelaClientes extends StatefulWidget {
  @override
  _TelaClientesState createState() => _TelaClientesState();
}

class _TelaClientesState extends State<TelaClientes> {
  @override
  void initState() {
    super.initState();
    // redesenha a tela sempre que os clientes mudarem no Firestore
    ClienteService.clientes.addListener(_atualizar);
  }

  @override
  void dispose() {
    ClienteService.clientes.removeListener(_atualizar);
    super.dispose();
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  // ---------- Ações ----------
  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  /// Janelinha para digitar o nome (serve para cadastrar e para editar)
  Future<void> _abrirFormulario([Cliente? cliente]) async {
    final controller = TextEditingController(text: cliente?.nome ?? '');

    final digitado = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cliente == null ? 'Novo cliente' : 'Editar cliente'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (valor) => Navigator.pop(context, valor),
          decoration: InputDecoration(
            labelText: 'Nome do cliente',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              'Salvar',
              style: TextStyle(color: Colors.green.shade800),
            ),
          ),
        ],
      ),
    );

    // cancelou
    if (digitado == null) return;

    final nome = digitado.trim();
    if (nome.isEmpty) {
      _aviso('Informe o nome do cliente');
      return;
    }

    // não deixa cadastrar dois clientes com o mesmo nome
    final jaExiste = ClienteService.listar().any(
          (c) => c.id != cliente?.id && c.nome.toLowerCase() == nome.toLowerCase(),
    );
    if (jaExiste) {
      _aviso('Já existe um cliente com esse nome');
      return;
    }

    if (cliente == null) {
      ClienteService.adicionar(Cliente(nome: nome));
    } else {
      ClienteService.atualizar(cliente, Cliente(nome: nome));
    }
  }

  Future<void> _confirmarExclusao(Cliente cliente) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text(
          'Tem certeza que deseja excluir "${cliente.nome}"? '
              'As vendas já cadastradas não são apagadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      ClienteService.remover(cliente);
    }
  }

  // ---------- Tela ----------
  @override
  Widget build(BuildContext context) {
    final clientes = ClienteService.listar();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Cabecalho(mostrarVoltar: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _botaoNovoCliente(),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Text(
                        'Clientes',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${clientes.length})',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (clientes.isEmpty)
                    _semClientes()
                  else
                    for (final cliente in clientes) ...[
                      _cardCliente(cliente),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Botão ----------
  Widget _botaoNovoCliente() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade800.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _abrirFormulario(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          '+ Novo cliente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ---------- Card de cliente ----------
  Widget _cardCliente(Cliente cliente) {
    // bolinha com a primeira letra do nome
    final inicial =
    cliente.nome.isEmpty ? '?' : cliente.nome.characters.first.toUpperCase();

    return InkWell(
      onTap: () => _abrirFormulario(cliente),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Text(
                inicial,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cliente.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (valor) {
                if (valor == 'editar') _abrirFormulario(cliente);
                if (valor == 'excluir') _confirmarExclusao(cliente);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(
                  value: 'excluir',
                  child: Text('Excluir',
                      style: TextStyle(color: Colors.red.shade700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Lista vazia ----------
  Widget _semClientes() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Nenhum cliente cadastrado',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}