# Os quatro estudos complementares

Nota de trabalho para discussão com Erika e Paulo (Miudo). Aqui está descrito **o que cada
estudo faz**, não os resultados. Os resultados preliminares vão numa segunda rodada, depois
que a gente concordar que o desenho está claro.

---

## Vocabulário usado nesta nota

Para evitar ambiguidade, alguns termos aparecem sempre com o mesmo sentido:

**Traço do macho (z).** A característica sexualmente selecionada que os machos expressam
(por exemplo, o tamanho de uma estrutura ou a intensidade de uma coloração). É o que as
fêmeas avaliam na hora de decidir se aceitam ou não.

**Preferência da fêmea (p).** O valor de traço que cada fêmea considera ideal, ou seja, o
pico da sua função de preferência. Não é o mesmo que exigência: a exigência (choosiness, s)
é o quão estrita ela é em torno desse pico, e nesta rodada s fica fixo em todos os estudos.

**Curva de preferência.** A regra que traduz o pico p da fêmea em uma probabilidade de
aceitar um macho de traço z. São quatro regras diferentes, descritas mais adiante. É uma
propriedade fixa do cenário, não evolui em nenhum dos estudos.

**sigma_p.** O quanto o pico de preferência varia entre as fêmeas da população. Valor baixo
significa que quase todas as fêmeas preferem o mesmo tipo de macho; valor alto significa que
elas discordam bastante entre si.

**sigma_z.** O quanto o traço varia entre os machos da população, ou seja, quanta variedade
de machos existe disponível para as fêmeas escolherem.

**Característica herdável.** Uma característica que os filhotes recebem dos pais. Ser
herdável é uma condição necessária para que ela possa responder à seleção, mas não garante
que ela vá mudar: se não houver seleção agindo sobre ela, ela apenas deriva ao acaso. Nesta
nota, quando dizemos que uma característica é herdável, estamos dizendo que ela está **livre
para evoluir**, e não que ela necessariamente evoluiu. Se evoluiu ou não, e em que direção,
é um resultado a ser observado.

**Característica re-sorteada (congelada).** Uma característica que não é herdada: a cada
geração seus valores são sorteados de novo da mesma distribuição, independentemente de quem
eram os pais. Ela nunca pode responder à seleção, por construção.

**Característica ambiental.** Mesma coisa que re-sorteada, mas com uma leitura biológica
específica: o valor que o indivíduo expressa depende da condição em que ele se desenvolveu
(alimento, ambiente), não do que ele herdou. Por isso não passa para os filhotes.

---

## A lógica: por que quatro estudos

Todos os estudos compartilham o mesmo ciclo de vida e as mesmas quatro curvas de preferência.
O que muda entre eles é **quais características são herdadas**, ou seja, quais delas estão
livres para responder à seleção. Cada estudo isola uma peça diferente do sistema:

| Estudo | Traço do macho (z) | Preferência da fêmea (p) | O que o estudo isola |
|---|---|---|---|
| **1. Sem evolução** | ambiental (re-sorteado) | re-sorteada | o efeito das regras de acasalamento sozinhas, sem nenhuma resposta evolutiva |
| **2. Fêmeas variando** | herdável, livre para evoluir | re-sorteada | como a heterogeneidade de preferência afeta a resposta evolutiva do traço |
| **3. Machos variando** | ambiental (re-sorteado) | herdável, livre para evoluir | como a disponibilidade de machos afeta a resposta evolutiva da preferência |
| **4. Co-evolução** | herdável, livre para evoluir | herdável, livre para evoluir | o feedback entre as duas (mecanismo de Fisher) |

Vale insistir num ponto: "livre para evoluir" descreve o desenho, não o resultado. Em vários
cenários a característica herdável pode simplesmente não mudar. O exemplo mais claro é a curva
de preferência aleatória, em que as fêmeas não discriminam entre machos: ali o traço continua
sendo herdável, mas como nenhuma seleção sexual age sobre ele, ele apenas deriva ao acaso. Ou
seja, a comparação entre curvas de preferência é justamente o que revela quando a herdabilidade
se traduz em mudança evolutiva e quando não.

