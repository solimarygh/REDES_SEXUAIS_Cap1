# IMS WhatsApp FAQ Bot

Bot de FAQ para o grupo comunitário psico-educativo do **Instituto Micélio Sagrado**.
Escuta o grupo, identifica perguntas que já estão no FAQ e responde **apenas** as
categorias seguras. Perguntas de legalidade ou de uso/segurança nunca são
respondidas automaticamente — vão para um humano.

---

## ⚠️ Leia antes de qualquer coisa

**1. Isto usa a API não-oficial do WhatsApp e viola os Termos de Serviço.**

A biblioteca [Baileys](https://github.com/WhiskeySockets/Baileys) conversa com o
WhatsApp pelo mesmo protocolo do WhatsApp Web, sem passar pela API oficial do
WhatsApp Business. Isso **viola os Termos de Serviço do WhatsApp**. A consequência
concreta é que o número pode ser **banido a qualquer momento, sem aviso e sem
recurso** — não existe suporte para apelar.

**2. Use um número secundário dedicado. Nunca o número principal do grupo.**

Consequências diretas de usar o número principal:

- se o número for banido, você perde a conta do WhatsApp inteira, não só o bot;
- perde o acesso administrativo aos grupos que esse número administra;
- perde o histórico de conversas associado.

Use um chip pré-pago separado ou um número virtual dedicado, adicionado ao grupo
como participante comum. **O número do bot não precisa ser admin do grupo.**

**3. A pasta `auth_info/` é uma credencial, não um arquivo de configuração.**

Quem tiver essa pasta consegue se passar pelo número pareado. Ela está no
`.gitignore` e **nunca** pode ir para o Git, nem para um repositório privado.
Mesma coisa para o `.env` e para o banco `data/bot.sqlite` (que contém mensagens
reais de pessoas do grupo).

**4. Responsabilidade editorial continua sendo humana.**

O bot repete texto que **você** escreveu no `faq-data.json`. Ele não gera
conteúdo novo. Revise cada resposta das categorias A, C e E como se fosse
publicá-la assinada — porque é exatamente isso que acontece.

---

## A regra central

| Categoria | Tema | O que o bot faz |
|---|---|---|
| **A** | Sobre o Instituto | ✅ responde automaticamente |
| **B** | Legalidade | 🔎 **nunca responde** — avisa os admins no privado |
| **C** | Ciência | ✅ responde automaticamente |
| **D** | Uso, preparação e segurança | 🔎 **nunca responde** — avisa os admins no privado |
| **E** | Integração, cerimônia e comunidade | ✅ responde automaticamente |

Essa regra é aplicada em **quatro camadas independentes**, de propósito:

1. `RESTRICTED_CATEGORIES` no `.env` — configuração.
2. O `config.ts` recusa subir se uma categoria aparecer em `AUTO_REPLY_CATEGORIES`
   e em `RESTRICTED_CATEGORIES` ao mesmo tempo.
3. O `FaqMatcher` nunca devolve `auto_reply` para uma entrada restrita, por mais
   alto que seja o score — e há um teste que percorre **todas** as entradas B/D
   com **todas** as suas variantes verificando isso.
4. O `bot.ts` confere a categoria mais uma vez na borda do envio e loga `BUG:` se
   algo escapar.

### Além disso: margem de ambiguidade e rede de segurança

**Ambiguidade.** Se a melhor pergunta de A/C/E não superar a melhor de B/D por
`AMBIGUITY_MARGIN` (default `0.10`), o bot trata a mensagem como ambígua, cala a
boca e sinaliza. "Quais as regras do grupo sobre dose?" não vira uma resposta
sobre regras do grupo.

**Rede de segurança lexical.** Qualquer mensagem contendo um termo de
`SAFETY_KEYWORDS` (nomes de antidepressivos, `dose`, `gramas`, `grávida`,
`bipolar`, `comprar`, …) é sinalizada aos admins **independentemente do score**,
e nunca é auto-respondida.

Isso existe porque medimos um ponto cego real do matching lexical:

| Mensagem | Score do matcher | Sem a rede | Com a rede |
|---|---|---|---|
| "tomo fluoxetina há anos, seria um problema?" | 0.061 | ignorada em silêncio | 🔎 sinalizada |
| "quantos gramas pra uma primeira vez?" | 0.420 | ignorada em silêncio | 🔎 sinalizada |
| "tô grávida, tem algum risco?" | 0.073 | ignorada em silêncio | 🔎 sinalizada |

Nome de fármaco e estado clínico não estão no vocabulário do FAQ, então pontuam
baixo e passariam batido — justamente as perguntas que mais precisam de olho
humano. A rede só torna o bot **mais** silencioso; ela nunca faz o bot falar.

---

## Primeiro passo obrigatório: grupo de teste

**Não aponte o bot para o grupo real antes de fazer isto.** A ordem importa.

1. Crie um grupo de WhatsApp privado só com você e talvez um moderador.
2. Adicione o número secundário do bot a esse grupo.
3. Configure `TARGET_GROUP_IDS` **só com o JID do grupo de teste**.
4. Rode com `DRY_RUN=true` (o default) por um tempo e leia os logs: o bot
   processa tudo e mostra o que *teria* feito, sem enviar nada.
5. Faça as perguntas do FAQ de várias formas diferentes, incluindo perguntas de
   dose e legalidade, e confira nos logs que as categorias B/D sempre aparecem
   como `flag_admins` e nunca como `auto_reply`.
6. Só então mude para `DRY_RUN=false` **ainda no grupo de teste** e veja as
   mensagens chegando de verdade.
7. Depois de tudo isso, troque `TARGET_GROUP_IDS` para o grupo real.

`DRY_RUN=true` é o default justamente para que o passo 4 não dependa de você
lembrar dele.

---

## Rodando localmente

Requisitos: **Node.js 20+** (testado no 22) e npm.

```bash
cd ims-whatsapp-bot
npm install
cp .env.example .env
```

### 1. Parear o número e descobrir o JID do grupo

```bash
npm run groups
```

Vai aparecer um QR code no terminal. No celular **do número secundário**:

**WhatsApp → Configurações → Aparelhos conectados → Conectar um aparelho →** aponte
para o QR.

O pareamento fica salvo em `auth_info/` e sobrevive a reinicializações — você só
escaneia de novo se a sessão for invalidada (logout no celular, ou a pasta ser
apagada).

Depois de conectar, o comando lista os grupos:

```
┌─────────┬──────────────────────────────┬──────────────────┬───────────────┐
│ (index) │ jid                          │ nome             │ participantes │
├─────────┼──────────────────────────────┼──────────────────┼───────────────┤
│ 0       │ '1203630xxxxxxxxxx@g.us'     │ 'Teste do bot'   │ 2             │
└─────────┴──────────────────────────────┴──────────────────┴───────────────┘
```

Copie o JID do **grupo de teste** para o `.env`:

```env
TARGET_GROUP_IDS=1203630xxxxxxxxxx@g.us
ADMIN_NUMBERS=5511999999999
DRY_RUN=true
```

### 2. Rodar

```bash
npm run dev     # com reload automático
```

### 3. Calibrar sem WhatsApp

Este é o comando que você mais vai usar ao ajustar o FAQ:

```bash
npm run match -- "qual a dose pra iniciante?"
npm run match -- "o que é o instituto?"

# ou várias de uma vez
printf 'e crime ter cogumelo?\ncomo funciona a integracao?\n' | npm run match
```

Ele mostra a decisão, o motivo e os cinco melhores candidatos com os scores
decompostos (lexical e semântico). Não conecta no WhatsApp, não envia nada.

---

## O formato do `faq-data.json`

Substitua `src/faq-data.json` pelo FAQ real de 38 entradas, mantendo esta forma:

```json
{
  "version": "1.0.0",
  "updatedAt": "2026-09-18",
  "categories": {
    "A": { "name": "Sobre o Instituto", "description": "opcional" },
    "B": { "name": "Legalidade" },
    "C": { "name": "Ciência" },
    "D": { "name": "Uso, preparação e segurança" },
    "E": { "name": "Integração, cerimônia e comunidade" }
  },
  "entries": [
    {
      "id": "A01",
      "category": "A",
      "question": "O que é o Instituto Micélio Sagrado?",
      "variants": [
        "O que é o IMS?",
        "Me explica o que é esse instituto",
        "Qual é a proposta do Micélio Sagrado?"
      ],
      "answer": "Texto exato que o bot envia no grupo.",
      "tags": ["institucional"]
    }
  ]
}
```

| Campo | Obrigatório | Observação |
|---|---|---|
| `id` | sim | único e **estável** — é a chave do cooldown e dos logs |
| `category` | sim | exatamente `A`, `B`, `C`, `D` ou `E` |
| `question` | sim | formulação canônica |
| `variants` | não | **é aqui que se ganha qualidade** (ver abaixo) |
| `answer` | sim | texto literal enviado; para B/D, só serve para uso humano |
| `tags` | não | só organização |

O arquivo é validado no startup: id duplicado, categoria inválida ou resposta
vazia derrubam o bot com mensagem explícita em vez de falhar silenciosamente.

Acentos funcionam normalmente — a normalização interna cuida disso. As respostas
do exemplo contêm o marcador `[SUBSTITUIR]`; enquanto ele existir, o bot avisa no
startup.

### Variantes são o que faz o matching funcionar

Com o matcher lexical (default, offline), **cada variante aumenta muito o
recall**. Medição real deste projeto:

| Mensagem | Melhor score |
|---|---|
| paráfrase próxima de uma variante | 1.000 |
| paráfrase com enchimento ("gente, o que é esse tal de…") | 0.634 |
| pergunta fora do FAQ | 0.052 |

A separação entre acerto e erro é enorme (0.63 contra 0.05), mas uma paráfrase
diluída fica **abaixo** do default de `0.75`. Três a cinco variantes por entrada,
escritas do jeito que as pessoas realmente escrevem no grupo (com gíria, sem
acento, sem ponto de interrogação), resolvem a maior parte disso.

---

## Calibrando os limiares

| Variável | Default | O que faz |
|---|---|---|
| `CONFIDENCE_THRESHOLD` | `0.75` | mínimo para responder |
| `RESTRICTED_FLAG_THRESHOLD` | `0.55` | mínimo para sinalizar B/D |
| `AMBIGUITY_MARGIN` | `0.10` | quanto A/C/E precisa superar B/D |

O limiar de sinalização é **mais baixo** que o de resposta de propósito: na
dúvida, é melhor acordar um moderador do que arriscar uma resposta automática.

**Se você ficar só no modo lexical** (`EMBEDDINGS_PROVIDER=none`), `0.75` é
conservador — muita paráfrase legítima vai ficar sem resposta. Duas saídas, nesta
ordem de preferência:

1. Escrever mais variantes (não custa nada e melhora a precisão também).
2. Baixar `CONFIDENCE_THRESHOLD` para algo em torno de `0.60`, **conferindo antes
   com `npm run match`** que nenhuma pergunta de B/D passa a ser respondida.

Falhar calado é o modo de falha correto para este bot. Prefira um limiar alto
demais a um limiar baixo demais.

### Matching semântico opcional

O default não usa rede nem chave de API: o score é 60% cosseno TF-IDF sobre
tokens + 40% Dice sobre trigramas de caracteres, tudo sobre o texto normalizado
(sem acento, sem pontuação, sem stopwords em português).

Para paráfrases mais distantes, ligue embeddings:

```env
EMBEDDINGS_PROVIDER=openai
EMBEDDINGS_API_KEY=sk-...
EMBEDDINGS_MODEL=text-embedding-3-small
SEMANTIC_WEIGHT=0.65
```

Funciona com qualquer API compatível com o endpoint `/embeddings` da OpenAI —
basta trocar `EMBEDDINGS_BASE_URL`. Os embeddings do FAQ são calculados uma vez
no startup; só a mensagem recebida gera chamada, com cache das últimas 500.

**Nota de privacidade:** com embeddings ligados, o texto das mensagens do grupo é
enviado para a API escolhida. Considere se isso é aceitável para um grupo que
discute esse tema, e mencione no combinado do grupo.

---

## Anti-spam

| Variável | Default | Comportamento |
|---|---|---|
| `COOLDOWN_HOURS` | `24` | não repete a mesma resposta para a mesma pessoa |
| `ADMIN_NOTIFY_COOLDOWN_HOURS` | `6` | não repete a mesma sinalização aos admins |
| `MAX_REPLIES_PER_HOUR` | `6` | teto global, janela deslizante de 60 min |
| `REPLY_DELAY_MIN_MS` / `MAX_MS` | `2000` / `5000` | atraso aleatório antes de responder |
| `MIN_MESSAGE_LENGTH` | `12` | abaixo disso nem tenta |

O cooldown é por `(pessoa, id da entrada)`: a mesma pessoa pode receber respostas
sobre assuntos diferentes no mesmo dia, mas não a mesma resposta duas vezes.

O bot também só considera mensagens dos últimos 5 minutos, para não responder
histórico antigo ao reconectar, e guarda os `message_id` já processados para não
responder duas vezes em caso de reentrega.

---

## Logs

Tudo vai para SQLite em `DB_PATH` (default `data/bot.sqlite`).

Tabela `events` — uma linha por mensagem processada:

```
ts, group_jid, sender_jid, message_id, message_text,
decision, outcome, reason,
faq_id, faq_category, score,
restricted_faq_id, restricted_category, restricted_score
```

`decision` é o que o matcher decidiu; `outcome` é o que de fato aconteceu:

| `outcome` | Significado |
|---|---|
| `replied` | respondeu no grupo |
| `flagged` | avisou os admins |
| `ignored` | não fez nada |
| `suppressed_cooldown` | ia agir, mas estava em cooldown |
| `suppressed_rate_limit` | ia responder, mas estourou o teto por hora |
| `suppressed_dry_run` | ia agir, mas `DRY_RUN=true` |
| `send_failed` | tentou enviar e falhou |

Consultas úteis:

```bash
sqlite3 data/bot.sqlite "SELECT outcome, COUNT(*) FROM events GROUP BY outcome;"

# o que foi sinalizado aos admins, mais recente primeiro
sqlite3 -box data/bot.sqlite \
  "SELECT ts, restricted_category, restricted_score, message_text
     FROM events WHERE outcome='flagged' ORDER BY ts DESC LIMIT 20;"

# quase-acertos: bom insumo para escrever variantes novas
sqlite3 -box data/bot.sqlite \
  "SELECT ts, faq_id, ROUND(score,3) AS score, message_text
     FROM events WHERE outcome='ignored' AND score > 0.4
     ORDER BY score DESC LIMIT 30;"
```

A última consulta é a mais valiosa na primeira semana: são as perguntas que o bot
quase reconheceu. Cada uma é uma variante que está faltando no `faq-data.json`.

> O banco contém mensagens reais de pessoas do grupo. Trate como dado sensível:
> não vai para o Git, e o backup precisa ser tão protegido quanto o servidor.

---

## Deploy na VPS (Hetzner)

Uma VPS pequena (CX22 ou equivalente) dá conta de sobra.

### 1. Preparar o servidor

```bash
ssh root@SEU_IP

adduser ims && usermod -aG sudo ims
su - ims

curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs build-essential sqlite3
node --version
```

`build-essential` é necessário para o `better-sqlite3` compilar caso não exista
binário pré-compilado para a plataforma.

### 2. Subir o código

```bash
git clone SEU_REPO ims-whatsapp-bot
cd ims-whatsapp-bot
npm ci
npm run build
cp .env.example .env
nano .env          # preencha, começando com DRY_RUN=true
```

### 3. Parear o QR code no servidor

O QR aparece no terminal, então basta estar em uma sessão SSH interativa:

```bash
npm run groups
```

Escaneie com o celular do número secundário. O `auth_info/` fica no servidor e
persiste — **não copie essa pasta da sua máquina para a VPS**; pareie direto lá.

### 4. systemd

```bash
sudo nano /etc/systemd/system/ims-bot.service
```

```ini
[Unit]
Description=IMS WhatsApp FAQ Bot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ims
WorkingDirectory=/home/ims/ims-whatsapp-bot
ExecStart=/usr/bin/node dist/bot.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Endurecimento básico
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=false
ReadWritePaths=/home/ims/ims-whatsapp-bot

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ims-bot
sudo systemctl status ims-bot
journalctl -u ims-bot -f        # acompanhar ao vivo
```

### 5. Backup

O que importa preservar:

```bash
# auth_info/ evita ter que reparear; data/ é o histórico
tar czf ~/ims-backup-$(date +%F).tar.gz auth_info data
```

Guarde fora da VPS e com a mesma proteção que você daria a uma senha.

### Atualizando

```bash
cd ~/ims-whatsapp-bot
git pull
npm ci
npm run build
sudo systemctl restart ims-bot
```

---

## Reconexão e desconexão

O WhatsApp derruba a conexão com frequência; isso é normal e o bot lida sozinho.

- **Queda comum:** reconecta com backoff exponencial (2s, 4s, 8s… teto de 60s),
  até `MAX_RECONNECT_ATTEMPTS` (default 10). O contador zera a cada conexão
  bem-sucedida.
- **Logout no celular** (`DisconnectReason.loggedOut`): a sessão foi invalidada e
  reconectar não adianta. O bot encerra com instrução explícita — apague
  `auth_info/` e pareie de novo.
- **Mensagens durante a queda:** não são recuperadas. O bot ignora mensagens com
  mais de 5 minutos para não responder histórico ao voltar.
- **Encerramento limpo:** `SIGINT`/`SIGTERM` fecham o banco e imprimem um resumo.

O bot sobe com `markOnlineOnConnect: false` para não roubar as notificações do
celular pareado, e `syncFullHistory: false` para não baixar todo o histórico.

---

## Testes

```bash
npm test          # 46 testes
npm run typecheck
```

A suíte cobre, entre outras coisas:

- normalização pt-BR (acento, caixa, alongamento de vogais, stopwords);
- detecção de pergunta sem ponto de interrogação;
- resposta correta para paráfrases de A, C e E;
- **um teste que percorre todas as entradas B/D com todas as suas variantes** e
  falha se alguma delas resultar em `auto_reply`;
- a margem de ambiguidade segurando uma resposta quando B/D está perto demais;
- a rede de segurança pegando perguntas que o matcher sozinho ignora;
- a calibração medida (a paráfrase diluída que fica em ~0.63) — se esse número
  mudar, o teste quebra e o README precisa ser revisto junto;
- cooldown, janela deslizante do rate limit e log no SQLite.

---

## Estrutura

```
src/
  bot.ts          conexão Baileys, listener, reconexão, fluxo de decisão
  faq-matcher.ts  matching e as regras de categoria (arquivo crítico)
  faq-data.json   o FAQ
  config.ts       toda a configuração, via variáveis de ambiente
  embeddings.ts   provedor opcional de embeddings
  store.ts        SQLite: log, cooldown, rate limit
  text.ts         normalização pt-BR e rede de segurança lexical
  types.ts        tipos compartilhados
  list-groups.ts  `npm run groups`
  try-match.ts    `npm run match`
tests/
  faq-matcher.test.ts
  store.test.ts
  fixtures/faq-test.json
```

---

## Limitações conhecidas

- **Só texto.** Áudio, imagem e vídeo são ignorados (legendas de imagem/vídeo são
  lidas). Num grupo onde muita gente manda áudio, boa parte das perguntas não
  chega ao bot.
- **Sem contexto de conversa.** Cada mensagem é avaliada isoladamente. "E pra
  quem toma remédio?" logo depois de outra pergunta não é entendido como
  continuação — mas a rede de segurança pega esse caso específico.
- **Sem memória entre reinícios além do SQLite.** Cooldown e rate limit
  sobrevivem ao restart; o estado da conversa, não.
- **O matching lexical não entende sinônimo que não esteja escrito.** É por isso
  que variantes importam tanto, e é por isso que existe a rede de segurança.
