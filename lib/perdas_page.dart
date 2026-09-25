import 'package:flutter/material.dart';
import 'app_data.dart';

class PerdasPage extends StatefulWidget {
  const PerdasPage({super.key});

  @override
  State<PerdasPage> createState() => _PerdasPageState();
}

class _PerdasPageState extends State<PerdasPage> {
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController motivoController = TextEditingController();

  String tipoPerda = 'ingrediente';
  Item? ingredienteSelecionado;
  Produto? produtoSelecionado;
  String unidadeUsadaPerda = 'unidade';

  @override
  void dispose() {
    quantidadeController.dispose();
    motivoController.dispose();
    super.dispose();
  }

  List<String> unidadesCompativeis(String unidadeBase) {
    if (unidadeBase == 'kg' || unidadeBase == 'g') {
      return ['kg', 'g'];
    }
    if (unidadeBase == 'L' || unidadeBase == 'ml') {
      return ['L', 'ml'];
    }
    return ['unidade'];
  }

  void abrirFormularioPerda() {
    tipoPerda = 'ingrediente';
    ingredienteSelecionado = null;
    produtoSelecionado = null;
    unidadeUsadaPerda = 'unidade';
    quantidadeController.clear();
    motivoController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Registrar perda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Ingrediente'),
                            selected: tipoPerda == 'ingrediente',
                            onSelected: (_) {
                              setStateDialog(() {
                                tipoPerda = 'ingrediente';
                                produtoSelecionado = null;
                                quantidadeController.clear();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Produto pronto'),
                            selected: tipoPerda == 'produto',
                            onSelected: (_) {
                              setStateDialog(() {
                                tipoPerda = 'produto';
                                ingredienteSelecionado = null;
                                quantidadeController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (tipoPerda == 'ingrediente') ...[
                      if (AppData.itens.isEmpty)
                        const Text(
                          'Cadastre ingredientes antes de registrar uma perda.',
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        DropdownButtonFormField<Item>(
                          value: ingredienteSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Ingrediente',
                          ),
                          items: AppData.itens.map((item) {
                            return DropdownMenuItem<Item>(
                              value: item,
                              child: Text(item.nome),
                            );
                          }).toList(),
                          onChanged: (item) {
                            setStateDialog(() {
                              ingredienteSelecionado = item;
                              if (item != null) {
                                unidadeUsadaPerda = item.unidade;
                              }
                            });
                          },
                        ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: quantidadeController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Quantidade perdida',
                        ),
                      ),

                      if (ingredienteSelecionado != null &&
                          unidadesCompativeis(
                            ingredienteSelecionado!.unidade,
                          ).length >
                              1) ...[
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Unidade usada:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: unidadesCompativeis(
                            ingredienteSelecionado!.unidade,
                          ).map((unidade) {
                            return ChoiceChip(
                              label: Text(unidade),
                              selected: unidadeUsadaPerda == unidade,
                              onSelected: (_) {
                                setStateDialog(() {
                                  unidadeUsadaPerda = unidade;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ] else ...[
                      if (AppData.produtos.isEmpty)
                        const Text(
                          'Cadastre produtos antes de registrar uma perda.',
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        DropdownButtonFormField<Produto>(
                          value: produtoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Produto',
                          ),
                          items: AppData.produtos.map((produto) {
                            return DropdownMenuItem<Produto>(
                              value: produto,
                              child: Text(produto.nome),
                            );
                          }).toList(),
                          onChanged: (produto) {
                            setStateDialog(() {
                              produtoSelecionado = produto;
                            });
                          },
                        ),

                      if (produtoSelecionado != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Disponível: '
                          '${AppData.formatarQuantidade(produtoSelecionado!.quantidadeEstoque)} unidade(s)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],

                      const SizedBox(height: 12),

                      TextField(
                        controller: quantidadeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade perdida (unidades)',
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    TextField(
                      controller: motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo (opcional)',
                        hintText: 'Ex: estragou, queimou, quebrou...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    registrarPerda();
                  },
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void registrarPerda() {
    if (tipoPerda == 'ingrediente') {
      registrarPerdaIngrediente();
    } else {
      registrarPerdaProduto();
    }
  }

   void registrarPerdaIngrediente() {
     final double? quantidade =
         double.tryParse(quantidadeController.text.replaceAll(',', '.'));

     if (ingredienteSelecionado == null ||
         quantidade == null ||
         quantidade <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text(
             'Selecione um ingrediente e informe uma quantidade válida.',
           ),
         ),
       );
       return;
     }

     final indexEstoque = AppData.estoque.indexWhere(
       (item) =>
           item.nome.toLowerCase() ==
           ingredienteSelecionado!.nome.toLowerCase(),
     );

     if (indexEstoque == -1) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Esse ingrediente não está no estoque.'),
         ),
       );
       return;
     }

     final itemEstoque = AppData.estoque[indexEstoque];

     final double quantidadeConvertida = AppData.converterParaUnidadeBase(
       quantidade: quantidade,
       unidadeUsada: unidadeUsadaPerda,
       unidadeBase: ingredienteSelecionado!.unidade,
     );

     if (itemEstoque.quantidade < quantidadeConvertida) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(
             'Quantidade maior que o disponível em estoque. '
             'Disponível: ${AppData.formatarQuantidade(itemEstoque.quantidade)} '
             '${ingredienteSelecionado!.unidade}.',
           ),
         ),
       );
       return;
     }

     final double valorPerdido =
         quantidadeConvertida * ingredienteSelecionado!.preco;

     setState(() {
       itemEstoque.quantidade -= quantidadeConvertida;

       if (itemEstoque.quantidade.abs() < 0.000001) {
         itemEstoque.quantidade = 0;
       }

       AppData.perdas.add(
         Perda(
           nomeIngrediente: ingredienteSelecionado!.nome,
           quantidade: quantidade,
           unidade: unidadeUsadaPerda,
           motivo: motivoController.text.trim().isEmpty
               ? 'Não informado'
               : motivoController.text.trim(),
           data: DateTime.now(),
           tipo: 'ingrediente',
           valorPerdido: valorPerdido,
         ),
       );
     });

     AppData.salvarDados();

     Navigator.pop(context);

     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text(
           'Perda registrada. Prejuízo: R\$ ${AppData.formatarValor(valorPerdido)}.',
         ),
       ),
     );
   }

   void registrarPerdaProduto() {
     final double? quantidade =
         double.tryParse(quantidadeController.text.replaceAll(',', '.'));

     if (produtoSelecionado == null || quantidade == null || quantidade <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text(
             'Selecione um produto e informe uma quantidade válida.',
           ),
         ),
       );
       return;
     }

     if (produtoSelecionado!.quantidadeEstoque < quantidade) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(
             'Quantidade maior que o disponível. Disponível: '
             '${AppData.formatarQuantidade(produtoSelecionado!.quantidadeEstoque)} unidade(s).',
           ),
         ),
       );
       return;
     }

     final double valorPerdido = produtoSelecionado!.custo * quantidade;

     setState(() {
       produtoSelecionado!.quantidadeEstoque -= quantidade;

       AppData.perdas.add(
         Perda(
           nomeIngrediente: produtoSelecionado!.nome,
           quantidade: quantidade,
           unidade: 'unidade',
           motivo: motivoController.text.trim().isEmpty
               ? 'Não informado'
               : motivoController.text.trim(),
           data: DateTime.now(),
           tipo: 'produto',
           valorPerdido: valorPerdido,
         ),
       );
     });

     AppData.salvarDados();

     Navigator.pop(context);

     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text(
           'Perda registrada. Prejuízo: R\$ ${AppData.formatarValor(valorPerdido)}.',
         ),
       ),
     );
   }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} $hora:$minuto';
  }

   @override
   Widget build(BuildContext context) {
     final perdasOrdenadas = List<Perda>.from(AppData.perdas)
       ..sort((a, b) => b.data.compareTo(a.data));

     double totalPrejuizo = 0;
     for (final perda in perdasOrdenadas) {
       totalPrejuizo += perda.valorPerdido;
     }

     return Scaffold(
       appBar: AppBar(
         title: const Text('Perdas e Desperdícios'),
         backgroundColor: Colors.blueAccent,
       ),
       body: perdasOrdenadas.isEmpty
           ? const Center(
               child: Text(
                 'Nenhuma perda registrada',
                 style: TextStyle(fontSize: 18),
               ),
             )
           : Column(
               children: [
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(16),
                   color: Colors.red.withOpacity(0.08),
                   child: Column(
                     children: [
                       const Text(
                         'Prejuízo total',
                         style: TextStyle(color: Colors.grey, fontSize: 14),
                       ),
                       Text(
                         'R\$ ${AppData.formatarValor(totalPrejuizo)}',
                         style: const TextStyle(
                           fontSize: 24,
                           fontWeight: FontWeight.bold,
                           color: Colors.red,
                         ),
                       ),
                     ],
                   ),
                 ),
                 Expanded(
                   child: ListView.builder(
                     padding: const EdgeInsets.all(12),
                     itemCount: perdasOrdenadas.length,
                     itemBuilder: (context, index) {
                final perda = perdasOrdenadas[index];
                final bool ehProduto = perda.tipo == 'produto';

                             return Card(
                               margin: const EdgeInsets.only(bottom: 12),
                               child: ListTile(
                                 leading: Icon(
                                   ehProduto
                                       ? Icons.shopping_bag_outlined
                                       : Icons.inventory_2_outlined,
                                   color: ehProduto ? Colors.deepPurple : Colors.brown,
                                 ),
                                 title: Text(perda.nomeIngrediente),
                                 subtitle: Text(
                                   'Quantidade: ${AppData.formatarQuantidade(perda.quantidade)} '
                                   '${perda.unidade}\n'
                                   '${ehProduto ? "Produto pronto" : "Ingrediente"} • '
                                   'Motivo: ${perda.motivo}\n'
                                   'Data: ${formatarData(perda.data)}',
                                 ),
                                 trailing: Text(
                                   '-R\$ ${AppData.formatarValor(perda.valorPerdido)}',
                                   style: const TextStyle(
                                     color: Colors.red,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                                       );
                                           },
                                         ),
                                       ),
                                     ],
                                   ),
                             floatingActionButton: FloatingActionButton(
                               onPressed: abrirFormularioPerda,
                               backgroundColor: Colors.blueAccent,
                               child: const Icon(Icons.add),
                             ),
                           );
                         }
                       }