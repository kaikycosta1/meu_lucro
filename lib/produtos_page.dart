import 'package:flutter/material.dart';
import 'app_data.dart';
import 'selecionar_ingrediente.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  List<Produto> get produtos => AppData.produtos;

  final TextEditingController nomeController = TextEditingController();
  final TextEditingController precoController = TextEditingController();
  final TextEditingController quantidadeController = TextEditingController();
  final TextEditingController rendimentoController = TextEditingController();
  final List<ItemReceita> receitaTemporaria = [];
  final TextEditingController quantidadeReceitaController = TextEditingController();
  String unidadeUsadaReceita = 'unidade';
  Item? itemSelecionadoReceita;
  String pesquisaProdutos = '';
  final Set<String> produtosExpandidos = {};

  @override
  void dispose() {
    nomeController.dispose();
    precoController.dispose();
    quantidadeController.dispose();
    rendimentoController.dispose();
    quantidadeReceitaController.dispose();
    super.dispose();
  }

double calcularCustoReceita(List<ItemReceita> receita) {
  double total = 0;

  for (final itemReceita in receita) {
    final indexItem = AppData.itens.indexWhere(
      (item) => item.nome == itemReceita.nomeItem,
    );

    if (indexItem != -1) {
      final item = AppData.itens[indexItem];

      final quantidadeConvertida = AppData.converterParaUnidadeBase(
        quantidade: itemReceita.quantidadeUsada,
        unidadeUsada: itemReceita.unidadeUsada,
        unidadeBase: item.unidade,
      );

      total += item.preco * quantidadeConvertida;
    }
  }

  return total;
}

