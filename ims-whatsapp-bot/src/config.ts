import 'dotenv/config';
import path from 'node:path';
import { CATEGORY_IDS, type CategoryId } from './types';

function str(name: string, fallback: string): string {
  const raw = process.env[name];
  return raw === undefined || raw.trim() === '' ? fallback : raw.trim();
}

function num(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw === undefined || raw.trim() === '') return fallback;
  const parsed = Number(raw);
  if (!Number.isFinite(parsed)) {
    throw new Error(`Config invalida: ${name}="${raw}" nao e um numero.`);
  }
  return parsed;
}

function bool(name: string, fallback: boolean): boolean {
  const raw = process.env[name];
  if (raw === undefined || raw.trim() === '') return fallback;
  const v = raw.trim().toLowerCase();
  if (['1', 'true', 'yes', 'sim', 'on'].includes(v)) return true;
  if (['0', 'false', 'no', 'nao', 'off'].includes(v)) return false;
  throw new Error(`Config invalida: ${name}="${raw}" nao e booleano.`);
}

function csv(name: string, fallback: string): string[] {
  return str(name, fallback)
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

function categories(name: string, fallback: string): CategoryId[] {
  const values = csv(name, fallback).map((s) => s.toUpperCase());
  for (const value of values) {
    if (!CATEGORY_IDS.includes(value as CategoryId)) {
      throw new Error(
        `Config invalida: ${name} contem "${value}". Categorias validas: ${CATEGORY_IDS.join(', ')}.`,
      );
    }
  }
  return values as CategoryId[];
}

/**
 * Normaliza um numero de telefone em JID de usuario do WhatsApp.
 * Aceita "+55 11 99999-9999" ou "5511999999999"; rejeita numero vazio.
 */
export function phoneToJid(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  if (digits.length < 8) {
    throw new Error(`Numero de admin invalido: "${phone}".`);
  }
  return `${digits}@s.whatsapp.net`;
}

const autoReplyCategories = categories('AUTO_REPLY_CATEGORIES', 'A,C,E');
const restrictedCategories = categories('RESTRICTED_CATEGORIES', 'B,D');

const overlap = autoReplyCategories.filter((c) => restrictedCategories.includes(c));
if (overlap.length > 0) {
  throw new Error(
    `Config invalida: categoria(s) ${overlap.join(', ')} aparecem em AUTO_REPLY_CATEGORIES ` +
      `e em RESTRICTED_CATEGORIES ao mesmo tempo. Uma categoria restrita nunca pode ser auto-respondida.`,
  );
}

export const config = {
  /** Pasta da sessao Baileys. NUNCA versionar (ver .gitignore). */
  authDir: path.resolve(str('WA_AUTH_DIR', './auth_info')),
  dbPath: path.resolve(str('DB_PATH', './data/bot.sqlite')),
  logLevel: str('LOG_LEVEL', 'info'),

  /**
   * Grupos onde o bot pode agir (JIDs terminados em @g.us).
   * Vazio = nao age em lugar nenhum. Use `npm run groups` para descobrir o JID
   * do seu grupo de teste.
   */
  targetGroupIds: csv('TARGET_GROUP_IDS', ''),

  /** Numeros que recebem as sinalizacoes de categoria restrita. */
  adminJids: csv('ADMIN_NUMBERS', '').map(phoneToJid),

  /**
   * Modo observacao: processa e loga tudo, mas nao envia nada.
   * Default `true` de proposito — voce precisa desligar conscientemente.
   */
  dryRun: bool('DRY_RUN', true),

  /** Categorias que o bot pode responder sozinho no grupo. */
  autoReplyCategories,
  /** Categorias que o bot NUNCA responde: apenas sinaliza aos admins. */
  restrictedCategories,

  /** Confianca minima para responder automaticamente. */
  confidenceThreshold: num('CONFIDENCE_THRESHOLD', 0.75),
  /**
   * Confianca minima para sinalizar uma categoria restrita aos admins.
   * Deliberadamente MAIS BAIXA que confidenceThreshold: na duvida,
   * preferimos acordar um humano a arriscar uma resposta automatica.
   */
  restrictedFlagThreshold: num('RESTRICTED_FLAG_THRESHOLD', 0.55),

  /**
   * Margem minima pela qual o melhor candidato auto-respondivel precisa
   * superar o melhor candidato restrito para que a resposta automatica saia.
   * Se a diferenca for menor, a mensagem e ambigua e vai para os admins.
   */
  ambiguityMargin: num('AMBIGUITY_MARGIN', 0.1),

  /** Nao repetir a mesma resposta para a mesma pessoa dentro desta janela. */
  cooldownHours: num('COOLDOWN_HOURS', 24),
  /** Nao repetir a mesma sinalizacao aos admins dentro desta janela. */
  adminNotifyCooldownHours: num('ADMIN_NOTIFY_COOLDOWN_HOURS', 6),

  /** Teto de respostas automaticas por hora (janela deslizante). */
  maxRepliesPerHour: num('MAX_REPLIES_PER_HOUR', 6),

  /** Atraso "humano" antes de responder. */
  replyDelayMinMs: num('REPLY_DELAY_MIN_MS', 2000),
  replyDelayMaxMs: num('REPLY_DELAY_MAX_MS', 5000),

  /** Mensagens menores que isso nunca sao tratadas como pergunta. */
  minMessageLength: num('MIN_MESSAGE_LENGTH', 12),

  /**
   * Rede de seguranca lexical. Qualquer mensagem que contenha um destes termos
   * NUNCA e auto-respondida: vai direto para os admins, qualquer que seja o
   * score do matcher.
   *
   * Existe porque o matching semantico erra justamente onde mais doi: nomes de
   * farmacos e condicoes clinicas que nao estao no vocabulario do FAQ pontuam
   * baixo e passariam batido. Deixe vazio para desligar.
   */
  safetyKeywords: csv(
    'SAFETY_KEYWORDS',
    [
      // dose e quantidade
      'dose', 'dosagem', 'microdose', 'microdosagem', 'grama', 'gramas',
      'quantidade', 'miligrama', 'mg',
      // psicofarmacos e interacoes
      'antidepressivo', 'antidepressivos', 'ssri', 'isrs', 'imao', 'lítio', 'litio',
      'fluoxetina', 'sertralina', 'escitalopram', 'citalopram', 'paroxetina',
      'venlafaxina', 'bupropiona', 'quetiapina', 'risperidona', 'lamotrigina',
      'clonazepam', 'rivotril', 'tramadol', 'lamictal', 'remedio', 'medicacao',
      'medicamento', 'interacao',
      // condicoes de risco
      'esquizofrenia', 'psicose', 'psicotico', 'bipolar', 'bipolaridade',
      'surto', 'epilepsia', 'convulsao', 'gravida', 'gravidez', 'gestante',
      'amamentando', 'cardiaco', 'coracao', 'suicida', 'suicidio',
      // preparo e obtencao
      'cultivar', 'cultivo', 'plantar', 'comprar', 'onde consigo', 'fornecedor',
      'sporo', 'esporo', 'kit',
    ].join(','),
  ),

  /** Assinatura anexada a toda resposta automatica (transparencia). */
  botSignature: str(
    'BOT_SIGNATURE',
    '\n\n_— resposta automatica do FAQ do IMS. Em caso de duvida, chame um moderador._',
  ),

  embeddings: {
    /** 'none' = so lexical (offline). 'openai' = API compativel com OpenAI. */
    provider: str('EMBEDDINGS_PROVIDER', 'none') as 'none' | 'openai',
    apiKey: str('EMBEDDINGS_API_KEY', ''),
    baseUrl: str('EMBEDDINGS_BASE_URL', 'https://api.openai.com/v1'),
    model: str('EMBEDDINGS_MODEL', 'text-embedding-3-small'),
    /** Peso do componente semantico no score final (0..1). */
    semanticWeight: num('SEMANTIC_WEIGHT', 0.65),
  },

  /** Tentativas de reconexao antes de desistir. */
  maxReconnectAttempts: num('MAX_RECONNECT_ATTEMPTS', 10),
} as const;

export type Config = typeof config;

/** Valida combinacoes de config e devolve avisos legiveis (nao lanca). */
export function validateConfig(cfg: Config = config): string[] {
  const warnings: string[] = [];

  if (cfg.confidenceThreshold < 0 || cfg.confidenceThreshold > 1) {
    throw new Error('CONFIDENCE_THRESHOLD deve estar entre 0 e 1.');
  }
  if (cfg.restrictedFlagThreshold < 0 || cfg.restrictedFlagThreshold > 1) {
    throw new Error('RESTRICTED_FLAG_THRESHOLD deve estar entre 0 e 1.');
  }
  if (cfg.embeddings.semanticWeight < 0 || cfg.embeddings.semanticWeight > 1) {
    throw new Error('SEMANTIC_WEIGHT deve estar entre 0 e 1.');
  }
  if (cfg.ambiguityMargin < 0 || cfg.ambiguityMargin > 1) {
    throw new Error('AMBIGUITY_MARGIN deve estar entre 0 e 1.');
  }
  if (cfg.replyDelayMinMs > cfg.replyDelayMaxMs) {
    throw new Error('REPLY_DELAY_MIN_MS nao pode ser maior que REPLY_DELAY_MAX_MS.');
  }
  if (cfg.embeddings.provider === 'openai' && cfg.embeddings.apiKey === '') {
    throw new Error('EMBEDDINGS_PROVIDER=openai exige EMBEDDINGS_API_KEY.');
  }

  if (cfg.restrictedFlagThreshold > cfg.confidenceThreshold) {
    warnings.push(
      'RESTRICTED_FLAG_THRESHOLD esta acima de CONFIDENCE_THRESHOLD: perguntas restritas ' +
        'duvidosas podem passar sem sinalizacao. O normal e o contrario.',
    );
  }
  if (cfg.targetGroupIds.length === 0) {
    warnings.push('TARGET_GROUP_IDS vazio: o bot vai observar e logar, mas nunca agir.');
  }
  for (const jid of cfg.targetGroupIds) {
    if (!jid.endsWith('@g.us')) {
      warnings.push(`TARGET_GROUP_IDS contem "${jid}", que nao parece um JID de grupo (@g.us).`);
    }
  }
  if (cfg.adminJids.length === 0) {
    warnings.push(
      'ADMIN_NUMBERS vazio: perguntas de categoria restrita serao logadas, mas ninguem sera avisado.',
    );
  }
  if (!cfg.dryRun && cfg.targetGroupIds.length === 0) {
    warnings.push('DRY_RUN=false sem TARGET_GROUP_IDS: nenhuma mensagem sera enviada mesmo assim.');
  }

  return warnings;
}
