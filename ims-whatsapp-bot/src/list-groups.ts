/**
 * Lista os grupos em que o numero pareado esta, com o JID de cada um.
 *
 *   npm run groups
 *
 * Copie o JID do seu GRUPO DE TESTE para TARGET_GROUP_IDS no .env.
 */
import makeWASocket, {
  fetchLatestBaileysVersion,
  useMultiFileAuthState,
} from '@whiskeysockets/baileys';
import qrcode from 'qrcode-terminal';

import { config } from './config';
import { logger } from './logger';

async function main(): Promise<void> {
  const { state, saveCreds } = await useMultiFileAuthState(config.authDir);
  const { version } = await fetchLatestBaileysVersion();

  const sock = makeWASocket({
    version,
    auth: state,
    logger: logger.child({ modulo: 'baileys' }, { level: 'error' }),
    markOnlineOnConnect: false,
    browser: ['IMS FAQ Bot (groups)', 'Chrome', '1.0.0'],
  });

  sock.ev.on('creds.update', saveCreds);

  sock.ev.on('connection.update', async ({ connection, qr }) => {
    if (qr) {
      console.log('Escaneie o QR code com o NUMERO SECUNDARIO:');
      qrcode.generate(qr, { small: true });
    }

    if (connection !== 'open') return;

    try {
      const groups = await sock.groupFetchAllParticipating();
      const rows = Object.values(groups).map((g) => ({
        jid: g.id,
        nome: g.subject,
        participantes: g.participants?.length ?? 0,
      }));

      if (rows.length === 0) {
        console.log('\nNenhum grupo encontrado. O numero ja foi adicionado ao grupo de teste?');
      } else {
        console.log(`\n${rows.length} grupo(s):\n`);
        console.table(rows);
        console.log('\nCopie o JID do grupo de TESTE para TARGET_GROUP_IDS no .env\n');
      }
    } catch (error) {
      console.error('Falha ao listar grupos:', error);
      process.exitCode = 1;
    } finally {
      await sock.logout().catch(() => undefined);
      process.exit(process.exitCode ?? 0);
    }
  });
}

void main().catch((error) => {
  console.error('Falha:', error);
  process.exit(1);
});
