import 'package:flutter/material.dart';
import 'app_data.dart';
import 'selecionar_ingrediente.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  List<ItemEstoque> get itensEstoque => AppData.estoque;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController minimoController = TextEditingController();

  Item? ingredienteSelecionadoEstoque;

 String pesquisaEstoque = '';

  @override
  void dispose() {
    nomeController.dispose();
    quantidadeController.dispose();
    minimoController.dispose();
    super.dispose();
  }

void compreiMaisIngrediente(ItemEstoque item) {
  final TextEditingController quantidadeCompradaController =
      TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Adicionar ${item.nome} ao estoque'),
       content: Column(
         mainAxisSize: MainAxisSize.min,
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'Disponível atualmente:',
             style: TextStyle(
               fontWeight: FontWeight.bold,
             ),
           ),

           Text(
             '${AppData.formatarQuantidade(item.quantidade)} ${AppData.buscarUnidadeIngrediente(item.nome)}',
             style: const TextStyle(
               fontSize: 18,
               color: Colors.blueAccent,
             ),
           ),

           const SizedBox(height: 16),

           TextField(
             controller: quantidadeCompradaController,
             keyboardType:
                 const TextInputType.numberWithOptions(decimal: true),
             decoration: InputDecoration(
               labelText:
                   'Quantidade a adicionar (${AppData.buscarUnidadeIngrediente(item.nome)})',
             ),
           ),
         ],
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
              final double? quantidadeComprada = double.tryParse(
                quantidadeCompradaController.text.replaceAll(',', '.'),
              );

              if (quantidadeComprada == null || quantidadeComprada <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe uma quantidade válida.'),
                  ),
                );
                return;
              }

              setState(() {
                item.quantidade += quantidadeComprada;
              });

              AppData.salvarDados();

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${item.nome} atualizado no estoque. Disponível: ${AppData.formatarQuantidade(item.quantidade)} ${AppData.buscarUnidadeIngrediente(item.nome)}',
                  ),
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}

 void adicionarItemEstoque() {
   final String nome = nomeController.text.trim();
   final double quantidade = quantidadeController.text.trim().isEmpty
       ? 0
       : double.tryParse(quantidadeController.text.replaceAll(',', '.')) ??
           -1;
   final double? minimo =
       double.tryParse(minimoController.text.replaceAll(',', '.'));

   if (nome.isEmpty || minimo == null || quantidade < 0 || minimo < 0) {
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
         content: Text(
           'Informe pelo menos o ingrediente e o limite de aviso. '
           'Quantidade e limite não podem ser negativos.',
         ),
       ),
     );

     return;
   }

   setState(() {
     final indexExistente = itensEstoque.indexWhere(
       (item) => item.nome.toLowerCase() == nome.toLowerCase(),
     );

     if (indexExistente != -1) {
       itensEstoque[indexExistente].quantidade += quantidade;
       itensEstoque[indexExistente].minimo = minimo;
     } else {
       itensEstoque.add(
         ItemEstoque(
           nome: nome,
           quantidade: quantidade,
           minimo: minimo,
         ),
       );
     }
   });

   AppData.salvarDados();

   nomeController.clear();
   quantidadeController.clear();
   minimoController.clear();
   ingredienteSelecionadoEstoque = null;

   Navigator.pop(context);
 }

  void abrirFormularioEstoque() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final String unidadeAtual =
                ingredienteSelecionadoEstoque?.unidade ?? '';

            return AlertDialog(
              title: const Text('Adicionar Ingrediente ao Estoque'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () async {
                        final Item? escolhido = await selecionarIngrediente(
                          context,
                          AppData.itens,
                        );

                        if (escolhido != null) {
                          setStateDialog(() {
                            ingredienteSelecionadoEstoque = escolhido;
                            nomeController.text = escolhido.nome;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ingrediente',
                          suffixIcon: Icon(Icons.search),
                        ),
                        child: Text(
                          ingredienteSelecionadoEstoque?.nome ??
                              'Toque para selecionar',
                          style: TextStyle(
                            color: ingredienteSelecionadoEstoque == null
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: quantidadeController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: unidadeAtual.isEmpty
                            ? 'Quantidade disponível'
                            : 'Quantidade disponível ($unidadeAtual)',
                      ),
                    ),
                    TextField(
                      controller: minimoController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: unidadeAtual.isEmpty
                            ? 'Avisar quando chegar em'
                            : 'Avisar quando chegar em ($unidadeAtual)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    nomeController.clear();
                    quantidadeController.clear();
                    minimoController.clear();
                    ingredienteSelecionadoEstoque = null;

                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: adicionarItemEstoque,
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String formatarNumero(double valor) {
    if (valor == valor.toInt()) {
      return valor.toInt().toString();
    }

    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

String buscarUnidadeIngrediente(String nomeIngrediente) {
  final indexItem = AppData.itens.indexWhere(
    (item) => item.nome.toLowerCase() == nomeIngrediente.toLowerCase(),
  );

  if (indexItem != -1) {
    return AppData.itens[indexItem].unidade;
  }

  return 'unidade';
}

 @override
 Widget build(BuildContext context) {
   final estoqueOrdenado = List<ItemEstoque>.from(itensEstoque);

   estoqueOrdenado.sort((a, b) {
     if (a.estoqueBaixo == b.estoqueBaixo) {
       return a.nome.toLowerCase().compareTo(
             b.nome.toLowerCase(),
           );
     }

     return a.estoqueBaixo ? -1 : 1;
   });

   final estoqueFiltrado = estoqueOrdenado.where((item) {
     return item.nome.toLowerCase().contains(
       pesquisaEstoque.toLowerCase(),
     );
   }).toList();

   return Scaffold(

      appBar: AppBar(
        title: const Text('Estoque'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Pesquisar no estoque',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) {
                setState(() {
                  pesquisaEstoque = valor;
                });
              },
            ),
          ),

          Expanded(
            child: itensEstoque.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warehouse_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhum ingrediente no estoque',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cadastre ingredientes na tela de Ingredientes\ne depois adicione a quantidade aqui.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : estoqueFiltrado.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum ingrediente encontrado',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: estoqueFiltrado.length,
                        itemBuilder: (context, index) {
                          final item = estoqueFiltrado[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                item.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Disponível: ${AppData.formatarQuantidade(item.quantidade)} '
                                    '${AppData.buscarUnidadeIngrediente(item.nome)}',
                                  ),
                                  Text(
                                    'Avisar em: ${AppData.formatarQuantidade(item.minimo)} '
                                    '${AppData.buscarUnidadeIngrediente(item.nome)}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.estoqueBaixo
                                        ? 'Estoque baixo'
                                        : 'Estoque OK',
                                    style: TextStyle(
                                      color: item.estoqueBaixo
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  item.estoqueBaixo
                                      ? const Icon(
                                          Icons.warning,
                                          color: Colors.red,
                                        )
                                      : const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () =>
                                        compreiMaisIngrediente(item),
                                    icon: const Icon(
                                      Icons.add_shopping_cart,
                                      size: 18,
                                    ),
                                    label: const Text('Adicionar estoque'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: abrirFormularioEstoque,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}