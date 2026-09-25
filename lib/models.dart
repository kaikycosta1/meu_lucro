class ItemReceita {
  String nomeItem;
  double quantidadeUsada;
  String unidadeUsada;

  ItemReceita({
    required this.nomeItem,
    required this.quantidadeUsada,
    required this.unidadeUsada,
  });

  Map<String, dynamic> toJson() {
    return {
      'nomeItem': nomeItem,
      'quantidadeUsada': quantidadeUsada,
      'unidadeUsada': unidadeUsada,
    };
  }

  factory ItemReceita.fromJson(Map<String, dynamic> json) {
    return ItemReceita(
      nomeItem: json['nomeItem'],
      quantidadeUsada: json['quantidadeUsada'],
      unidadeUsada: json['unidadeUsada'] ?? 'unidade',
    );
  }
}

class Produto {
  String nome;
  double custo;
  double precoVenda;
  double quantidadeEstoque;
  List<ItemReceita> receita;
  double rendimento;

  Produto({
    required this.nome,
    required this.custo,
    required this.precoVenda,
    required this.quantidadeEstoque,
    required this.receita,
    this.rendimento = 1,
  });

  double get lucro => precoVenda - custo;
  double get porcentagemLucro => custo > 0 ? (lucro / custo) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'custo': custo,
      'precoVenda': precoVenda,
      'quantidadeEstoque': quantidadeEstoque,
      'receita': receita.map((item) => item.toJson()).toList(),
      'rendimento': rendimento,
    };
  }

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      nome: json['nome'],
      custo: json['custo'],
      precoVenda: json['precoVenda'],
      quantidadeEstoque: json['quantidadeEstoque'],
      receita: (json['receita'] as List)
          .map((item) => ItemReceita.fromJson(item))
          .toList(),
      rendimento: (json['rendimento'] is num)
          ? (json['rendimento'] as num).toDouble()
          : 1,
    );
  }
}

class Venda {
  String nomeProduto;
  int quantidade;
  double valorVenda;
  double lucro;
  DateTime data;

  Venda({
    required this.nomeProduto,
    required this.quantidade,
    required this.valorVenda,
    required this.lucro,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'nomeProduto': nomeProduto,
      'quantidade': quantidade,
      'valorVenda': valorVenda,
      'lucro': lucro,
      'data': data.toIso8601String(),
    };
  }

  factory Venda.fromJson(Map<String, dynamic> json) {
    return Venda(
      nomeProduto: json['nomeProduto'],
      quantidade: json['quantidade'] ?? 1,
      valorVenda: json['valorVenda'],
      lucro: json['lucro'],
      data: DateTime.parse(json['data']),
    );
  }
}

class ItemEstoque {
  String nome;
  double quantidade;
  double minimo;

  ItemEstoque({
    required this.nome,
    required this.quantidade,
    required this.minimo,
  });

  bool get estoqueBaixo => quantidade <= minimo;

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'quantidade': quantidade,
      'minimo': minimo,
    };
  }

  factory ItemEstoque.fromJson(Map<String, dynamic> json) {
    return ItemEstoque(
      nome: json['nome'],
      quantidade: json['quantidade'],
      minimo: json['minimo'],
    );
  }
}

class Item {
  String nome;
  double preco;
  String unidade;

  Item({
    required this.nome,
    required this.preco,
    required this.unidade,
  });

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'preco': preco,
      'unidade': unidade,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      nome: json['nome'],
      preco: json['preco'],
      unidade: json['unidade'] ?? 'unidade',
    );
  }
}

class Perda {
  String nomeIngrediente;
  double quantidade;
  String unidade;
  String motivo;
  DateTime data;
  String tipo;
  double valorPerdido;

  Perda({
    required this.nomeIngrediente,
    required this.quantidade,
    required this.unidade,
    required this.motivo,
    required this.data,
    this.tipo = 'ingrediente',
    this.valorPerdido = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'nomeIngrediente': nomeIngrediente,
      'quantidade': quantidade,
      'unidade': unidade,
      'motivo': motivo,
      'data': data.toIso8601String(),
      'tipo': tipo,
      'valorPerdido': valorPerdido,
    };
  }

  factory Perda.fromJson(Map<String, dynamic> json) {
    return Perda(
      nomeIngrediente: json['nomeIngrediente'],
      quantidade: json['quantidade'],
      unidade: json['unidade'] ?? 'unidade',
      motivo: json['motivo'] ?? '',
      data: DateTime.parse(json['data']),
      tipo: json['tipo'] ?? 'ingrediente',
      valorPerdido: (json['valorPerdido'] is num)
          ? (json['valorPerdido'] as num).toDouble()
          : 0,
    );
  }
}