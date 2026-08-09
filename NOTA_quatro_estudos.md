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

**Variabilidade total, ou a norma.** Quanta variação existe no sistema como um todo, somando os
dois sexos: `sqrt(sigma_p^2 + sigma_z^2)`. É alta quando os dois sexos são heterogêneos e baixa
quando os dois são homogêneos. Não diz nada sobre qual dos dois contribui mais.

**Assimetria.** De que lado está a variação: `log(sigma_z / sigma_p)`. Vale zero quando os dois
sexos variam o mesmo, é positiva quando os machos variam mais que as fêmeas e negativa no caso
contrário. O logaritmo está ali porque a comparação é de razão e não de diferença: os machos
variarem o dobro das fêmeas e as fêmeas variarem o dobro dos machos são situações igualmente
assimétricas em sentidos opostos, e o logaritmo as coloca à mesma distância de zero (mais e menos
0.69). Sem ele, a razão 2 ficaria a 1 de distância e a razão 0.5 ficaria a apenas 0.5.

As duas juntas são apenas outra forma de escrever o par (sigma_p, sigma_z), como trocar
coordenadas cartesianas por polares: a mesma informação, reorganizada para separar duas perguntas
que se confundiam. Quanta variação existe é uma coisa; de que lado está é outra. A análise do
Controle mostrou que a segunda pergunta é a que importa, e é por isso que estes dois termos
aparecem aqui em vez de sigma_p e sigma_z crus.

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

**Parâmetro imposto e condição inicial.** Uma distinção que importa na hora de comparar os
estudos. Um parâmetro imposto é re-aplicado a cada geração e portanto continua valendo do começo
ao fim da réplica. Já uma condição inicial vale só na geração 1, e daí em diante a distribuição
fica por conta da seleção e da deriva. Em Fêmeas variando, os 7 níveis de sigma_p são impostos e
sigma_z_init é apenas condição inicial (fixa em 1.0). Em Machos variando, o espelho, os 7 níveis
de sigma_z são impostos e sigma_p_init é apenas condição inicial (fixa em 1.0).
Nesse aspecto os dois estudos são simétricos. A assimetria real está noutro ponto: a seleção natural de viabilidade age sobre z nos dois estudos, mas em Fêmeas variando ela age diretamente sobre a característica que evolui, competindo com a seleção sexual, enquanto em Machos variando ela age sobre uma característica ambiental e não tem consequência evolutiva nenhuma. A preferência, que é o que evolui ali, não recebe seleção natural.

### Vocabulário do desenho

**Cenário e réplica.** Um cenário é uma combinação concreta de valores dos fatores do desenho:
uma curva de preferência, um sigma, um A_max, um k e um regime de seleção natural. Uma réplica é
uma repetição independente do mesmo cenário, com outra semente aleatória. Quando dizemos "70.560
cenários", as réplicas já estão contadas dentro.

**Célula.** Usado só nas análises, e não é sinônimo de cenário: uma célula é uma combinação de
tudo MENOS a curva de preferência. Serve para comparar as quatro curvas entre si mantendo o resto
igual, que é a única forma de isolar o efeito da curva.

**A_max.** Quantos machos distintos cada fêmea consegue avaliar antes de decidir com quem
acasalar. Representa o custo ecológico de procurar parceiro: quanto menor, mais cara é a busca.
Assume os valores 200, 40 e 10.

**k, e a poliandria realizada.** k é o número máximo de parceiros que a fêmea busca (5, 10 ou
20). Ela para quando o atinge ou quando esgota os A_max machos que avaliou, o que vier primeiro,
então k é um teto e não uma cota. A poliandria realizada é quantos parceiros ela de fato
conseguiu, e é uma variável resposta e não um parâmetro. A seção sobre a interação entre A_max, k
e a curva de preferência mostra o quanto as duas coisas podem diferir.

### Vocabulário das respostas

**As quatro métricas de topologia.** Calculadas sobre a rede bipartita de acasalamentos.
Modularidade é o quanto a rede se divide em grupos que acasalam preferencialmente entre si.
Aninhamento (NODF) é o quanto os parceiros dos machos menos procurados são um subconjunto dos
parceiros dos mais procurados, ou seja, o quanto existe hierarquia. Centralização é o quanto os
acasalamentos se concentram em poucos indivíduos. Oportunidade de seleção sexual (Is) é a
desigualdade no número de parceiras entre os machos. A seção sobre as métricas dá as definições
completas.

