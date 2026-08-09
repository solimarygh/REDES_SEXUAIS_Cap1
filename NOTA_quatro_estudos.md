# Os quatro estudos complementares

Olá Erika y Paulo. Aqui está descrito o que cada
estudo faz, não os resultados. Os resultados preliminares vão num documento à parte
(`Resultados_Preliminares.Rmd`).

Esta versão da nota foi conferida linha a linha contra o código. A última seção lista, para
cada afirmação, o arquivo e a função onde ela pode ser verificada.

O histórico das decisões que levaram a este desenho está em duas notas de reunião aparte. Esta nota descreve o desenho; aquelas contam por que ele é assim.

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
que ela vá mudar. Se evoluiu ou não, e em que direção,
é um resultado a ser observado.

**Característica re-sorteada (congelada).** Uma característica que não é herdada: a cada
geração seus valores são sorteados de novo da mesma distribuição, independentemente de quem
eram os pais. Ela nunca pode responder à seleção, por construção.

**Característica  re-sorteada (ambiental).** Mesma coisa que re-sorteada, mas com uma leitura biológica
específica (pensando mais específicamente no trait z dos machos): o valor que o indivíduo expressa depende da condição em que ele se desenvolveu
(alimento, ambiente), não do que ele herdou. Por isso não passa para os filhotes.

**Parâmetro imposto e condição inicial.** Na hora de comparar os estudos, uma distinção que importa para comparar os
estudos é que um parâmetro imposto é re-aplicado a cada geração e portanto continua valendo do
começo ao fim da réplica. Já, uma condição inicial vale só na geração 1, e daí em diante a
distribuição fica por conta da seleção e da deriva. No Estudo 2 (femeas variando), os 7 níveis de sigma_p são impostos, e sigma_z_init é a condição inicial (fija en 1.0); no
Estudo 3 (o espelho, machos variando), os 7 níveis de sigma_p são impostos, e sigma_p_init é apenas condição inicial (fija en 1.0). 
Nesse aspecto os dois estudos são simétricos. A assimetria real está noutro ponto: a seleção natural de viabilidade age sobre z nos dois estudos, mas no Estudo 2 ela age diretamente sobre a característica que evolui, competindo com a seleção sexual, enquanto no Estudo 3 ela age sobre uma característica ambiental e não tem consequência evolutiva nenhuma. A preferência, que é o que evolui ali, não recebe seleção natural.
---

## A lógica: por que quatro estudos

Todos os estudos compartilham o mesmo ciclo de vida e as mesmas quatro curvas de preferência.
O que muda entre eles é quais características são herdadas, ou seja, quais delas estão
livres para responder à seleção. Cada estudo isola uma peça diferente do sistema:

| Estudo | Traço do macho (z) | Preferência da fêmea (p) | O que o estudo isola |
|---|---|---|---|
| 1. Sem evolução | sorteado | sorteada | o efeito das regras de acasalamento sozinhas, sem nenhuma resposta evolutiva |
| 2. Fêmeas variando | herdável, livre para evoluir | re-sorteada | como a heterogeneidade de preferência afeta a resposta evolutiva do traço |
| 3. Machos variando |  re-sorteado (ambiental) | herdável, livre para evoluir | como a disponibilidade de machos afeta a resposta evolutiva da preferência |
| 4. Co-evolução | herdável, livre para evoluir | herdável, livre para evoluir | o feedback entre as duas (mecanismo de Fisher) |

Vale insistir num ponto: "livre para evoluir" descreve o desenho, não o resultado. Em vários
cenários a característica herdável pode simplesmente não mudar. O exemplo mais claro é a curva
de preferência aleatória, em que as fêmeas não discriminam entre machos: ali o traço continua
sendo herdável, mas como nenhuma seleção sexual age sobre ele, ele apenas deriva ao acaso. A comparação entre curvas de preferência é justamente o que revela quando a herdabilidade
se traduz em mudança evolutiva e quando não.

A comparação entre os estudos nos ajuda a entender o sistema melhor: 
- A diferença entre o Estudo 2 e o Estudo 1 mostra o que a resposta evolutiva do traço acrescenta.
- A diferença entre o Estudo 3 e o Estudo 1 mostra o que a resposta evolutiva da preferência acrescenta.
- O Estudo 4 mostra o que emerge quando as duas evoluem juntas, que não é a soma dos anteriores.

---

## Estudo 1. Sem evolução (controle nulo)

**Pergunta.** Que topologia de rede as regras de acasalamento produzem por si só, antes de
qualquer resposta evolutiva?

**Como funciona.** Nenhuma característica é herdada. O traço dos machos e o pico de preferência
das fêmeas são sorteados, a seleção natural de viabilidade filtra os machos (quando está
ligada), a rede de acasalamentos se forma, medem-se as métricas de topologia, e acabou. Não
existe geração seguinte nem feedback. A seleção natural entra aqui como filtro puramente
ecológico: ela muda quais machos estão disponíveis para as fêmeas, mas não tem consequência
evolutiva nenhuma, porque não há geração seguinte para receber o efeito.

**Por que basta uma única geração.** Sem herança, a geração 2 seria um sorteio independente da
geração 1, com exatamente a mesma distribuição. Rodar 100 gerações seria apenas fazer 100
réplicas disfarçadas. Por isso rodamos uma geração e usamos as réplicas para estimar a
variabilidade. Isso torna cada cenário cerca de cem vezes mais barato que nos outros estudos, e
é justamente o que permite cruzar sigma_p com sigma_z por inteiro sem custo proibitivo.

**Por que ele precisa ser um estudo independente.** A geração 1 dos outros estudos já é um
controle, porque na primeira geração nada evoluiu ainda. Mas cada um cobre apenas uma linha do
espaço de parâmetros:
- A geração 1 do Estudo 2 varre sigma_p, mas com sigma_z fixo em 1.0.
- A geração 1 do Estudo 3 varre sigma_z, mas com sigma_p fixo em 1.0.

As duas se cruzam exatamente no ponto sigma_p = sigma_z = 1.0, que é literalmente o mesmo
cenário nos dois estudos. Juntas, portanto, elas formam uma cruz no espaço de parâmetros, e as
combinações extremas ficam de fora: nunca se observa, por exemplo, fêmeas muito heterogêneas
diante de machos muito homogêneos, ou o contrário. Como justamente essas combinações extremas
são as mais informativas sobre o que a regra de acasalamento faz sozinha, vale a pena rodar a
superfície inteira.

**Por que não aproveitar a geração 1 do Estudo 4.** Seria possível: se o Estudo 4 cruzasse
sigma_p com sigma_z nas condições iniciais, a sua geração 1 daria a superfície completa de
graça. Mas isso obrigaria o Estudo 4 a ter um desenho sete vezes maior por uma razão que não é
dele: no Estudo 4 o que interessa é a dinâmica da covariância entre preferência e traço, e não
quanta variância havia no ponto de partida. Como este controle é barato, sai mais em conta
mantê-lo separado e deixar o Estudo 4 livre para ser desenhado segundo a sua própria pergunta.

**Desenho.** Cruzamento completo de sigma_p (7 valores: 0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0) por
sigma_z (os mesmos 7 valores), somado aos mesmos fatores dos outros estudos: 4 curvas de
preferência, 3 valores de A_max, 3 valores de k e 2 regimes de seleção natural. Com 20 réplicas,
isso dá 4 x 7 x 7 x 3 x 3 x 2 x 20 = 70.560 cenários, de uma geração cada.

**Estado.** Concluído com o modelo atual (censo de adultos constante e poliandria realizada):
70.560 cenários, 20 réplicas, sem falhas. As análises do plano do Estudo 4 citadas mais adiante
vêm de uma rodada anterior, com 30 réplicas e o modelo antigo, e devem ser refeitas sobre estes
dados. Script `Fase_Controle.R`, semente base 2029.

---

## Estudo 2. Fêmeas variando: sigma_p varia, o traço do macho é herdável

**Pergunta.** Como a variação do pico de preferência entre as fêmeas (sigma_p) afeta a
topologia da rede de acasalamentos e a resposta evolutiva do traço masculino?

**Como funciona.**
- O eixo do experimento é sigma_p, que varia de 0.2 (fêmeas quase todas iguais no que
  preferem) a 2.0 (fêmeas bem diferentes entre si).
- A preferência é re-sorteada a cada geração de uma distribuição fixa N(5, sigma_p). Ela não é
  herdada e portanto não pode evoluir, por construção. Isso é intencional: fixa a distribuição
  de preferências e permite isolar o efeito da forma da curva de preferência e da largura dessa
  distribuição, sem o confundimento de a preferência estar mudando ao mesmo tempo.
- O traço do macho é herdável e portanto livre para evoluir: os filhotes recebem a média
  dos pais mais a variância de segregação, e os dois sexos carregam o traço. A fêmea carrega
  sem expressar, o que é o que permite que o traço passe pela linhagem materna também.
