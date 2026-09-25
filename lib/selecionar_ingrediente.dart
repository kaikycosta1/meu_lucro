import 'package:flutter/material.dart';
import 'app_data.dart';

Future<Item?> selecionarIngrediente(
  BuildContext context,
  List<Item> itens,
) async {
  String busca = '';

  return showModalBottomSheet<Item>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateSheet) {
          final List<Item> itensFiltrados = itens.where((item) {
            return item.nome.toLowerCase().contains(busca.toLowerCase());
          }).toList();

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    const Text(
                      'Selecionar ingrediente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Pesquisar ingrediente',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (valor) {
                        setStateSheet(() {
                          busca = valor;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: itensFiltrados.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhum ingrediente encontrado',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: itensFiltrados.length,
                              itemBuilder: (context, index) {
                                final item = itensFiltrados[index];
                                return ListTile(
                                  title: Text(item.nome),
                                  subtitle: Text(
                                    'R\$ ${AppData.formatarValor(item.preco)}/${item.unidade}',
                                  ),
                                  onTap: () {
                                    Navigator.pop(context, item);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}