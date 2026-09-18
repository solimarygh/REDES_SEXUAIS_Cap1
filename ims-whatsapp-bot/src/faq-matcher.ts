import type { EmbeddingProvider } from './embeddings';
import {
  charNgrams,
  cosineSimilarity,
  diceCoefficient,
  findSafetyKeywords,
  looksLikeQuestion,
  normalize,
  tokenize,
} from './text';
import {
  CATEGORY_IDS,
  type CategoryId,
  type FaqData,
  type FaqEntry,
  type MatchCandidate,
  type MatchResult,
} from './types';

export interface MatcherOptions {
  /** Categorias que podem virar resposta automatica. */
  autoReplyCategories: CategoryId[];
  /** Categorias que nunca sao respondidas, apenas sinalizadas. */
  restrictedCategories: CategoryId[];
  confidenceThreshold: number;
  restrictedFlagThreshold: number;
  ambiguityMargin: number;
  minMessageLength: number;
  /** Peso do componente semantico. Ignorado quando nao ha provider. */
  semanticWeight: number;
  /**
   * Termos de alto risco que forcam sinalizacao aos admins, qualquer que seja
   * o score. Lista vazia desliga a rede de seguranca.
   */
  safetyKeywords?: string[];
  /** `null` = matching apenas lexical. */
  embeddingProvider?: EmbeddingProvider | null;
  /** Quantos candidatos retornar em `candidates`. */
  topN?: number;
}

/** Peso relativo dos dois componentes lexicais dentro do score lexical. */
const TOKEN_WEIGHT = 0.6;
const NGRAM_WEIGHT = 0.4;

/** Um texto indexado: a pergunta canonica ou uma de suas variantes. */
interface IndexedText {
  entry: FaqEntry;
  text: string;
  tokens: string[];
  ngrams: string[];
  vector: Map<string, number>;
  embedding?: number[];
}

/** Valida a forma do FAQ e lanca erro legivel quando algo esta errado. */
export function validateFaqData(data: unknown): FaqData {
  if (typeof data !== 'object' || data === null) {
    throw new Error('faq-data.json: raiz precisa ser um objeto.');
  }
  const faq = data as Partial<FaqData>;

  if (!faq.categories || typeof faq.categories !== 'object') {
    throw new Error('faq-data.json: campo "categories" ausente.');
  }
  for (const id of CATEGORY_IDS) {
    if (!faq.categories[id]?.name) {
      throw new Error(`faq-data.json: categoria "${id}" ausente ou sem "name".`);
    }
  }

  if (!Array.isArray(faq.entries) || faq.entries.length === 0) {
    throw new Error('faq-data.json: "entries" precisa ser um array nao vazio.');
  }

  const seen = new Set<string>();
  faq.entries.forEach((entry, i) => {
    const where = `faq-data.json: entries[${i}]`;
    if (!entry.id) throw new Error(`${where} sem "id".`);
    if (seen.has(entry.id)) throw new Error(`${where} tem id duplicado "${entry.id}".`);
    seen.add(entry.id);
    if (!CATEGORY_IDS.includes(entry.category)) {
      throw new Error(`${where} ("${entry.id}") tem categoria invalida "${entry.category}".`);
    }
    if (!entry.question?.trim()) throw new Error(`${where} ("${entry.id}") sem "question".`);
    if (!entry.answer?.trim()) throw new Error(`${where} ("${entry.id}") sem "answer".`);
    if (entry.variants && !Array.isArray(entry.variants)) {
      throw new Error(`${where} ("${entry.id}") tem "variants" que nao e array.`);
    }
  });

  return faq as FaqData;
}

function buildVector(tokens: string[], idf: Map<string, number>, fallbackIdf: number): Map<string, number> {
  const tf = new Map<string, number>();
  for (const token of tokens) tf.set(token, (tf.get(token) ?? 0) + 1);

  const vector = new Map<string, number>();
  for (const [term, count] of tf) {
    vector.set(term, (1 + Math.log(count)) * (idf.get(term) ?? fallbackIdf));
  }
  return vector;
}