**Divergência entre curvas de preferência.** Uma grandeza construída por nós para a análise, e o
resultado principal do Controle. Dentro de uma célula, calcula-se a média de cada uma das quatro
métricas para cada curva, e a divergência é o quanto essas quatro posições se afastam do centro
comum delas. Vale zero se as quatro curvas produzem a mesma topologia, e cresce quanto mais elas
se separam. As métricas são padronizadas antes, para que a de maior escala não domine o cálculo.

### Vocabulário do modelo

**Regra de escape.** Uma regra da versão antiga do modelo, já removida. Se a fêmea avaliava os
machos e não aceitava nenhum, ela acabava acasalando à força com o último avaliado, de modo que
nenhuma fêmea ficava sem acasalar. Como a fecundidade é neutra, isso fazia com que todas as
fêmeas tivessem exatamente o mesmo sucesso reprodutivo, e sem variância de sucesso não pode haver
seleção sobre a preferência. Agora quem não aceita ninguém fica sem acasalar.

**Variância de segregação.** O quanto um filhote se desvia da média dos seus dois pais. Vem de
qual metade dos genes de cada pai ele calhou de receber. No modelo infinitesimal, que é o que
usamos, esse desvio é proporcional à variância que existe entre os pais, e não um ruído de
tamanho fixo escolhido por nós.

**R^2 parcial.** Nas análises, o quanto um termo explica do que ainda sobrava depois de já
descontar outros. Aparece porque o regime de busca (A_max, k e seleção natural) domina o
fenômeno, e um R^2 comum, sem descontá-lo, esmagaria todos os outros efeitos e os faria parecer
nulos.
---

## A lógica: por que quatro estudos

Todos os estudos compartilham o mesmo ciclo de vida e as mesmas quatro curvas de preferência.
O que muda entre eles é quais características são herdadas, ou seja, quais delas estão
livres para responder à seleção. Cada estudo isola uma peça diferente do sistema:

| Estudo | O que varia | Traço do macho (z) | Preferência da fêmea (p) | O que o estudo isola |
|---|---|---|---|---|
| **Controle** | sigma_p e sigma_z | sorteado | sorteada | o efeito das regras de acasalamento sozinhas, sem nenhuma resposta evolutiva |
| **Fêmeas variando** | sigma_p | herdável, livre para evoluir | re-sorteada | como a heterogeneidade de preferência afeta a resposta evolutiva do traço |
| **Machos variando** | sigma_z | re-sorteado (ambiental) | herdável, livre para evoluir | como a disponibilidade de machos afeta a resposta evolutiva da preferência |
| **Co-evolução** | os dois, só como condição inicial | herdável, livre para evoluir | herdável, livre para evoluir | o feedback entre as duas (mecanismo de Fisher) |

Repare na última coluna da esquerda: nos três primeiros estudos o que varia é um parâmetro
imposto, que vale do começo ao fim. Em Co-evolução isso é impossível, e a razão está explicada
na seção daquele estudo.

Vale insistir num ponto: "livre para evoluir" descreve o desenho, não o resultado. Em vários
cenários a característica herdável pode simplesmente não mudar. O exemplo mais claro é a curva
de preferência aleatória, em que as fêmeas não discriminam entre machos: ali o traço continua
sendo herdável, mas como nenhuma seleção sexual age sobre ele, ele apenas deriva ao acaso. A comparação entre curvas de preferência é justamente o que revela quando a herdabilidade
se traduz em mudança evolutiva e quando não.

A comparação entre os estudos nos ajuda a entender o sistema melhor: 
- A diferença entre Fêmeas variando e o Controle mostra o que a resposta evolutiva do traço acrescenta.
- A diferença entre Machos variando e o Controle mostra o que a resposta evolutiva da preferência acrescenta.
- O Co-evolução mostra o que emerge quando as duas evoluem juntas, que não é a soma dos anteriores.

---

## O que é comum aos quatro estudos

Antes de descrever cada estudo, o que todos compartilham. Os quatro usam exatamente o mesmo
ciclo de vida, as mesmas quatro curvas de preferência e os mesmos fatores cruzados, e é por isso
que as diferenças entre eles podem ser atribuídas ao que de fato muda: quais características são
herdadas. Cada seção de estudo mais adiante descreve só o que aquele estudo altera.

