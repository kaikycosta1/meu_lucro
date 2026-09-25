import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_data.dart';
import 'ia_service.dart';

class ItensPage extends StatefulWidget {
  const ItensPage({super.key});

  @override
  State<ItensPage> createState() => _ItensPageState();
}

class _ItensPageState extends State<ItensPage> {
  List<Item> get itens => AppData.itens;

   final TextEditingController nomeController = TextEditingController();
   final TextEditingController precoController = TextEditingController();
   final TextEditingController minimoController = TextEditingController();
 String unidadeSelecionada = 'unidade';
 String pesquisa = '';

    @override
    void dispose() {
      nomeController.dispose();
      precoController.dispose();
      minimoController.dispose();
      super.dispose();
    }

  Future<void> identificarComFoto() async {
    final ImageSource? origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (origem == null) {
      return;
    }

    final ImagePicker picker = ImagePicker();

    final XFile? foto = await picker.pickImage(
      source: origem,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (foto == null) {
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Identificando ingrediente...')),
            ],
          ),
        );
      },
    );

    final bytes = await File(foto.path).readAsBytes();
    final String imagemBase64 = base64Encode(bytes);

    final resultado = await IaService.identificarIngrediente(imagemBase64);

    if (!mounted) return;

    Navigator.pop(context);

        if (resultado == null) {
          mostrarAvisoFoto(
            'Não foi possível identificar o ingrediente. Tente novamente ou cadastre manualmente.',
          );
          return;
        }

        if (resultado.containsKey('erro')) {
          mostrarAvisoFoto(resultado['erro']);
          return;
        }

            final double precoTotal = (resultado['preco'] as num).toDouble();
            final double quantidadeEmbalagem =
                 (resultado['quantidade'] as num).toDouble();

            final double precoPorUnidadeBase = quantidadeEmbalagem > 0
                ? precoTotal / quantidadeEmbalagem
                : precoTotal;

            nomeController.text = resultado['nome'];
            precoController.text = AppData.formatarValor(precoPorUnidadeBase);
            unidadeSelecionada = resultado['unidade'];

            abrirFormulario();
         }

         void mostrarAvisoFoto(String mensagem) {
           showDialog(
             context: context,
             builder: (context) {
               return AlertDialog(
                 title: const Row(
                   children: [
                     Icon(Icons.warning_amber_rounded, color: Colors.orange),
                     SizedBox(width: 10),
                     Text('Atenção'),
                   ],
                 ),
                 content: Text(mensagem),
                 actions: [
                   ElevatedButton(
                     onPressed: () {
                       Navigator.pop(context);
                     },
                     child: const Text('OK'),
                   ),
                 ],
               );
             },
           );
         }

void confirmarExcluirIngrediente(Item item) {

final produtosUsandoIngrediente = AppData.produtos.where((produto) {
  return produto.receita.any(
    (ingrediente) =>
        ingrediente.nomeItem.toLowerCase() == item.nome.toLowerCase(),
  );
}).toList();

if (produtosUsandoIngrediente.isNotEmpty) {
  final nomesProdutos = produtosUsandoIngrediente
      .map((produto) => produto.nome)
      .join(', ');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Não dá para apagar'),
        content: Text(
          'Esse ingrediente está sendo usado em: $nomesProdutos.\n\nApague ou edite esses produtos antes.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Entendi'),
          ),
        ],
      );
    },
  );

  return;
}

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Apagar ingrediente?'),
        content: Text(
          'Deseja apagar "${item.nome}"?\n\nEle também será removido do estoque.',
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
              setState(() {
                itens.remove(item);

                AppData.estoque.removeWhere(
                  (estoqueItem) =>
                      estoqueItem.nome.toLowerCase() ==
                      item.nome.toLowerCase(),
                );
              });

              AppData.salvarDados();

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ingrediente apagado com sucesso.'),
                ),
              );
            },
            child: const Text('Apagar'),
          ),
        ],
      );
    },
  );
}

void atualizarCustosDosProdutos() {
  for (final produto in AppData.produtos) {
    double novoCusto = 0;

    for (final itemReceita in produto.receita) {
      final indexIngrediente = AppData.itens.indexWhere(
        (ingrediente) =>
            ingrediente.nome.toLowerCase() ==
            itemReceita.nomeItem.toLowerCase(),
      );

      if (indexIngrediente == -1) {
        continue;
      }

      final ingrediente = AppData.itens[indexIngrediente];

      final double quantidadeConvertida = AppData.converterParaUnidadeBase(
        quantidade: itemReceita.quantidadeUsada,
        unidadeUsada: itemReceita.unidadeUsada,
        unidadeBase: ingrediente.unidade,
      );

      novoCusto += ingrediente.preco * quantidadeConvertida;
    }

    produto.custo = novoCusto;
  }
}