- O traço da fêmea, na geração 1, é sorteado da mesma distribuição N(5, sigma_z_init) que o dos
  machos. Nos cenários deste estudo sigma_z_init fica fixo em 1.0.

**O papel da escolha da fêmea aqui é ser a causa da seleção.** Ela não muda ao longo do tempo;
é ela que gera a pressão seletiva sobre o traço masculino. Se o traço vai de fato mudar, e
quanto, depende da curva de preferência e é justamente o que o estudo mede.

**Variáveis resposta.** Métricas de topologia da rede (modularidade, aninhamento, centralização
e oportunidade de seleção sexual Is), média e variância do traço dos machos sobreviventes ao
longo das gerações, e a proporção de fêmeas que ficaram sem acasalar.

**Estado.** Rodando com o modelo atual: 10.080 cenários (4 curvas de preferência x 7 valores de
sigma_p x 3 valores de A_max x 3 valores de k x 2 regimes de seleção natural x 20 réplicas), 100
gerações cada, repartido entre duas máquinas Linux. As réplicas 1 a 8 já terminaram, sem falhas e
sem nenhum cenário encerrado antes das 100 gerações. Script `Fase4_TodasAsCurvas.R`, semente
base 2026.

---

## Estudo 3. Machos variando: sigma_z varia, a preferência da fêmea é herdável

**Pergunta.** Como a disponibilidade de machos com traços variados (sigma_z) afeta a resposta
evolutiva da preferência feminina?

**Como funciona.** É o espelho do Estudo 2: os papéis se invertem.
- O eixo do experimento é sigma_z, que varia de 0.2 (machos quase todos parecidos) a 2.0
  (machos muito variados).
- O traço do macho passa a ser ambiental: é re-sorteado a cada geração de N(5, sigma_z) e não é
  herdado. A leitura biológica é de dependência de condição, ou seja, o macho expressa aquele
  traço por causa do ambiente em que se desenvolveu, e não por causa dos genes que vai transmitir.
- O pico de preferência da fêmea passa a ser herdável e bi-parental, portanto livre para
  evoluir: os dois sexos carregam p (o macho carrega sem expressar, do mesmo modo que no
  Estudo 2 a fêmea carrega o traço sem expressar) e o filhote recebe a média dos pais mais a
  variância de segregação.

**Aqui o papel da escolha da fêmea se inverte: ela deixa de ser a causa da seleção e passa a
ser o alvo dela.** A força seletiva que age sobre a preferência é ecológica, não sexual: é a
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

**Uma assimetria estrutural que vale declarar no paper.** No Estudo 2, sigma_p é um parâmetro
imposto: a distribuição de preferências é re-sorteada com aquela largura a cada uma das 100
gerações, então o tratamento continua valendo até o fim. No Estudo 3, sigma_z também é imposto
a cada geração (o traço é re-sorteado), mas sigma_p_init é apenas condição inicial, fixada em
1.0 em todos os cenários: da geração 2 em diante a largura da distribuição de preferências é o
que a seleção e a deriva fizerem dela. Os dois estudos são espelhos no que diz respeito ao eixo
do experimento, que é imposto nos dois casos, mas não no que diz respeito à característica que
evolui. Foi exatamente por causa dessa assimetria que descartamos a primeira versão do
experimento inverso (`Fase_MachoVariando.R`), em que o eixo era sigma_z_init, ou seja, uma
condição inicial e não uma propriedade permanente da população. Esse script continua no
repositório apenas como registro dessa tentativa, e não é um dos quatro estudos.

**Variáveis resposta.** As mesmas métricas de topologia da rede, mais a média e a variância do
pico de preferência ao longo das gerações, e a proporção de fêmeas sem acasalar, que aqui deixa
de ser apenas descritiva e passa a ser o indicador direto da força de seleção agindo sobre a
preferência. A preferência é registrada de duas formas: no pool genotípico (os dois sexos
juntos, que é a variável evolutiva propriamente dita) e apenas nas fêmeas (que é a preferência
efetivamente expressa e que gera a rede).

**Estado.** Concluído com o modelo atual: 10.080 cenários, mesmo desenho fatorial do Estudo 2,
20 réplicas, 100 gerações cada. Script `Fase_Espelho.R`, semente base 2028.

---

## Estudo 4. Co-evolução entre preferência e traço (proposta)

**Pergunta.** O que acontece quando as duas características são herdáveis ao mesmo tempo?

**Como funciona.** Traço e preferência são ambos herdáveis, e cada indivíduo carrega os dois
genótipos: o macho carrega o pico de preferência sem expressar, e a fêmea carrega o traço sem
expressar. A expressão continua sendo dimórfica (só o macho mostra z, só a fêmea usa p), mas a
transmissão é bi-parental para as duas características.

**A grandeza central deixa de ser a média de cada característica e passa a ser a covariância
genética entre elas, cov(z, p).** O acasalamento assortativo constrói essa covariância: fêmeas
que preferem machos com traço alto acasalam com machos de traço alto, e os filhotes desses casais
herdam juntos os genes da preferência e os genes do traço. Uma vez que essa associação existe, a
seleção que age sobre o traço arrasta a preferência junto, mesmo sem nenhuma seleção agindo
diretamente sobre a preferência. Esse é o mecanismo do Fisherian runaway (Lande 1981;
Kirkpatrick 1982).

**Como as quatro curvas de preferência devem se comportar, e por quê.** Esta é a previsão que
o estudo testa:
- Aleatória: a probabilidade de aceite não depende de z nem de p, então o acasalamento não é
  assortativo e cov(z, p) deve ficar em torno de zero o tempo todo. É o controle: qualquer
  mudança nas médias é deriva.
- Sigmoide (direcional): é a curva onde o runaway pode aparecer, porque o aceite cresce
  monotonicamente com z. Fêmeas de pico alto são as mais exigentes em termos absolutos, acasalam
  com os machos de traço mais alto, e a covariância se acumula com sinal positivo.
- Gaussiana (estabilizadora): gera acasalamento assortativo forte, porque cada fêmea acasala com
  machos parecidos com o seu próprio pico, e portanto deve gerar a maior covariância. Mas como a
  seleção sobre z é estabilizadora, o esperado é um deslocamento contido e não uma fuga.
- U-shaped (disruptiva): gera acasalamento dissortativo, ou seja, covariância negativa, e é a
  única curva em que a preferência e o traço podem ser puxados em direções opostas.

**Um cuidado de implementação que vale registrar.** Como cada indivíduo carrega duas
características que precisam viajar juntas, os filhotes têm que ser amostrados por índice, e não
por valor. Se o traço e a preferência forem embaralhados separadamente, a covariância entre eles
é destruída e o runaway desaparece por causa de um erro de programação, e não por causa da
biologia. É o tipo de erro que não gera mensagem de erro nenhuma. Nos Estudos 2 e 3 esse
problema não existia, porque só havia uma característica herdável em cada um.

### O que já existe e o que falta

Já há um rascunho no repositório, `Fase_Coevolucao.R`, escrito antes das decisões da reunião
com Erika e Miudo. Ele acertou o essencial: os dois sexos carregam as duas características, o
macho sobrevivente leva o seu p junto (`male_p_surv <- male_p_gen[survive]`), a herança é de
ponto médio para as duas, os juvenis são amostrados por índice, e `cov_zp` já é registrado como
a grandeza central. A parte de baixo do arquivo é um teste rápido (`testar_coevolucao`), com 4
curvas de preferência e 5 réplicas, que roda automaticamente ao dar source.

O que ficou desatualizado em relação ao que combinamos depois:
1. A segregação é de ruído fixo (`eps_sd`, `eps_p`), sem a opção infinitesimal. É a mesma coisa
   que corrigimos nos Estudos 2 e 3: com ruído fixo a variância genética cai até o piso 2 vezes
   eps^2 e a resposta evolutiva fica artificialmente comprimida. Num estudo cuja grandeza central
   é a covariância, isso é especialmente grave, porque a covariância é limitada pelas variâncias.
2. Não há coluna `segregacao` na saída, que foi o que adotamos nos outros estudos para saber
   depois qual modo foi usado.
3. Quando ninguém acasala, o rascunho devolve a geração anterior em vez de encerrar a réplica.
4. Não há bloco de desenho experimental: nem `expand.grid`, nem `rodar_cenarios`, nem backup,
   nem reparto entre máquinas, nem semente própria. Ou seja, ele ainda não é um estudo, é um
   motor com um teste.
5. O teste roda sozinho ao dar source, o que atrapalha se a gente quiser apenas carregar as
   funções. Nos outros scripts resolvemos isso com uma flag (`ESPELHO_SO_FUNCOES`,
   `CONTROLE_SO_FUNCOES`).
6. `phi_p` existe como parâmetro separado de `phi`, o que permitiria começar a preferência
   centrada num valor diferente do ótimo ecológico. É uma possibilidade interessante, mas nesta
   rodada os dois ficam em 5, como nos outros estudos.

