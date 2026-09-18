import { describe, expect, it } from 'vitest';

import { FaqMatcher, validateFaqData, type MatcherOptions } from '../src/faq-matcher';
import type { EmbeddingProvider } from '../src/embeddings';
import { looksLikeQuestion, normalize, tokenize } from '../src/text';
import type { CategoryId, FaqData } from '../src/types';
import fixture from './fixtures/faq-test.json';

const faq: FaqData = validateFaqData(fixture);

const BASE_OPTIONS: MatcherOptions = {
  autoReplyCategories: ['A', 'C', 'E'],
  restrictedCategories: ['B', 'D'],
  confidenceThreshold: 0.75,
  restrictedFlagThreshold: 0.55,
  ambiguityMargin: 0.1,
  minMessageLength: 12,
  semanticWeight: 0.65,
  embeddingProvider: null,
  safetyKeywords: [],
  topN: 5,
};

async function makeMatcher(overrides: Partial<MatcherOptions> = {}): Promise<FaqMatcher> {
  const matcher = new FaqMatcher(faq, { ...BASE_OPTIONS, ...overrides });
  await matcher.init();
  return matcher;
}

describe('normalizacao de texto pt-BR', () => {
  it('remove acentos, pontuacao e caixa', () => {
    expect(normalize('É SEGURO?! Não sei...')).toBe('e seguro nao sei');
  });

  it('colapsa alongamento de vogais tipico de WhatsApp', () => {
    expect(normalize('naoooooo')).toBe('naoo');
  });

  it('descarta stopwords na tokenizacao', () => {
    expect(tokenize('qual é a dose de cogumelo')).toEqual(['qual', 'dose', 'cogumelo']);
  });

  it('reconhece pergunta sem ponto de interrogacao', () => {
    expect(looksLikeQuestion('alguem sabe como funciona a integracao')).toBe(true);
    expect(looksLikeQuestion('bom dia pessoal')).toBe(false);
    expect(looksLikeQuestion('kkkkk')).toBe(false);
  });
});

describe('matching semantico contra o FAQ', () => {
  it('responde parafrase de pergunta institucional (categoria A)', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match('me explica o que e esse instituto');

    expect(result.decision).toBe('auto_reply');
    expect(result.best?.entry.id).toBe('A01');
    expect(result.best?.score).toBeGreaterThanOrEqual(0.75);
  });

  it('responde pergunta de ciencia (categoria C)', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match('tem estudo cientifico sobre psilocibina pra depressao?');

    expect(result.decision).toBe('auto_reply');
    expect(result.best?.entry.id).toBe('C01');
  });

  it('responde pergunta de comunidade (categoria E)', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match('quais as regras aqui do grupo?');

    expect(result.decision).toBe('auto_reply');
    expect(result.best?.entry.category).toBe('E');
  });

  it('casa pela variante, nao so pela pergunta canonica', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match('como funciona o processo de integracao?');

    expect(result.decision).toBe('auto_reply');
    expect(result.best?.entry.id).toBe('E01');
    expect(result.best?.matchedText).toBe('Como funciona o processo de integracao?');
  });

  it('ignora conversa que nao e pergunta', async () => {
    const matcher = await makeMatcher();

    for (const message of ['bom dia pessoal', 'kkkkkkk', '👏👏👏', 'obrigada gente']) {
      const result = await matcher.match(message);
      expect(result.decision).toBe('ignore');
      expect(result.looksLikeQuestion).toBe(false);
    }
  });

  it('ignora pergunta fora do escopo do FAQ', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match('alguem sabe o horario do ultimo onibus pra Santos?');

    expect(result.decision).toBe('ignore');
  });
});

describe('regra critica: categorias restritas nunca sao auto-respondidas', () => {
  it('sinaliza pergunta de legalidade (categoria B) em vez de responder', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match('pessoal, e crime ter cogumelo aqui no Brasil?');

    expect(result.decision).toBe('flag_admins');
    expect(result.bestRestricted?.entry.category).toBe('B');
    expect(result.reason).toMatch(/B|ambigua/i);
  });

  it('sinaliza pergunta de dose (categoria D) em vez de responder', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match('qual a dose de cogumelo pra iniciante?');

    expect(result.decision).toBe('flag_admins');
    expect(result.bestRestricted?.entry.id).toBe('D01');
  });

  it('sinaliza pergunta sobre interacao com antidepressivo (categoria D)', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match('posso usar psilocibina tomando antidepressivo?');

    expect(result.decision).toBe('flag_admins');
    expect(result.bestRestricted?.entry.category).toBe('D');
  });

  it('nunca devolve auto_reply para NENHUMA entrada restrita, nem no melhor caso', async () => {
    const matcher = await makeMatcher();
    const restricted = faq.entries.filter((e) => ['B', 'D'].includes(e.category));

    expect(restricted.length).toBeGreaterThan(0);

    for (const entry of restricted) {
      for (const text of [entry.question, ...(entry.variants ?? [])]) {
        const result = await matcher.match(text);

        expect(
          result.decision,
          `"${text}" (${entry.id}, categoria ${entry.category}) nao pode ser auto-respondida`,
        ).not.toBe('auto_reply');
        expect(result.decision).toBe('flag_admins');
      }
    }
  });

  it('nao responde quando o melhor candidato restrito esta perto demais do melhor auto-respondivel', async () => {
    // Limiar baixo faz tudo casar; a margem de ambiguidade e quem segura.
    const matcher = await makeMatcher({
      confidenceThreshold: 0.01,
      restrictedFlagThreshold: 0.01,
      ambiguityMargin: 0.99,
    });
    const result = await matcher.match('o que e o Instituto Micelio Sagrado?');

    expect(result.decision).toBe('flag_admins');
    expect(result.reason).toMatch(/ambigua/i);
  });

  it('nao aceita categoria em AUTO e RESTRITA ao mesmo tempo', () => {
    expect(
      () =>
        new FaqMatcher(faq, {
          ...BASE_OPTIONS,
          autoReplyCategories: ['A', 'D'] as CategoryId[],
          restrictedCategories: ['B', 'D'] as CategoryId[],
        }),
    ).toThrow(/ao mesmo tempo/);
  });
});