void abrirFormularioProduto({Produto? produto}) {
  final bool editando = produto != null;

  if (editando) {
    nomeController.text = produto.nome;
    precoController.text =
        produto.precoVenda.toString().replaceAll('.', ',');
    quantidadeController.text =
        produto.quantidadeEstoque.toString().replaceAll('.', ',');
    rendimentoController.text =
        produto.rendimento.toString().replaceAll('.', ',');

    receitaTemporaria
      ..clear()
      ..addAll(
        produto.receita.map(
          (item) => ItemReceita(
            nomeItem: item.nomeItem,
            quantidadeUsada: item.quantidadeUsada,
            unidadeUsada: item.unidadeUsada,
          ),
        ),
      );
  } else {
    nomeController.clear();
    precoController.clear();
    quantidadeController.clear();
    rendimentoController.text = '1';
    receitaTemporaria.clear();
  }

  quantidadeReceitaController.clear();
  itemSelecionadoReceita = null;
  unidadeUsadaReceita = 'unidade';

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              editando ? 'Editar produto' : 'Adicionar produto',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do produto',
                    ),
                  ),

                  TextField(
                    controller: precoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Preço de venda',
                    ),
                  ),

                  TextField(
                    controller: quantidadeController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantidade pronta',
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: rendimentoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText:
                          'Rende quantas unidades essa receita? (opcional)',
                      helperText:
                          'Deixe 1 se a receita já é para 1 unidade. Ex: uma receita de bolo de pote que rende 15 potinhos.',
                    ),
                    onChanged: (valor) {
                      setStateDialog(() {});
                    },
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  const Text(
                    'Receita',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (AppData.itens.isEmpty)
                    const Text(
                      'Cadastre ingredientes antes de montar o produto.',
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    InkWell(
                      onTap: () async {
                        final Item? escolhido = await selecionarIngrediente(
                          context,
                          AppData.itens,
                        );

                        if (escolhido != null) {
                          setStateDialog(() {
                            itemSelecionadoReceita = escolhido;
                            unidadeUsadaReceita = escolhido.unidade;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ingrediente',
                          suffixIcon: Icon(Icons.search),
                        ),
                        child: Text(
                          itemSelecionadoReceita?.nome ??
                              'Toque para selecionar',
                          style: TextStyle(
                            color: itemSelecionadoReceita == null
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: quantidadeReceitaController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Quantidade usada por unidade',
                    ),
                  ),

                  if (itemSelecionadoReceita != null &&
                      unidadesCompativeis(
                        itemSelecionadoReceita!.unidade,
                      ).length >
                          1) ...[
                    const SizedBox(height: 10),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Unidade usada:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Wrap(
                      spacing: 8,
                      children: unidadesCompativeis(
                        itemSelecionadoReceita!.unidade,
                      ).map((unidade) {
                        return ChoiceChip(
                          label: Text(unidade),
                          selected: unidadeUsadaReceita == unidade,
                          onSelected: (_) {
                            setStateDialog(() {
                              unidadeUsadaReceita = unidade;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  if (itemSelecionadoReceita != null &&
                      unidadesCompativeis(
                        itemSelecionadoReceita!.unidade,
                      ).length ==
                          1) ...[
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Unidade: ${itemSelecionadoReceita!.unidade}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: () {
                      final double? quantidadeUsada = double.tryParse(
                        quantidadeReceitaController.text
                            .replaceAll(',', '.'),
                      );

                      if (itemSelecionadoReceita == null ||
                          quantidadeUsada == null ||
                          quantidadeUsada <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Selecione um ingrediente e informe uma quantidade válida.',
                            ),
                          ),
                        );
                        return;
                      }

                      final bool ingredienteJaExiste =
                          receitaTemporaria.any(
                        (item) =>
                            item.nomeItem.toLowerCase() ==
                            itemSelecionadoReceita!.nome.toLowerCase(),
                      );

                      if (ingredienteJaExiste) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Esse ingrediente já está na receita.',
                            ),
                          ),
                        );
                        return;
                      }

                      setStateDialog(() {
                        receitaTemporaria.add(
                          ItemReceita(
                            nomeItem: itemSelecionadoReceita!.nome,
                            quantidadeUsada: quantidadeUsada,
                            unidadeUsada: unidadeUsadaReceita,
                          ),
                        );

                        quantidadeReceitaController.clear();
                        itemSelecionadoReceita = null;
                        unidadeUsadaReceita = 'unidade';
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar ingrediente'),
                  ),

                  const SizedBox(height: 12),

                  if (receitaTemporaria.isEmpty)
                    const Text(
                      'Nenhum ingrediente adicionado.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...receitaTemporaria.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final ItemReceita item = entry.value;

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${item.nomeItem} — '
                          '${AppData.formatarQuantidade(item.quantidadeUsada)} '
                          '${item.unidadeUsada}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              receitaTemporaria.removeAt(index);
                            });
                          },
                        ),
                      );
                    }),

                  if (receitaTemporaria.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final double custoTotal =
                            calcularCustoReceita(receitaTemporaria);
                        final double rendimentoAtual = double.tryParse(
                              rendimentoController.text.replaceAll(',', '.'),
                            ) ??
                            1;
                        final double rendimentoValido =
                            rendimentoAtual > 0 ? rendimentoAtual : 1;
                        final double custoPorUnidade =
                            custoTotal / rendimentoValido;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custo total da receita: R\$ '
                              '${AppData.formatarValor(custoTotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (rendimentoValido > 1)
                              Text(
                                'Custo por unidade (rende ${AppData.formatarQuantidade(rendimentoValido)}): '
                                'R\$ ${AppData.formatarValor(custoPorUnidade)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              )
                            else
                              Text(
                                'Custo por unidade: R\$ '
                                '${AppData.formatarValor(custoPorUnidade)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  nomeController.clear();
                  precoController.clear();
                  quantidadeController.clear();
                  rendimentoController.clear();
                  quantidadeReceitaController.clear();
                  receitaTemporaria.clear();
                  itemSelecionadoReceita = null;
                  unidadeUsadaReceita = 'unidade';

                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),

              ElevatedButton(
                onPressed: () {
                  final String nome = nomeController.text.trim();

                  final double? preco = double.tryParse(
                    precoController.text.replaceAll(',', '.'),
                  );

                  final double? quantidade = double.tryParse(
                    quantidadeController.text.replaceAll(',', '.'),
                  );

                  if (nome.isEmpty ||
                      preco == null ||
                      preco <= 0 ||
                      quantidade == null ||
                      quantidade < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Preencha os dados do produto corretamente.',
                        ),
                      ),
                    );
                    return;
                  }

                  if (receitaTemporaria.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Adicione pelo menos um ingrediente na receita.',
                        ),
                      ),
                    );
                    return;
                  }

                  final bool nomeJaExiste = produtos.any(
                    (produtoExistente) =>
                        produtoExistente != produto &&
                        produtoExistente.nome.toLowerCase() ==
                            nome.toLowerCase(),
                  );

                  if (nomeJaExiste) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Já existe outro produto com esse nome.',
                        ),
                      ),
                    );
                    return;
                  }

                  final List<ItemReceita> receitaFinal =
                      receitaTemporaria.map((item) {
                    return ItemReceita(
                      nomeItem: item.nomeItem,
                      quantidadeUsada: item.quantidadeUsada,
                      unidadeUsada: item.unidadeUsada,
                    );
                  }).toList();

                  final double rendimentoInformado = double.tryParse(
                        rendimentoController.text.replaceAll(',', '.'),
                      ) ??
                      1;
                  final double rendimentoFinal =
                      rendimentoInformado > 0 ? rendimentoInformado : 1;

                  final double custoTotalReceita =
                      calcularCustoReceita(receitaFinal);
                  final double custoFinal =
                      custoTotalReceita / rendimentoFinal;

                  setState(() {
                    if (editando) {
                      produto.nome = nome;
                      produto.precoVenda = preco;
                      produto.quantidadeEstoque = quantidade;
                      produto.receita = receitaFinal;
                      produto.custo = custoFinal;
                      produto.rendimento = rendimentoFinal;
                    } else {
                      produtos.add(
                        Produto(
                          nome: nome,
                          custo: custoFinal,
                          precoVenda: preco,
                          quantidadeEstoque: quantidade,
                          receita: receitaFinal,
                          rendimento: rendimentoFinal,
                        ),
                      );
                    }
                  });

                  AppData.salvarDados();

                  nomeController.clear();
                  precoController.clear();
                  quantidadeController.clear();
                  rendimentoController.clear();
                  quantidadeReceitaController.clear();
                  receitaTemporaria.clear();
                  itemSelecionadoReceita = null;
                  unidadeUsadaReceita = 'unidade';

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        editando
                            ? 'Produto atualizado com sucesso.'
                            : 'Produto cadastrado com sucesso.',
                      ),
                    ),
                  );
                },
                child: Text(
                  editando ? 'Salvar alterações' : 'Salvar produto',
                ),
              ),
            ],
          );
        },
      );
    },
  );
}