A proposta abaixo é a versão atualizada desse arquivo, já com as quatro decisões do modelo e
com o desenho experimental.

### Proposta de desenho: a diagonal em vez da superfície

Os Estudos 2 e 3 gastam 10.080 cenários cada um para varrer um eixo. Cruzar sigma_p_init com
sigma_z_init no Estudo 4 custaria 70.560 cenários com 100 gerações cada, o que é inviável.
A análise do Estudo 1 sugere um corte defensável.

No Estudo 1, a divergência entre as curvas de preferência no espaço das métricas de topologia
foi modelada em função da posição no plano sigma_p por sigma_z. O que ficou:
- A variabilidade total, medida pela norma sqrt(sigma_p^2 + sigma_z^2), explica R^2 = 0.539.
- O máximo entre as duas, max(sigma_p, sigma_z), explica R^2 = 0.556, e é estatisticamente
  equivalente à norma (diferença de AIC de 1.8).
- O descasamento entre as duas, medido por |log(sigma_p / sigma_z)|, explica R^2 = 0.004
  (p = 0.67), ou seja, praticamente nada.

A leitura é que o que importa é quanta variabilidade existe no sistema como um todo, e não como
ela está repartida entre os dois sexos. Se isso vale também com as duas características
evoluindo, então percorrer a diagonal sigma_p_init = sigma_z_init já cobre o gradiente
relevante, e o desenho volta a caber em 10.080 cenários, do mesmo tamanho dos Estudos 2 e 3.

Duas ressalvas honestas sobre esse argumento. Primeira, o resultado vem de uma única geração sem
herança, então ele diz respeito ao que a regra de acasalamento faz, e não necessariamente ao que
a dinâmica de 100 gerações faz. Segunda, no Estudo 4 as duas larguras são condições iniciais, e
não parâmetros impostos, então elas deixam de valer a partir da geração 2 de qualquer maneira.
Por isso a proposta é começar pela diagonal e, se os resultados mostrarem que a repartição entre
os sexos importa depois de tudo, rodar as combinações fora da diagonal em seguida. O motor não
muda, só o `expand.grid`.

### Código proposto

Substitui o conteúdo de `Fase_Coevolucao.R`. O motor reaproveita tudo o que já existe em
`01_metricas_e_utilitarios.R` (`mate_with_survivors`, `calc_metrics_from_M`,
`ensure_min_survivors`, `rodar_cenarios`). O que é novo em relação ao rascunho é a segregação
infinitesimal, o registro da covariância dentro dos casais e o bloco de desenho experimental.
A função `testar_coevolucao` do rascunho continua útil como verificação rápida e pode ser
mantida no arquivo, atrás da flag `COEVO_SO_FUNCOES`.