void editarIngrediente(Item item) {
  final TextEditingController novoPrecoController = TextEditingController(
    text: item.preco.toString().replaceAll('.', ','),
  );

  String unidadeEditada = item.unidade;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Editar ${item.nome}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: novoPrecoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Novo preço',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: unidadeEditada,
                  decoration: const InputDecoration(
                    labelText: 'Unidade de medida',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'unidade',
                      child: Text('Unidade'),
                    ),
                    DropdownMenuItem(
                      value: 'g',
                      child: Text('Gramas (g)'),
                    ),
                    DropdownMenuItem(
                      value: 'kg',
                      child: Text('Quilos (kg)'),
                    ),
                    DropdownMenuItem(
                      value: 'ml',
                      child: Text('Mililitros (ml)'),
                    ),
                    DropdownMenuItem(
                      value: 'L',
                      child: Text('Litros (L)'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor != null) {
                      setStateDialog(() {
                        unidadeEditada = valor;
                      });
                    }
                  },
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
                  final double? novoPreco =
                      double.tryParse(novoPrecoController.text.replaceAll(',', '.'));

                  if (novoPreco == null || novoPreco <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Informe um preço válido.'),
                      ),
                    );
                    return;
                  }

final bool unidadeFoiAlterada =
    unidadeEditada != item.unidade;

final bool ingredienteEmReceita = AppData.produtos.any(
  (produto) => produto.receita.any(
    (ingrediente) =>
        ingrediente.nomeItem.toLowerCase() ==
        item.nome.toLowerCase(),
  ),
);

final itemNoEstoque = AppData.estoque.where(
  (estoqueItem) =>
      estoqueItem.nome.toLowerCase() ==
      item.nome.toLowerCase(),
);

final bool possuiEstoque =
    itemNoEstoque.isNotEmpty &&
    itemNoEstoque.first.quantidade > 0;

if (unidadeFoiAlterada &&
    (ingredienteEmReceita || possuiEstoque)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Não é possível alterar a unidade porque este ingrediente já possui estoque ou está sendo usado em uma receita.',
      ),
    ),
  );
  return;
}

                  setState(() {
                    item.preco = novoPreco;
                    item.unidade = unidadeEditada;
                  });

                  atualizarCustosDosProdutos();

                  AppData.salvarDados();

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrediente atualizado com sucesso.'),
                    ),
                  );
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );
    },
  );
}

  void adicionarItem() {
    final String nome = nomeController.text.trim();
    final double? preco =
        double.tryParse(precoController.text.replaceAll(',', '.'));

    if (nome.isEmpty || preco == null || preco <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o nome e um preço válido para o ingrediente.'),
        ),
      );
      return;
    }

final bool ingredienteJaExiste = itens.any(
  (item) => item.nome.toLowerCase() == nome.toLowerCase(),
);

