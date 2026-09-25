import 'package:flutter/material.dart';
import 'app_data.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  String filtroPeriodo = 'Todas';

  bool _dentroDoPeriodo(DateTime data) {
    final agora = DateTime.now();

    if (filtroPeriodo == 'Hoje') {
      return data.year == agora.year &&
          data.month == agora.month &&
          data.day == agora.day;
    }

    if (filtroPeriodo == '7 dias') {
      return data.isAfter(agora.subtract(const Duration(days: 7)));
    }

    if (filtroPeriodo == '30 dias') {
      return data.isAfter(agora.subtract(const Duration(days: 30)));
    }

    return true;
  }

  List<Venda> get vendasFiltradas {
    return AppData.vendas.where((venda) => _dentroDoPeriodo(venda.data)).toList();
  }

  List<Perda> get perdasFiltradas {
    return AppData.perdas.where((perda) => _dentroDoPeriodo(perda.data)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vendas = vendasFiltradas;
    final perdas = perdasFiltradas;

    double faturamentoTotal = 0;
    double lucroTotal = 0;
    int quantidadeTotal = 0;

    final Map<String, int> quantidadePorProduto = {};
    final Map<String, double> lucroPorProduto = {};

    for (final venda in vendas) {
      faturamentoTotal += venda.valorVenda;
      lucroTotal += venda.lucro;
      quantidadeTotal += venda.quantidade;

      quantidadePorProduto[venda.nomeProduto] =
          (quantidadePorProduto[venda.nomeProduto] ?? 0) + venda.quantidade;

      lucroPorProduto[venda.nomeProduto] =
          (lucroPorProduto[venda.nomeProduto] ?? 0) + venda.lucro;
    }

    String? produtoMaisVendido;
    int maiorQuantidade = 0;

    quantidadePorProduto.forEach((nome, quantidade) {
      if (quantidade > maiorQuantidade) {
        maiorQuantidade = quantidade;
        produtoMaisVendido = nome;
      }
    });

    String? produtoMaisLucrativo;
    double maiorLucro = 0;

    lucroPorProduto.forEach((nome, lucro) {
      if (produtoMaisLucrativo == null || lucro > maiorLucro) {
        maiorLucro = lucro;
        produtoMaisLucrativo = nome;
      }
    });

    double totalPerdas = 0;
    for (final perda in perdas) {
      totalPerdas += perda.valorPerdido;
    }

    final double lucroLiquido = lucroTotal - totalPerdas;

    final bool semDadosNoPeriodo = vendas.isEmpty && perdas.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Colors.blueAccent,
      ),
      body: AppData.vendas.isEmpty && AppData.perdas.isEmpty
          ? const Center(
              child: Text(
                'Nenhum dado registrado ainda',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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

                  const SizedBox(height: 16),

                  if (semDadosNoPeriodo)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Nenhum dado neste período',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        children: [
                          if (vendas.isNotEmpty) ...[
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Resumo do período',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Quantidade vendida: $quantidadeTotal',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Faturamento: R\$ ${AppData.formatarValor(faturamentoTotal)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Lucro bruto: R\$ ${AppData.formatarValor(lucroTotal)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: lucroTotal < 0
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    if (totalPerdas > 0) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Lucro líquido (após perdas): R\$ ${AppData.formatarValor(lucroLiquido)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: lucroLiquido < 0
                                              ? Colors.red
                                              : Colors.green.shade800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (perdas.isNotEmpty) ...[
                            Card(
                              elevation: 3,
                              color: Colors.red.withOpacity(0.05),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.trending_down,
                                            color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Perdas e desperdícios',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Registros no período: ${perdas.length}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Prejuízo total: R\$ ${AppData.formatarValor(totalPerdas)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (vendas.isNotEmpty) ...[
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.emoji_events,
                                            color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text(
                                          'Produto mais vendido',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      produtoMaisVendido ?? '—',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    if (produtoMaisVendido != null)
                                      Text(
                                        '$maiorQuantidade unidades vendidas',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.trending_up,
                                            color: Colors.green),
                                        SizedBox(width: 8),
                                        Text(
                                          'Produto mais lucrativo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      produtoMaisLucrativo ?? '—',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    if (produtoMaisLucrativo != null)
                                      Text(
                                        'R\$ ${AppData.formatarValor(maiorLucro)} de lucro',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}