```r
# =====================================================================
# ESTUDO 4: CO-EVOLUÇÃO — traço do macho e preferência da fêmea, ambos herdáveis
# =====================================================================
source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

# ---------------------------------------------------------------------
# Reprodução com DUAS características herdáveis
# ---------------------------------------------------------------------
# O ponto crítico está no final: as vagas da próxima geração são sorteadas
# UMA VEZ, por ÍNDICE, e os dois vetores são indexados pelo MESMO idx. Assim o
# z e o p de um mesmo filhote continuam juntos, e cov(z, p) sobrevive.
produce_offspring_coevo <- function(M, male_z_surv, male_p_surv,
                                    female_z_gen, female_p_gen,
                                    N_males_next = 200, N_females_next = 200,
                                    fecundidade_base = 50,
                                    segregacao = c("infinitesimal", "fixa"),
                                    eps_sd = 0.2, mut_sd = 0.05) {
  segregacao <- match.arg(segregacao)
  n_femeas <- ncol(M)

  # Fecundidade neutra: quem acasalou deixa F filhotes; quem não acasalou, 0.
  acasalaram   <- colSums(M) > 0
  num_filhotes_por_femea <- ifelse(acasalaram, fecundidade_base, 0)
  total_filhotes         <- sum(num_filhotes_por_femea)
  # CASO DEGENERADO: mesma regra dos Estudos 2 e 3
  if (total_filhotes < 2 * (N_males_next + N_females_next)) return(NULL)

  moms <- rep(seq_len(n_femeas), times = num_filhotes_por_femea)
  dads <- vapply(moms, function(mom) {
    parceiros <- which(M[, mom] == 1L)
    if (length(parceiros) > 1) sample(parceiros, 1) else parceiros[1]
  }, integer(1))

  # Herança de ponto médio das DUAS características, do MESMO casal.
  # É aqui que a covariância nasce: se o acasalamento foi assortativo, os pais
  # de um mesmo filhote têm z e p correlacionados, e o filhote herda os dois.
  z_dads <- male_z_surv[dads]; z_moms <- female_z_gen[moms]
  p_dads <- male_p_surv[dads]; p_moms <- female_p_gen[moms]
  midparent_z <- (z_dads + z_moms) / 2
  midparent_p <- (p_dads + p_moms) / 2

  desvio_segregacao <- function(valores_pais) {
    if (segregacao == "fixa") return(rnorm(total_filhotes, 0, eps_sd))
    var_pais <- var(valores_pais)
    if (!is.finite(var_pais) || var_pais < 0) var_pais <- 0
    rnorm(total_filhotes, 0, sqrt(var_pais / 2)) + rnorm(total_filhotes, 0, mut_sd)
  }

  # Os desvios de segregação de z e de p são independentes entre si: a
  # segregação embaralha cada característica separadamente, e é a herança de
  # ponto médio que carrega a associação. Isso é o comportamento correto.
  z_filhotes <- pmax(0, midparent_z + desvio_segregacao(c(male_z_surv, female_z_gen)))
  p_filhotes <- pmax(0, midparent_p + desvio_segregacao(c(male_p_surv, female_p_gen)))

  # TODOS os filhotes são juvenis; o sexo é atribuído ao acaso, 1:1. É AQUI que a
  # covariância sobrevive: um único sorteio de índices, e os dois vetores
  # indexados pelo MESMO idx, para que z e p de um mesmo filhote fiquem juntos.
  # A capacidade de carga é imposta só no censo adulto da geração seguinte.
  idx  <- sample.int(total_filhotes)
  meio <- total_filhotes %/% 2
  i_m <- idx[seq_len(meio)]
  i_f <- idx[(meio + 1):(2 * meio)]

  list(male_z_juv   = z_filhotes[i_m], male_p_juv   = p_filhotes[i_m],
       female_z_juv = z_filhotes[i_f], female_p_juv = p_filhotes[i_f])
}

# ---------------------------------------------------------------------
# Loop evolutivo da co-evolução
# ---------------------------------------------------------------------
simulate_coevolucao <- function(generations = 100, N_machos = 200, N_femeas = 200,
                                sigma_z_init = 1.0, sigma_p_init = 1.0,
                                sigma_s = 0.2, phi = 5, gamma = 0.2,
                                tipo_selecao = "gaussian", encounters_n = 200,
                                selecao_natural = TRUE, k_fixo = NULL,
                                fecundidade_base = 50, eps_sd = 0.2,
                                segregacao = c("infinitesimal", "fixa"), mut_sd = 0.05) {
  segregacao <- match.arg(segregacao)
  # O pool de juvenis não é parâmetro livre: é o que a fecundidade produz.
  N_juvenis <- N_femeas * fecundidade_base %/% 2

  # Os DOIS sexos carregam as DUAS características. A expressão é que é dimórfica:
  # só o macho mostra z, só a fêmea usa p. Os machos entram como JUVENIS: a
  # viabilidade age sobre eles e o censo adulto fica sempre em N_machos.
  male_z_juv   <- pmax(0, rnorm(N_juvenis, phi, sigma_z_init))
  male_p_juv   <- pmax(0, rnorm(N_juvenis, phi, sigma_p_init))  # carregada, não expressa
  female_z_juv <- pmax(0, rnorm(N_juvenis, phi, sigma_z_init))  # carregada, não expressa
  female_p_juv <- pmax(0, rnorm(N_juvenis, phi, sigma_p_init))

  out <- vector("list", generations)
  extincao_gen <- NA_integer_   # geração em que a réplica foi encerrada; NA = chegou ao fim

  for (t in seq_len(generations)) {

    female_p <- female_p_gen                                     # HERDADA (evolui)
    female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s)) # choosiness fixa

    # (1) Censo de adultos constante. A viabilidade age sobre os machos JUVENIS
    # e sobram sempre N_machos adultos. No Estudo 4 ela volta a ter consequência
    # evolutiva (o traço é herdado) e é a única força que age DIRETAMENTE contra
    # a exageração do traço. selecionar_machos_adultos devolve ÍNDICES, então o
    # par (z, p) do mesmo macho viaja junto.
    idx_adultos  <- selecionar_machos_adultos(male_z_juv, N_machos, phi, gamma, selecao_natural)
    male_z_surv  <- male_z_juv[idx_adultos]
    male_p_surv  <- male_p_juv[idx_adultos]
    # Fêmeas não passam por viabilidade: censo por sorteio aleatório, MESMO índice
    # para z e p, senão a covariância dentro de cada fêmea se perde.
    idx_f        <- sample.int(length(female_z_juv), N_femeas)
    female_z_gen <- female_z_juv[idx_f]
    female_p_gen <- female_p_juv[idx_f]

    # (2) Rede de acasalamentos (sem regra de escape)
    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                             encounters_n = encounters_n, k_fixo = k_fixo)
    metrics <- calc_metrics_from_M(M, k_alvo = k_fixo)

    # (3) Registro. A GRANDEZA CENTRAL deste estudo é cov(z, p) no pool
    # genotípico: é ela que mede o quanto preferência e traço estão associados,
    # e portanto o quanto a seleção sobre um arrasta o outro.
    # Pool genotípico = CENSO ADULTO (N_machos + N_femeas), balanceado entre os
    # sexos. Atenção: aqui, ao contrário do Estudo 3, a seleção de viabilidade
    # NÃO é neutra em relação a p, porque z e p estão correlacionados. Usar o
    # censo adulto é o correto: é a população que de fato se reproduz.
    pool_z <- c(male_z_surv, female_z_gen)
    pool_p <- c(male_p_surv, female_p_gen)
    out[[t]] <- data.frame(
      generation = t, tipo_selecao = tipo_selecao, segregacao = segregacao,
      sigma_z_init = sigma_z_init, sigma_p_init = sigma_p_init,
      encounters_n = encounters_n,
      k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
      selecao_natural = selecao_natural,
      zbar_pop = mean(pool_z), varz_pop = var(pool_z),
      pbar_pop = mean(pool_p), varp_pop = var(pool_p),
      cov_zp   = cov(pool_z, pool_p),
      cor_zp   = suppressWarnings(cor(pool_z, pool_p)),
      # a covariância entre os PARES que de fato acasalaram, que é o passo
      # anterior na cadeia causal: é ela que gera a covariância genética
      cov_casais = {
        pares <- which(M == 1L, arr.ind = TRUE)
        if (nrow(pares) > 1) cov(male_z_surv[pares[, 1]], female_p[pares[, 2]]) else NA_real_
      },
      zbar_males = mean(male_z_surv), varz_males = var(male_z_surv),
      pbar_femeas = mean(female_p),   varp_femeas = var(female_p),
      n_machos_surv = length(male_z_surv),   # pool disponível: covariável de densidade
      metrics
    )

    # (4) Próxima geração: as duas características, pareadas
    off <- produce_offspring_coevo(M, male_z_surv, male_p_surv,
                                   female_z_gen, female_p_gen,
                                   N_machos, N_femeas,
                                   fecundidade_base = fecundidade_base,
                                   segregacao = segregacao,
                                   eps_sd = eps_sd, mut_sd = mut_sd)
    if (is.null(off)) { extincao_gen <- t; break }   # encerra e registra onde parou
    male_z_juv   <- off$male_z_juv
    male_p_juv   <- off$male_p_juv
    female_z_juv <- off$female_z_juv
    female_p_juv <- off$female_p_juv
  }

  df_out <- dplyr::bind_rows(out)
  df_out$extincao_gen <- extincao_gen
  df_out
}

# =====================================================================
# DESENHO EXPERIMENTAL: a DIAGONAL sigma_p_init = sigma_z_init
# =====================================================================
if (!exists("COEVO_SO_FUNCOES") || !isTRUE(COEVO_SO_FUNCOES)) {

  diretorios <- configurar_diretorios("Fase_Coevolucao")
  cat("Iniciando Estudo 4: co-evolução (traço e preferência herdáveis)...\n")

  valores_sigma <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
  n_replicas    <- 20

  # DIAGONAL: um único eixo sigma_init aplicado às DUAS características.
  # Justificativa no texto: no Estudo 1 a divergência entre curvas de
  # preferência depende da variabilidade TOTAL e não da repartição entre sexos.
  cenarios <- expand.grid(
    tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
    sigma_init      = valores_sigma,
    encounters_n    = c(200, 40, 10),
    k_fixo          = c(5L, 10L, 20L),
    selecao_natural = c(TRUE, FALSE),
    replica         = 1:n_replicas
  )

  cenarios$idx_global <- seq_len(nrow(cenarios))
  REP_MIN <- as.integer(Sys.getenv("REP_MIN", unset = "1"))
  REP_MAX <- as.integer(Sys.getenv("REP_MAX", unset = as.character(n_replicas)))
  cenarios <- cenarios[cenarios$replica >= REP_MIN & cenarios$replica <= REP_MAX, ]
  sufixo_rep <- if (REP_MIN == 1 && REP_MAX == n_replicas) "" else sprintf("_rep%d-%d", REP_MIN, REP_MAX)
  cat(sprintf("Réplicas: %d a %d  (%d cenários)\n", REP_MIN, REP_MAX, nrow(cenarios)))

  arquivo_backup      <- file.path(diretorios$dados, paste0("backup_Coevolucao", sufixo_rep, ".rds"))
  arquivo_final       <- file.path(diretorios$dados, paste0("resultados_Coevolucao", sufixo_rep, ".rds"))
  arquivo_backup_full <- file.path(diretorios$dados, "backup_Coevolucao.rds")

  if (file.exists(arquivo_backup)) {
    lista <- readRDS(arquivo_backup)
    cat("Backup encontrado! Retomando...\n")
    if (length(lista) != nrow(cenarios)) length(lista) <- nrow(cenarios)
  } else if (sufixo_rep != "" && file.exists(arquivo_backup_full)) {
    full_lst <- readRDS(arquivo_backup_full)
    lista <- full_lst[cenarios$idx_global]
    rm(full_lst); gc()
    cat(sprintf("Aproveitando %d cenários já prontos do backup completo.\n",
                sum(!vapply(lista, is.null, logical(1)))))
  } else {
    lista <- vector("list", nrow(cenarios))
    cat("Nenhum backup encontrado. Iniciando do zero.\n")
  }

  SEED_BASE <- 2030   # semente própria deste estudo
  N_CORES   <- as.integer(Sys.getenv("N_CORES", unset = "5"))

  simular_i <- function(i) {
    res <- simulate_coevolucao(
      generations     = 100,
      N_machos        = 200,
      N_femeas        = 200,
      tipo_selecao    = as.character(cenarios$tipo_selecao[i]),
      sigma_z_init    = cenarios$sigma_init[i],   # a DIAGONAL: os dois recebem
      sigma_p_init    = cenarios$sigma_init[i],   # o mesmo valor
      encounters_n    = cenarios$encounters_n[i],
      k_fixo          = cenarios$k_fixo[i],
      selecao_natural = cenarios$selecao_natural[i]
    )
    if (is.null(res) || nrow(res) == 0) return(NULL)
    res$replica <- cenarios$replica[i]
    res
  }

  lista <- rodar_cenarios(cenarios, lista, arquivo_backup, simular_i,
                          n_cores = N_CORES, seed_base = SEED_BASE,
                          idx_global = cenarios$idx_global)

  saveRDS(lista, arquivo_backup)
  df_coevo <- bind_rows(lista[!sapply(lista, is.null)])
  saveRDS(df_coevo, arquivo_final)
  cat("\nEstudo 4 (co-evolução) concluído! Dados salvos em:", arquivo_final, "\n")
  cat(sprintf("Total de linhas: %d\n", nrow(df_coevo)))
}
```

**Quatro pontos para discutir antes de rodar.**
0. O gradiente de k precisa ser repensado, e este é o ponto mais urgente dos quatro. Como está
   detalhado na seção sobre a interação entre A_max, k e a curva de preferência, das nove
   células do cruzamento A_max por k, as três com A_max = 10 e k igual a 10 ou 20 não são
   tratamentos distintos: nelas o k nunca é atingido e o que sobra é sempre "ela acasala com
   quem aceitar entre dez machos". Copiar o desenho dos Estudos 2 e 3 para o Estudo 4 seria
   gastar cenários em células que não separam nada. Três saídas possíveis, em ordem crescente de
   ambição: (a) manter o cruzamento como está, para conservar a comparabilidade com os Estudos 2
   e 3, e apenas declarar a limitação; (b) substituir o k fixo por um k proporcional a A_max, de
   modo que o gradiente de poliandria seja o mesmo em todos os níveis de custo de busca; (c)
   deixar o k de fora do Estudo 4, aproveitando que ele já foi varrido nos Estudos 2 e 3, e usar
   os cenários economizados para sondar fora da diagonal de sigma. A opção (a) é a mais
   conservadora e a que menos compromete a comparação entre estudos; a (c) é a que aproveita
   melhor o orçamento de simulação. Isso precisa ser decidido antes, porque muda o
   `expand.grid`. E em qualquer das três, as duas colunas novas de grau realizado deveriam
   entrar, para que a limitação passe de argumentada a medida.
