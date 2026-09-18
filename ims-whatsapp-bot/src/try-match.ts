/**
 * Testa o matcher sem conectar no WhatsApp — a forma mais rapida de calibrar
 * CONFIDENCE_THRESHOLD e RESTRICTED_FLAG_THRESHOLD.
 *
 *   npm run match -- "qual a dose pra iniciante?"
 *   npm run match            # le perguntas do stdin, uma por linha
 */
import readline from 'node:readline';

import { config } from './config';
import { createEmbeddingProvider } from './embeddings';
import { FaqMatcher, validateFaqData } from './faq-matcher';
import rawFaq from './faq-data.json';

const DECISION_LABEL: Record<string, string> = {
  auto_reply: '✅ RESPONDE no grupo',
  flag_admins: '🔎 SINALIZA aos admins (nao responde)',
  ignore: '➖ IGNORA',
};

async function main(): Promise<void> {
  const faq = validateFaqData(rawFaq);
  const matcher = new FaqMatcher(faq, {
    autoReplyCategories: [...config.autoReplyCategories],
    restrictedCategories: [...config.restrictedCategories],
    confidenceThreshold: config.confidenceThreshold,
    restrictedFlagThreshold: config.restrictedFlagThreshold,
    ambiguityMargin: config.ambiguityMargin,
    minMessageLength: config.minMessageLength,
    semanticWeight: config.embeddings.semanticWeight,
    safetyKeywords: [...config.safetyKeywords],
    embeddingProvider: createEmbeddingProvider(config.embeddings),
    topN: 5,
  });
  await matcher.init();

  console.log(
    `FAQ: ${matcher.entryCount} entradas / ${matcher.indexedTextCount} textos indexados. ` +
      `Semantico: ${matcher.usesSemanticMatching ? config.embeddings.model : 'desligado'}.`,
  );
  console.log(
    `Limiares: auto >= ${config.confidenceThreshold}, ` +
      `sinalizar >= ${config.restrictedFlagThreshold}, margem ${config.ambiguityMargin}.\n`,
  );

  async function evaluate(question: string): Promise<void> {
    const result = await matcher.match(question);
    console.log(`> ${question}`);
    console.log(`  ${DECISION_LABEL[result.decision] ?? result.decision}`);
    console.log(`  motivo: ${result.reason}`);
    for (const candidate of result.candidates) {
      console.log(
        `    ${candidate.entry.id} [${candidate.entry.category}] ` +
          `total=${candidate.score.toFixed(3)} lex=${candidate.lexicalScore.toFixed(3)}` +
          (Number.isNaN(candidate.semanticScore)
            ? ''
            : ` sem=${candidate.semanticScore.toFixed(3)}`) +
          ` — ${candidate.matchedText}`,
      );
    }
    console.log('');
  }

  const args = process.argv.slice(2);
  if (args.length > 0) {
    await evaluate(args.join(' '));
    return;
  }

  const rl = readline.createInterface({ input: process.stdin, terminal: false });
  for await (const line of rl) {
    const question = line.trim();
    if (question) await evaluate(question);
  }
}

void main().catch((error) => {
  console.error(error);
  process.exit(1);
});