**População.** 200 machos e 200 fêmeas, gerações discretas e não sobrepostas, tamanho
populacional constante. Cem gerações por réplica em Fêmeas variando, Machos variando e Co-evolução; uma geração no Controle.

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
- NMachos variando, em que o traço do macho é ambiental, a seleção natural continua funcionando como
  filtro ecológico (muda quais machos estão disponíveis), mas não tem consequência evolutiva,
  porque o traço não é transmitido aos filhotes. O mesmo vale para o Controle, por não haver
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

Vale explicar por que não ficamos com nenhuma das duas soluções anteriores. Fêmeas variando devolvia a
geração anterior, o que fabrica uma geração de pais imortais que não deixaram descendência mas
continuam na população. E devolvia apenas os machos sobreviventes, não os 200: a população
encolhia em silêncio, e a partir dali o passo de viabilidade reciclava um vetor mais curto,
`male_z_gen[survive]` passava a devolver NA, e a réplica seguia rodando produzindo lixo sem
nenhum aviso. Machos variando encerrava a réplica, que é o correto, mas sem deixar registro: ela
entrava no conjunto de dados apenas com menos gerações, e desaparecia depois no filtro
`generation == 100`. Como as réplicas que falham são justamente as dos cenários mais duros, essa
perda silenciosa seria enviesada.

Com a coluna `extincao_gen`, quantas réplicas se extinguem por cenário passa a ser um resultado
que se pode reportar: é a medida de quando as regras de acasalamento foram restritivas demais
para a população se sustentar. Na prática esperamos que seja zero em todos os cenários já
rodados, porque a proporção de fêmeas sem acasalar nunca chegou perto de 92%, mas isso agora fica
verificável em vez de suposto.

---

## Controle

*Variam sigma_p e sigma_z. Nada é herdado.*

Daqui em diante, um estudo por seção. Tudo o que não estiver dito é o que ficou descrito acima,
no ciclo de vida e nos fatores comuns.

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
- A geração 1 de Fêmeas variando varre sigma_p, mas com sigma_z fixo em 1.0.
- A geração 1 de Machos variando varre sigma_z, mas com sigma_p fixo em 1.0.

As duas se cruzam exatamente no ponto sigma_p = sigma_z = 1.0, que é literalmente o mesmo
cenário nos dois estudos. Juntas, portanto, elas formam uma cruz no espaço de parâmetros, e as
combinações extremas ficam de fora: nunca se observa, por exemplo, fêmeas muito heterogêneas
diante de machos muito homogêneos, ou o contrário. Como justamente essas combinações extremas
são as mais informativas sobre o que a regra de acasalamento faz sozinha, vale a pena rodar a
superfície inteira.

**Por que não aproveitar a geração 1 de Co-evolução.** Seria possível: se Co-evolução cruzasse
sigma_p com sigma_z nas condições iniciais, a sua geração 1 daria a superfície completa de
graça. Mas isso obrigaria Co-evolução a ter um desenho sete vezes maior por uma razão que não é
dele: em Co-evolução o que interessa é a dinâmica da covariância entre preferência e traço, e não
quanta variância havia no ponto de partida. Como este controle é barato, sai mais em conta
mantê-lo separado e deixar Co-evolução livre para ser desenhado segundo a sua própria pergunta.

**Desenho.** Cruzamento completo de sigma_p (7 valores: 0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0) por
sigma_z (os mesmos 7 valores), somado aos mesmos fatores dos outros estudos: 4 curvas de
preferência, 3 valores de A_max, 3 valores de k e 2 regimes de seleção natural. Com 20 réplicas,
isso dá 4 x 7 x 7 x 3 x 3 x 2 x 20 = 70.560 cenários, de uma geração cada.

**Estado.** Concluído com o modelo atual (censo de adultos constante e poliandria realizada):
70.560 cenários, 20 réplicas, sem falhas. As análises do plano de Co-evolução citadas mais adiante
vêm de uma rodada anterior, com 30 réplicas e o modelo antigo, e devem ser refeitas sobre estes
dados. Script `Fase_Controle.R`, semente base 2029.

---

## Fêmeas variando

*Varia sigma_p. Evolui o traço do macho.*

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

## Machos variando

*Varia sigma_z. Evolui a preferência da fêmea.*

**Pergunta.** Como a disponibilidade de machos com traços variados (sigma_z) afeta a resposta
evolutiva da preferência feminina?

**Como funciona.** É o espelho de Fêmeas variando: os papéis se invertem.
- O eixo do experimento é sigma_z, que varia de 0.2 (machos quase todos parecidos) a 2.0
  (machos muito variados).