1. A diagonal é suficiente, ou queremos ao menos alguns pontos fora dela como sonda? Uma
   alternativa barata seria acrescentar os quatro cantos (0.2 x 2.0 e 2.0 x 0.2), o que custaria
   pouco e daria uma verificação direta do argumento do Estudo 1.
2. A `cov_casais` é uma variável nova, que mede a covariância entre traço e preferência dentro
   dos casais que efetivamente acasalaram. Ela é o passo anterior na cadeia causal (acasalamento
   assortativo primeiro, covariância genética depois), e permite separar os dois. Vale a pena
   registrar as duas ou é redundante?
3. Se o runaway aparecer com a curva sigmoide e sem seleção natural, o traço pode crescer sem
   limite e a réplica vira uma explosão numérica. Nos Estudos 2 e 3 isso não acontecia porque só
   uma característica evoluía. Talvez valha registrar um indicador de fuga (por exemplo, a
   geração em que a média do traço passa de algum múltiplo de phi) em vez de deixar a réplica
   correr até a geração 100 sem aviso.

**Estado.** Motor rascunhado em `Fase_Coevolucao.R`, com os seis pontos de atualização listados
acima ainda pendentes. Nada rodado, aguardando a discussão dos três pontos de desenho.

---

## O que é comum aos quatro estudos

**População.** 200 machos e 200 fêmeas, gerações discretas e não sobrepostas, tamanho
populacional constante. Cem gerações por réplica nos Estudos 2, 3 e 4; uma geração no Estudo 1.

**As quatro curvas de preferência.** P_ij é a probabilidade de a fêmea i aceitar o macho j,
onde s é a exigência dela, p é o pico dela e z é o traço dele. Todas partem do mesmo pico médio,
de modo que as diferenças entre elas vêm da geometria da regra e não de as fêmeas quererem
coisas diferentes em média:
- Aleatória (nula): P = 0.5, constante. A fêmea aceita qualquer macho com a mesma probabilidade.
  Serve de controle: aqui não existe seleção sexual, então qualquer mudança no traço é deriva.
- Gaussiana (estabilizadora): P = exp(-s (z - p)^2). A fêmea aceita machos cujo traço está
  próximo do seu pico, e rejeita tanto os muito maiores quanto os muito menores.
- Sigmoide (direcional): P = 1 / (1 + exp(-s (z - p))). A fêmea aceita machos cujo traço supera
  o seu pico, e quanto mais o supera, mais provável é o aceite.
- U-shaped (disruptiva): P = 1 - exp(-s (z - p)^2). A fêmea evita machos parecidos com o seu
  pico e aceita os que estão distantes dele, para mais ou para menos.

**Fatores cruzados em todos os estudos.**
- A_max: quantos machos distintos cada fêmea consegue avaliar antes de decidir (200, 40 ou 10,
  em número absoluto). Representa o custo ecológico de procurar parceiro. O nível 200 é a
  condição de saturação, "sem restrição de busca", e não um terceiro ponto equidistante do
  gradiente. Ver a seção sobre o tamanho do pool de machos: os rótulos percentuais que usávamos
  antes eram enganosos.
- k: quantos parceiros cada fêmea acasala (5, 10 ou 20). Representa o grau de poliandria.
- Seleção natural de viabilidade sobre o traço do macho, ligada ou desligada.

---

## A interação entre A_max, k e a curva de preferência

Este ponto precisa ficar explícito porque afeta a leitura de todos os estudos já rodados e,
principalmente, a escolha de parâmetros do Estudo 4, que ainda está aberta.

**O parâmetro k não é o número de parceiros, é um teto.** O número de parceiros que uma fêmea
de fato consegue é

    parceiros = min( k , número de machos que ela aceitou entre os A_max avaliados )

e, como a amostragem é sem reposição, ela nunca pode acasalar com mais machos do que os que
avaliou. Nos cenários com A_max = 10 e k = 20, portanto, o k é inalcançável por construção: o
máximo absoluto é 10. Isso não é um defeito do modelo, é exatamente o custo de busca que
queremos representar, mas significa que o efeito de k não pode ser lido isoladamente do de A_max.

**O teto morde muito antes do que o limite aritmético sugere.** Ela não acasala com os dez que
avaliou, acasala com os que aceitou entre esses dez. Com A_max = 10 e uma taxa média de aceite
de 0.5, o número esperado de aceites é 5. Ou seja, mesmo o cenário k = 5 já fica no limite, e o
cenário k = 10 exigiria que ela aceitasse todos os dez.

**E a taxa de aceite depende da curva de preferência.** Aqui está a parte que mais preocupa,
porque transforma uma interação entre dois fatores de desenho numa interação com a variável de
interesse do paper. Tomando s = 2 e sigma_p = sigma_z = 1.0, a probabilidade média de aceite por
macho avaliado é aproximadamente:

| Curva de preferência | Fórmula | Aceite médio |
|---|---|---|
| Aleatória | P = 0.5 | 0.50 |
| Sigmoide | P = 1 / (1 + exp(-s (z - p))) | 0.50 |
| Gaussiana | P = exp(-s (z - p)^2) | 0.33 |
| U-shaped | P = 1 - exp(-s (z - p)^2) | 0.67 |

(Para a gaussiana, a diferença z - p tem variância sigma_z^2 + sigma_p^2, e a média de
exp(-s d^2) para d normal de variância v é 1 / sqrt(1 + 2 s v). A u-shaped é o complemento.)

Os números medidos (`00_teste_motores.R`, uma réplica por célula, sem seleção natural). Em cada
célula, a poliandria realizada e, entre parênteses, a proporção que atingiu o k nominal:

| A_max | curva | k = 5 | k = 10 | k = 20 |
|---|---|---|---|---|
| 200 | gaussiana | 4.98 (100%) | 9.91 (98%) | 19.68 (95%) |
| 200 | aleatória | 5.00 (100%) | 10.00 (100%) | 20.00 (100%) |
| 200 | U-shaped | 5.00 (100%) | 10.00 (100%) | 20.00 (100%) |
| 40 | gaussiana | 4.83 (93%) | 9.15 (79%) | 13.08 (10%) |
| 40 | aleatória | 5.00 (100%) | 10.00 (100%) | 18.91 (62%) |
| 40 | U-shaped | 5.00 (100%) | 10.00 (100%) | 19.90 (94%) |
| 10 | gaussiana | 3.32 (26%) | 3.56 (0%) | 3.51 (0%) |
| 10 | aleatória | 4.45 (66%) | 5.15 (0%) | 5.10 (0%) |
| 10 | U-shaped | 4.78 (84%) | 6.55 (4%) | 6.89 (0%) |

**Os números seguem uma regra simples:** a poliandria realizada é aproximadamente
`min(k, A_max x taxa de aceite)`. Confira na faixa de A_max = 10, onde o teto nunca ata:
10 x 0.33 = 3.3 contra 3.56 medido na gaussiana, 10 x 0.50 = 5.0 contra 5.15 na aleatória,
10 x 0.67 = 6.7 contra 6.55 na U-shaped. É uma validação do motor: ele se comporta como a teoria
prevê.

A conclusão prática é forte: **com A_max = 10, as células k = 10 e k = 20 não são dois
tratamentos distintos de poliandria, são o mesmo tratamento**, que na prática é "ela acasala com
quem aceitar entre dez machos". O gradiente de poliandria simplesmente não existe nessa faixa de
A_max. E com A_max = 40 o problema não desapareceu de todo: na curva gaussiana, só 10% das fêmeas
chega a k = 20, enquanto na U-shaped chegam 94%.

**Em compensação, com A_max = 200 está tudo limpo.** Todas as curvas atingem o k, e o grau
realizado é idêntico entre elas (5.00, 10.00, 20.00), ou seja, a densidade da rede está
equiparada. Isso dá um caminho analítico direto, descrito na seção sobre as hipóteses.

Uma nota metodológica. As estimativas analíticas que fizemos antes destes números (21%, 2%, 92%,
99% nas células críticas) erraram de forma sistemática, sempre para baixo na gaussiana e para
cima na U-shaped. O cálculo binomial trata todas as fêmeas como iguais, mas o pico p varia entre
elas: uma fêmea com p perto de 5, onde estão quase todos os machos, aceita muito mais que a
média, e uma com p extremo aceita muito menos. Isso gera sobredispersão, e as caudas é justamente
onde o teto é ou não atingido. Valem os números medidos.

**Duas consequências para a análise.**

Primeira, o k realizado difere sistematicamente entre curvas de preferência, o que é um
confundimento direto sobre a H1. Se a gaussiana e a u-shaped produzem topologias diferentes, uma
parte dessa diferença pode vir simplesmente de as fêmeas da u-shaped terem mais parceiros, e não
da geometria da escolha. Densidade de arestas afeta modularidade, aninhamento e centralização.

