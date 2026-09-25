import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_keys.dart';

class IaService {
  static const String _apiKey = geminiApiKey;

static const List<String> _modelos = [
  'gemini-3.5-flash-lite',
];

  static String _url(String modelo) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$modelo:generateContent?key=$_apiKey';

  static Future<Map<String, dynamic>?> identificarIngrediente(
    String imagemBase64,
  ) async {
    final String prompt = '''
Você está vendo uma foto de uma embalagem, etiqueta de preço de prateleira
ou nota fiscal de um ingrediente alimentício, tirada em um supermercado.

PRIMEIRO, avalie a qualidade da foto para leitura de texto:
- Está legível (mesmo que não perfeita)? Ou está tão desfocada, escura,
  cortada ou distante que é impossível ler o nome/preço com confiança?
- A foto mostra CLARAMENTE UM produto principal? Se a foto mostra uma
  prateleira inteira ou vários produtos diferentes, sem um produto
  claramente em destaque/próximo, considere a qualidade RUIM, mesmo que
  o texto esteja legível.

Depois, extraia estas informações:
- qualidade_ok: true se der para ler o texto principal da imagem,
  false se a imagem estiver ruim demais para confiar no que foi lido.
- motivo_problema: se qualidade_ok for false, explique em UMA frase curta
  e simples, em português, o que está errado e como corrigir. Use frases
  como "A foto está desfocada. Tente firmar a mão e tirar novamente.",
  "A foto está muito longe. Aproxime mais a câmera do produto.",
  "A foto está escura. Tire em um local mais iluminado.",
  "Não é possível ver o preço na foto. Inclua a etiqueta de preço.",
  "A foto mostra vários produtos diferentes. Tire uma foto de perto,
  focando em apenas um produto por vez."
  Se qualidade_ok for true, deixe este campo como "".
- nome: nome do produto SEM a marca, de forma curta (ex: "Farinha de Trigo",
  não "Farinha de Trigo Trigolar Tipo 1 Enriquecida com Ferro").
  Deixe "" se qualidade_ok for false.
- preco: o preço à vista em reais, como número decimal (ex: 5.49).
  Se houver mais de um preço na imagem (ex: preço normal e preço promocional,
  ou preço por unidade e preço por kg), use o preço PRINCIPAL, maior e mais
  destacado na etiqueta. Se não encontrar nenhum preço, use 0.
- quantidade: o peso ou volume indicado na embalagem (ex: "1 kg" -> 1,
  "500 g" -> 500, "2 L" -> 2). Se não encontrar, use 1.
- unidade: escolha UMA destas cinco opções exatas, baseada na quantidade:
  "unidade" (para itens contados, sem peso/volume), "g" (gramas),
  "kg" (quilos), "ml" (mililitros), "L" (litros).

Exemplo de resposta para uma foto boa de "Farinha de Trigo Trigolar
Tipo 1 - 1kg" com preço de R\$ 5,49:
{"qualidade_ok": true, "motivo_problema": "", "nome": "Farinha de Trigo", "preco": 5.49, "quantidade": 1, "unidade": "kg"}

Exemplo de resposta para uma foto desfocada:
{"qualidade_ok": false, "motivo_problema": "A foto está desfocada. Tente firmar a mão e tirar novamente.", "nome": "", "preco": 0, "quantidade": 1, "unidade": "unidade"}

Exemplo de resposta para uma foto de uma prateleira inteira com vários
produtos diferentes, sem nenhum em destaque:
{"qualidade_ok": false, "motivo_problema": "A foto mostra vários produtos diferentes. Tire uma foto de perto, focando em apenas um produto por vez.", "nome": "", "preco": 0, "quantidade": 1, "unidade": "unidade"}

Responda APENAS com o JSON, sem texto adicional, sem markdown.
''';

    final body = jsonEncode({
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": imagemBase64,
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "responseMimeType": "application/json",
        "temperature": 0.2,
      }
    });

    for (final modelo in _modelos) {
      for (int tentativa = 1; tentativa <= 2; tentativa++) {
        try {
          final response = await http
              .post(
                Uri.parse(_url(modelo)),
                headers: {'Content-Type': 'application/json'},
                body: body,
              )
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 503 || response.statusCode == 429) {
            if (tentativa < 2) {
              await Future.delayed(const Duration(seconds: 3));
              continue;
            }
            break;
          }

          if (response.statusCode != 200) {
            return {
              'erro':
                  'Erro técnico (status ${response.statusCode}): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
            };
          }

          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          final List candidatos = jsonResponse['candidates'] ?? [];

          if (candidatos.isEmpty) {
            return {
              'erro': 'A IA não retornou nenhuma resposta para esta imagem.',
            };
          }

          final content = candidatos[0]['content'];
          final List partes = content != null ? (content['parts'] ?? []) : [];

          if (partes.isEmpty || partes[0]['text'] == null) {
            return {
              'erro': 'A IA retornou uma resposta vazia para esta imagem.',
            };
          }

          final String textoResposta = partes[0]['text'];

          String textoLimpo = textoResposta
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();

          final RegExp regexJson = RegExp(r'\{[\s\S]*\}');
          final match = regexJson.firstMatch(textoLimpo);

          if (match != null) {
            textoLimpo = match.group(0)!;
          }

          final Map<String, dynamic> dados = jsonDecode(textoLimpo);

          final bool qualidadeOk = dados['qualidade_ok'] == true;

          if (!qualidadeOk) {
            final String motivo =
                (dados['motivo_problema'] ?? '').toString().trim();

            return {
              'erro': motivo.isNotEmpty
                  ? motivo
                  : 'A foto não ficou boa o suficiente. Tente novamente com mais luz e foco.',
            };
          }

          final String nome = (dados['nome'] ?? '').toString().trim();
          final unidadesValidas = ['unidade', 'g', 'kg', 'ml', 'L'];
          final String unidade = unidadesValidas.contains(dados['unidade'])
              ? dados['unidade']
              : 'unidade';

          return {
            'nome': nome,
            'preco': (dados['preco'] is num) ? dados['preco'].toDouble() : 0.0,
            'quantidade': (dados['quantidade'] is num)
                ? dados['quantidade'].toDouble()
                : 1.0,
            'unidade': unidade,
          };
        } catch (e) {
          if (tentativa < 2) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        }
      }
    }

    return {
      'erro':
          'O serviço de IA está temporariamente sobrecarregado. Aguarde um momento e tente novamente, ou cadastre manualmente.',
    };
  }
}