import 'package:flutter/material.dart';
import '../services/venda_service.dart';
import '../model/venda_model.dart';
import '../widgets/cabecalho.dart';


class TelaCadastroVenda extends StatefulWidget {
  @override
  _TelaCadastroVendaState createState() => _TelaCadastroVendaState();
}

class _TelaCadastroVendaState extends State<TelaCadastroVenda>{
  final TextEditingController _compradorController = TextEditingController();
  final TextEditingController _pesoCaixaController = TextEditingController();
  final TextEditingController _quantidadeCaixaController = TextEditingController();
  final TextEditingController _valorCaixaController = TextEditingController();

  double _valorTotal = 0;

  void _calcularTotal() {
    final quantidade = int.tryParse(_quantidadeCaixaController.text) ?? 0;
    final valorCaixa = double.tryParse(_valorCaixaController.text) ?? 0;
    setState(() {
      _valorTotal = quantidade * valorCaixa;
    });
  }
  void _cadastrarVenda(){
    final novaVenda = Venda(
      comprador: _compradorController.text,
      pesoCaixa: int.parse(_pesoCaixaController.text),
      quantidadeCaixa: int.parse(_quantidadeCaixaController.text),
      valorCaixa: double.parse(_valorCaixaController.text),
    );
    VendaService.adicionar(novaVenda);
    Navigator.pop(context);
  }

  @override

  Widget build (BuildContext context){
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
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12, blurRadius: 8,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detalhes da Venda",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),

                        _label("Comprador"),
                        TextField(
                          controller: _compradorController,
                          decoration: _inputDecoration(),
                        ),
                        SizedBox(height: 16),

                        _label("Peso da caixa"),
                        TextField(
                          controller: _pesoCaixaController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(sufixo: "kg"),
                        ),
                        SizedBox(height: 16),

                        _label("Quantidade de caixas"),
                        TextField(
                          controller: _quantidadeCaixaController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(),
                          onChanged: (_) => _calcularTotal(),
                        ),
                        SizedBox(height: 16),
                        _label("Valor por caixa"),

                        TextField(
                          controller: _valorCaixaController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(prefixo: "R\$"),
                          onChanged: (_) => _calcularTotal(),
                        ),
                        SizedBox(height: 20),

                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                "R\$ ${_valorTotal.toStringAsFixed(2)}",
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
              SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cadastrarVenda,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade800,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Cadastrar Venda",
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
      child: Text(texto, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}