function sparseCosine(a: Map<string, number>, b: Map<string, number>): number {
  if (a.size === 0 || b.size === 0) return 0;

  // Itera sobre o menor dos dois mapas.
  const [small, large] = a.size <= b.size ? [a, b] : [b, a];
  let dot = 0;
  for (const [term, weight] of small) {
    const other = large.get(term);
    if (other !== undefined) dot += weight * other;
  }
  if (dot === 0) return 0;

  let normA = 0;
  for (const w of a.values()) normA += w * w;
  let normB = 0;
  for (const w of b.values()) normB += w * w;

  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

export class FaqMatcher {
  private readonly texts: IndexedText[] = [];
  private readonly idf = new Map<string, number>();
  private fallbackIdf = 1;
  private initialized = false;
  private semanticEnabled = false;
  private readonly queryEmbeddingCache = new Map<string, number[]>();

  constructor(
    private readonly faq: FaqData,
    private readonly options: MatcherOptions,
  ) {
    const overlap = options.autoReplyCategories.filter((c) =>
      options.restrictedCategories.includes(c),
    );
    if (overlap.length > 0) {
      throw new Error(
        `Categoria(s) ${overlap.join(', ')} marcadas como auto-respondiveis e restritas ao mesmo tempo.`,
      );
    }

    for (const entry of faq.entries) {
      for (const text of [entry.question, ...(entry.variants ?? [])]) {
        if (!text?.trim()) continue;
        this.texts.push({
          entry,
          text,
          tokens: tokenize(text),
          ngrams: charNgrams(text),
          vector: new Map(),
        });
      }
    }

    this.buildIdf();
  }

  private buildIdf(): void {
    const documentFrequency = new Map<string, number>();
    for (const indexed of this.texts) {
      for (const term of new Set(indexed.tokens)) {
        documentFrequency.set(term, (documentFrequency.get(term) ?? 0) + 1);
      }
    }

    const total = this.texts.length;
    for (const [term, df] of documentFrequency) {
      this.idf.set(term, Math.log(1 + total / (1 + df)));
    }
    // Termo que nunca aparece no FAQ e o mais informativo possivel — e,
    // como nao casa com nada, so aumenta a norma da query (reduz o score).
    this.fallbackIdf = Math.log(1 + total);

    for (const indexed of this.texts) {
      indexed.vector = buildVector(indexed.tokens, this.idf, this.fallbackIdf);
    }
  }

  /**
   * Pre-computa os embeddings do FAQ. Obrigatorio antes do primeiro `match()`
   * quando ha provider; sem provider e um no-op barato.
   */
  async init(): Promise<void> {
    if (this.initialized) return;

    const provider = this.options.embeddingProvider;
    if (provider) {
      const vectors = await provider.embed(this.texts.map((t) => t.text));
      if (vectors.length !== this.texts.length) {
        throw new Error('Provider devolveu numero de embeddings diferente do esperado.');
      }
      this.texts.forEach((indexed, i) => {
        indexed.embedding = vectors[i];
      });
      this.semanticEnabled = true;
    }

    this.initialized = true;
  }

  get entryCount(): number {
    return this.faq.entries.length;
  }

  get indexedTextCount(): number {
    return this.texts.length;
  }

  get usesSemanticMatching(): boolean {
    return this.semanticEnabled;
  }

  private lexicalScore(
    queryVector: Map<string, number>,
    queryNgrams: string[],
    indexed: IndexedText,
  ): number {
    const tokenScore = sparseCosine(queryVector, indexed.vector);
    const ngramScore = diceCoefficient(queryNgrams, indexed.ngrams);
    return TOKEN_WEIGHT * tokenScore + NGRAM_WEIGHT * ngramScore;
  }

  private async embedQuery(message: string): Promise<number[] | null> {
    const provider = this.options.embeddingProvider;
    if (!provider || !this.semanticEnabled) return null;

    const key = normalize(message);
    const cached = this.queryEmbeddingCache.get(key);
    if (cached) return cached;

    const [vector] = await provider.embed([message]);
    if (!vector) return null;

    // Cache simples com teto, para nao crescer sem limite num grupo movimentado.
    if (this.queryEmbeddingCache.size >= 500) {
      const oldest = this.queryEmbeddingCache.keys().next().value;
      if (oldest !== undefined) this.queryEmbeddingCache.delete(oldest);
    }
    this.queryEmbeddingCache.set(key, vector);
    return vector;
  }

  /** Pontua a mensagem contra todo o FAQ, sem aplicar as regras de decisao. */
  async score(message: string): Promise<MatchCandidate[]> {
    if (!this.initialized) {
      throw new Error('FaqMatcher.init() precisa ser chamado antes de match()/score().');
    }

    const queryVector = buildVector(tokenize(message), this.idf, this.fallbackIdf);
    const queryNgrams = charNgrams(message);
    const queryEmbedding = await this.embedQuery(message);
    const weight = queryEmbedding ? this.options.semanticWeight : 0;

    // Melhor score por entrada: uma entrada casa pelo seu texto mais parecido.
    const bestByEntry = new Map<string, MatchCandidate>();

    for (const indexed of this.texts) {
      const lexical = this.lexicalScore(queryVector, queryNgrams, indexed);

      let semantic = Number.NaN;
      if (queryEmbedding && indexed.embedding) {
        // Cosseno vive em [-1, 1]; reescalado para [0, 1] para combinar com o lexical.
        semantic = (cosineSimilarity(queryEmbedding, indexed.embedding) + 1) / 2;
      }

      const combined = Number.isNaN(semantic)
        ? lexical
        : weight * semantic + (1 - weight) * lexical;

      const previous = bestByEntry.get(indexed.entry.id);
      if (!previous || combined > previous.score) {
        bestByEntry.set(indexed.entry.id, {
          entry: indexed.entry,
          score: combined,
          lexicalScore: lexical,
          semanticScore: semantic,
          matchedText: indexed.text,
        });
      }
    }

    return [...bestByEntry.values()].sort((a, b) => b.score - a.score);
  }

  /**
   * Decide o que fazer com a mensagem.
   *
   * A ordem das regras e deliberada e e a parte critica deste arquivo:
   *
   * 1. Mensagem que nao parece pergunta -> `ignore` (sem custo de embedding).
   * 2. Mensagem com termo de alto risco (`safetyKeywords`) -> `flag_admins`,
   *    qualquer que seja o score. Rede contra o ponto cego do matching lexical:
   *    nome de farmaco fora do vocabulario do FAQ pontua baixo e escaparia.
   * 3. Se algum candidato de categoria RESTRITA (B/D) passa do limiar de
   *    sinalizacao, a resposta automatica so pode sair se um candidato de
   *    categoria auto-respondivel o superar por `ambiguityMargin`. Caso
   *    contrario -> `flag_admins`. Uma entrada restrita NUNCA e respondida,
   *    por mais alto que seja o score.
   * 4. Candidato auto-respondivel acima de `confidenceThreshold` -> `auto_reply`.
   * 5. Resto -> `ignore`.
   */
  async match(message: string): Promise<MatchResult> {
    const empty: MatchResult = {
      decision: 'ignore',
      reason: '',
      best: null,
      bestRestricted: null,
      candidates: [],
      looksLikeQuestion: false,
    };

    if (!looksLikeQuestion(message, this.options.minMessageLength)) {
      return { ...empty, reason: 'Mensagem nao parece uma pergunta.' };
    }

    const ranked = await this.score(message);
    const topN = this.options.topN ?? 3;
    const best = ranked[0] ?? null;
    const bestRestricted =
      ranked.find((c) => this.options.restrictedCategories.includes(c.entry.category)) ?? null;

    const result: MatchResult = {
      decision: 'ignore',
      reason: '',
      best,
      bestRestricted,
      candidates: ranked.slice(0, topN),
      looksLikeQuestion: true,
    };

    if (!best) {
      return { ...result, reason: 'FAQ vazio: nenhum candidato.' };
    }

    // Rede de seguranca: um termo de alto risco na mensagem impede a resposta
    // automatica mesmo quando o matcher esta confiante em outra categoria.
    // Roda antes de qualquer decisao de envio, de proposito.
    const safetyHits = findSafetyKeywords(message, this.options.safetyKeywords ?? []);
    if (safetyHits.length > 0) {
      return {
        ...result,
        decision: 'flag_admins',
        reason:
          `Termo(s) de alto risco na mensagem: ${safetyHits.join(', ')}. ` +
          'Resposta automatica bloqueada; revisar manualmente. ' +
          `Melhor candidato: ${best.entry.id} [${best.entry.category}] ${best.score.toFixed(3)}.`,
      };
    }

    const restrictedHit =
      bestRestricted !== null && bestRestricted.score >= this.options.restrictedFlagThreshold;

    const autoCandidate =
      this.options.autoReplyCategories.includes(best.entry.category) &&
      best.score >= this.options.confidenceThreshold;

    if (autoCandidate) {
      const margin = restrictedHit && bestRestricted ? best.score - bestRestricted.score : Infinity;

      if (margin >= this.options.ambiguityMargin) {
        return {
          ...result,
          decision: 'auto_reply',
          reason:
            `Casou com ${best.entry.id} (categoria ${best.entry.category}) ` +
            `com score ${best.score.toFixed(3)} >= ${this.options.confidenceThreshold}.`,
        };
      }

      return {
        ...result,
        decision: 'flag_admins',
        reason:
          `Ambigua: ${best.entry.id} (${best.entry.category}, ${best.score.toFixed(3)}) esta muito ` +
          `proximo de ${bestRestricted?.entry.id} (${bestRestricted?.entry.category}, ` +
          `${bestRestricted?.score.toFixed(3)}). Margem ${margin.toFixed(3)} < ${this.options.ambiguityMargin}.`,
      };
    }

    if (restrictedHit && bestRestricted) {
      return {
        ...result,
        decision: 'flag_admins',
        reason:
          `Possivel pergunta da categoria ${bestRestricted.entry.category} ` +
          `(${this.faq.categories[bestRestricted.entry.category].name}): ` +
          `${bestRestricted.entry.id} com score ${bestRestricted.score.toFixed(3)}. Revisar.`,
      };
    }

    return {
      ...result,
      reason: `Nenhum candidato acima do limiar (melhor: ${best.entry.id} = ${best.score.toFixed(3)}).`,
    };
  }
}
