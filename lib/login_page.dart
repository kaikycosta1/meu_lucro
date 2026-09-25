import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_data.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool modoCadastro = false;
  bool carregando = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

    String traduzirErro(String codigo) {
      switch (codigo) {
        case 'user-not-found':
          return 'Nenhuma conta encontrada com esse e-mail.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'E-mail ou senha incorretos.';
        case 'email-already-in-use':
          return 'Já existe uma conta com esse e-mail.';
        case 'weak-password':
          return 'A senha precisa ter pelo menos 6 caracteres.';
        case 'invalid-email':
          return 'Informe um e-mail válido.';
        case 'network-request-failed':
          return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
        default:
          return 'Ocorreu um erro. Tente novamente.';
      }
    }

  Future<void> recuperarSenha() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite seu e-mail no campo acima antes de continuar.'),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enviamos um link de redefinição para $email. Confira sua caixa de entrada.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(traduzirErro(e.code)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> entrarOuCadastrar() async {
    final String email = emailController.text.trim();
    final String senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o e-mail e a senha.'),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
          if (modoCadastro) {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: senha,
            );

            await FirebaseAuth.instance.currentUser?.sendEmailVerification();

            if (!mounted) return;

            await showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Confirme seu e-mail'),
                  content: Text(
                    'Enviamos um link de confirmação para $email. Você já pode usar o app normalmente, mas recomendamos confirmar seu e-mail em breve.',
                  ),
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
          } else {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: senha,
            );
          }

          await AppData.carregarDados();

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(traduzirErro(e.code)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const SizedBox(height: 20),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.savings_outlined,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Meu Lucro',
                                    textAlign: TextAlign.center,
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
                  const SizedBox(height: 48),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          modoCadastro ? 'Criar conta' : 'Entrar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                    TextField(
                                              controller: emailController,
                                              keyboardType: TextInputType.emailAddress,
                                              style: const TextStyle(color: Colors.white),
                                              decoration: InputDecoration(
                                                labelText: 'E-mail',
                                                labelStyle: const TextStyle(color: Colors.white70),
                                                filled: true,
                                                fillColor: Colors.white.withOpacity(0.12),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: Colors.white.withOpacity(0.5),
                                                  ),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(color: Colors.white),
                                                ),
                                              ),
                                            ),

                        const SizedBox(height: 16),

                       TextField(
                                                 controller: senhaController,
                                                 obscureText: true,
                                                 style: const TextStyle(color: Colors.white),
                                                 decoration: InputDecoration(
                                                   labelText: 'Senha',
                                                   labelStyle: const TextStyle(color: Colors.white70),
                                                   filled: true,
                                                   fillColor: Colors.white.withOpacity(0.12),
                                                   enabledBorder: OutlineInputBorder(
                                                     borderRadius: BorderRadius.circular(10),
                                                     borderSide: BorderSide(
                                                       color: Colors.white.withOpacity(0.5),
                                                     ),
                                                   ),
                                                   focusedBorder: OutlineInputBorder(
                                                     borderRadius: BorderRadius.circular(10),
                                                     borderSide: const BorderSide(color: Colors.white),
                                                   ),
                                                 ),
                                               ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: carregando ? null : entrarOuCadastrar,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                            ),
                            child: carregando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    modoCadastro ? 'Criar conta' : 'Entrar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                                               const SizedBox(height: 12),

                                               TextButton(
                                                 onPressed: carregando
                                                     ? null
                                                     : () {
                                                         setState(() {
                                                           modoCadastro = !modoCadastro;
                                                         });
                                                       },
                                                 child: Text(
                                                   modoCadastro
                                                       ? 'Já tem uma conta? Entrar'
                                                       : 'Não tem conta? Criar agora',
                                                   style: const TextStyle(color: Colors.white70),
                                                 ),
                                               ),

                                               if (!modoCadastro)
                                                 TextButton(
                                                   onPressed: carregando ? null : recuperarSenha,
                                                   child: const Text(
                                                     'Esqueci minha senha',
                                                     style: TextStyle(
                                                       color: Colors.white60,
                                                       fontSize: 13,
                                                     ),
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
      ),
    );
  }
}