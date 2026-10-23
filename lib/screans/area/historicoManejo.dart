import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/area_model.dart';
import '../../model/atividade_model.dart';
import '../../model/tipoManejo_model.dart';
import '../../services/atividade_service.dart';
import '../../widgets/cabecalho.dart';

/// Histórico completo: todas as atividades concluídas de uma área
class TelaHistoricoManejo extends StatelessWidget {
  final Area area;

  const TelaHistoricoManejo({super.key, required this.area});

  static final DateFormat _formatoData = DateFormat('dd/MM/yyyy');

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
              // se uma atividade mudar, a lista se atualiza sozinha
              child: ValueListenableBuilder<List<Atividade>>(
                valueListenable: AtividadeService.atividades,
                builder: (context, todas, _) {
                  final feitas = todas
                      .where((a) => a.areaId == area.id && a.concluida)
                      .toList()
                    ..sort((a, b) {
                      final porData = b.data.compareTo(a.data);
                      return porData != 0
                          ? porData
                          : b.horario.compareTo(a.horario);
                    });

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Histórico de manejo',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        area.nome,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      if (feitas.isEmpty)
                        _semHistorico()
                      else
                        for (final atividade in feitas) ...[
                          _cardAtividade(atividade),
                          const SizedBox(height: 12),
                        ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardAtividade(Atividade a) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              TipoManejo.iconeDe(a.tipo),
              color: Colors.green.shade800,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  '${a.tipo}  •  ${a.horario}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatoData.format(a.data),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _semHistorico() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Nenhuma atividade concluída nesta área',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}