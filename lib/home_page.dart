import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_data.dart';
import 'login_page.dart';
import 'itens_page.dart';
import 'estoque_page.dart';
import 'produtos_page.dart';
import 'vendas_page.dart';
import 'relatorios_page.dart';
import 'perdas_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

bool avisoEmailFechado = false;

int get itensComEstoqueBaixo {
  return AppData.estoque.where((item) => item.estoqueBaixo).length;
}

int get totalVendas {
  return AppData.vendas.length;
}

double get faturamentoTotal {
  double total = 0;

  for (final venda in AppData.vendas) {
    total += venda.valorVenda;
  }

  return total;
}
double get lucroTotal {
  double total = 0;

  for (final venda in AppData.vendas) {
    total += venda.lucro;
  }

  return total;
}

void fazerLogout() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente para acessar seus dados.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              AppData.limparDadosLocais();
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
            child: const Text('Sair'),
          ),
        ],
      );
    },
  );
}

void confirmarLimpezaDados() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Apagar todos os dados da nuvem?'),
        content: const Text(
          'Isso vai apagar PERMANENTEMENTE produtos, ingredientes, estoque e vendas desta conta no banco de dados na nuvem. Não pode ser desfeito.\n\nUse apenas para testes, nunca durante uma demonstração real.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await AppData.limparDados();

              setState(() {});

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dados apagados com sucesso.'),
                ),
              );
            },
            child: const Text('Apagar tudo'),
          ),
        ],
      );
    },
  );
}

  Widget buildMenuCard({
     required BuildContext context,
     required IconData icon,
     required String titulo,
     required VoidCallback onTap,
     required Color cor,
   }) {
     return GestureDetector(
       onTap: onTap,
       child: Container(
         width: 150,
         height: 120,
         decoration: BoxDecoration(
           color: cor.withOpacity(0.25),
           borderRadius: BorderRadius.circular(22),
           border: Border.all(
             color: Colors.white.withOpacity(0.2),
           ),
         ),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               icon,
               size: 34,
               color: Colors.white,
             ),
             const SizedBox(height: 12),
             Text(
               titulo,
               textAlign: TextAlign.center,
               style: const TextStyle(
                 color: Colors.white,
                 fontSize: 16,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ],
         ),
       ),
     );
   }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF7B1FA2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Meu Lucro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
                              const Text(
                                'Menos esforço, mais controle',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                                             Container(
                                               padding: const EdgeInsets.symmetric(
                                                 horizontal: 14,
                                                 vertical: 6,
                                               ),
                                               decoration: BoxDecoration(
                                                 color: Colors.white.withOpacity(0.15),
                                                 borderRadius: BorderRadius.circular(20),
                                               ),
                                               child: Row(
                                                 mainAxisSize: MainAxisSize.min,
                                                 children: [
                                                   const Icon(
                                                     Icons.person_outline,
                                                     color: Colors.white70,
                                                     size: 16,
                                                   ),
                                                   const SizedBox(width: 6),
                                                   Text(
                                                     FirebaseAuth.instance.currentUser?.email ?? '',
                                                     style: const TextStyle(
                                                       color: Colors.white70,
                                                       fontSize: 13,
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                             ),

                                             if (!avisoEmailFechado &&
                                                 FirebaseAuth.instance.currentUser?.emailVerified ==
                                                     false) ...[
                                               const SizedBox(height: 12),
                                               Container(
                                                 padding: const EdgeInsets.all(12),
                                                 decoration: BoxDecoration(
                                                   color: Colors.orange.withOpacity(0.25),
                                                   borderRadius: BorderRadius.circular(12),
                                                   border: Border.all(
                                                     color: Colors.orange.withOpacity(0.5),
                                                   ),
                                                 ),
                                                 child: Column(
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     const Row(
                                                       children: [
                                                         Icon(Icons.mail_outline,
                                                             color: Colors.white, size: 18),
                                                         SizedBox(width: 6),
                                                         Expanded(
                                                           child: Text(
                                                             'Confirme seu e-mail para maior segurança da conta.',
                                                             style: TextStyle(
                                                               color: Colors.white,
                                                               fontSize: 13,
                                                             ),
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                     const SizedBox(height: 8),
                                                     Row(
                                                       mainAxisAlignment: MainAxisAlignment.end,
                                                       children: [
                                                         TextButton(
                                                           onPressed: () {
                                                             setState(() {
                                                               avisoEmailFechado = true;
                                                             });
                                                           },
                                                           child: const Text(
                                                             'Fechar',
                                                             style: TextStyle(color: Colors.white70),
                                                           ),
                                                         ),
                                                         TextButton(
                                                           onPressed: () async {
                                                             await FirebaseAuth.instance.currentUser
                                                                 ?.sendEmailVerification();

                                                             if (!mounted) return;

                                                             ScaffoldMessenger.of(context).showSnackBar(
                                                               const SnackBar(
                                                                 content: Text(
                                                                   'E-mail de confirmação reenviado.',
                                                                 ),
                                                               ),
                                                             );
                                                           },
                                                           child: const Text(
                                                             'Reenviar e-mail',
                                                             style: TextStyle(color: Colors.white),
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ],
                                                 ),
                                               ),
                                             ],

                                             const SizedBox(height: 30),
                                             const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     Row(
                       children: [
                         Icon(
                           itensComEstoqueBaixo > 0
                               ? Icons.warning_amber_rounded
                               : Icons.check_circle_outline,
                           color: Colors.white,
                         ),
                         const SizedBox(width: 10),
                         Expanded(
                           child: Text(
                             itensComEstoqueBaixo == 0
                                 ? 'Estoque em dia'
                                 : '$itensComEstoqueBaixo '
                                     '${itensComEstoqueBaixo == 1 ? 'ingrediente precisa' : 'ingredientes precisam'} '
                                     'de reposição',
                             style: const TextStyle(
                               color: Colors.white,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ),
                       ],
                     ),

                     const SizedBox(height: 12),
                     Divider(
                       color: Colors.white.withOpacity(0.35),
                       height: 1,
                     ),
                     const SizedBox(height: 12),

                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text(
                           'Vendas',
                           style: TextStyle(color: Colors.white),
                         ),
                         Text(
                           '$totalVendas',
                           style: const TextStyle(
                             color: Colors.white,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),

                     const SizedBox(height: 8),

                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text(
                           'Receita',
                           style: TextStyle(color: Colors.white),
                         ),
                         Text(
                           'R\$ ${AppData.formatarValor(faturamentoTotal)}',
                           style: const TextStyle(
                             color: Colors.white,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),

                     const SizedBox(height: 8),

                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text(
                           'Lucro',
                           style: TextStyle(color: Colors.white),
                         ),
                         Text(
                           'R\$ ${AppData.formatarValor(lucroTotal)}',
                           style: TextStyle(
                             color: lucroTotal < 0
                                 ? Colors.redAccent
                                 : Colors.white,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
                 ),

               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   buildMenuCard(
                     context: context,
                     icon: Icons.inventory_2_outlined,
                     titulo: 'Ingredientes',
                     cor: Colors.orange,
                     onTap: () async {
                       await Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const ItensPage(),
                         ),
                       );

                       setState(() {});
                     },
                   ),
                 buildMenuCard(
                                      context: context,
                                      icon: Icons.warehouse_outlined,
                                      titulo: 'Estoque',
                                      cor: Colors.green,
                     onTap: () async {
                       await Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const EstoquePage(),
                         ),
                       );

                       setState(() {});
                     },
                   ),
                 ],
               ),

               const SizedBox(height: 20),

               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   buildMenuCard(
                     context: context,
                     icon: Icons.shopping_bag_outlined,
                     titulo: 'Produtos',
                     cor: Colors.blue,
                     onTap: () async {
                       await Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const ProdutosPage(),
                         ),
                       );

                       setState(() {});
                     },
                   ),
                   buildMenuCard(
                     context: context,
                     icon: Icons.receipt_long_outlined,
                     titulo: 'Vendas',
                     cor: Colors.teal,
                     onTap: () async {
                       await Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => const VendasPage(),
                         ),
                       );

                       setState(() {});
                     },
                  ),
                                   ],
                                 ),

                                 const SizedBox(height: 20),

                                Row(
                                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                 children: [
                                                   buildMenuCard(
                                                     context: context,
                                                     icon: Icons.bar_chart,
                                                     titulo: 'Relatórios',
                                               cor: Colors.deepPurple,
                                               onTap: () async {
                                                 await Navigator.push(
                                                   context,
                                                   MaterialPageRoute(
                                                     builder: (context) => const RelatoriosPage(),
                                                   ),
                                                 );

                                                 setState(() {});
                                               },
                                             ),
                                             buildMenuCard(
                                               context: context,
                                               icon: Icons.delete_forever_outlined,
                                               titulo: 'Perdas',
                                               cor: Colors.brown,
                                               onTap: () async {
                                                 await Navigator.push(
                                                   context,
                                                   MaterialPageRoute(
                                                     builder: (context) => const PerdasPage(),
                                                   ),
                                                 );

                                                 setState(() {});
                                               },
                                             ),
                                           ],
                                         ),

                             const SizedBox(height: 20),

                              const SizedBox(height: 40),

TextButton.icon(
  onPressed: fazerLogout,
  icon: const Icon(Icons.logout, color: Colors.white70),
  label: const Text(
    'Sair da conta',
    style: TextStyle(color: Colors.white70),
  ),
),
const SizedBox(height: 8),
TextButton.icon(
  onPressed: confirmarLimpezaDados,
  icon: const Icon(Icons.delete_outline, color: Colors.white70),
  label: const Text(
    'Limpar dados de teste',
    style: TextStyle(color: Colors.white70),
  ),
),
const SizedBox(height: 8),

                const Text(
                  'Fácil e prático',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
            ],
                        ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }