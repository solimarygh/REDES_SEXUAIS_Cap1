/**
 * Utilitarios de normalizacao de texto para portugues brasileiro.
 *
 * O objetivo nao e NLP sofisticado: e reduzir variacoes de escrita tipicas de
 * WhatsApp (acentos omitidos, caixa alta, pontuacao, alongamento de vogais)
 * a uma forma canonica antes de comparar.
 */

/** Stopwords pt-BR. Removidas dos tokens, mas nao da comparacao por n-gramas. */
const STOPWORDS = new Set([
  'a', 'ao', 'aos', 'as', 'da', 'das', 'de', 'do', 'dos', 'e', 'em', 'na', 'nas',
  'no', 'nos', 'o', 'os', 'um', 'uma', 'uns', 'umas', 'para', 'pra', 'pro',
  'por', 'com', 'sem', 'que', 'se', 'ou', 'eu', 'voce', 'voces', 'vc', 'vcs',
  'ele', 'ela', 'eles', 'elas', 'nao', 'sim', 'ja', 'la', 'ai', 'mas', 'tambem',
  'muito', 'mais', 'menos', 'ser', 'sou', 'sao', 'esta', 'estao', 'estou',
  'ter', 'tem', 'tenho', 'foi', 'era', 'isso', 'isto', 'esse', 'essa', 'este',
  'aquilo', 'meu', 'minha', 'seu', 'sua', 'me', 'mim', 'te', 'lhe',
  'oi', 'ola', 'bom', 'boa', 'dia', 'tarde', 'noite', 'obrigado', 'obrigada',
  'gente', 'galera', 'pessoal', 'favor', 'alguem', 'sabe', 'ah', 'eh', 'ne',
]);

/**
 * Palavras que sinalizam pergunta. Usadas no filtro de "parece pergunta"
 * quando a pessoa nao usa ponto de interrogacao — o que e comum no WhatsApp.
 */
const QUESTION_CUES = [
  'qual', 'quais', 'quando', 'quanto', 'quanta', 'como', 'onde', 'quem',
  'porque', 'porquê', 'por que', 'pq', 'o que', 'oque', 'que que',
  'tem como', 'da pra', 'dá pra', 'pode', 'posso', 'podemos', 'preciso',
  'existe', 'sabem', 'saberia', 'alguem sabe', 'alguém sabe', 'duvida',
  'dúvida', 'ajuda', 'como faco', 'como faço', 'vale a pena', 'e seguro',
  'é seguro', 'e verdade', 'é verdade', 'funciona', 'serve',
];

/** Remove acentos/diacriticos. */
export function stripAccents(input: string): string {
  return input.normalize('NFD').replace(/[̀-ͯ]/g, '');
}

/**
 * Forma canonica: minusculas, sem acentos, sem pontuacao, sem emoji,
 * com vogais/consoantes alongadas colapsadas ("naooooo" -> "naoo") e
 * espacos normalizados.
 */
export function normalize(input: string): string {
  return stripAccents(input)
    .toLowerCase()
    .replace(/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}]/gu, ' ')
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/(.)\1{2,}/g, '$1$1')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Tokens de conteudo: normalizados, sem stopwords, com 2+ caracteres. */
export function tokenize(input: string): string[] {
  return normalize(input)
    .split(' ')
    .filter((t) => t.length >= 2 && !STOPWORDS.has(t));
}

/** N-gramas de caracteres sobre o texto normalizado (default: trigramas). */
export function charNgrams(input: string, n = 3): string[] {
  const padded = ` ${normalize(input)} `;
  if (padded.length <= n) return [padded];
  const grams: string[] = [];
  for (let i = 0; i <= padded.length - n; i++) {
    grams.push(padded.slice(i, i + n));
  }
  return grams;
}

/** Coeficiente de Dice entre dois multiconjuntos, tratados como conjuntos. */
export function diceCoefficient(a: string[], b: string[]): number {
  if (a.length === 0 || b.length === 0) return 0;
  const setA = new Set(a);
  const setB = new Set(b);
  let intersection = 0;
  for (const item of setA) {
    if (setB.has(item)) intersection++;
  }
  return (2 * intersection) / (setA.size + setB.size);
}

/** Cosseno entre dois vetores densos de mesmo tamanho. */
export function cosineSimilarity(a: number[], b: number[]): number {
  if (a.length !== b.length || a.length === 0) return 0;
  let dot = 0;
  let normA = 0;
  let normB = 0;
  for (let i = 0; i < a.length; i++) {
    const x = a[i] as number;
    const y = b[i] as number;
    dot += x * y;
    normA += x * x;
    normB += y * y;
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

/**
 * Heuristica de "isso parece uma pergunta?".
 *
 * Roda ANTES do matching para nao gastar chamada de embedding em cada "kkkk"
 * do grupo, e para reduzir o risco de responder a um comentario solto que por
 * acaso compartilha vocabulario com o FAQ.
 */
export function looksLikeQuestion(input: string, minLength = 12): boolean {
  const raw = input.trim();
  if (raw.length < minLength) return false;
  if (raw.includes('?')) return true;

  const normalized = normalize(raw);
  return QUESTION_CUES.some((cue) => {
    const cueNormalized = normalize(cue);
    return (
      normalized === cueNormalized ||
      normalized.startsWith(`${cueNormalized} `) ||
      normalized.includes(` ${cueNormalized} `)
    );
  });
}

/**
 * Procura termos de alto risco na mensagem e devolve os que encontrou.
 *
 * Compara sobre a forma normalizada, entao "Fluoxetina" e "fluoxetina" casam,
 * assim como "20MG" e "20 mg". Termos de uma palavra exigem limite de palavra
 * (para "mg" nao casar dentro de "imagem"); termos com espaco sao buscados
 * como subcadeia.
 */
export function findSafetyKeywords(input: string, keywords: string[]): string[] {
  if (keywords.length === 0) return [];

  const haystack = ` ${normalize(input)} `;
  const found = new Set<string>();

  for (const keyword of keywords) {
    const needle = normalize(keyword);
    if (needle === '') continue;

    const hit = needle.includes(' ')
      ? haystack.includes(needle)
      : haystack.includes(` ${needle} `);

    if (hit) found.add(keyword);
  }

  return [...found];
}