A comparação entre os estudos é o que dá o poder inferencial:
- A diferença entre o Estudo 2 e o Estudo 1 mostra o que a resposta evolutiva do traço acrescenta.
- A diferença entre o Estudo 3 e o Estudo 1 mostra o que a resposta evolutiva da preferência acrescenta.
- O Estudo 4 mostra o que emerge quando as duas evoluem juntas, que não é a soma dos anteriores.

---

## Estudo 1. Sem evolução (controle nulo)

**Pergunta.** Que topologia de rede as regras de acasalamento produzem por si só, antes de
qualquer resposta evolutiva?

**Como funciona.** Nenhuma característica é herdada. A cada geração, tanto o traço dos machos
quanto o pico de preferência das fêmeas são re-sorteados das mesmas distribuições. A rede de
acasalamentos se forma, medem-se as métricas de topologia, e a geração seguinte recomeça do
zero. Não existe feedback entre gerações.

**Por que importa.** É a linha de base contra a qual os outros estudos são lidos. Sem ela não
dá para separar "esta topologia vem da regra de escolha" de "esta topologia vem da evolução
que já aconteceu nas gerações anteriores".

**Observação prática.** Como nada é herdado, cada geração é uma amostra independente das
demais, e a dinâmica não existe. Isso significa que a **geração 1 do Estudo 2 já é este
controle** (com sigma_z fixo em 1.0): na primeira geração ainda não houve nenhuma resposta
evolutiva. O controle sai de graça dos dados que já temos, e vem pareado com o experimento
(mesmas réplicas, mesmas sementes), o que é estatisticamente mais forte do que rodar um
controle separado.

**Estado.** Disponível dentro dos dados do Estudo 2. Só valeria a pena escrever um script
próprio se quiséssemos cruzar sigma_p com sigma_z na ausência de evolução, o que hoje não
está em nenhuma das hipóteses.

---

## Estudo 2. Fêmeas variando: sigma_p varia, o traço do macho é herdável

**Pergunta.** Como a variação do pico de preferência entre as fêmeas (sigma_p) afeta a
topologia da rede de acasalamentos e a resposta evolutiva do traço masculino?

**Como funciona.**
- O eixo do experimento é **sigma_p**, que varia de 0.2 (fêmeas quase todas iguais no que
  preferem) a 2.0 (fêmeas bem diferentes entre si).
- A preferência é **re-sorteada** a cada geração de uma distribuição fixa. Ela não é herdada
  e portanto não pode evoluir, por construção. Isso é intencional: fixa a distribuição de
  preferências e permite isolar o efeito da forma da curva de preferência e da largura dessa
  distribuição, sem o confundimento de a preferência estar mudando ao mesmo tempo.
- O traço do macho é **herdável** e portanto livre para evoluir: os filhotes recebem a média
  dos pais mais a variância de segregação, e os dois sexos carregam o traço (a fêmea carrega
  sem expressar).

**O papel da escolha da fêmea aqui é ser a CAUSA da seleção.** Ela não muda ao longo do tempo;
é ela que gera a pressão seletiva sobre o traço masculino. Se o traço vai de fato mudar, e
quanto, depende da curva de preferência e é justamente o que o estudo mede.

**Variáveis resposta.** Métricas de topologia da rede (modularidade, aninhamento, centralização
e oportunidade de seleção sexual Is), média e variância do traço masculino ao longo das gerações,
e a proporção de fêmeas que ficaram sem acasalar.

**Estado.** Concluído. 15.120 cenários (4 curvas de preferência x 7 valores de sigma_p x 3
valores de A_max x 3 valores de k x 2 regimes de seleção natural x 30 réplicas), 100 gerações
cada, sem falhas.