- O traço do macho passa a ser ambiental: é re-sorteado a cada geração de N(5, sigma_z) e não é
  herdado. A leitura biológica é de dependência de condição, ou seja, o macho expressa aquele
  traço por causa do ambiente em que se desenvolveu, e não por causa dos genes que vai transmitir.
- O pico de preferência da fêmea passa a ser herdável e bi-parental, portanto livre para
  evoluir: os dois sexos carregam p (o macho carrega sem expressar, do mesmo modo que no
  Fêmeas variando a fêmea carrega o traço sem expressar) e o filhote recebe a média dos pais mais a
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

**Uma assimetria estrutural que vale declarar no paper.** NFêmeas variando, sigma_p é um parâmetro
imposto: a distribuição de preferências é re-sorteada com aquela largura a cada uma das 100
gerações, então o tratamento continua valendo até o fim. NMachos variando, sigma_z também é imposto
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

**Estado.** Concluído com o modelo atual: 10.080 cenários, mesmo desenho fatorial de Fêmeas variando,
20 réplicas, 100 gerações cada. Script `Fase_Espelho.R`, semente base 2028.

---

## Co-evolução (proposta)

*Evoluem os dois. Os dois sigmas são apenas condição inicial.*

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

**Uma previsão sobre a variância inicial.** No Controle, em Fêmeas variando e em Machos variando,
sigma é um parâmetro imposto e por isso vale do começo ao fim. Em Co-evolução isso é impossível:
como as duas características são herdáveis, impor a variância significaria re-sortear os valores a
cada geração, e re-sortear é exatamente o que impede a herança. Os dois sigmas só podem ser
condição inicial.

Isso não os torna irrelevantes, muda a pergunta que eles fazem. A resposta à seleção é
proporcional à variância genética disponível: com pouca variância de partida o sistema responde
devagar, com muita responde rápido. E como o mecanismo de Fisher é um ciclo de retroalimentação,
a velocidade inicial pode decidir se ele chega a se acender. Se a covariância cresce devagar
demais, a seleção natural puxa o traço de volta para phi antes que o ciclo se estabeleça, e a
seleção também vai erodindo a própria variância que alimentaria a resposta.

**A previsão, então, é de limiar e não de dose.** Esperamos uma variância inicial abaixo da qual
o runaway não acontece e acima da qual acontece, e não uma resposta que cresça suavemente com
sigma_init. O limiar deve depender da curva de preferência, sendo mais baixo na sigmoide, que é a
única direcional, e deve subir quando a seleção natural está ligada, porque ela é a força que
compete com o ciclo.

Uma ressalva teórica. No modelo analítico de Lande, se o runaway ocorre é uma condição sobre os
parâmetros, e não sobre a variância inicial: esta determina só a direção ao longo da linha de
equilíbrios. O limiar que esperamos aqui é um efeito de população finita, em que a variância
erode sob seleção e a deriva atua, então ele é uma previsão sobre a simulação e não sobre a
teoria. Vale declarar isso ao reportar.

**Consequência para o desenho.** Procurar um limiar não exige um gradiente fino. Três níveis bem
separados de variância inicial (baixa, média, alta) bastam para localizá-lo, e os cenários
economizados podem ir para o eixo que a análise do Controle mostrou ser o que manda.

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
biologia. É o tipo de erro que não gera mensagem de erro nenhuma. Em Fêmeas variando e em Machos variando esse
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
   que corrigimos em Fêmeas variando e em Machos variando: com ruído fixo a variância genética cai até o piso 2 vezes
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

### Proposta de desenho: medir a assimetria em vez de impô-la

Cruzar sigma_p_init com sigma_z_init em Co-evolução custaria 70.560 cenários com 100 gerações
cada, o que é inviável. Fêmeas variando e Machos variando gastam 10.080 cada um para varrer um
eixo só. É preciso um corte, e a análise do Controle diz qual.

**O que o Controle mostrou** (`10_Analise_Diagonal.R`, sobre os 70.560 cenários da superfície
completa). A divergência entre as quatro curvas de preferência, medida como a distância média ao
centroide delas no espaço das quatro métricas padronizadas, foi modelada em função da posição no
plano. O regime de busca domina: A_max, k e seleção natural sozinhos explicam R^2 = 0.679. Sobre
essa base, o que cada termo de dispersão acrescenta é:

