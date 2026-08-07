# Os quatro estudos complementares

Nota de trabalho para discussão com Erika e Paulo (Miudo). Aqui está descrito o que cada
estudo faz, não os resultados. Os resultados preliminares vão num documento à parte
(`Resultados_Preliminares.Rmd`).

Esta versão da nota foi conferida linha a linha contra o código. A última seção lista, para
cada afirmação, o arquivo e a função onde ela pode ser verificada.

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
nota, quando dizemos que uma característica é herdável, estamos dizendo que ela está livre
para evoluir, e não que ela necessariamente evoluiu. Se evoluiu ou não, e em que direção,
é um resultado a ser observado.

**Característica re-sorteada (congelada).** Uma característica que não é herdada: a cada
geração seus valores são sorteados de novo da mesma distribuição, independentemente de quem
eram os pais. Ela nunca pode responder à seleção, por construção.

**Característica ambiental.** Mesma coisa que re-sorteada, mas com uma leitura biológica
específica: o valor que o indivíduo expressa depende da condição em que ele se desenvolveu
(alimento, ambiente), não do que ele herdou. Por isso não passa para os filhotes.

**Parâmetro imposto e condição inicial.** Uma distinção que importa para comparar os
estudos. Um parâmetro imposto é re-aplicado a cada geração e portanto continua valendo do
começo ao fim da réplica. Uma condição inicial vale só na geração 1, e daí em diante a
distribuição fica por conta da seleção e da deriva. No Estudo 2, sigma_p é imposto; no
Estudo 3, sigma_z é imposto e sigma_p_init é apenas condição inicial. Voltamos a este ponto
adiante, porque ele é a única assimetria estrutural entre os dois estudos.

---

## A lógica: por que quatro estudos

Todos os estudos compartilham o mesmo ciclo de vida e as mesmas quatro curvas de preferência.
O que muda entre eles é quais características são herdadas, ou seja, quais delas estão
livres para responder à seleção. Cada estudo isola uma peça diferente do sistema:

| Estudo | Traço do macho (z) | Preferência da fêmea (p) | O que o estudo isola |
|---|---|---|---|
| 1. Sem evolução | sorteado | sorteada | o efeito das regras de acasalamento sozinhas, sem nenhuma resposta evolutiva |
| 2. Fêmeas variando | herdável, livre para evoluir | re-sorteada | como a heterogeneidade de preferência afeta a resposta evolutiva do traço |
| 3. Machos variando | ambiental (re-sorteado) | herdável, livre para evoluir | como a disponibilidade de machos afeta a resposta evolutiva da preferência |
| 4. Co-evolução | herdável, livre para evoluir | herdável, livre para evoluir | o feedback entre as duas (mecanismo de Fisher) |

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
preferência, 3 valores de A_max, 3 valores de k e 2 regimes de seleção natural. Com 30 réplicas,
isso dá 4 x 7 x 7 x 3 x 3 x 2 x 30 = 105.840 cenários, de uma geração cada.

**Estado.** Concluído. Script `Fase_Controle.R`, semente base 2029.

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

**Estado.** Concluído. 15.120 cenários (4 curvas de preferência x 7 valores de sigma_p x 3
valores de A_max x 3 valores de k x 2 regimes de seleção natural x 30 réplicas), 100 gerações
cada, sem falhas. Script `Fase4_TodasAsCurvas.R`, semente base 2026.

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

**Estado.** Concluído. 15.120 cenários, mesmo desenho fatorial do Estudo 2, 30 réplicas por
cenário, 100 gerações cada. Script `Fase_Espelho.R`, semente base 2028. Os dados foram rodados
repartidos entre duas máquinas e depois reunidos; a conferência confirmou 504 cenários com 30
réplicas cada.

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