describe('rede de seguranca por palavra-chave', () => {
  const SAFETY = ['fluoxetina', 'antidepressivo', 'dose', 'gramas', 'gravida'];

  /**
   * Cada uma destas e uma pergunta que um moderador precisa ver, e todas
   * escapam do matching lexical porque usam vocabulario que o FAQ nao tem
   * (nome de farmaco, estado clinico, giria de quantidade). Sem a rede de
   * seguranca elas sao ignoradas EM SILENCIO — ninguem fica sabendo.
   */
  const ESCAPAM_DO_MATCHER = [
    ['tomo fluoxetina ha anos, seria um problema?', /fluoxetina/],
    ['quantos gramas pra uma primeira vez?', /gramas/],
    ['to gravida, tem algum risco?', /gravida/],
  ] as const;

  it.each(ESCAPAM_DO_MATCHER)(
    'sinaliza "%s", que o matcher sozinho ignoraria',
    async (pergunta, termo) => {
      const semRede = await makeMatcher();
      expect(
        (await semRede.match(pergunta)).decision,
        'premissa do teste: sem a rede esta pergunta passa batido',
      ).toBe('ignore');

      const comRede = await makeMatcher({ safetyKeywords: SAFETY });
      const result = await comRede.match(pergunta);

      expect(result.decision).toBe('flag_admins');
      expect(result.reason).toMatch(termo);
    },
  );

  it('bloqueia a resposta automatica mesmo com match forte em categoria liberada', async () => {
    const matcher = await makeMatcher({ safetyKeywords: SAFETY });
    const result = await matcher.match(
      'quais as regras aqui do grupo sobre dose?',
    );

    expect(result.decision).toBe('flag_admins');
    expect(result.reason).toMatch(/alto risco/);
  });

  it('nao dispara em pergunta institucional inofensiva', async () => {
    const matcher = await makeMatcher({ safetyKeywords: SAFETY });
    const result = await matcher.match('me explica o que e esse instituto');

    expect(result.decision).toBe('auto_reply');
  });

  it('casa ignorando acento e caixa', async () => {
    const matcher = await makeMatcher({ safetyKeywords: ['gravida'] });
    const result = await matcher.match('sou GRÁVIDA, o que a ciencia diz sobre isso?');

    expect(result.decision).toBe('flag_admins');
  });

  it('exige limite de palavra: nao casa termo curto dentro de outra palavra', async () => {
    const matcher = await makeMatcher({ safetyKeywords: ['mg'] });
    const result = await matcher.match('me explica o que e esse instituto');

    expect(result.decision).toBe('auto_reply');
  });

  it('lista vazia desliga a rede', async () => {
    const matcher = await makeMatcher({ safetyKeywords: [] });
    const result = await matcher.match('me explica o que e esse instituto');

    expect(result.decision).toBe('auto_reply');
  });
});

