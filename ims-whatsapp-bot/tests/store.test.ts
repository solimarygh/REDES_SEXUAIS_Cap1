import { beforeEach, describe, expect, it } from 'vitest';

import { Store, type EventRecord } from '../src/store';

function makeStore(): Store {
  return new Store(':memory:');
}

function event(overrides: Partial<EventRecord> = {}): EventRecord {
  return {
    groupJid: '123@g.us',
    senderJid: '5511999999999@s.whatsapp.net',
    messageId: `msg-${Math.random().toString(36).slice(2)}`,
    messageText: 'o que e o instituto?',
    decision: 'auto_reply',
    outcome: 'replied',
    reason: 'teste',
    faqId: 'A01',
    faqCategory: 'A',
    score: 0.9,
    restrictedFaqId: null,
    restrictedCategory: null,
    restrictedScore: null,
    ...overrides,
  };
}

describe('Store', () => {
  let store: Store;

  beforeEach(() => {
    store = makeStore();
  });

  it('registra evento e resume por resultado', () => {
    store.logEvent(event());
    store.logEvent(event({ outcome: 'flagged', decision: 'flag_admins' }));
    store.logEvent(event({ outcome: 'ignored', decision: 'ignore' }));

    expect(store.summary()).toEqual({ replied: 1, flagged: 1, ignored: 1 });
  });

  it('reconhece mensagem ja processada', () => {
    store.logEvent(event({ messageId: 'abc' }));

    expect(store.hasSeenMessage('abc')).toBe(true);
    expect(store.hasSeenMessage('outra')).toBe(false);
  });

  describe('cooldown', () => {
    const sender = '5511999999999@s.whatsapp.net';

    it('bloqueia a mesma resposta para a mesma pessoa dentro da janela', () => {
      const now = Date.now();
      store.recordDelivery('reply', sender, 'A01', now);

      expect(store.isInCooldown('reply', sender, 'A01', 24, now + 3_600_000)).toBe(true);
    });

    it('libera depois da janela', () => {
      const now = Date.now();
      store.recordDelivery('reply', sender, 'A01', now);

      expect(store.isInCooldown('reply', sender, 'A01', 24, now + 25 * 3_600_000)).toBe(false);
    });

    it('e independente por pessoa, por entrada e por tipo de entrega', () => {
      const now = Date.now();
      store.recordDelivery('reply', sender, 'A01', now);

      expect(store.isInCooldown('reply', sender, 'C01', 24, now)).toBe(false);
      expect(store.isInCooldown('reply', 'outra@s.whatsapp.net', 'A01', 24, now)).toBe(false);
      expect(store.isInCooldown('admin_flag', sender, 'A01', 24, now)).toBe(false);
    });

    it('cooldown zero desliga a regra', () => {
      const now = Date.now();
      store.recordDelivery('reply', sender, 'A01', now);

      expect(store.isInCooldown('reply', sender, 'A01', 0, now)).toBe(false);
    });
  });

  describe('rate limit', () => {
    it('conta apenas respostas efetivamente enviadas', () => {
      const now = Date.now();
      store.logEvent(event({ outcome: 'replied' }), now);
      store.logEvent(event({ outcome: 'flagged' }), now);
      store.logEvent(event({ outcome: 'suppressed_dry_run' }), now);

      expect(store.countRepliesSince(now - 1000)).toBe(1);
    });

    it('fecha a torneira ao atingir o teto na janela de uma hora', () => {
      const now = Date.now();
      for (let i = 0; i < 3; i++) {
        store.logEvent(event({ outcome: 'replied' }), now);
      }

      expect(store.hasReplyQuota(3, now)).toBe(false);
      expect(store.hasReplyQuota(4, now)).toBe(true);
    });

    it('a janela desliza: respostas de mais de uma hora atras nao contam', () => {
      const now = Date.now();
      for (let i = 0; i < 5; i++) {
        store.logEvent(event({ outcome: 'replied' }), now - 2 * 3_600_000);
      }

      expect(store.hasReplyQuota(3, now)).toBe(true);
    });

    it('teto zero bloqueia tudo', () => {
      expect(store.hasReplyQuota(0)).toBe(false);
    });
  });
});