| Termo | R^2 parcial (dentro do regime de busca) | R^2 (agregado nas 49 células) |
|---|---|---|
| Assimetria, `log(sigma_z / sigma_p)` | **0.428** | **0.639** |
| Descasamento, `abs(log(sigma_p / sigma_z))` | 0.103 | 0.154 |
| Máximo, `max(sigma_p, sigma_z)` | 0.049 | 0.074 |
| Variabilidade total, `sqrt(sigma_p^2 + sigma_z^2)` | 0.020 | 0.030 |

**O que importa não é quanta variabilidade existe, é de que lado ela está.** A divergência é
máxima quando as fêmeas são homogêneas e os machos variados: das 37 células cuja divergência
ultrapassa o máximo alcançado pela diagonal, todas têm sigma_p baixo e sigma_z alto, e nenhuma o
contrário. A leitura biológica é direta. Quando todas as fêmeas querem a mesma coisa, a geometria
da curva se traduz sem ruído em quem acasala com quem; quando as fêmeas discordam entre si, a
variação individual delas borra a assinatura. E é preciso haver machos variados para que exista
algo a discriminar.

Repare na diferença entre as duas primeiras linhas da tabela. As duas medem a repartição entre os
sexos, mas o descasamento em valor absoluto trata como equivalentes duas situações biologicamente
opostas, fêmeas homogêneas com machos variados e o contrário, e por isso subestima as duas. É
preciso medir com sinal.

**Um resultado colateral que vale para o paper.** O espalhamento da poliandria realizada entre as
curvas acrescenta R^2 parcial de 0.0097, e somado à assimetria acrescenta 0.0003, com AIC pior. A
divergência entre curvas de preferência não é, portanto, um artefato de densidade de rede. A
ressalva é que o modelo base já contém A_max e k, que são os maiores determinantes do grau
realizado, então o que este teste mostra é que a densidade residual não explica nada. Não é uma
análise de mediação completa.

**Mas nada disso pode ser imposto em Co-evolução.** Como as duas características são herdáveis,
os dois sigmas são apenas condição inicial (ver a previsão sobre a variância inicial, acima). A
assimetria da geração 50 não é a que fixamos na geração 1.

Isso não anula o resultado do Controle, muda o seu papel. Ele é um fato sobre a regra de
acasalamento, não sobre o desenho: dada uma população com estas dispersões, as curvas divergem
isto. Vale em qualquer geração de qualquer estudo, porque as quatro usam a mesma
`mate_with_survivors`. O que deixa de valer é usá-lo para desenhar a grade de sigma_init.

**A proposta, então, é medir em vez de impor.** A assimetria realizada é calculável a cada
geração a partir do que já gravamos:

    assimetria_realizada(t) = 0.5 * log( varz_pop(t) / varp_pop(t) )

Ela entra na análise como covariável geração a geração, e a pergunta passa a ser se a relação que
o Controle encontrou se mantém quando as duas características evoluem. Manter-se ou não é
resultado.

Para a condição inicial bastam três níveis bem separados de variância (0.5, 1.0 e 2.0), porque o
que se procura ali é o limiar de ignição descrito acima, e não uma curva de resposta. Mas os três
níveis vão CRUZADOS entre os dois sexos, e não ao longo da diagonal. A razão é que a geração 1 de
Co-evolução é uma situação de tipo controle, onde a assimetria inicial afeta de verdade a rede
que se forma, e a pergunta em aberto é se esse efeito se propaga ou se dissolve. Só o cruzamento
permite perguntá-lo; a diagonal fixaria a assimetria inicial em zero e a pergunta desapareceria.

As nove combinações, ordenadas pela assimetria. As duas colunas da direita são as grandezas
definidas no vocabulário: a norma diz quanta variação há, a assimetria diz de que lado está.

| sigma_p | sigma_z | Assimetria log(sigma_z/sigma_p) | Norma sqrt(sigma_p^2+sigma_z^2) | |
|---|---|---|---|---|
| 2.0 | 0.5 | -1.39 | 2.06 | fêmeas muito variadas, machos homogêneos |
| 1.0 | 0.5 | -0.69 | 1.12 | |
| 2.0 | 1.0 | -0.69 | 2.24 | |
| 0.5 | 0.5 | 0.00 | 0.71 | a diagonal, pouca variação |
| 1.0 | 1.0 | 0.00 | 1.41 | a diagonal, média |
| 2.0 | 2.0 | 0.00 | 2.83 | a diagonal, muita |
| 0.5 | 1.0 | +0.69 | 1.12 | |
| 1.0 | 2.0 | +0.69 | 2.24 | |
| 0.5 | 2.0 | +1.39 | 2.06 | fêmeas homogêneas, machos variados |