---

## Estudo 3. Machos variando: sigma_z varia, a preferência da fêmea é herdável

**Pergunta.** Como a disponibilidade de machos com traços variados (sigma_z) afeta a resposta
evolutiva da preferência feminina?

**Como funciona.** É o espelho do Estudo 2: os papéis se invertem.
- O eixo do experimento é **sigma_z**, que varia de 0.2 (machos quase todos parecidos) a 2.0
  (machos muito variados).
- O traço do macho passa a ser **ambiental**: é re-sorteado a cada geração e não é herdado.
  A leitura biológica é de dependência de condição, ou seja, o macho expressa aquele traço
  por causa do ambiente em que se desenvolveu, e não por causa dos genes que vai transmitir.
- O pico de preferência da fêmea passa a ser **herdável** e bi-parental, portanto livre para
  evoluir: os dois sexos carregam p (o macho carrega sem expressar, do mesmo modo que no
  Estudo 2 a fêmea carrega o traço sem expressar) e o filhote recebe a média dos pais mais a
  variância de segregação.

**Aqui o papel da escolha da fêmea se inverte: ela deixa de ser a causa da seleção e passa a
ser o ALVO dela.** A força seletiva que age sobre a preferência é ecológica, não sexual: é a
disponibilidade de machos. É a analogia que a Erika propôs, de que a planta não escolhe, mas a
disponibilidade de plantas gera seleção sobre a preferência do herbívoro que escolhe.

**O que pode evoluir é o pico p**, ou seja, qual valor de traço a fêmea prefere. A exigência
(choosiness) continua fixa e não evolui neste estudo.

**Uma condição necessária para o estudo funcionar.** Para que exista seleção sobre a preferência
é preciso que haja variância de sucesso reprodutivo entre as fêmeas. Se todas deixassem o mesmo
número de filhotes, nenhuma preferência seria mais bem-sucedida que outra e a preferência apenas
derivaria. Por isso tiramos a regra de escape: agora uma fêmea que não aceita nenhum macho fica
sem acasalar e deixa zero filhotes. A fecundidade continua neutra (quem acasalou deixa sempre o
mesmo número de filhotes, independentemente de com quantos machos acasalou), como tínhamos
combinado.

**Variáveis resposta.** As mesmas métricas de topologia da rede, mais a média e a variância do
pico de preferência ao longo das gerações, e a proporção de fêmeas sem acasalar, que aqui deixa
de ser apenas descritiva e passa a ser o indicador direto da força de seleção agindo sobre a
preferência.

**Estado.** Rodando, com o mesmo desenho fatorial do Estudo 2 e 30 réplicas.

---

## Estudo 4. Co-evolução entre preferência e traço (planejado)

**Pergunta.** O que acontece quando as duas características são herdáveis ao mesmo tempo?

**Como funciona.** Traço e preferência são **ambos herdáveis**, e cada indivíduo carrega os dois
genótipos: o macho carrega o pico de preferência sem expressar, e a fêmea carrega o traço sem
expressar.

**A grandeza central deixa de ser a média de cada característica e passa a ser a covariância
genética entre elas, cov(z, p).** O acasalamento assortativo constrói essa covariância: fêmeas
que preferem machos com traço alto acasalam com machos de traço alto, e os filhotes desses casais
herdam juntos os genes da preferência e os genes do traço. Uma vez que essa associação existe, a
seleção que age sobre o traço arrasta a preferência junto, mesmo sem nenhuma seleção agindo
diretamente sobre a preferência. Esse é o mecanismo do Fisherian runaway (Lande 1981;
Kirkpatrick 1982).

**Um cuidado de implementação que vale registrar.** Como cada indivíduo carrega duas
características que precisam viajar juntas, os filhotes têm que ser amostrados por índice, e não
por valor. Se o traço e a preferência forem embaralhados separadamente, a covariância entre eles
é destruída e o runaway desaparece por causa de um erro de programação, e não por causa da
biologia. É o tipo de erro que não gera mensagem de erro nenhuma.