Segunda, o efeito de A_max e o de k estão parcialmente confundidos entre si, então nenhum dos
dois pode entrar num modelo como fator aditivo sem o termo de interação, e a interpretação de
qualquer coeficiente marginal de k é enganosa.

**Uma ressalva sobre esses números.** São aproximações analíticas com s fixo em 2, ignorando o
truncamento em zero, a variação de s entre fêmeas e o efeito da seleção natural, que estreita a
distribuição dos machos e portanto aumenta a taxa de aceite da gaussiana. Servem para mostrar a
ordem de grandeza do problema, não como estimativa exata.

**A decisão: k é apetite, não cota.** A fêmea busca até k parceiros; quantos consegue depende da
disponibilidade e da própria seletividade. A poliandria realizada passa a ser variável resposta,
e não parâmetro. Três razões sustentam isso. É o que o código sempre fez, porque
`matings_per_female` é condição de parada e não cota garantida. Converte as células degeneradas
nas mais interessantes: A_max = 10 com k = 20 não é lixo, é poliandria frustrada, e comparada
com A_max = 200 e k = 20 é exatamente o teste da H3. E é mais defensável biologicamente, porque
nenhum organismo tem garantido o seu número de parceiros.

O reenquadramento exige medir, e por isso `calc_metrics_from_M` passou a gravar
`grau_medio_femeas` (a poliandria realizada), `prop_femeas_atingiu_k` e `arestas`. Nenhuma delas
podia ser recuperada dos dados antigos: o Is é calculado sobre os machos e não permite
reconstruir o grau das fêmeas. Foi a razão mais forte para refazer os três estudos.

**O desenho fatorial fica intacto, os 3 por 3 de A_max e k.** Chegou a ser proposto cortar a
célula A_max = 10 com k = 10, por ser estatisticamente indistinguível de k = 20. A proposta foi
retirada: agora que a poliandria realizada é medida, a convergência entre as duas células é
justamente a evidência de que k é apetite e não cota. Manter o fatorial balanceado vale mais que
os 11% de computação economizados.

**Uma dúvida de inferência causal, para levar ao Miudo.** Se o grau realizado depende da curva de
preferência, e o usamos como covariável para comparar curvas, estamos controlando por um mediador
e não por um confundidor: a curva causa o grau realizado e a topologia, então controlar remove
parte do efeito causal que queremos medir. A saída provável é reportar as duas coisas, o efeito
total da curva e o efeito líquido de densidade, declarando que respondem a perguntas diferentes.

---

## O tamanho do pool de machos não é constante

Esta seção nasceu de uma observação sobre o rótulo de A_max, mas o problema de fundo acabou
sendo outro, e maior.

**Primeiro, o que NÃO é um problema.** Descrevemos os níveis de A_max como "100%, 20% e 5% de
N = 200". Os rótulos percentuais estão errados quando a seleção natural está ligada, mas o
tratamento em si continua comparável: A_max = 40 quer dizer "ela avalia 40 machos" com a seleção
ligada ou desligada, e A_max = 200 quer dizer "ela avalia todos os disponíveis" nos dois casos,
porque o código faz `min(A_max, número de sobreviventes)`. A correção aqui é só de rótulo:
descrever A_max em número absoluto de machos avaliados, e não em porcentagem. O que muda é a
interpretação de A_max = 200, que não é um terceiro ponto equidistante num gradiente, e sim a
condição de saturação, "sem restrição de busca". Por isso A_max deve entrar nos modelos como
fator, nunca como covariável contínua.

**Segundo, o que é um problema de verdade.** O número de machos disponíveis muda de cenário para
cenário, porque a seleção natural de viabilidade remove uma fração que depende de sigma_z. A
fração que sobrevive é aproximadamente `1 / sqrt(1 + 2 gamma sigma_z^2)`, ou seja, com
gamma = 0.2:

| sigma_z | 0.2 | 0.5 | 0.8 | 1.0 | 1.2 | 1.5 | 2.0 |
|---|---|---|---|---|---|---|---|
| Machos sobreviventes (de 200) | 198 | 191 | 178 | 169 | 159 | 145 | 124 |

O pool encolhe 37% ao longo do gradiente. Como o número de fêmeas e o k continuam os mesmos, o
número total de arestas da rede não muda, mas ele se reparte entre menos machos: com k = 5, o
grau médio dos machos passa de cerca de 5.1 para cerca de 8.1. Isso afeta diretamente o Is, a
centralização e o aninhamento, e não tem nada a ver com a escolha feminina.

**Onde isso morde.** No Estudo 2 pouco, porque sigma_z fica fixo em 1.0 e o pool é estável. No
Estudo 1 e no Estudo 3 morde de frente, porque ali sigma_z é justamente um eixo do experimento:
parte de qualquer tendência das métricas ao longo de sigma_z, nos cenários com seleção natural
ligada, é apenas o pool encolhendo. E como a comparação entre seleção natural ligada e desligada
é um dos nossos contrastes, vale lembrar que os dois regimes diferem em duas coisas ao mesmo
tempo: na distribuição do traço e no tamanho do pool.

**O que foi feito: censo de adultos constante.** A seleção de viabilidade passou a agir sobre
juvenis, antes do censo de adultos. Cada geração começa com três machos juvenis por vaga, a
viabilidade age sobre eles, e o censo adulto fica sempre em 200 machos. A seleção natural
continua mudando quais machos estão disponíveis, que é o efeito que nos interessa, e deixa de
mudar quantos, que era o confundimento. Biologicamente é a formulação mais comum: a mortalidade
de viabilidade age sobre juvenis e o censo é de adultos.

Vale registrar as duas alternativas que foram descartadas, porque o argumento pode voltar.

Registrar e controlar, ou seja, gravar `n_machos_surv` e usá-lo como covariável nos modelos.
Custo zero e sem mudar o modelo, mas deixa o confundimento na estrutura dos dados e obriga a
confiar num ajuste estatístico para algo que dá para resolver na origem. Foi a recomendação
inicial, feita quando ainda supúnhamos que os três estudos não seriam refeitos. A partir do
momento em que o recorrido completo entrou em cena, ela deixou de fazer sentido. A coluna
`n_machos_surv` continua sendo gravada, mas agora como verificação e não como correção.

Redefinir A_max como proporção do pool. Tornaria o custo de busca comparável entre regimes, mas
não resolve o problema principal, que é a densidade, e além disso deixaria A_max e o tamanho do
pool colineares por construção.

**Uma nota sobre comparabilidade entre estudos.** A objeção original ao censo constante era que
mudar a regra faria o Estudo 4 deixar de ser comparável com os Estudos 1, 2 e 3, e a inferência
inteira depende dessa comparação: a diferença entre o Estudo 4 e o Estudo 1 é o que a co-evolução
acrescentou, e essa subtração não vale se os dois também diferirem na demografia. A objeção era
correta, mas valia apenas enquanto os três primeiros estudos ficassem como estavam. Como o
recorrido completo vai acontecer de qualquer maneira, o censo constante passa a valer para os
quatro e a comparabilidade fica intacta.

**Decisões de modelo tomadas nesta rodada.**
1. Amostragem sem reposição. A_max passa a ser literalmente o número de machos distintos
   que a fêmea avalia. Antes, com reposição, ela reencontrava o mesmo macho várias vezes e via
   menos machos distintos do que o parâmetro sugeria.
2. Sem regra de escape. Antes, uma fêmea que não aceitasse ninguém acasalava com o último
   macho avaliado, de modo que todas acasalavam. Agora ela fica sem acasalar e deixa zero
   filhotes. Sem essa mudança não existiria variância de sucesso reprodutivo entre fêmeas, e o
   Estudo 3 seria impossível.
3. Fecundidade neutra. A poliandria não aumenta o número de filhotes; ela só distribui a
   paternidade entre os parceiros.
4. Variância de segregação proporcional (modelo infinitesimal de Falconer e Mackay). O
   desvio dos filhotes em relação à média dos pais tem variância igual a metade da variância
   parental, em vez de um ruído fixo. Com ruído fixo, a variância genética erodia geração após
   geração até um piso artificial baixo (2 vezes eps^2, cerca de 0.08 com eps = 0.2), e isso
   comprimia artificialmente a resposta evolutiva de qualquer característica herdável. O modo
   antigo continua disponível no código (`segregacao = "fixa"`) para comparação, e o modo usado
   fica registrado numa coluna da saída de cada simulação.

**Réplicas.** 20 nesta rodada de exploração, mais na rodada final. São 20 e não mais porque os
problemas que motivaram o recorrido (o teto de k, o pool de machos, o caso degenerado) são vieses
sistemáticos e não ruído: mais réplicas não os tocariam.

---

## O ciclo de vida, passo a passo

Cada geração segue sempre a mesma sequência, nos quatro estudos. O que muda entre os estudos
é apenas quais características são herdadas no passo 5.