void confirmarVenda(Produto produto) {
  final TextEditingController quantidadeVendaController =
      TextEditingController(text: '1');

  int quantidadeVenda = 1;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final double valorTotal =
              produto.precoVenda * quantidadeVenda;

          final double lucroTotalVenda =
              produto.lucro * quantidadeVenda;

          return AlertDialog(
            title: const Text('Registrar venda'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(produto.nome),

                  const SizedBox(height: 12),

                  Text(
                    'Disponível: '
                    '${AppData.formatarQuantidade(produto.quantidadeEstoque)}',
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: quantidadeVendaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade vendida',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (valor) {
                      final quantidade =
                          int.tryParse(valor);

                      setStateDialog(() {
                        quantidadeVenda =
                            quantidade != null && quantidade > 0
                                ? quantidade
                                : 0;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Valor total: R\$ ${AppData.formatarValor(valorTotal)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Lucro estimado: R\$ '
                    '${AppData.formatarValor(lucroTotalVenda)}',
                    style: TextStyle(
                      color: lucroTotalVenda < 0
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (quantidadeVenda >
                      produto.quantidadeEstoque) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Quantidade maior que o estoque disponível.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                onPressed: quantidadeVenda > 0 &&
                        quantidadeVenda <=
                            produto.quantidadeEstoque
                    ? () {
                        Navigator.pop(context);

                        venderProduto(
                          produto,
                          quantidadeVenda,
                        );
                      }
                    : null,
                child: const Text('Registrar'),
              ),
            ],
          );
        },
      );
    },
  );
}

void confirmarExcluirProduto(Produto produto) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Apagar produto?'),
        content: Text(
          'Deseja apagar "${produto.nome}"?',
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
                produtos.remove(produto);
              });

              AppData.salvarDados();

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Produto apagado com sucesso.'),
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