**Estado.** Motor rascunhado, ainda não rodado.

---

## O que é comum aos quatro estudos

**População.** 200 machos e 200 fêmeas, gerações discretas e não sobrepostas, 100 gerações por
réplica, tamanho populacional constante.

**As quatro curvas de preferência.** Todas partem do mesmo pico médio, de modo que as diferenças
entre elas vêm da geometria da regra e não de as fêmeas quererem coisas diferentes em média:
- **Aleatória (nula).** A fêmea aceita qualquer macho com a mesma probabilidade. Serve de
  controle: aqui não existe seleção sexual, então qualquer mudança no traço é deriva.
- **Gaussiana (estabilizadora).** A fêmea aceita machos cujo traço está próximo do seu pico, e
  rejeita tanto os muito maiores quanto os muito menores.
- **Sigmoide (direcional).** A fêmea aceita machos cujo traço supera o seu pico, e quanto mais
  o supera, mais provável é o aceite.
- **U-shaped (disruptiva).** A fêmea evita machos parecidos com o seu pico e aceita os que estão
  distantes dele, para mais ou para menos.

**Fatores cruzados em todos os estudos rodados.**
- **A_max**: quantos machos distintos cada fêmea consegue avaliar antes de decidir (200, 40 ou
  10). Representa o custo ecológico de procurar parceiro.
- **k**: quantos parceiros cada fêmea acasala (5, 10 ou 20). Representa o grau de poliandria.
- **Seleção natural de viabilidade** sobre o traço do macho, ligada ou desligada.

**Decisões de modelo tomadas nesta rodada.**
1. **Amostragem sem reposição.** A_max passa a ser literalmente o número de machos distintos
   que a fêmea avalia. Antes, com reposição, ela reencontrava o mesmo macho várias vezes e via
   menos machos distintos do que o parâmetro sugeria.
2. **Sem regra de escape.** Antes, uma fêmea que não aceitasse ninguém acasalava com o último
   macho avaliado, de modo que todas acasalavam. Agora ela fica sem acasalar e deixa zero
   filhotes. Sem essa mudança não existiria variância de sucesso reprodutivo entre fêmeas, e o
   Estudo 3 seria impossível.
3. **Fecundidade neutra.** A poliandria não aumenta o número de filhotes; ela só distribui a
   paternidade entre os parceiros.
4. **Variância de segregação proporcional** (modelo infinitesimal de Falconer e Mackay). O
   desvio dos filhotes em relação à média dos pais tem variância igual a metade da variância
   parental, em vez de um ruído fixo. Com ruído fixo, a variância genética erodia geração após
   geração até um piso artificial baixo, e isso comprimia artificialmente a resposta evolutiva
   de qualquer característica herdável.

**Réplicas.** 30 nesta rodada de exploração, 100 na rodada final.

---

## Como a comparação entre estudos responde às hipóteses

- **H1: a forma da curva de preferência gera assinaturas topológicas distintas.** O Estudo 1
  testa isso sem o confundimento da evolução, ou seja, mostra a topologia que a regra de escolha
  produz sozinha. O Estudo 2 mostra se essa assinatura persiste depois de 100 gerações de
  resposta evolutiva do traço.
- **H2: a topologia da rede prediz a trajetória evolutiva.** O Estudo 2 testa isso para o traço
  do macho, e o Estudo 3 testa o análogo para a preferência da fêmea.
- **H3: a restrição de amostragem apaga as assinaturas topológicas.** O gradiente de A_max está
  presente nos três estudos rodados, então dá para verificar se o efeito do custo de busca é o
  mesmo quando quem responde à seleção é o traço e quando é a preferência.
- **Mecanismo de Fisher.** Só o Estudo 4 pode testar, porque é o único desenho em que a
  covariância genética entre preferência e traço pode se acumular.