describe('limiar de confianca', () => {
  /**
   * Parafrase real de WhatsApp: mesma intencao de A01, mas com palavras de
   * enchimento ("gente", "esse tal de") que diluem o score lexical.
   *
   * Este teste existe para fixar o trade-off medido: SEM embeddings, uma
   * parafrase assim fica na casa de 0.6 e nao passa no default de 0.75 —
   * o bot cala a boca em vez de arriscar. Se este numero mudar, a calibragem
   * documentada no README mudou junto e precisa ser revista.
   */
  const PARAFRASE_COM_ENCHIMENTO = 'gente, o que e esse tal de Micelio Sagrado?';

  it('parafrase diluida fica abaixo do default de 0.75 no modo lexical', async () => {
    const matcher = await makeMatcher();
    const result = await matcher.match(PARAFRASE_COM_ENCHIMENTO);

    expect(result.best?.entry.id).toBe('A01');
    expect(result.best!.score).toBeGreaterThan(0.55);
    expect(result.best!.score).toBeLessThan(0.75);
    expect(result.decision).toBe('ignore');
  });

  it('a mesma parafrase passa com o limiar calibrado para o modo lexical', async () => {
    const matcher = await makeMatcher({ confidenceThreshold: 0.6 });
    const result = await matcher.match(PARAFRASE_COM_ENCHIMENTO);

    expect(result.decision).toBe('auto_reply');
    expect(result.best?.entry.id).toBe('A01');
  });

  it('limiar alto demais silencia ate parafrases que passariam no default', async () => {
    // Esta pergunta pontua ~0.98 e seria respondida com o default de 0.75.
    const pergunta = 'tem estudo cientifico sobre psilocibina pra depressao?';

    expect((await (await makeMatcher()).match(pergunta)).decision).toBe('auto_reply');

    const estrito = await makeMatcher({ confidenceThreshold: 0.99 });
    const result = await estrito.match(pergunta);

    expect(result.decision).toBe('ignore');
    expect(result.best?.entry.id).toBe('C01');
  });

  it('separa bem: pergunta fora do FAQ fica muito abaixo do limiar de sinalizacao', async () => {
    const matcher = await makeMatcher();
    const candidates = await matcher.score('alguem sabe o horario do ultimo onibus pra Santos?');

    expect(candidates[0]!.score).toBeLessThan(0.2);
  });

  it('scores ficam no intervalo [0, 1] e vem ordenados', async () => {
    const matcher = await makeMatcher();
    const candidates = await matcher.score('como a psilocibina age no cerebro?');

    expect(candidates.length).toBe(faq.entries.length);
    for (const candidate of candidates) {
      expect(candidate.score).toBeGreaterThanOrEqual(0);
      expect(candidate.score).toBeLessThanOrEqual(1);
    }
    for (let i = 1; i < candidates.length; i++) {
      expect(candidates[i - 1]!.score).toBeGreaterThanOrEqual(candidates[i]!.score);
    }
  });
});

describe('caminho com embeddings', () => {
  /** Provider deterministico: vetor bag-of-words sobre um vocabulario fixo. */
  function fakeProvider(): EmbeddingProvider {
    const vocabulary = [
      'instituto', 'micelio', 'sagrado', 'dose', 'cogumelo', 'depressao',
      'cerebro', 'integracao', 'grupo', 'legal', 'crime',
    ];
    return {
      name: 'fake',
      async embed(texts: string[]): Promise<number[][]> {
        return texts.map((text) => {
          const tokens = new Set(tokenize(text));
          return vocabulary.map((term) => (tokens.has(term) ? 1 : 0));
        });
      },
    };
  }

  it('combina componente semantico e lexical', async () => {
    const matcher = await makeMatcher({ embeddingProvider: fakeProvider() });

    expect(matcher.usesSemanticMatching).toBe(true);

    const [top] = await matcher.score('o que e o instituto micelio sagrado?');
    expect(top?.entry.id).toBe('A01');
    expect(Number.isNaN(top!.semanticScore)).toBe(false);
    expect(top!.semanticScore).toBeGreaterThan(0.5);
  });

  it('mantem a regra de categoria restrita com embeddings ligados', async () => {
    const matcher = await makeMatcher({ embeddingProvider: fakeProvider() });
    const result = await matcher.match('quantos gramas de cogumelo devo tomar?');

    expect(result.decision).toBe('flag_admins');
    expect(result.bestRestricted?.entry.category).toBe('D');
  });

  it('exige init() antes de pontuar', async () => {
    const matcher = new FaqMatcher(faq, BASE_OPTIONS);
    await expect(matcher.score('qualquer coisa')).rejects.toThrow(/init\(\)/);
  });
});

describe('validacao do faq-data.json', () => {
  it('aceita o FAQ de exemplo do projeto', async () => {
    const real = await import('../src/faq-data.json');
    const parsed = validateFaqData(real.default ?? real);

    expect(parsed.entries.length).toBeGreaterThan(0);
    for (const id of ['A', 'B', 'C', 'D', 'E'] as CategoryId[]) {
      expect(parsed.categories[id]?.name).toBeTruthy();
    }
  });

  it('rejeita categoria invalida', () => {
    expect(() =>
      validateFaqData({
        ...faq,
        entries: [{ id: 'X01', category: 'Z', question: 'q', answer: 'a' }],
      }),
    ).toThrow(/categoria invalida/);
  });

  it('rejeita id duplicado', () => {
    expect(() =>
      validateFaqData({
        ...faq,
        entries: [faq.entries[0], faq.entries[0]],
      }),
    ).toThrow(/duplicado/);
  });

  it('rejeita entrada sem resposta', () => {
    expect(() =>
      validateFaqData({
        ...faq,
        entries: [{ id: 'A99', category: 'A', question: 'tem resposta?', answer: '' }],
      }),
    ).toThrow(/sem "answer"/);
  });
});