void venderProduto(Produto produto, int quantidadeVenda) {
  if (quantidadeVenda <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informe uma quantidade válida.'),
      ),
    );
    return;
  }

  if (produto.quantidadeEstoque < quantidadeVenda) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Quantidade insuficiente. Disponível: '
          '${AppData.formatarQuantidade(produto.quantidadeEstoque)}.',
        ),
      ),
    );
    return;
  }

  setState(() {
    produto.quantidadeEstoque -= quantidadeVenda;

    AppData.vendas.add(
      Venda(
        nomeProduto: produto.nome,
        quantidade: quantidadeVenda,
        valorVenda: produto.precoVenda * quantidadeVenda,
        lucro: produto.lucro * quantidadeVenda,
        data: DateTime.now(),
      ),
    );
  });

  AppData.salvarDados();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$quantidadeVenda ${quantidadeVenda == 1 ? 'unidade' : 'unidades'} '
        'de ${produto.nome} vendida${quantidadeVenda == 1 ? '' : 's'} '
        'com sucesso!',
      ),
    ),
  );
}

void registrarProducao(Produto produto) {
  final TextEditingController quantidadeProduzidaController =
      TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Registrar produção de ${produto.nome}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantidade pronta atual: '
                '${AppData.formatarQuantidade(produto.quantidadeEstoque)}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (produto.rendimento > 1)
                Text(
                  'Essa receita rende ${AppData.formatarQuantidade(produto.rendimento)} unidades por lote.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              const Text(
                'Isso vai descontar os ingredientes da receita do estoque.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantidadeProduzidaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantas unidades você fez agora?',
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
              final int? quantidadeProduzida =
                  int.tryParse(quantidadeProduzidaController.text);

              if (quantidadeProduzida == null || quantidadeProduzida <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe uma quantidade válida.'),
                  ),
                );
                return;
              }

              final double rendimentoProduto =
                  produto.rendimento > 0 ? produto.rendimento : 1;
              final double fatorProducao =
                  quantidadeProduzida / rendimentoProduto;

              for (final itemReceita in produto.receita) {
                final indexEstoque = AppData.estoque.indexWhere(
                  (item) =>
                      item.nome.toLowerCase() ==
                      itemReceita.nomeItem.toLowerCase(),
                );

                if (indexEstoque == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Item ${itemReceita.nomeItem} não encontrado no estoque.',
                      ),
                    ),
                  );
                  return;
                }

                final indexIngrediente = AppData.itens.indexWhere(
                  (item) =>
                      item.nome.toLowerCase() ==
                      itemReceita.nomeItem.toLowerCase(),
                );

                if (indexIngrediente == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ingrediente ${itemReceita.nomeItem} não encontrado.',
                      ),
                    ),
                  );
                  return;
                }

                final itemEstoque = AppData.estoque[indexEstoque];
                final ingrediente = AppData.itens[indexIngrediente];

                final quantidadeNecessaria = AppData.converterParaUnidadeBase(
                  quantidade: itemReceita.quantidadeUsada * fatorProducao,
                  unidadeUsada: itemReceita.unidadeUsada,
                  unidadeBase: ingrediente.unidade,
                );

                if (itemEstoque.quantidade < quantidadeNecessaria) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Estoque insuficiente de ${itemReceita.nomeItem}. '
                        'Disponível: ${AppData.formatarQuantidade(itemEstoque.quantidade)} '
                        '${ingrediente.unidade}.',
                      ),
                    ),
                  );
                  return;
                }
              }

              setState(() {
                for (final itemReceita in produto.receita) {
                  final itemEstoque = AppData.estoque.firstWhere(
                    (item) =>
                        item.nome.toLowerCase() ==
                        itemReceita.nomeItem.toLowerCase(),
                  );

                  final ingrediente = AppData.itens.firstWhere(
                    (item) =>
                        item.nome.toLowerCase() ==
                        itemReceita.nomeItem.toLowerCase(),
                  );

                  final quantidadeNecessaria =
                      AppData.converterParaUnidadeBase(
                    quantidade: itemReceita.quantidadeUsada * fatorProducao,
                    unidadeUsada: itemReceita.unidadeUsada,
                    unidadeBase: ingrediente.unidade,
                  );

                  itemEstoque.quantidade -= quantidadeNecessaria;

                  if (itemEstoque.quantidade.abs() < 0.000001) {
                    itemEstoque.quantidade = 0;
                  }
                }

                produto.quantidadeEstoque += quantidadeProduzida;
              });

              AppData.salvarDados();

              Navigator.pop(context);

              final ingredientesAcabando = <String>[];

              for (final itemReceita in produto.receita) {
                final itemEstoque = AppData.estoque.firstWhere(
                  (item) => item.nome == itemReceita.nomeItem,
                );

                if (itemEstoque.estoqueBaixo) {
                  ingredientesAcabando.add(itemEstoque.nome);
                }
              }

              String mensagem =
                  '$quantidadeProduzida ${produto.nome} adicionado(s) ao estoque de produção.';

              if (ingredientesAcabando.isNotEmpty) {
                mensagem +=
                    ' Atenção: ${ingredientesAcabando.join(', ')} está acabando.';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(mensagem)),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      );
    },
  );
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

  @override
  Widget build(BuildContext context) {
  final produtosFiltrados = produtos.where((produto) {
    return produto.nome.toLowerCase().contains(
      pesquisaProdutos.toLowerCase(),
    );
  }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        backgroundColor: Colors.blueAccent,
      ),
     body: Column(
       children: [
         Padding(
           padding: const EdgeInsets.all(12),
           child: TextField(
             decoration: const InputDecoration(
               labelText: 'Pesquisar produto',
               prefixIcon: Icon(Icons.search),
               border: OutlineInputBorder(),
             ),
             onChanged: (valor) {
               setState(() {
                 pesquisaProdutos = valor;
               });
             },
           ),
         ),

         Expanded(
           child: produtos.isEmpty
               ? Center(
                   child: Padding(
                     padding: const EdgeInsets.all(24),
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(
                           Icons.shopping_bag_outlined,
                           size: 64,
                           color: Colors.grey,
                         ),
                         const SizedBox(height: 16),
                         const Text(
                           'Nenhum produto cadastrado',
                           style: TextStyle(
                             fontSize: 18,
                             fontWeight: FontWeight.bold,
                           ),
                           textAlign: TextAlign.center,
                         ),
                         const SizedBox(height: 8),
                         const Text(
                           'Toque no botão + para criar o primeiro produto,\nusando os ingredientes já cadastrados.',
                           style: TextStyle(fontSize: 14, color: Colors.grey),
                           textAlign: TextAlign.center,
                         ),
                       ],
                     ),
                   ),
                 )
               : produtosFiltrados.isEmpty
                   ? const Center(
                       child: Text(
                         'Nenhum produto encontrado',
                         style: TextStyle(fontSize: 16),
                       ),
                     )
                   : ListView.builder(
                       padding: const EdgeInsets.all(12),
                       itemCount: produtosFiltrados.length,
                       itemBuilder: (context, index) {
                         final produto = produtosFiltrados[index];

                         final bool expandido =
                             produtosExpandidos.contains(produto.nome);

                         return Card(
                           margin: const EdgeInsets.only(bottom: 12),
                           child: Padding(
                             padding: const EdgeInsets.all(14),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Expanded(
                                       child: Column(
                                         crossAxisAlignment:
                                             CrossAxisAlignment.start,
                                         children: [
                                           Text(
                                             produto.nome,
                                             style: const TextStyle(
                                               fontSize: 18,
                                               fontWeight: FontWeight.bold,
                                             ),
                                           ),
                                           const SizedBox(height: 4),
                                           Text(
                                             'Quantidade pronta: '
                                             '${AppData.formatarQuantidade(produto.quantidadeEstoque)}',
                                             style: const TextStyle(
                                               color: Colors.grey,
                                             ),
                                           ),
                                           Text(
                                             'Preço: R\$ ${AppData.formatarValor(produto.precoVenda)}',
                                             style: const TextStyle(
                                               color: Colors.grey,
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                     const SizedBox(width: 12),
                                     Column(
                                       children: [
                                         SizedBox(
                                           height: 44,
                                           child: ElevatedButton.icon(
                                             onPressed:
                                                 produto.quantidadeEstoque > 0
                                                     ? () =>
                                                         confirmarVenda(produto)
                                                     : null,
                                             icon: const Icon(
                                               Icons.shopping_cart_checkout,
                                               size: 18,
                                             ),
                                             label: Text(
                                               produto.quantidadeEstoque > 0
                                                   ? 'Vender'
                                                   : 'Acabou',
                                             ),
                                             style: ElevatedButton.styleFrom(
                                               padding:
                                                   const EdgeInsets.symmetric(
                                                 horizontal: 14,
                                               ),
                                             ),
                                           ),
                                         ),
                                         const SizedBox(height: 6),
                                         SizedBox(
                                           height: 36,
                                           child: OutlinedButton.icon(
                                             onPressed: () =>
                                                 registrarProducao(produto),
                                             icon: const Icon(
                                               Icons.add_box_outlined,
                                               size: 16,
                                               color: Colors.green,
                                             ),
                                             label: const Text(
                                               'Produzir',
                                               style: TextStyle(
                                                 color: Colors.green,
                                               ),
                                             ),
                                             style: OutlinedButton.styleFrom(
                                               padding:
                                                   const EdgeInsets.symmetric(
                                                 horizontal: 10,
                                               ),
                                               side: const BorderSide(
                                                 color: Colors.green,
                                               ),
                                             ),
                                           ),
                                         ),
                                       ],
                                     ),
                                   ],
                                 ),

                                 const SizedBox(height: 8),

                                 TextButton.icon(
                                   onPressed: () {
                                     setState(() {
                                       if (expandido) {
                                         produtosExpandidos.remove(produto.nome);
                                       } else {
                                         produtosExpandidos.add(produto.nome);
                                       }
                                     });
                                   },
                                   icon: Icon(
                                     expandido
                                         ? Icons.expand_less
                                         : Icons.expand_more,
                                     size: 18,
                                   ),
                                   label: Text(
                                     expandido ? 'Ver menos' : 'Saiba mais',
                                   ),
                                   style: TextButton.styleFrom(
                                     padding: EdgeInsets.zero,
                                     minimumSize: const Size(0, 30),
                                     tapTargetSize:
                                         MaterialTapTargetSize.shrinkWrap,
                                   ),
                                 ),

                                 if (expandido) ...[
                                   const Divider(),

                                   Text(
                                     'Custo para fazer: R\$ ${AppData.formatarValor(produto.custo)}',
                                   ),
                                   Text(
                                     'Preço de venda: R\$ ${AppData.formatarValor(produto.precoVenda)}',
                                   ),
                                   Text(
                                     'Lucro por venda: R\$ ${AppData.formatarValor(produto.lucro)}',
                                     style: TextStyle(
                                       color: produto.lucro < 0
                                           ? Colors.red
                                           : Colors.green,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                   if (produto.rendimento > 1)
                                     Text(
                                       'Rende ${AppData.formatarQuantidade(produto.rendimento)} unidades por receita',
                                       style: const TextStyle(
                                           color: Colors.grey),
                                     ),

                                   const SizedBox(height: 8),

                                   const Text(
                                     'Receita',
                                     style: TextStyle(
                                       fontWeight: FontWeight.bold,
                                       fontSize: 15,
                                     ),
                                   ),

                                   if (produto.receita.isNotEmpty) ...[
                                     const SizedBox(height: 6),
                                     ...produto.receita.map((item) {
                                       return Padding(
                                         padding: const EdgeInsets.only(top: 4),
                                         child: Row(
                                           crossAxisAlignment:
                                               CrossAxisAlignment.start,
                                           children: [
                                             const Text('• '),
                                             Expanded(
                                               child: Text(
                                                 '${item.nomeItem} — '
                                                 '${AppData.formatarQuantidade(item.quantidadeUsada)} '
                                                 '${item.unidadeUsada}',
                                               ),
                                             ),
                                           ],
                                         ),
                                       );
                                     }).toList(),
                                   ],

                                   const SizedBox(height: 10),

                                   TextButton.icon(
                                     onPressed: () => abrirFormularioProduto(
                                       produto: produto,
                                     ),
                                     icon: const Icon(
                                       Icons.edit,
                                       color: Colors.blueAccent,
                                     ),
                                     label: const Text(
                                       'Editar produto',
                                       style: TextStyle(
                                         color: Colors.blueAccent,
                                       ),
                                     ),
                                   ),

                                   TextButton.icon(
                                     onPressed: () =>
                                         confirmarExcluirProduto(produto),
                                     icon: const Icon(
                                       Icons.delete_outline,
                                       color: Colors.red,
                                     ),
                                     label: const Text(
                                       'Apagar produto',
                                       style: TextStyle(
                                         color: Colors.red,
                                       ),
                                     ),
                                   ),
                                 ],
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
       onPressed: () => abrirFormularioProduto(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}