**1. Ponto de partida.** Todas as distribuições são centradas em phi = 5, que é ao mesmo tempo
a média inicial do traço, a média inicial do pico de preferência e o ótimo da seleção natural.
Os machos começam com traço sorteado de N(5, sigma_z) e as fêmeas com pico de preferência
sorteado de N(5, sigma_p). Todos os valores são truncados em zero, ou seja, nem o traço nem a
preferência podem ser negativos.

**2. Seleção natural de viabilidade (ligada ou desligada), e o censo de adultos.** A seleção de
viabilidade age sobre os JUVENIS, antes do censo de adultos. Quando ela está ligada, cada um dos
cerca de 5.000 juvenis machos sobrevive com probabilidade

    V = exp(-gamma * (z - phi)^2),  com gamma = 0.2

ou seja, quanto mais o traço se afasta do ótimo ecológico phi = 5, menor a chance de sobreviver.
Entre os juvenis que sobrevivem, sorteiam-se ao acaso os 200 que formam o censo adulto de machos.
As fêmeas não passam por viabilidade: sorteiam-se 200 ao acaso.

**A ordem importa.** Como a seleção age antes do censo, o número de machos disponíveis para
acasalar é sempre 200, com ou sem seleção natural e para qualquer valor de sigma_z. A seleção
muda QUAIS machos estão disponíveis, que é o efeito que nos interessa, e não QUANTOS, que seria
um confundimento de densidade. Ver a seção sobre o tamanho do pool de machos: na versão anterior
a viabilidade agia depois do censo, o pool caía de 198 para 124 ao longo do gradiente de sigma_z,
e isso sozinho mexia em Is, centralização e aninhamento.

Quatro observações:
- A seleção natural age apenas sobre os machos e apenas sobre o traço, nunca sobre a
  preferência.
- Quando está desligada, todos os juvenis são equivalentes (V = 1) e o censo é um sorteio
  aleatório, o que isola o efeito puro da escolha feminina.
- Há uma trava de segurança: se menos de 2 juvenis sobrevivessem, os 2 de maior viabilidade são
  resgatados, para que a rede nunca fique degenerada demais para calcular as métricas. A coluna
  `n_machos_surv` grava o censo efetivo, então qualquer cenário em que a trava tenha entrado é
  identificável na hora.
- No Estudo 3, em que o traço do macho é ambiental, a seleção natural continua funcionando como
  filtro ecológico (muda quais machos estão disponíveis), mas não tem consequência evolutiva,
  porque o traço não é transmitido aos filhotes. O mesmo vale para o Estudo 1, por não haver
  geração seguinte.

**3. Formação da rede de acasalamentos.** Cada fêmea avalia A_max machos distintos, sorteados
sem reposição entre os sobreviventes (ou todos eles, se houver menos sobreviventes do que
A_max). Para cada macho avaliado, ela aceita ou não com uma probabilidade dada pela curva de
preferência, que depende da distância entre o traço dele e o pico dela, e da exigência dela (a
choosiness s, sorteada de N(2, 0.2) a cada geração e nunca herdada, em todos os estudos). Ela
para quando atinge k parceiros ou quando esgota os A_max machos. Se não aceitar nenhum, fica sem
acasalar. A matriz é binária, então um mesmo par nunca conta duas vezes.

O resultado é uma matriz de quem acasalou com quem, que é a rede bipartita sobre a qual
calculamos as métricas de topologia.

**4. Fecundidade e paternidade.** Cada fêmea que acasalou produz 50 filhotes, e as que não
acasalaram produzem zero. O número de filhotes não depende de com quantos machos ela acasalou
(fecundidade neutra). A paternidade de cada filhote é sorteada ao acaso entre os parceiros
daquela fêmea, o que equivale a uma competição espermática justa, sem viés para nenhum macho.

**5. Herança.** É aqui que os quatro estudos diferem. Cada característica herdável do filhote é
a média dos dois pais mais um desvio de segregação com variância igual a metade da variância
parental, mais um termo mutacional pequeno (desvio padrão 0.05). As características não
herdáveis são simplesmente re-sorteadas na geração seguinte.

**6. Os juvenis da geração seguinte.** Todos os filhotes (cerca de 10.000, quando quase todas as
fêmeas acasalam) recebem sexo ao acaso, metade machos e metade fêmeas. São eles os juvenis da
geração seguinte, e é sobre eles que o passo 2 volta a agir. Não há nenhum corte aqui: a
capacidade de carga é imposta uma vez só, no censo de adultos do passo 2.

O modelo tem portanto duas mortalidades, e a diferença entre elas é o ponto todo. A viabilidade é
seletiva e age só sobre os machos. O censo é sorteio puro, sem seleção nenhuma, e é a fonte de
deriva genética do modelo. Uma característica só evolui de forma dirigida se alguns pais
colocaram mais filhotes no pote do que outros.

**O caso degenerado, e por que ele merece uma regra explícita.** Pode acontecer de o pote não
dar para formar a geração seguinte, seja porque nenhuma fêmea acasalou, seja porque acasalaram
tão poucas que os filhotes não bastam para formar a população adulta (o que exigiria que menos de
16 das 200 fêmeas acasalassem, ou seja, mais de 92% sem acasalar). A regra agora é a mesma nos três motores: a réplica é encerrada ali, as gerações já
rodadas são mantidas, e a coluna `extincao_gen` guarda em que geração isso aconteceu. Quando a
réplica chega ao fim normalmente, `extincao_gen` fica NA.

Vale explicar por que não ficamos com nenhuma das duas soluções anteriores. O Estudo 2 devolvia a
geração anterior, o que fabrica uma geração de pais imortais que não deixaram descendência mas
continuam na população. E devolvia apenas os machos sobreviventes, não os 200: a população
encolhia em silêncio, e a partir dali o passo de viabilidade reciclava um vetor mais curto,
`male_z_gen[survive]` passava a devolver NA, e a réplica seguia rodando produzindo lixo sem
nenhum aviso. O Estudo 3 encerrava a réplica, que é o correto, mas sem deixar registro: ela
entrava no conjunto de dados apenas com menos gerações, e desaparecia depois no filtro
`generation == 100`. Como as réplicas que falham são justamente as dos cenários mais duros, essa
perda silenciosa seria enviesada.

Com a coluna `extincao_gen`, quantas réplicas se extinguem por cenário passa a ser um resultado
que se pode reportar: é a medida de quando as regras de acasalamento foram restritivas demais
para a população se sustentar. Na prática esperamos que seja zero em todos os cenários já
rodados, porque a proporção de fêmeas sem acasalar nunca chegou perto de 92%, mas isso agora fica
verificável em vez de suposto.

---

## Parâmetros do modelo

| Símbolo | O que é | Valor |
|---|---|---|
| N | machos e fêmeas adultos por geração | 200 de cada |
| gerações | duração de cada réplica | 100 (1 no Estudo 1) |
| phi | ótimo da seleção natural e média inicial das distribuições | 5 |
| gamma | intensidade da seleção natural de viabilidade | 0.2 (ou seleção desligada) |
| sigma_p | variação do pico de preferência entre fêmeas | eixo do Estudo 2: 0.2 a 2.0 |
| sigma_z | variação do traço entre machos | eixo do Estudo 3: 0.2 a 2.0 |
| s | exigência da fêmea (choosiness), fixa, nunca herdada | N(2, 0.2) |
| A_max | machos distintos avaliados por fêmea | 200, 40 ou 10 |
| k | parceiros por fêmea | 5, 10 ou 20 |
| F | filhotes por fêmea que acasalou | 50 |
| mut_sd | termo mutacional somado à segregação | 0.05 |
| eps_sd | ruído de segregação do modo antigo | 0.2 (só usado com `segregacao = "fixa"`) |
| min_surv | mínimo de machos resgatados da seleção natural | 2 |
| réplicas | repetições independentes por cenário | 20 (final: subir depois) |
| semente base | por estudo, para reprodutibilidade | 2026 (E2), 2028 (E3), 2029 (E1), 2030 (E4) |

Todos os cenários são reprodutíveis: a semente de cada um é `semente base + índice global do
cenário`, definida dentro da tarefa. Isso vale mesmo quando as réplicas são repartidas entre
máquinas diferentes, porque o índice usado é o do desenho completo e não o da fatia.

**Duas ressalvas sobre reprodutibilidade, que valem para os Métodos.** A primeira é de
plataforma: ao rodar o mesmo teste com a mesma semente no Mac e no servidor Linux, um valor
divergiu na segunda casa decimal (5.10 contra 5.09), enquanto as outras 24 comparações saíram
idênticas. A explicação provável é uma diferença de um bit na implementação de `exp()`, virando
uma comparação de aceite que estava no limite. Não é erro nem viés, cada réplica continua sendo
um sorteio válido do modelo, mas significa que a reprodução exata exige a mesma plataforma, e que
re-simular um cenário para extrair a rede deve ser feito na máquina que o gerou. A segunda é de
versão: a semente só reproduz os dados junto com o código que os gerou, e o motor mudou várias
vezes. Por isso vale etiquetar o commit de cada rodada.

