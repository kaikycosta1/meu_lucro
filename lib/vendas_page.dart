import 'package:flutter/material.dart';
import 'app_data.dart';

class VendasPage extends StatefulWidget {
  const VendasPage({super.key});

  @override
  State<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage> {
  List<Venda> get vendas => AppData.vendas;
  String filtroPeriodo = 'Todas';

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year} $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
  final vendasOrdenadas = List<Venda>.from(vendas)
    ..sort((a, b) => b.data.compareTo(a.data));
    final agora = DateTime.now();

    final vendasFiltradas = vendasOrdenadas.where((venda) {
      if (filtroPeriodo == 'Hoje') {
        return venda.data.year == agora.year &&
            venda.data.month == agora.month &&
            venda.data.day == agora.day;
      }

      if (filtroPeriodo == '7 dias') {
        return venda.data.isAfter(
          agora.subtract(const Duration(days: 7)),
        );
      }

      if (filtroPeriodo == '30 dias') {
        return venda.data.isAfter(
          agora.subtract(const Duration(days: 30)),
        );
      }

      return true;
    }).toList();

double receitaFiltrada = 0;
double lucroFiltrado = 0;

for (final venda in vendasFiltradas) {
  receitaFiltrada += venda.valorVenda;
  lucroFiltrado += venda.lucro;
}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendas'),
        backgroundColor: Colors.blueAccent,
      ),
            body: vendas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhuma venda registrada',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Vá até a tela de Produtos e toque em "Vender"\npara registrar a primeira venda.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: filtroPeriodo == 'Todas',
                      onSelected: (_) {
                        setState(() {
                          filtroPeriodo = 'Todas';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Hoje'),
                      selected: filtroPeriodo == 'Hoje',
                      onSelected: (_) {
                        setState(() {
                          filtroPeriodo = 'Hoje';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('7 dias'),
                      selected: filtroPeriodo == '7 dias',
                      onSelected: (_) {
                        setState(() {
                          filtroPeriodo = '7 dias';
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('30 dias'),
                      selected: filtroPeriodo == '30 dias',
                      onSelected: (_) {
                        setState(() {
                          filtroPeriodo = '30 dias';
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                         const Text(
                           'Resumo',
                           style: TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         const SizedBox(height: 8),
                        Text(
                          'Vendas registradas: ${vendasFiltradas.length}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Receita: R\$ ${AppData.formatarValor(receitaFiltrada)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Lucro: R\$ ${AppData.formatarValor(lucroFiltrado)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: lucroFiltrado < 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: vendasFiltradas.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhuma venda neste período',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                     itemCount: vendasFiltradas.length,
                      itemBuilder: (context, index) {
                       final venda = vendasFiltradas[index];

                        return Card(
                          child: ListTile(
                            title: Text(venda.nomeProduto),
                            subtitle: Text(
                              'Quantidade: ${venda.quantidade}\n'
                              'Vendido em: ${formatarData(venda.data)}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                 'Total: R\$ ${AppData.formatarValor(venda.valorVenda)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Lucro: R\$ ${AppData.formatarValor(venda.lucro)}',
                                  style: TextStyle(
                                    color: venda.lucro < 0 ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}