if (ingredienteJaExiste) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Esse ingrediente já foi cadastrado.'),
    ),
  );
  return;
}

   setState(() {
    itens.add(
      Item(
        nome: nome,
        preco: preco,
        unidade: unidadeSelecionada,
      ),
    );

         final bool jaExisteNoEstoque = AppData.estoque.any((e) => e.nome == nome);

         if (!jaExisteNoEstoque) {
           final double minimoInformado = double.tryParse(
                 minimoController.text.replaceAll(',', '.'),
               ) ??
               1;

           AppData.estoque.add(
             ItemEstoque(
               nome: nome,
               quantidade: 0,
               minimo: minimoInformado > 0 ? minimoInformado : 1,
             ),
           );
         }
       });

       AppData.salvarDados();

       nomeController.clear();
       precoController.clear();
       minimoController.clear();
       unidadeSelecionada = 'unidade';

        Navigator.pop(context);
      }

    void abrirFormulario() {
      if (minimoController.text.isEmpty) {
        minimoController.text = '1';
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Adicionar Ingrediente'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Ingrediente',
                  ),
                ),

                TextField(
                  controller: precoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: minimoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Avisar quando o estoque chegar em',
                    helperText:
                        'Quantidade mínima antes do alerta de estoque baixo',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: unidadeSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Unidade de medida',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'unidade',
                    child: Text('Unidade'),
                  ),
                  DropdownMenuItem(
                    value: 'g',
                    child: Text('Gramas (g)'),
                  ),
                  DropdownMenuItem(
                    value: 'kg',
                    child: Text('Quilos (kg)'),
                  ),
                  DropdownMenuItem(
                    value: 'ml',
                    child: Text('Mililitros (ml)'),
                  ),
                  DropdownMenuItem(
                    value: 'L',
                    child: Text('Litros (L)'),
                  ),
                ],
                onChanged: (valor) {
                  if (valor != null) {
                    unidadeSelecionada = valor;
                  }
                },
              ),
            ],
          ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          nomeController.clear();
                          precoController.clear();
                          minimoController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: adicionarItem,
                        child: const Text('Salvar'),
                      ),
                    ],
                  );
                },
              );
            }

 @override
 Widget build(BuildContext context) {
   final itensFiltrados = itens.where((item) {
     return item.nome.toLowerCase().contains(
       pesquisa.toLowerCase(),
     );
   }).toList();

   return Scaffold(
     appBar: AppBar(
       title: const Text('Ingredientes'),
       backgroundColor: Colors.blueAccent,
     ),
     body: Column(
       children: [
         Padding(
           padding: const EdgeInsets.all(12),
           child: TextField(
             decoration: const InputDecoration(
               labelText: 'Pesquisar ingrediente',
               prefixIcon: Icon(Icons.search),
               border: OutlineInputBorder(),
             ),
             onChanged: (valor) {
               setState(() {
                 pesquisa = valor;
               });
             },
           ),
         ),
                 Expanded(
                   child: itens.isEmpty
                       ? Center(
                           child: Padding(
                             padding: const EdgeInsets.all(24),
                             child: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 const Icon(
                                   Icons.inventory_2_outlined,
                                   size: 64,
                                   color: Colors.grey,
                                 ),
                                 const SizedBox(height: 16),
                                 const Text(
                                   'Nenhum ingrediente cadastrado',
                                   style: TextStyle(
                                     fontSize: 18,
                                     fontWeight: FontWeight.bold,
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                                 const SizedBox(height: 8),
                                 const Text(
                                   'Toque no botão + para cadastrar o primeiro,\nou use a câmera para identificar um automaticamente.',
                                   style: TextStyle(fontSize: 14, color: Colors.grey),
                                   textAlign: TextAlign.center,
                                 ),
                               ],
                             ),
                           ),
                         )
                       : itensFiltrados.isEmpty
                   ? const Center(
                       child: Text(
                         'Nenhum ingrediente encontrado',
                         style: TextStyle(fontSize: 16),
                       ),
                     )
                   : ListView.builder(
                       padding: const EdgeInsets.all(12),
                       itemCount: itensFiltrados.length,
                       itemBuilder: (context, index) {
                         final item = itensFiltrados[index];

                         return Card(
                           margin: const EdgeInsets.only(bottom: 12),
                           child: ListTile(
                             title: Text(item.nome),
                             subtitle: Text(
                               'R\$ ${item.preco.toStringAsFixed(2).replaceAll('.', ',')}/${item.unidade}',
                             ),
                             trailing: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 IconButton(
                                   icon: const Icon(
                                     Icons.edit,
                                     color: Colors.blueAccent,
                                   ),
                                   onPressed: () => editarIngrediente(item),
                                 ),
                                 IconButton(
                                   icon: const Icon(
                                     Icons.delete_outline,
                                     color: Colors.red,
                                   ),
                                   onPressed: () =>
                                       confirmarExcluirIngrediente(item),
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
     floatingActionButton: Column(
       mainAxisAlignment: MainAxisAlignment.end,
       children: [
         FloatingActionButton(
           heroTag: 'botaoCamera',
           onPressed: identificarComFoto,
           backgroundColor: Colors.deepPurple,
           child: const Icon(Icons.camera_alt),
         ),
         const SizedBox(height: 12),
         FloatingActionButton(
           heroTag: 'botaoAdicionar',
           onPressed: abrirFormulario,
           backgroundColor: Colors.blueAccent,
           child: const Icon(Icons.add),
         ),
       ],
     ),
   );
 }
 }