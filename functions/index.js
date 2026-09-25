const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {GoogleGenAI} = require("@google/genai");

const GEMINI_API_KEY = "CHAVE_REMOVIDA_POR_SEGURANCA";

exports.identificarIngrediente = onCall(
    {region: "southamerica-east1"},
    async (request) => {
      const imagemBase64 = request.data.imagem;

      if (!imagemBase64) {
        throw new HttpsError(
            "invalid-argument",
            "Nenhuma imagem foi enviada.",
        );
      }

      const ai = new GoogleGenAI({apiKey: GEMINI_API_KEY});

      const prompt = `Você está vendo uma foto de uma embalagem ou nota
fiscal de um ingrediente alimentício. Extraia as seguintes informações:
- nome: o nome do produto/ingrediente
- preco: o preço, como número decimal (ex: 6.50). Se não encontrar, use 0.
- quantidade: o peso ou volume, como número decimal (ex: 1 para 1kg).
  Se não encontrar, use 1.
- unidade: uma destas opções exatas: "unidade", "g", "kg", "ml", "L".

Responda APENAS com um JSON válido, sem texto adicional, no formato:
{"nome": "...", "preco": 0.0, "quantidade": 0.0, "unidade": "..."}`;

      try {
        const response = await ai.models.generateContent({
          model: "gemini-2.0-flash",
          contents: [
            {
              role: "user",
              parts: [
                {text: prompt},
                {
                  inlineData: {
                    mimeType: "image/jpeg",
                    data: imagemBase64,
                  },
                },
              ],
            },
          ],
        });

        const textoResposta = response.text.trim();

        const textoLimpo = textoResposta
            .replace(/```json/g, "")
            .replace(/```/g, "")
            .trim();

        const dados = JSON.parse(textoLimpo);

        return {
          nome: dados.nome || "",
          preco: Number(dados.preco) || 0,
          quantidade: Number(dados.quantidade) || 1,
          unidade: dados.unidade || "unidade",
        };
      } catch (error) {
        console.error("Erro ao chamar Gemini:", error);
        throw new HttpsError(
            "internal",
            "Não foi possível identificar o ingrediente na imagem.",
        );
      }
    },
);