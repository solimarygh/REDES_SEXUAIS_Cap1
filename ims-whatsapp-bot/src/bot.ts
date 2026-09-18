import makeWASocket, {
  DisconnectReason,
  fetchLatestBaileysVersion,
  useMultiFileAuthState,
  type WAMessage,
  type WASocket,
} from '@whiskeysockets/baileys';
import qrcode from 'qrcode-terminal';

import { config, validateConfig } from './config';
import { createEmbeddingProvider } from './embeddings';
import { FaqMatcher, validateFaqData } from './faq-matcher';
import { logger } from './logger';
import { Store, type EventRecord, type Outcome } from './store';
import type { MatchResult } from './types';
import rawFaq from './faq-data.json';

/** Mensagens mais antigas que isso sao historico, nao conversa ao vivo. */
const MAX_MESSAGE_AGE_MS = 5 * 60 * 1000;

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function randomBetween(min: number, max: number): number {
  return Math.floor(min + Math.random() * (max - min));
}

/** Extrai o status code de desconexao do erro do Baileys, sem depender do Boom. */
function disconnectStatusCode(error: unknown): number | undefined {
  const output = (error as { output?: { statusCode?: number } } | undefined)?.output;
  return output?.statusCode;
}

/** Texto util da mensagem, cobrindo os envelopes mais comuns do WhatsApp. */
function extractText(msg: WAMessage): string | null {
  const m = msg.message;
  if (!m) return null;

  const inner = m.ephemeralMessage?.message ?? m.viewOnceMessage?.message ?? m;

  return (
    inner.conversation ??
    inner.extendedTextMessage?.text ??
    inner.imageMessage?.caption ??
    inner.videoMessage?.caption ??
    null
  );
}

function buildAdminNotification(
  result: MatchResult,
  messageText: string,
  groupJid: string,
): string {
  const target = result.bestRestricted ?? result.best;
  const categoryLabel = target
    ? `categoria ${target.entry.category} (${target.entry.id}, score ${target.score.toFixed(3)})`
    : 'categoria desconhecida';

  const candidateLines = result.candidates
    .map((c) => `  • ${c.entry.id} [${c.entry.category}] ${c.score.toFixed(3)} — ${c.entry.question}`)
    .join('\n');

  return [
    '🔎 *Revisar: possivel pergunta de categoria restrita*',
    '',
    `*Sinalizacao:* ${categoryLabel}`,
    `*Grupo:* ${groupJid}`,
    '',
    '*Mensagem recebida:*',
    `"${messageText.slice(0, 500)}"`,
    '',
    '*Candidatos do FAQ:*',
    candidateLines || '  (nenhum)',
    '',
    `*Motivo:* ${result.reason}`,
    '',
    '_O bot NAO respondeu no grupo. Um humano precisa decidir._',
  ].join('\n');
}