---

## As métricas de topologia da rede

Calculadas a cada geração sobre a rede bipartita de acasalamentos:

- **Modularidade.** O quanto a rede se divide em grupos que acasalam preferencialmente entre si.
  Calculada com o algoritmo de Louvain sobre a projeção não dirigida da rede bipartita. A
  alternativa seria a modularidade bipartida do pacote `bipartite`, que é mais defensável mas
  centenas de vezes mais lenta, e inviável no número de redes que geramos. Vale confirmar com o
  Miudo se a escolha se sustenta.
- **Aninhamento (NODF).** O quanto os parceiros dos machos menos procurados são um subconjunto
  dos parceiros dos machos mais procurados, ou seja, o quanto existe uma hierarquia.
- **Centralização.** O quanto os acasalamentos se concentram em poucos indivíduos. Calculada
  sobre todos os nós, machos e fêmeas juntos.
- **Oportunidade de seleção sexual (Is).** A variância no número de parceiras por macho dividida
  pelo quadrado da média. Mede o quanto o sucesso reprodutivo é desigual entre os machos.
- **Proporção de fêmeas sem acasalar.** Variável nova nesta rodada. É descritiva nos Estudos 1 e
  2, mas no Estudo 3 é o indicador direto da força de seleção agindo sobre a preferência.

- **Poliandria realizada (`grau_medio_femeas`).** O grau médio das fêmeas que acasalaram, ou
  seja, quantos parceiros elas de fato conseguiram. Atenção ao denominador: esta média exclui as
  fêmeas que não acasalaram, enquanto `prop_femeas_atingiu_k` é calculada sobre TODAS. Os dois
  denominadores são diferentes de propósito, e como `prop_femeas_sem_acasalar` também é gravada,
  qualquer das duas pode ser recalculada na base que se preferir. Sob o reenquadramento de k como apetite (ver
  a seção sobre a interação entre A_max, k e a curva de preferência), esta é a variável de
  poliandria do paper, e não o k nominal.
- **Proporção que atingiu o teto (`prop_femeas_atingiu_k`).** Quantas fêmeas chegaram ao k que
  buscavam. Mede diretamente o quanto o teto foi vinculante em cada cenário.
- **Arestas (`arestas`).** O total de acasalamentos da rede, ou seja, a densidade.
- **Censo adulto de machos (`n_machos_surv`).** Deve ser sempre 200 com o censo constante; fica
  gravado como verificação.
- **Geração de encerramento (`extincao_gen`).** NA quando a réplica chegou ao fim.

Quando a rede é pequena ou degenerada demais para uma métrica fazer sentido (por exemplo, menos
de dois machos ou menos de duas cópulas para o NODF), a métrica devolve NA em vez de zero. Isso
é deliberado: devolver zero introduziria um viés, fazendo parecer que a topologia foi medida e
deu zero, quando na verdade ela não pôde ser medida.

**Uma decisão de cálculo que vale registrar.** As fêmeas que não acasalaram são excluídas do
cálculo das métricas de topologia, porque entrariam como nós isolados e inflariam artificialmente
a modularidade e o número de subgrupos. Elas são contabilizadas separadamente, na proporção de
fêmeas sem acasalar. Já os machos com zero acasalamentos são mantidos no cálculo, porque eles são
justamente o sinal da seleção sexual (é a variação no sucesso deles que o Is mede).

---

## Como a comparação entre estudos responde às hipóteses

- **H1: a forma da curva de preferência gera assinaturas topológicas distintas.** O Estudo 1
  testa isso sem o confundimento da evolução, ou seja, mostra a topologia que a regra de escolha
  produz sozinha. O Estudo 2 mostra se essa assinatura persiste depois de 100 gerações de
  resposta evolutiva do traço.
- **H2: a topologia da rede prediz a trajetória evolutiva.** O Estudo 2 testa isso para o traço
  do macho, e o Estudo 3 testa o análogo para a preferência da fêmea.
- **H3: a restrição de amostragem apaga as assinaturas topológicas.** O gradiente de A_max está
  presente nos quatro estudos, então dá para verificar se o efeito do custo de busca é o
  mesmo quando quem responde à seleção é o traço e quando é a preferência. Vale registrar que no
  Estudo 1 esse efeito não saiu na direção esperada: a divergência entre curvas de preferência
  foi maior, e não menor, com A_max = 10. Isso precisa ser olhado com cuidado, porque a
  comparação envolve escalas diferentes entre as métricas.
- **Mecanismo de Fisher.** Só o Estudo 4 pode testar, porque é o único desenho em que a
  covariância genética entre preferência e traço pode se acumular.

---

## Convenção de nomes entre os estudos

Os motores dos Estudos 2 e 3 fazem a mesma coisa com características diferentes, mas tinham sido
escritos em momentos diferentes e usavam nomes distintos para os mesmos objetos. Isso dificultava
comparar as duas funções lado a lado, que é justamente o que a gente precisa fazer para explicar
o desenho. Os nomes foram uniformizados assim:

| O que é | Nome padrão |
|---|---|
| Filhotes por fêmea | `num_filhotes_por_femea` |
| Total de filhotes na geração | `total_filhotes` |
| Índice da mãe de cada filhote | `moms` |
| Índice do pai de cada filhote | `dads` |
| Valor paterno e materno | `z_dads` / `z_moms`, `p_dads` / `p_moms` |
| Média dos pais | `midparent` |
| Desvio de segregação | `desvio` |
| Variância parental | `var_pais` |
| Valor dos filhotes | `z_filhotes` / `p_filhotes` |
| Vagas da próxima geração | `vagas` |
| Ruído fixo do modo antigo | `eps_sd` (era `eps_p` no Estudo 3) |

**A regra é que a letra da característica não muda.** No Estudo 3 o que se herda é a preferência,
então continua sendo `p_filhotes` e não `z_filhotes`: a letra diz qual característica é, e é
justamente ela que distingue um estudo do outro. O que se uniformiza é todo o resto do nome.

**Uma assimetria que ficou de propósito.** `sigma_p` no Estudo 2 contra `sigma_p_init` no
Estudo 3: os nomes são diferentes porque as coisas são diferentes, um é parâmetro imposto a cada
geração e o outro é condição inicial, como está explicado na seção do Estudo 3.

**O sorteio dos sobreviventes agora é por índice nos três motores.** O Estudo 2 sorteava por
valor (`sample(z_filhotes, ...)`) e o Estudo 3 por índice
(`sample(seq_len(total_filhotes), ...)`). Com uma única característica herdável os dois são
equivalentes, porque `sample` sobre um vetor é implementado como sorteio de índices seguido de
indexação, e portanto consome o mesmo RNG. Mas no Estudo 4 só a forma por índice funciona, então
o Estudo 2 foi padronizado para ela: assim o padrão do código já está correto quando as duas
características entrarem. Como a mudança mexe numa chamada de sorteio, vale confirmar num cenário
com semente fixa que o resultado sai idêntico.

---

## Correspondência com o código

Esta nota foi conferida contra os scripts. A tabela abaixo diz onde verificar cada bloco.

| Afirmação da nota | Onde verificar |
|---|---|
| Curvas de preferência e suas fórmulas | `01_metricas_e_utilitarios.R`, `mate_with_survivors` |
| Amostragem sem reposição, parada em k, ausência de regra de escape | `01_metricas_e_utilitarios.R`, `mate_with_survivors` |
| Teto de parceiros: `evaluacoes_reais <- min(encounters_n, n_m)` e `if (matings_done >= matings_per_female[i]) break` | `01_metricas_e_utilitarios.R`, `mate_with_survivors` |
| Seleção natural, gamma, trava de 2 sobreviventes | `01_metricas_e_utilitarios.R`, `ensure_min_survivors` e os loops de cada estudo |
| Fecundidade neutra, paternidade sorteada, segregação infinitesimal | `01_metricas_e_utilitarios.R`, `produce_offspring` |
| Exclusão das fêmeas sem acasalar das métricas, retorno de NA | `01_metricas_e_utilitarios.R`, `calc_metrics_from_M` |
| Sementes, reparto entre máquinas, retomada por backup | `01_metricas_e_utilitarios.R`, `rodar_cenarios` |
| Estudo 1: uma geração, superfície completa, 70.560 cenários | `Fase_Controle.R` |
| Estudo 2: sigma_p imposto a cada geração, traço herdável | `Fase4_TodasAsCurvas.R` e `simulate_evolution` |
| Estudo 3: traço ambiental, preferência herdável bi-parental | `Fase_Espelho.R`, `simulate_espelho` e `produce_offspring_espelho` |
| Estudo 4: rascunho do motor, ainda sem desenho experimental | `Fase_Coevolucao.R`, e a versão atualizada nesta nota |
| Primeira versão descartada do experimento inverso | `Fase_MachoVariando.R`, mantido só como registro |
