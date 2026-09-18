export type CategoryId = 'A' | 'B' | 'C' | 'D' | 'E';

export const CATEGORY_IDS: CategoryId[] = ['A', 'B', 'C', 'D', 'E'];

export interface CategoryMeta {
  /** Nome legivel da categoria, ex.: "Sobre o Instituto". */
  name: string;
  /** Descricao curta (opcional), util para revisao humana. */
  description?: string;
}

export interface FaqEntry {
  /** Identificador estavel, ex.: "A01". Usado no cooldown e nos logs. */
  id: string;
  category: CategoryId;
  /** Formulacao canonica da pergunta. */
  question: string;
  /**
   * Outras formas de perguntar a mesma coisa. Cada variante e indexada
   * separadamente no matcher, entao variantes boas aumentam muito o recall.
   */
  variants?: string[];
  /** Texto exato que o bot envia no grupo (quando a categoria permite). */
  answer: string;
  tags?: string[];
}

export interface FaqData {
  version: string;
  updatedAt: string;
  categories: Record<CategoryId, CategoryMeta>;
  entries: FaqEntry[];
}

/** O que o matcher recomenda fazer com uma mensagem. */
export type Decision =
  /** Casou com categoria auto-respondivel acima do limiar. */
  | 'auto_reply'
  /** Parece pergunta de categoria restrita (B/D): avisar admins, nao responder. */
  | 'flag_admins'
  /** Nao casou com nada com confianca suficiente. */
  | 'ignore';

export interface MatchCandidate {
  entry: FaqEntry;
  /** Score final combinado, 0..1. */
  score: number;
  /** Componente lexical, 0..1. */
  lexicalScore: number;
  /** Componente semantico (embeddings), 0..1. NaN quando desabilitado. */
  semanticScore: number;
  /** Qual texto da entrada casou (pergunta canonica ou uma variante). */
  matchedText: string;
}

export interface MatchResult {
  decision: Decision;
  /** Explicacao curta e legivel da decisao — vai para o log e para os admins. */
  reason: string;
  /** Melhor candidato global, independente de categoria. */
  best: MatchCandidate | null;
  /** Melhor candidato entre as categorias restritas (B/D). */
  bestRestricted: MatchCandidate | null;
  /** Top-N candidatos, para depuracao e para a mensagem aos admins. */
  candidates: MatchCandidate[];
  /** A mensagem passou no filtro de "parece uma pergunta"? */
  looksLikeQuestion: boolean;
}