async function main(): Promise<void> {
  for (const warning of validateConfig()) {
    logger.warn(warning);
  }

  const faq = validateFaqData(rawFaq);
  const placeholders = faq.entries.filter((e) => e.answer.includes('[SUBSTITUIR'));
  if (placeholders.length > 0) {
    logger.warn(
      { ids: placeholders.map((e) => e.id) },
      `${placeholders.length} entrada(s) do FAQ ainda tem resposta de exemplo. ` +
        'Substitua src/faq-data.json pelo FAQ real antes de desligar DRY_RUN.',
    );
  }

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
  });

  await matcher.init();
  logger.info(
    {
      entradas: matcher.entryCount,
      textosIndexados: matcher.indexedTextCount,
      semantico: matcher.usesSemanticMatching ? config.embeddings.model : 'desligado (lexical)',
      autoResponde: config.autoReplyCategories.join(','),
      restritas: config.restrictedCategories.join(','),
      dryRun: config.dryRun,
      grupos: config.targetGroupIds.length,
      admins: config.adminJids.length,
    },
    'FAQ carregado.',
  );

  const store = new Store(config.dbPath);

  // Processamento serial: o rate limit e o cooldown leem e escrevem o mesmo
  // estado, entao duas mensagens simultaneas nao podem correr em paralelo.
  let queue: Promise<void> = Promise.resolve();
  let reconnectAttempts = 0;
  let shuttingDown = false;

  async function connect(): Promise<void> {
    const { state, saveCreds } = await useMultiFileAuthState(config.authDir);
    const { version, isLatest } = await fetchLatestBaileysVersion();
    logger.info({ version: version.join('.'), isLatest }, 'Versao do protocolo WhatsApp Web.');

    const sock: WASocket = makeWASocket({
      version,
      auth: state,
      logger: logger.child({ modulo: 'baileys' }, { level: 'warn' }),
      // Nao roubar as notificacoes do celular pareado.
      markOnlineOnConnect: false,
      syncFullHistory: false,
      browser: ['IMS FAQ Bot', 'Chrome', '1.0.0'],
    });

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
      const { connection, lastDisconnect, qr } = update;

      if (qr) {
        logger.info('Escaneie o QR code abaixo com o WhatsApp do NUMERO SECUNDARIO.');
        logger.info('WhatsApp > Aparelhos conectados > Conectar um aparelho');
        qrcode.generate(qr, { small: true });
      }

      if (connection === 'open') {
        reconnectAttempts = 0;
        logger.info({ jid: sock.user?.id }, 'Conectado ao WhatsApp.');
        if (config.dryRun) {
          logger.warn('DRY_RUN ligado: nada sera enviado. Defina DRY_RUN=false para agir.');
        }
      }

      if (connection === 'close') {
        const statusCode = disconnectStatusCode(lastDisconnect?.error);
        const loggedOut = statusCode === DisconnectReason.loggedOut;

        if (shuttingDown) {
          logger.info('Conexao encerrada durante o shutdown.');
          return;
        }

        if (loggedOut) {
          logger.error(
            `Sessao invalidada (logout no celular). Apague a pasta ${config.authDir} ` +
              'e pareie de novo com `npm run dev`.',
          );
          process.exitCode = 1;
          return;
        }

        if (reconnectAttempts >= config.maxReconnectAttempts) {
          logger.error(
            { tentativas: reconnectAttempts },
            'Limite de tentativas de reconexao atingido. Encerrando.',
          );
          process.exitCode = 1;
          return;
        }

        reconnectAttempts++;
        // Backoff exponencial com teto de 60s.
        const delay = Math.min(2_000 * 2 ** (reconnectAttempts - 1), 60_000);
        logger.warn(
          { statusCode, tentativa: reconnectAttempts, emMs: delay },
          'Conexao caiu. Reconectando.',
        );
        setTimeout(() => {
          void connect().catch((error) => {
            logger.error({ error }, 'Falha ao reconectar.');
          });
        }, delay);
      }
    });

    sock.ev.on('messages.upsert', ({ messages, type }) => {
      if (type !== 'notify') return;
      for (const msg of messages) {
        queue = queue
          .then(() => handleMessage(sock, msg))
          .catch((error) => {
            logger.error({ error }, 'Erro ao processar mensagem.');
          });
      }
    });
  }

  async function handleMessage(sock: WASocket, msg: WAMessage): Promise<void> {
    const groupJid = msg.key.remoteJid;
    const messageId = msg.key.id;

    if (!groupJid || !messageId) return;
    if (msg.key.fromMe) return;
    if (!groupJid.endsWith('@g.us')) return;
    if (!config.targetGroupIds.includes(groupJid)) return;

    const timestamp = Number(msg.messageTimestamp ?? 0) * 1000;
    if (timestamp > 0 && Date.now() - timestamp > MAX_MESSAGE_AGE_MS) {
      logger.debug({ messageId }, 'Mensagem antiga (historico), ignorada.');
      return;
    }

    if (store.hasSeenMessage(messageId)) return;

    const text = extractText(msg);
    if (!text?.trim()) return;

    const senderJid = msg.key.participant ?? groupJid;
    const result = await matcher.match(text);

    const record: Omit<EventRecord, 'outcome'> = {
      groupJid,
      senderJid,
      messageId,
      messageText: text,
      decision: result.decision,
      reason: result.reason,
      faqId: result.best?.entry.id ?? null,
      faqCategory: result.best?.entry.category ?? null,
      score: result.best?.score ?? null,
      restrictedFaqId: result.bestRestricted?.entry.id ?? null,
      restrictedCategory: result.bestRestricted?.entry.category ?? null,
      restrictedScore: result.bestRestricted?.score ?? null,
    };

    const finish = (outcome: Outcome): void => {
      store.logEvent({ ...record, outcome });
      logger[outcome === 'send_failed' ? 'error' : 'info'](
        {
          outcome,
          decisao: result.decision,
          faqId: record.faqId,
          categoria: record.faqCategory,
          score: record.score?.toFixed(3),
          de: senderJid,
        },
        result.reason || 'Mensagem processada.',
      );
    };

    if (result.decision === 'ignore') {
      finish('ignored');
      return;
    }

    if (result.decision === 'flag_admins') {
      const flagId = result.bestRestricted?.entry.id ?? result.best?.entry.id ?? 'desconhecido';

      if (store.isInCooldown('admin_flag', senderJid, flagId, config.adminNotifyCooldownHours)) {
        finish('suppressed_cooldown');
        return;
      }
      if (config.dryRun || config.adminJids.length === 0) {
        finish('suppressed_dry_run');
        return;
      }

      const notification = buildAdminNotification(result, text, groupJid);
      try {
        for (const adminJid of config.adminJids) {
          await sock.sendMessage(adminJid, { text: notification });
        }
        store.recordDelivery('admin_flag', senderJid, flagId);
        finish('flagged');
      } catch (error) {
        logger.error({ error }, 'Falha ao avisar os admins.');
        finish('send_failed');
      }
      return;
    }

    // decision === 'auto_reply'
    const best = result.best;
    if (!best) {
      finish('ignored');
      return;
    }

    // Invariante de seguranca, checada de novo na borda do envio: mesmo que o
    // matcher mude, nada de categoria restrita sai daqui.
    if (config.restrictedCategories.includes(best.entry.category)) {
      logger.error(
        { faqId: best.entry.id, categoria: best.entry.category },
        'BUG: auto_reply para categoria restrita foi bloqueado na borda do envio.',
      );
      finish('ignored');
      return;
    }

    if (store.isInCooldown('reply', senderJid, best.entry.id, config.cooldownHours)) {
      finish('suppressed_cooldown');
      return;
    }
    if (!store.hasReplyQuota(config.maxRepliesPerHour)) {
      finish('suppressed_rate_limit');
      return;
    }
    if (config.dryRun) {
      finish('suppressed_dry_run');
      return;
    }

    const delay = randomBetween(config.replyDelayMinMs, config.replyDelayMaxMs);
    try {
      await sock.sendPresenceUpdate('composing', groupJid);
    } catch {
      // Presenca e cosmetica; falhar aqui nao impede a resposta.
    }
    await sleep(delay);

    try {
      await sock.sendMessage(
        groupJid,
        { text: `${best.entry.answer}${config.botSignature}` },
        { quoted: msg },
      );
      store.recordDelivery('reply', senderJid, best.entry.id);
      finish('replied');
    } catch (error) {
      logger.error({ error }, 'Falha ao enviar resposta no grupo.');
      finish('send_failed');
    } finally {
      try {
        await sock.sendPresenceUpdate('paused', groupJid);
      } catch {
        // idem
      }
    }
  }

  for (const signal of ['SIGINT', 'SIGTERM'] as const) {
    process.on(signal, () => {
      if (shuttingDown) return;
      shuttingDown = true;
      logger.info({ resumo: store.summary() }, 'Encerrando.');
      store.close();
      process.exit(0);
    });
  }

  await connect();
}

void main().catch((error) => {
  logger.error({ error }, 'Falha fatal na inicializacao.');
  process.exit(1);
});