Os Estudos 2 e 3 gastam 15.120 cenários cada um para varrer um eixo. Cruzar sigma_p_init com
sigma_z_init no Estudo 4 custaria 105.840 cenários com 100 gerações cada, o que é inviável.
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
relevante, e o desenho volta a caber em 15.120 cenários, do mesmo tamanho dos Estudos 2 e 3.

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
  num_filhotes <- ifelse(acasalaram, fecundidade_base, 0)
  total_juv    <- sum(num_filhotes)
  if (total_juv == 0) return(NULL)

  moms <- rep(seq_len(n_femeas), times = num_filhotes)
  dads <- vapply(moms, function(mom) {
    parceiros <- which(M[, mom] == 1L)
    if (length(parceiros) > 1) sample(parceiros, 1) else parceiros[1]
  }, integer(1))

  # Herança de ponto médio das DUAS características, do MESMO casal.
  # É aqui que a covariância nasce: se o acasalamento foi assortativo, os pais
  # de um mesmo filhote têm z e p correlacionados, e o filhote herda os dois.
  mid_z <- (male_z_surv[dads]  + female_z_gen[moms]) / 2
  mid_p <- (male_p_surv[dads]  + female_p_gen[moms]) / 2

  desvio_segregacao <- function(valores_pais) {
    if (segregacao == "fixa") return(rnorm(total_juv, 0, eps_sd))
    v <- var(valores_pais)
    if (!is.finite(v) || v < 0) v <- 0
    rnorm(total_juv, 0, sqrt(v / 2)) + rnorm(total_juv, 0, mut_sd)
  }

  # Os desvios de segregação de z e de p são independentes entre si: a
  # segregação embaralha cada característica separadamente, e é a herança de
  # ponto médio que carrega a associação. Isso é o comportamento correto.
  z_juv <- pmax(0, mid_z + desvio_segregacao(c(male_z_surv, female_z_gen)))
  p_juv <- pmax(0, mid_p + desvio_segregacao(c(male_p_surv, female_p_gen)))

  # Capacidade de carga: mortalidade aleatória, POR ÍNDICE
  vagas <- min(N_males_next + N_females_next, total_juv)
  idx   <- sample(seq_len(total_juv), size = vagas, replace = FALSE)
  meio  <- floor(vagas / 2)
  if (meio < 1) return(NULL)
  i_m <- idx[1:meio]
  i_f <- idx[(meio + 1):(2 * meio)]

  list(male_z_next   = z_juv[i_m], male_p_next   = p_juv[i_m],
       female_z_next = z_juv[i_f], female_p_next = p_juv[i_f])
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

  # Os DOIS sexos carregam as DUAS características. A expressão é que é dimórfica:
  # só o macho mostra z, só a fêmea usa p.
  male_z_gen   <- pmax(0, rnorm(N_machos, phi, sigma_z_init))
  male_p_gen   <- pmax(0, rnorm(N_machos, phi, sigma_p_init))   # carregada, não expressa
  female_z_gen <- pmax(0, rnorm(N_femeas, phi, sigma_z_init))   # carregada, não expressa
  female_p_gen <- pmax(0, rnorm(N_femeas, phi, sigma_p_init))

  out <- vector("list", generations)

  for (t in seq_len(generations)) {

    female_p <- female_p_gen                                     # HERDADA (evolui)
    female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s)) # choosiness fixa

    # (1) Seleção natural de viabilidade sobre o traço do macho.
    # No Estudo 4 ela volta a ter consequência evolutiva (o traço é herdado) e
    # é a única força que age DIRETAMENTE contra a exageração do traço.
    if (selecao_natural) {
      V <- exp(-gamma * (male_z_gen - phi)^2)
      survive <- runif(N_machos) <= V
      survive <- ensure_min_survivors(survive, V, min_surv = 2)
    } else {
      survive <- rep(TRUE, N_machos)
    }
    male_z_surv <- male_z_gen[survive]
    male_p_surv <- male_p_gen[survive]   # o índice é o mesmo: z e p do mesmo macho

    # (2) Rede de acasalamentos (sem regra de escape)
    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                             encounters_n = encounters_n, k_fixo = k_fixo)
    metrics <- calc_metrics_from_M(M)

    # (3) Registro. A GRANDEZA CENTRAL deste estudo é cov(z, p) no pool
    # genotípico: é ela que mede o quanto preferência e traço estão associados,
    # e portanto o quanto a seleção sobre um arrasta o outro.
    pool_z <- c(male_z_gen, female_z_gen)
    pool_p <- c(male_p_gen, female_p_gen)
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
      metrics
    )

    # (4) Próxima geração: as duas características, pareadas
    off <- produce_offspring_coevo(M, male_z_surv, male_p_surv,
                                   female_z_gen, female_p_gen,
                                   N_machos, N_femeas,
                                   fecundidade_base = fecundidade_base,
                                   segregacao = segregacao,
                                   eps_sd = eps_sd, mut_sd = mut_sd)
    if (is.null(off)) break   # ninguém acasalou: encerra a réplica
    male_z_gen   <- off$male_z_next
    male_p_gen   <- off$male_p_next
    female_z_gen <- off$female_z_next
    female_p_gen <- off$female_p_next
  }

  dplyr::bind_rows(out)
}

# =====================================================================
# DESENHO EXPERIMENTAL: a DIAGONAL sigma_p_init = sigma_z_init
# =====================================================================
if (!exists("COEVO_SO_FUNCOES") || !isTRUE(COEVO_SO_FUNCOES)) {

  diretorios <- configurar_diretorios("Fase_Coevolucao")
  cat("Iniciando Estudo 4: co-evolução (traço e preferência herdáveis)...\n")

  valores_sigma <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
  n_replicas    <- 30

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

**Três pontos para discutir antes de rodar.**
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
  ou seja, 100%, 20% e 5% dos machos). Representa o custo ecológico de procurar parceiro.
- k: quantos parceiros cada fêmea acasala (5, 10 ou 20). Representa o grau de poliandria.
- Seleção natural de viabilidade sobre o traço do macho, ligada ou desligada.

**Uma interação entre A_max e k que precisa ser lembrada na análise.** Como a amostragem é sem
reposição, uma fêmea nunca pode acasalar com mais machos do que os que ela avaliou. Nos cenários
com A_max = 10 e k = 20, o k é inalcançável: o máximo efetivo é 10, e mesmo isso só se ela
aceitar todos os dez. Com A_max = 10 e k = 5, ela precisa aceitar metade dos machos que viu.
Isso não é um defeito do modelo, é exatamente o custo de busca que queremos representar, mas
significa que o efeito de k não pode ser lido isoladamente do de A_max.

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

