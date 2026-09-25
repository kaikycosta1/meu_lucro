import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

export 'models.dart';

class AppData {
  static final List<Produto> produtos = [];
  static final List<Item> itens = [];
  static final List<ItemEstoque> estoque = [];
  static final List<Venda> vendas = [];
  static final List<Perda> perdas = [];

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>>? get _documentoUsuario {
    final uid = _uid;

    if (uid == null) {
      return null;
    }

    return FirebaseFirestore.instance.collection('usuarios').doc(uid);
  }

  static Future<void> salvarDados() async {
    final documento = _documentoUsuario;

    if (documento == null) {
      return;
    }

    await documento.set({
      'produtos': produtos.map((produto) => produto.toJson()).toList(),
      'itens': itens.map((item) => item.toJson()).toList(),
      'estoque': estoque.map((item) => item.toJson()).toList(),
      'vendas': vendas.map((venda) => venda.toJson()).toList(),
      'perdas': perdas.map((perda) => perda.toJson()).toList(),
    });
  }

  static Future<void> carregarDados() async {
    limparDadosLocais();

    final documento = _documentoUsuario;

    if (documento == null) {
      return;
    }

    final snapshot = await documento.get();

    if (!snapshot.exists) {
      return;
    }

    final dados = snapshot.data();

    if (dados == null) {
      return;
    }

    if (dados['produtos'] != null) {
      produtos.addAll(
        (dados['produtos'] as List).map(
          (item) => Produto.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    }

    if (dados['itens'] != null) {
      itens.addAll(
        (dados['itens'] as List).map(
          (item) => Item.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    }

    if (dados['estoque'] != null) {
      estoque.addAll(
        (dados['estoque'] as List).map(
          (item) => ItemEstoque.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    }

    if (dados['vendas'] != null) {
      vendas.addAll(
        (dados['vendas'] as List).map(
          (item) => Venda.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    }

    if (dados['perdas'] != null) {
      perdas.addAll(
        (dados['perdas'] as List).map(
          (item) => Perda.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
    }
  }

  static void limparDadosLocais() {
    produtos.clear();
    itens.clear();
    estoque.clear();
    vendas.clear();
    perdas.clear();
  }

  static Future<void> limparDados() async {
    limparDadosLocais();

    final documento = _documentoUsuario;

    if (documento != null) {
      await documento.delete();
    }
  }

  static double converterParaUnidadeBase({
    required double quantidade,
    required String unidadeUsada,
    required String unidadeBase,
  }) {
    if (unidadeUsada == unidadeBase) {
      return quantidade;
    }

    if (unidadeUsada == 'g' && unidadeBase == 'kg') {
      return quantidade / 1000;
    }

    if (unidadeUsada == 'kg' && unidadeBase == 'g') {
      return quantidade * 1000;
    }

    if (unidadeUsada == 'ml' && unidadeBase == 'L') {
      return quantidade / 1000;
    }

    if (unidadeUsada == 'L' && unidadeBase == 'ml') {
      return quantidade * 1000;
    }

    return quantidade;
  }

  static String formatarValor(double valor) {
    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String formatarQuantidade(double valor) {
    if (valor == valor.toInt()) {
      return valor.toInt().toString();
    }

    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  static String buscarUnidadeIngrediente(String nomeIngrediente) {
    final indexItem = itens.indexWhere(
      (item) => item.nome.toLowerCase() == nomeIngrediente.toLowerCase(),
    );

    if (indexItem != -1) {
      return itens[indexItem].unidade;
    }

    return 'unidade';
  }
}