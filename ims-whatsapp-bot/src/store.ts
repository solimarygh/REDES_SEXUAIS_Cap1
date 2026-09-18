import fs from 'node:fs';
import path from 'node:path';
import Database from 'better-sqlite3';
import type { Decision } from './types';

/** Tudo que fica registrado sobre uma mensagem processada. */
export interface EventRecord {
  groupJid: string;
  senderJid: string;
  messageId: string;
  messageText: string;
  /** Decisao do matcher, antes dos filtros de cooldown/rate limit. */
  decision: Decision;
  /** O que de fato aconteceu depois de todos os filtros. */
  outcome: Outcome;
  reason: string;
  faqId: string | null;
  faqCategory: string | null;
  score: number | null;
  restrictedFaqId: string | null;
  restrictedCategory: string | null;
  restrictedScore: number | null;
}

export type Outcome =
  | 'replied'
  | 'flagged'
  | 'ignored'
  | 'suppressed_cooldown'
  | 'suppressed_rate_limit'
  | 'suppressed_dry_run'
  | 'send_failed';

/** Tipos de entrega sujeitos a cooldown. */
export type DeliveryKind = 'reply' | 'admin_flag';

const SCHEMA = `
CREATE TABLE IF NOT EXISTS events (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  ts                 TEXT    NOT NULL,
  ts_epoch           INTEGER NOT NULL,
  group_jid          TEXT    NOT NULL,
  sender_jid         TEXT    NOT NULL,
  message_id         TEXT    NOT NULL,
  message_text       TEXT    NOT NULL,
  decision           TEXT    NOT NULL,
  outcome            TEXT    NOT NULL,
  reason             TEXT    NOT NULL,
  faq_id             TEXT,
  faq_category       TEXT,
  score              REAL,
  restricted_faq_id  TEXT,
  restricted_category TEXT,
  restricted_score   REAL
);

CREATE INDEX IF NOT EXISTS idx_events_ts_epoch ON events (ts_epoch);
CREATE INDEX IF NOT EXISTS idx_events_outcome  ON events (outcome, ts_epoch);
CREATE INDEX IF NOT EXISTS idx_events_message  ON events (message_id);

CREATE TABLE IF NOT EXISTS deliveries (
  kind            TEXT    NOT NULL,
  sender_jid      TEXT    NOT NULL,
  faq_id          TEXT    NOT NULL,
  last_sent_epoch INTEGER NOT NULL,
  PRIMARY KEY (kind, sender_jid, faq_id)
);
`;

/**
 * Persistencia do bot: log de eventos, cooldown por pessoa+resposta e
 * rate limit por janela deslizante.
 */
export class Store {
  private readonly db: Database.Database;

  constructor(dbPath: string) {
    if (dbPath !== ':memory:') {
      fs.mkdirSync(path.dirname(dbPath), { recursive: true });
    }
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.db.exec(SCHEMA);
  }

  logEvent(record: EventRecord, now = Date.now()): void {
    this.db
      .prepare(
        `INSERT INTO events (
           ts, ts_epoch, group_jid, sender_jid, message_id, message_text,
           decision, outcome, reason, faq_id, faq_category, score,
           restricted_faq_id, restricted_category, restricted_score
         ) VALUES (
           @ts, @tsEpoch, @groupJid, @senderJid, @messageId, @messageText,
           @decision, @outcome, @reason, @faqId, @faqCategory, @score,
           @restrictedFaqId, @restrictedCategory, @restrictedScore
         )`,
      )
      .run({
        ...record,
        ts: new Date(now).toISOString(),
        tsEpoch: now,
      });
  }

  /** Ja processamos esta mensagem? Protege contra reentrega do Baileys. */
  hasSeenMessage(messageId: string): boolean {
    const row = this.db
      .prepare('SELECT 1 FROM events WHERE message_id = ? LIMIT 1')
      .get(messageId);
    return row !== undefined;
  }

  /**
   * A mesma pessoa ja recebeu esta resposta dentro da janela de cooldown?
   * `cooldownHours <= 0` desliga o cooldown.
   */
  isInCooldown(
    kind: DeliveryKind,
    senderJid: string,
    faqId: string,
    cooldownHours: number,
    now = Date.now(),
  ): boolean {
    if (cooldownHours <= 0) return false;

    const row = this.db
      .prepare(
        'SELECT last_sent_epoch FROM deliveries WHERE kind = ? AND sender_jid = ? AND faq_id = ?',
      )
      .get(kind, senderJid, faqId) as { last_sent_epoch: number } | undefined;

    if (!row) return false;
    return now - row.last_sent_epoch < cooldownHours * 3_600_000;
  }

  recordDelivery(
    kind: DeliveryKind,
    senderJid: string,
    faqId: string,
    now = Date.now(),
  ): void {
    this.db
      .prepare(
        `INSERT INTO deliveries (kind, sender_jid, faq_id, last_sent_epoch)
         VALUES (?, ?, ?, ?)
         ON CONFLICT (kind, sender_jid, faq_id)
         DO UPDATE SET last_sent_epoch = excluded.last_sent_epoch`,
      )
      .run(kind, senderJid, faqId, now);
  }

  /** Respostas automaticas efetivamente enviadas na ultima hora. */
  countRepliesSince(sinceEpoch: number): number {
    const row = this.db
      .prepare("SELECT COUNT(*) AS n FROM events WHERE outcome = 'replied' AND ts_epoch >= ?")
      .get(sinceEpoch) as { n: number };
    return row.n;
  }

  /** `true` se ainda ha cota na janela deslizante de uma hora. */
  hasReplyQuota(maxPerHour: number, now = Date.now()): boolean {
    if (maxPerHour <= 0) return false;
    return this.countRepliesSince(now - 3_600_000) < maxPerHour;
  }

  /** Resumo rapido por resultado, para inspecao manual. */
  summary(sinceEpoch = 0): Record<string, number> {
    const rows = this.db
      .prepare('SELECT outcome, COUNT(*) AS n FROM events WHERE ts_epoch >= ? GROUP BY outcome')
      .all(sinceEpoch) as { outcome: string; n: number }[];

    return Object.fromEntries(rows.map((r) => [r.outcome, r.n]));
  }

  close(): void {
    this.db.close();
  }
}