**Réplicas.** 30 nesta rodada de exploração, 100 na rodada final.

---

## O ciclo de vida, passo a passo

Cada geração segue sempre a mesma sequência, nos quatro estudos. O que muda entre os estudos
é apenas quais características são herdadas no passo 5.

**1. Ponto de partida.** Todas as distribuições são centradas em phi = 5, que é ao mesmo tempo
a média inicial do traço, a média inicial do pico de preferência e o ótimo da seleção natural.
Os machos começam com traço sorteado de N(5, sigma_z) e as fêmeas com pico de preferência
sorteado de N(5, sigma_p). Todos os valores são truncados em zero, ou seja, nem o traço nem a
preferência podem ser negativos.

**2. Seleção natural de viabilidade (ligada ou desligada).** Quando está ligada, cada macho
sobrevive até a fase de acasalamento com probabilidade

    V = exp(-gamma * (z - phi)^2),  com gamma = 0.2

ou seja, quanto mais o traço do macho se afasta do ótimo ecológico phi = 5, menor a chance dele
sobreviver. Quem não sobrevive é removido e não entra no pool de acasalamento. Quatro
observações importantes:
- A seleção natural age apenas sobre os machos e apenas sobre o traço, nunca sobre a
  preferência.
- Quando está desligada, todos os machos sobrevivem (V = 1), e assim isolamos o efeito puro da
  escolha feminina.
- Há uma trava de segurança: se menos de 2 machos sobrevivessem, os 2 de maior viabilidade são
  resgatados. Serve para que a rede nunca fique degenerada demais para calcular as métricas.
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

**6. Mortalidade e capacidade de carga.** Todos os filhotes vão para um mesmo pote (cerca de
10.000, quando quase todas as fêmeas acasalam) e desse pote são sorteados ao acaso 200 machos e
200 fêmeas para formar a geração seguinte. Esse sorteio não tem seleção nenhuma: é mortalidade
aleatória, e é a fonte de deriva genética do modelo. Uma característica só evolui de forma
dirigida se alguns pais colocaram mais filhotes nesse pote do que outros.

**Um caso extremo que o código trata.** Se numa geração absolutamente nenhuma fêmea acasalar, o
pote fica vazio. Nos Estudos 3 e 4 a réplica é encerrada ali e as gerações já rodadas são
mantidas. No Estudo 2 o código repete a geração anterior em vez de encerrar. Essa diferença é
uma inconsistência menor herdada da ordem em que os scripts foram escritos, e vale uniformizar
antes da rodada final. Na prática ela não deve estar afetando nada, porque a taxa de fêmeas sem
acasalar nunca chegou perto de 100% em nenhum cenário.

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
| réplicas | repetições independentes por cenário | 30 (final: 100) |
| semente base | por estudo, para reprodutibilidade | 2026 (E2), 2028 (E3), 2029 (E1), 2030 (E4) |

Todos os cenários são reprodutíveis: a semente de cada um é `semente base + índice global do
cenário`, definida dentro da tarefa. Isso vale mesmo quando as réplicas são repartidas entre
máquinas diferentes, porque o índice usado é o do desenho completo e não o da fatia.

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

## Correspondência com o código

Esta nota foi conferida contra os scripts. A tabela abaixo diz onde verificar cada bloco.

| Afirmação da nota | Onde verificar |
|---|---|
| Curvas de preferência e suas fórmulas | `01_metricas_e_utilitarios.R`, `mate_with_survivors` |
| Amostragem sem reposição, parada em k, ausência de regra de escape | `01_metricas_e_utilitarios.R`, `mate_with_survivors` |
| Seleção natural, gamma, trava de 2 sobreviventes | `01_metricas_e_utilitarios.R`, `ensure_min_survivors` e os loops de cada estudo |
| Fecundidade neutra, paternidade sorteada, segregação infinitesimal | `01_metricas_e_utilitarios.R`, `produce_offspring` |
| Exclusão das fêmeas sem acasalar das métricas, retorno de NA | `01_metricas_e_utilitarios.R`, `calc_metrics_from_M` |
| Sementes, reparto entre máquinas, retomada por backup | `01_metricas_e_utilitarios.R`, `rodar_cenarios` |
| Estudo 1: uma geração, superfície completa, 105.840 cenários | `Fase_Controle.R` |
| Estudo 2: sigma_p imposto a cada geração, traço herdável | `Fase4_TodasAsCurvas.R` e `simulate_evolution` |
| Estudo 3: traço ambiental, preferência herdável bi-parental | `Fase_Espelho.R`, `simulate_espelho` e `produce_offspring_espelho` |
| Estudo 4: rascunho do motor, ainda sem desenho experimental | `Fase_Coevolucao.R`, e a versão atualizada nesta nota |
| Primeira versão descartada do experimento inverso | `Fase_MachoVariando.R`, mantido só como registro |