São cinco valores de assimetria e seis de variabilidade total. As três linhas do meio são a
diagonal que havíamos proposto: percorre a norma de 0.71 a 2.83 e deixa a assimetria presa em
zero, exatamente ao contrário do que interessa. A última linha é o canto onde o Controle
encontrou a divergência máxima, e o desenho diagonal a deixaria de fora por completo.

**A assimetria com sinal e a norma ficam exatamente descorrelacionadas neste desenho** (r = 0),
porque cada assimetria positiva tem o seu espelho negativo com a mesma norma e as contribuições
se cancelam. Os dois efeitos podem então ser estimados separadamente, sem colinearidade, que era
o risco de qualquer redução. Um limite honesto: as assimetrias extremas (mais e menos 1.39) só
aparecem com norma 2.06, e não há como evitar isso com três níveis.

O desenho fica em 4 curvas x 9 combinações x 3 A_max x 3 k x 2 regimes x 20 réplicas = 12.960
cenários, cerca de um quinto a mais que Fêmeas variando e Machos variando, e menos de um quinto
da superfície completa.

**E daqui sai uma previsão que liga as duas coisas.** Em Co-evolução o traço está sob seleção de
viabilidade e sob seleção sexual, enquanto a preferência não recebe seleção direta nenhuma. Se
sigma_z erodir mais depressa que sigma_p, a assimetria realizada deriva para valores negativos, e
o Controle diz que essa é a região de divergência baixa. A previsão é que a assinatura topológica
das curvas de preferência se desvaneça ao longo das gerações, a menos que o runaway se acenda e
reponha variância no traço. A persistência da assinatura seria, ela mesma, um indicador de que o
ciclo de Fisher está ativo.

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
  # CASO DEGENERADO: mesma regra dos outros estudos
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
    # e sobram sempre N_machos adultos. NCo-evolução ela volta a ter consequência
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
    # sexos. Atenção: aqui, ao contrário de Machos variando, a seleção de viabilidade
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
# DESENHO EXPERIMENTAL: três níveis de variância inicial
# =====================================================================
if (!exists("COEVO_SO_FUNCOES") || !isTRUE(COEVO_SO_FUNCOES)) {

  diretorios <- configurar_diretorios("Fase_Coevolucao")
  cat("Iniciando Co-evolução (traço e preferência herdáveis)...\n")

  # Três níveis bem separados, CRUZADOS entre os dois sexos. Não é um gradiente
  # fino de propósito: aqui sigma é só condição inicial e o que se procura é o
  # LIMIAR de ignição do ciclo de Fisher, não uma curva de resposta.
  # O cruzamento (e não a diagonal) é o que permite perguntar se PARTIR
  # assimétrico muda a trajetória. A assimetria das gerações seguintes não é
  # imposta, é MEDIDA a partir de varz_pop e varp_pop (ver o texto).
  valores_sigma <- c(0.5, 1.0, 2.0)
  n_replicas    <- 20

  cenarios <- expand.grid(
    tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
    sigma_p_init    = valores_sigma,
    sigma_z_init    = valores_sigma,
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
      sigma_p_init    = cenarios$sigma_p_init[i],
      sigma_z_init    = cenarios$sigma_z_init[i],
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
  cat("\nCo-evolução (co-evolução) concluído! Dados salvos em:", arquivo_final, "\n")
  cat(sprintf("Total de linhas: %d\n", nrow(df_coevo)))
}
```

**Quatro pontos para discutir antes de rodar.**

**1. O gradiente de k**, que é o mais urgente. Como está detalhado na seção sobre a interação
entre A_max, k e a curva de preferência, das nove células do cruzamento A_max por k, as com
A_max = 10 e k igual a 10 ou 20 não são tratamentos distintos: nelas o k nunca é atingido e o que
sobra é sempre "ela acasala com quem aceitar entre dez machos". Copiar o desenho de Fêmeas
variando e Machos variando gastaria cenários em células que não separam nada. Três saídas, em
ordem crescente de ambição: (a) manter o cruzamento como está, para conservar a comparabilidade
com os outros estudos, e apenas declarar a limitação; (b) substituir o k fixo por um k
proporcional a A_max, de modo que o gradiente de poliandria seja o mesmo em todos os níveis de
custo de busca; (c) deixar o k de fora de Co-evolução, já que ele foi varrido nos outros dois, e
usar os cenários economizados para outra coisa. A opção (a) é a mais conservadora; a (c) é a que
aproveita melhor o orçamento.

**2. Os três níveis de variância inicial bastam?** A previsão é de limiar e não de dose, o que
justifica três níveis bem separados. Mas se o limiar cair entre dois deles, saberemos que existe
e não onde está. Vale acrescentar um quarto nível, ou é melhor localizá-lo depois, com uma
varredura fina só na curva de preferência onde ele aparecer?

**3. A `cov_casais`**, que mede a covariância entre traço e preferência dentro dos casais que
efetivamente acasalaram. É o passo anterior na cadeia causal, acasalamento assortativo primeiro e
covariância genética depois, e permite separar os dois. Vale registrar as duas ou é redundante?

**4. A explosão numérica.** Se o runaway aparecer com a curva sigmoide e sem seleção natural, o
traço pode crescer sem limite. Em Fêmeas variando e Machos variando isso não acontecia porque só
uma característica evoluía. Talvez valha registrar um indicador de fuga, por exemplo a geração em
que a média do traço passa de algum múltiplo de phi, em vez de deixar a réplica correr até a
geração 100 sem aviso.

**Estado.** Motor rascunhado em `Fase_Coevolucao.R`, com os pontos de atualização listados acima
ainda pendentes. Nada rodado, aguardando a discussão dos quatro pontos de desenho.

---

## A interação entre A_max, k e a curva de preferência

Este ponto precisa ficar explícito porque afeta a leitura de todos os estudos já rodados e,
principalmente, a escolha de parâmetros de Co-evolução, que ainda está aberta.

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

**Segundo, o que é um problema de verdade, e ele só existia com a seleção natural LIGADA.** Com
ela desligada, o código fazia `survive <- rep(TRUE, N_machos)` e os 200 machos passavam todos, de
modo que o pool era constante. Com ela ligada, o número de machos disponíveis muda de cenário
para cenário, porque a viabilidade remove uma fração que depende de sigma_z. A fração que
sobrevive é aproximadamente `1 / sqrt(1 + 2 gamma sigma_z^2)`, ou seja, com gamma = 0.2:

| sigma_z | 0.2 | 0.5 | 0.8 | 1.0 | 1.2 | 1.5 | 2.0 |
|---|---|---|---|---|---|---|---|
| Machos sobreviventes (de 200) | 198 | 191 | 178 | 169 | 159 | 145 | 124 |

O pool encolhe 37% ao longo do gradiente. Como o número de fêmeas e o k continuam os mesmos, o
número total de arestas da rede não muda, mas ele se reparte entre menos machos: com k = 5, o
grau médio dos machos passa de cerca de 5.1 para cerca de 8.1. Isso afeta diretamente o Is, a
centralização e o aninhamento, e não tem nada a ver com a escolha feminina.

**Onde isso morde.** Em Fêmeas variando pouco, porque sigma_z fica fixo em 1.0 e o pool é
estável. No Controle e em Machos variando morde de frente, porque ali sigma_z é o eixo do
experimento: parte de qualquer tendência das métricas ao longo dele, nos cenários com seleção
natural ligada, era só o pool encolhendo.

**E o pior é que o confundimento estava alinhado com o contraste que interessa.** Como o pool só
encolhia com a seleção natural ligada, comparar os dois regimes não comparava apenas "há seleção"
contra "não há": comparava também "há menos machos" contra "há 200". Um artefato de densidade
teria se apresentado como um efeito da seleção natural, que é o pior lugar possível para ele
estar.

O lado prático disso é bom: para a metade do desenho sem seleção natural, o censo constante é uma
mudança cosmética. O código antigo entregava 200 machos e o novo entrega 200 machos, com a mesma
distribuição.

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
mudar a regra faria Co-evolução deixar de ser comparável com os Controle, Fêmeas variando e Machos variando, e a inferência
inteira depende dessa comparação: a diferença entre Co-evolução e o Controle é o que a co-evolução
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
   Machos variando seria impossível.
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

## Parâmetros do modelo

| Símbolo | O que é | Valor |
|---|---|---|
| N | machos e fêmeas adultos por geração | 200 de cada |
| gerações | duração de cada réplica | 100 (1 no Controle) |
| phi | ótimo da seleção natural e média inicial das distribuições | 5 |
| gamma | intensidade da seleção natural de viabilidade | 0.2 (ou seleção desligada) |
| sigma_p | variação do pico de preferência entre fêmeas | eixo de Fêmeas variando: 0.2 a 2.0 |
| sigma_z | variação do traço entre machos | eixo de Machos variando: 0.2 a 2.0 |
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
  2, mas em Machos variando é o indicador direto da força de seleção agindo sobre a preferência.

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

- **H1: a forma da curva de preferência gera assinaturas topológicas distintas.** O Controle
  testa isso sem o confundimento da evolução, ou seja, mostra a topologia que a regra de escolha
  produz sozinha. Fêmeas variando mostra se essa assinatura persiste depois de 100 gerações de
  resposta evolutiva do traço.
- **H2: a topologia da rede prediz a trajetória evolutiva.** Fêmeas variando testa isso para o traço
  do macho, e Machos variando testa o análogo para a preferência da fêmea.
- **H3: a restrição de amostragem apaga as assinaturas topológicas.** O gradiente de A_max está
  presente nos quatro estudos, então dá para verificar se o efeito do custo de busca é o
  mesmo quando quem responde à seleção é o traço e quando é a preferência. Vale registrar que no
  Controle esse efeito não saiu na direção esperada: a divergência entre curvas de preferência
  foi maior, e não menor, com A_max = 10. Isso precisa ser olhado com cuidado, porque a
  comparação envolve escalas diferentes entre as métricas.
- **Mecanismo de Fisher.** Só Co-evolução pode testar, porque é o único desenho em que a
  covariância genética entre preferência e traço pode se acumular.

---

## Convenção de nomes entre os estudos

Os motores de Fêmeas variando e de Machos variando fazem a mesma coisa com características diferentes, mas tinham sido
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
| Ruído fixo do modo antigo | `eps_sd` (era `eps_p` em Machos variando) |

**A regra é que a letra da característica não muda.** NMachos variando o que se herda é a preferência,
então continua sendo `p_filhotes` e não `z_filhotes`: a letra diz qual característica é, e é
justamente ela que distingue um estudo do outro. O que se uniformiza é todo o resto do nome.

**Uma assimetria que ficou de propósito.** `sigma_p` em Fêmeas variando contra `sigma_p_init` no
Machos variando: os nomes são diferentes porque as coisas são diferentes, um é parâmetro imposto a cada
geração e o outro é condição inicial, como está explicado na seção de Machos variando.

**O sorteio dos sobreviventes agora é por índice nos três motores.** Fêmeas variando sorteava por
valor (`sample(z_filhotes, ...)`) e Machos variando por índice
(`sample(seq_len(total_filhotes), ...)`). Com uma única característica herdável os dois são
equivalentes, porque `sample` sobre um vetor é implementado como sorteio de índices seguido de
indexação, e portanto consome o mesmo RNG. Mas em Co-evolução só a forma por índice funciona, então
o motor de Fêmeas variando foi padronizado para ela: assim o padrão do código já está correto quando as duas
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
| Seleção natural, gamma, censo adulto constante, trava de 2 sobreviventes | `01_metricas_e_utilitarios.R`, `selecionar_machos_adultos` |
| Fecundidade neutra, paternidade sorteada, segregação infinitesimal | `01_metricas_e_utilitarios.R`, `produce_offspring` |
| Exclusão das fêmeas sem acasalar das métricas, retorno de NA | `01_metricas_e_utilitarios.R`, `calc_metrics_from_M` |
| Sementes, reparto entre máquinas, retomada por backup | `01_metricas_e_utilitarios.R`, `rodar_cenarios` |
| Controle: uma geração, superfície completa, 70.560 cenários | `Fase_Controle.R` |
| Fêmeas variando: sigma_p imposto a cada geração, traço herdável | `Fase4_TodasAsCurvas.R` e `simulate_evolution` |
| Machos variando: traço ambiental, preferência herdável bi-parental | `Fase_Espelho.R`, `simulate_espelho` e `produce_offspring_espelho` |
| Co-evolução: rascunho do motor, ainda sem desenho experimental | `Fase_Coevolucao.R`, e a versão atualizada nesta nota |
| Primeira versão descartada do experimento inverso | `Fase_MachoVariando.R`, mantido só como registro |
