/**
 * Provedores de embedding para o matching semantico.
 *
 * O default do projeto e `none`: o matcher roda so com o componente lexical,
 * que e offline, gratuito e suficiente para um FAQ de ~38 entradas *desde que*
 * cada entrada tenha variantes bem escritas. Ligar `openai` melhora o recall
 * para parafrases distantes, ao custo de uma chamada de rede por mensagem.
 */

export interface EmbeddingProvider {
  readonly name: string;
  /** Devolve um vetor por texto, na mesma ordem. */
  embed(texts: string[]): Promise<number[][]>;
}

export interface EmbeddingConfig {
  provider: 'none' | 'openai';
  apiKey: string;
  baseUrl: string;
  model: string;
}

const BATCH_SIZE = 96;
const MAX_RETRIES = 3;

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/** Provedor para qualquer API compativel com o endpoint /embeddings da OpenAI. */
class OpenAiCompatibleProvider implements EmbeddingProvider {
  readonly name: string;

  constructor(private readonly cfg: EmbeddingConfig) {
    this.name = `openai:${cfg.model}`;
  }

  async embed(texts: string[]): Promise<number[][]> {
    const out: number[][] = [];
    for (let i = 0; i < texts.length; i += BATCH_SIZE) {
      const batch = texts.slice(i, i + BATCH_SIZE);
      out.push(...(await this.embedBatch(batch)));
    }
    return out;
  }

  private async embedBatch(batch: string[]): Promise<number[][]> {
    let lastError: unknown;

    for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
      if (attempt > 0) await sleep(500 * 2 ** (attempt - 1));

      try {
        const response = await fetch(`${this.cfg.baseUrl.replace(/\/$/, '')}/embeddings`, {
          method: 'POST',
          headers: {
            'content-type': 'application/json',
            authorization: `Bearer ${this.cfg.apiKey}`,
          },
          body: JSON.stringify({ model: this.cfg.model, input: batch }),
        });

        if (!response.ok) {
          const body = await response.text();
          // 4xx que nao seja rate limit nao melhora com retry.
          if (response.status !== 429 && response.status < 500) {
            throw new Error(`Embeddings API ${response.status}: ${body.slice(0, 300)}`);
          }
          lastError = new Error(`Embeddings API ${response.status}: ${body.slice(0, 300)}`);
          continue;
        }

        const json = (await response.json()) as {
          data?: { embedding: number[]; index: number }[];
        };
        const data = json.data;
        if (!Array.isArray(data) || data.length !== batch.length) {
          throw new Error('Resposta da API de embeddings com formato inesperado.');
        }

        return [...data]
          .sort((a, b) => a.index - b.index)
          .map((item) => item.embedding);
      } catch (error) {
        lastError = error;
        // Erro definitivo (4xx/formato): nao insiste.
        if (error instanceof Error && /Embeddings API 4|formato inesperado/.test(error.message)) {
          throw error;
        }
      }
    }

    throw lastError instanceof Error
      ? lastError
      : new Error('Falha ao chamar a API de embeddings.');
  }
}

/** Devolve `null` quando o matching semantico esta desligado. */
export function createEmbeddingProvider(cfg: EmbeddingConfig): EmbeddingProvider | null {
  if (cfg.provider === 'none') return null;
  if (cfg.provider === 'openai') {
    if (!cfg.apiKey) throw new Error('EMBEDDINGS_PROVIDER=openai exige EMBEDDINGS_API_KEY.');
    return new OpenAiCompatibleProvider(cfg);
  }
  throw new Error(`EMBEDDINGS_PROVIDER desconhecido: "${cfg.provider}".`);
}
