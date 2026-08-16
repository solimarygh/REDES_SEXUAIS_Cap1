---
editor_options: 
  markdown: 
    wrap: 72
---

# Os quatro estudos complementares

Olá Erika e Paulo. O que está aqui é o que cada estudo faz, e não os
resultados, que vão no documento de Exploracao de Paneis que mandarei
junto.

------------------------------------------------------------------------

Para evitar ambiguidade, alguns termos aparecem sempre com o mesmo
sentido:

**Traço do macho (z).** A característica sexualmente selecionada que os
machos expressam (por exemplo, o tamanho de uma estrutura ou a
intensidade de uma coloração). É o que as fêmeas avaliam na hora de
decidir se aceitam ou não.

**Preferência da fêmea (p).** O valor de traço que cada fêmea considera
ideal, ou seja, o pico da sua função de preferência. Não é o mesmo que
exigência: a exigência (choosiness, s) é o quão estrita ela é em torno
desse pico, e nesta rodada s fica fixo em todos os estudos.

**Curva de preferência.** A regra que traduz o pico p da fêmea em uma
probabilidade de aceitar um macho de traço z. São quatro regras
diferentes, descritas mais adiante. É uma propriedade fixa do cenário,
não evolui em nenhum dos estudos.

**sigma_p.** O quanto o pico de preferência varia entre as fêmeas da
população. Valor baixo significa que quase todas as fêmeas preferem o
mesmo tipo de macho; valor alto significa que elas discordam bastante
entre si.

**sigma_z.** O quanto o traço varia entre os machos da população, ou
seja, quanta variedade de machos existe disponível para as fêmeas
escolherem.

**Variabilidade total, ou a norma.** Quanta variação existe no sistema
como um todo, somando os dois sexos: `sqrt(sigma_p^2 + sigma_z^2)`. É
alta quando os dois sexos são heterogêneos e baixa quando os dois são
homogêneos. Não diz nada sobre qual dos dois contribui mais.

**Assimetria.** De que lado está a variação: `log(sigma_z / sigma_p)`.
Vale zero quando os dois sexos variam o mesmo, é positiva quando os
machos variam mais que as fêmeas e negativa no caso contrário. O
logaritmo está ali porque a comparação é de razão e não de diferença: os
machos variarem o dobro das fêmeas e as fêmeas variarem o dobro dos
machos são situações igualmente assimétricas em sentidos opostos, e o
logaritmo as coloca à mesma distância de zero (mais e menos 0.69). Sem
ele, a razão 2 ficaria a 1 de distância e a razão 0.5 ficaria a apenas
0.5.

As duas juntas são apenas outra forma de escrever o par (sigma_p,
sigma_z), como trocar coordenadas cartesianas por polares: a mesma
informação, reorganizada para separar duas perguntas que se confundiam.
Quanta variação existe é uma coisa; de que lado está é outra. A análise
do Controle mostrou que a segunda pergunta é a que importa, e é por isso
que estes dois termos aparecem aqui em vez de sigma_p e sigma_z crus.

**Característica herdável.** Uma característica que os filhotes recebem
dos pais. Ser herdável é uma condição necessária para que ela possa
responder à seleção, mas não garante que ela vá mudar. Se evoluiu ou
não, e em que direção, é um resultado a ser observado.

**Característica re-sorteada (congelada).** Uma característica que não é
herdada: a cada geração seus valores são sorteados de novo da mesma
distribuição, independentemente de quem eram os pais. Ela nunca pode
responder à seleção, por construção.

**Característica re-sorteada (ambiental).** Mesma coisa que re-sorteada,
mas com uma leitura biológica específica (pensando mais específicamente
no trait z dos machos): o valor que o indivíduo expressa depende da
condição em que ele se desenvolveu (alimento, ambiente), não do que ele
herdou. Por isso não passa para os filhotes.

**Parâmetro imposto e condição inicial.** Uma distinção que importa na
hora de comparar os estudos. Um parâmetro imposto é re-aplicado a cada
geração e portanto continua valendo do começo ao fim da réplica. Já uma
condição inicial vale só na geração 1, e daí em diante a distribuição
fica por conta da seleção e da deriva. Em Fêmeas variando, os 7 níveis
de sigma_p são impostos e sigma_z_init é apenas condição inicial (fixa
em 1.0). Em Machos variando, o espelho, os 7 níveis de sigma_z são
impostos e sigma_p_init é apenas condição inicial (fixa em 1.0). Nesse
aspecto os dois estudos são simétricos. A assimetria real está noutro
ponto: a seleção natural de viabilidade age sobre z nos dois estudos,
mas em Fêmeas variando ela age diretamente sobre a característica que
evolui, competindo com a seleção sexual, enquanto em Machos variando ela
age sobre uma característica ambiental e não tem consequência evolutiva
nenhuma. A preferência, que é o que evolui ali, não recebe seleção
natural.

### Vocabulário do desenho

**Cenário e réplica.** Um cenário é uma combinação concreta de valores
dos fatores do desenho: uma curva de preferência, um sigma, um A_max, um
k e um regime de seleção natural. Uma réplica é uma repetição
independente do mesmo cenário, com outra semente aleatória. Quando
dizemos "70.560 cenários", as réplicas já estão contadas dentro.

**Célula.** Usado só nas análises e especialmente num grafico, e não é
sinônimo de cenário: uma célula é uma combinação de tudo MENOS a curva
de preferência. Serve para comparar as quatro curvas entre si mantendo o
resto igual, que é a única forma de isolar o efeito da curva.

**A_max.** Quantos machos distintos cada fêmea consegue avaliar antes de
decidir com quem acasalar. Representa o custo ecológico de procurar
parceiro: quanto menor, mais cara é a busca. Assume os valores 200, 40 e
10.

**k, e a poliandria realizada.** k é o número máximo de parceiros que a
fêmea busca (5, 10 ou 20). Ela para quando o atinge ou quando esgota os
A_max machos que avaliou, o que vier primeiro, então k é um teto e não
uma cota. A poliandria realizada é quantos parceiros ela de fato
conseguiu, e é uma variável resposta e não um parâmetro. A seção sobre a
interação entre A_max, k e a curva de preferência mostra o quanto as
duas coisas podem diferir.

### Vocabulário das respostas

**As quatro métricas de topologia.** Calculadas sobre a rede bipartita
de acasalamentos. Modularidade é o quanto a rede se divide em grupos que
acasalam preferencialmente entre si. Aninhamento (NODF) é o quanto os
parceiros dos machos menos procurados são um subconjunto dos parceiros
dos mais procurados, ou seja, o quanto existe hierarquia. Centralização
é o quanto os acasalamentos se concentram em poucos indivíduos.
Oportunidade de seleção sexual (Is) é a desigualdade no número de
parceiras entre os machos. A seção sobre as métricas dá as definições
completas.

**Divergência entre curvas de preferência.** Uma grandeza construída por
nós para a análise, e o resultado principal do Controle. Dentro de uma
célula, calcula-se a média de cada uma das quatro métricas para cada
curva, e a divergência é o quanto essas quatro posições se afastam do
centro comum delas. Vale zero se as quatro curvas produzem a mesma
topologia, e cresce quanto mais elas se separam.

**A padronização, que é o passo delicado.** Antes de qualquer conta,
cada métrica é convertida em z-score: subtrai-se a média e divide-se
pelo desvio padrão, de modo que ela passe a ser lida como "a quantos
desvios padrão do valor típico este cenário está". Depois disso as
quatro métricas estão na mesma unidade e podem ser somadas dentro de uma
distância.

Sem esse passo a conta seria dominada por uma métrica só. As quatro
vivem em escalas muito diferentes: a modularidade e a centralização
ficam entre 0 e 1, o Is é um número positivo sem teto, e o NODF é
definido de 0 a 100, ainda que nos nossos cenários ande numa faixa de
poucos pontos. Como a distância euclidiana soma quadrados, a métrica de
maior amplitude entra elevada ao quadrado e as outras viram
arredondamento. A divergência mediria o aninhamento e mais nada, e isso
seria um artefato de unidades e não um resultado.

**E a padronização é feita uma vez só, sobre a tabela inteira**, com uma
média e um desvio por métrica calculados sobre todos os 70.560 cenários.
Isso importa mais do que parece. Se padronizássemos dentro de cada
célula, cada uma seria reescalada pela sua própria dispersão, e uma
célula onde as curvas mal se distinguem sairia com o mesmo valor de uma
onde elas se separam muito, porque em ambas as diferenças teriam sido
esticadas até preencher a mesma escala. A comparação entre células, que
é justamente a pergunta ("em que ponto do plano as curvas divergem
mais?"), desapareceria. Padronizando uma vez só, a operação é uma troca
de unidades e nada mais: muda o número, preserva quem é maior que quem.

### Vocabulário do modelo

**Regra de escape.** Uma regra da versão antiga do modelo, já removida.
Se a fêmea avaliava os machos e não aceitava nenhum, ela acabava
acasalando à força com o último avaliado, de modo que nenhuma fêmea
ficava sem acasalar. Como a fecundidade é neutra, isso fazia com que
todas as fêmeas tivessem exatamente o mesmo sucesso reprodutivo, e sem
variância de sucesso não pode haver seleção sobre a preferência. Agora
quem não aceita ninguém fica sem acasalar.

**Variância de segregação.** O quanto um filhote se desvia da média dos
seus dois pais. Vem de qual metade dos genes de cada pai ele calhou de
receber. No modelo infinitesimal, que é o que usamos mais recentemen,
esse desvio é proporcional à variância que existe entre os pais, e não
um ruído de tamanho fixo escolhido por nós. - quero estudar melhor isso.

## Resumindo os quatro estudos

Todos os estudos compartilham o mesmo ciclo de vida e as mesmas quatro
curvas de preferência. O que muda entre eles é quais características são
herdadas, ou seja, quais delas estão livres para responder à seleção.
Cada estudo isola uma peça diferente do sistema:

| Estudo | O que varia | Traço do macho (z) | Preferência da fêmea (p) | O que o estudo isola |
|----|----|----|----|----|
| **Controle** | sigma_p e sigma_z | sorteado | sorteada | o efeito das regras de acasalamento sozinhas, sem nenhuma resposta evolutiva |
| **Fêmeas variando** | sigma_p | herdável, livre para evoluir | re-sorteada | como a heterogeneidade de preferência afeta a resposta evolutiva do traço |
| **Machos variando** | sigma_z | re-sorteado (ambiental) | herdável, livre para evoluir | como a disponibilidade de machos afeta a resposta evolutiva da preferência |
| **Co-evolução** | os dois, só como condição inicial | herdável, livre para evoluir | herdável, livre para evoluir | o feedback entre as duas (mecanismo de Fisher) |

Reparem que nos três primeiros estudos o que varia é um parâmetro
imposto, que vale do começo ao fim. Em Co-evolução isso é impossível, e
mostro mais detalhes na seção daquele estudo.

Vale insistir num ponto: "livre para evoluir" descreve o desenho, não o
resultado. Em vários cenários a característica herdável pode
simplesmente não mudar. O exemplo mais claro é a curva de preferência
aleatória, em que as fêmeas não discriminam entre machos: ali o traço
continua sendo herdável, mas como nenhuma seleção sexual age sobre ele,
ele apenas deriva ao acaso. A comparação entre curvas de preferência é
justamente o que revela quando a herdabilidade se traduz em mudança
evolutiva e quando não.

A comparação entre os estudos nos ajuda a entender o sistema melhor: - A
diferença entre Fêmeas variando e o Controle mostra o qué a resposta
evolutiva do traço acrescenta. - A diferença entre Machos variando e o
Controle mostra o qué a resposta evolutiva da preferência acrescenta. -
O Co-evolução mostra o que emerge quando as duas evoluem juntas, que não
é a soma dos anteriores.

------------------------------------------------------------------------

## O que é comum aos quatro estudos

Antes de descrever cada estudo, o que todos compartilham. Os quatro usam
exatamente o mesmo ciclo de vida, as mesmas quatro curvas de preferência
e os mesmos fatores cruzados, e é por isso que as diferenças entre eles
podem ser atribuídas ao que de fato muda: quais características são
herdadas. Cada seção de estudo mais adiante descreve só o que aquele
estudo altera.

**População.** 200 machos e 200 fêmeas, gerações discretas e não
sobrepostas, tamanho populacional constante. Cem gerações por réplica em
Fêmeas variando, Machos variando e Co-evolução; uma geração no Controle.

**As quatro curvas de preferência.** P_ij é a probabilidade de a fêmea i
aceitar o macho j, onde s é a exigência dela, p é o pico dela e z é o
traço dele. Todas partem do mesmo pico médio, de modo que as diferenças
entre elas vêm da geometria da regra e não de as fêmeas quererem coisas
diferentes em média: - Aleatória (nula): P = 0.5, constante. A fêmea
aceita qualquer macho com a mesma probabilidade. Serve de controle: aqui
não existe seleção sexual, então qualquer mudança no traço é deriva. -
Gaussiana (estabilizadora): P = exp(-s (z - p)\^2). A fêmea aceita
machos cujo traço está próximo do seu pico, e rejeita tanto os muito
maiores quanto os muito menores. - Sigmoide (direcional): P = 1 / (1 +
exp(-s (z - p))). A fêmea aceita machos cujo traço supera o seu pico, e
quanto mais o supera, mais provável é o aceite. - U-shaped (disruptiva):
P = 1 - exp(-s (z - p)\^2). A fêmea evita machos parecidos com o seu
pico e aceita os que estão distantes dele, para mais ou para menos.

**Fatores cruzados em todos os estudos.** - A_max: quantos machos
distintos cada fêmea consegue avaliar antes de decidir (200, 40 ou 10,
em número absoluto). Representa o custo ecológico de procurar parceiro.
O nível 200 é a condição de saturação, "sem restrição de busca", e não
um terceiro ponto equidistante do gradiente. Ver a seção sobre o tamanho
do pool de machos: os rótulos percentuais que usávamos antes eram
enganosos. - k: quantos parceiros cada fêmea idealmente se acasalaria
(5, 10 ou 20). - Seleção natural de viabilidade sobre o traço do macho,
ligada ou desligada.

------------------------------------------------------------------------

## O ciclo de vida, passo a passo

Cada geração segue sempre a mesma sequência nos quatro estudos. O que
muda entre os estudos é apenas quais características são herdadas no
passo 5.

**1. Ponto de partida.** Todas as distribuições são centradas em phi =
5, que é ao mesmo tempo a média inicial do traço, a média inicial do
pico de preferência e o ótimo da seleção natural. Os machos começam com
traço sorteado de N(5, sigma_z) e as fêmeas com pico de preferência
sorteado de N(5, sigma_p). Todos os valores são truncados em zero, ou
seja, nem o traço nem a preferência podem ser negativos.

**2. Seleção natural de viabilidade (ligada ou desligada), e o censo de
adultos.** A seleção de viabilidade age sobre os JUVENIS, antes do censo
de adultos. Quando ela está ligada, cada um dos cerca de 5.000 juvenis
machos sobrevive com probabilidade

```         
V = exp(-gamma * (z - phi)^2),  com gamma = 0.2
```

ou seja, quanto mais o traço se afasta do ótimo ecológico phi = 5, menor
a chance de sobreviver. Entre os juvenis que sobrevivem, sorteiam-se ao
acaso os 200 que formam o censo adulto de machos. As fêmeas não passam
por viabilidade: sorteiam-se 200 ao acaso (en Exploraço_Paneis, explico
las consequencias atuais disso!)

A ordem dos dois passos é o que faz a diferença. Como a seleção age
antes do censo, o número de machos disponíveis para acasalar é sempre
200 (só que não! en Exploraço_Paneis, explico), com ou sem seleção
natural e para qualquer valor de sigma_z: ela muda quais machos estão
disponíveis, que é o efeito que nos interessa, e não quantos, que seria
um confundimento de densidade. Na versão anterior a viabilidade agia
depois do censo, o pool caía de 198 para 124 ao longo do gradiente de
sigma_z, e isso sozinho mexia em Is, centralização e aninhamento. A
seção sobre o tamanho do pool de machos conta essa história por inteiro.

Quatro observações: - A seleção natural age apenas sobre os machos e
apenas sobre o traço, nunca sobre a preferência. - Quando está
desligada, todos os juvenis são equivalentes (V = 1) e o censo é um
sorteio aleatório, o que isola o efeito puro da escolha feminina. - Há
uma trava de segurança: se menos de 2 juvenis sobrevivessem, os 2 de
maior viabilidade são resgatados, para que a rede nunca fique degenerada
demais para calcular as métricas. A coluna `n_machos_surv` grava o censo
efetivo, então qualquer cenário em que a trava tenha entrado é
identificável na hora. - Em Machos variando, em que o traço do macho é
ambiental, a seleção natural continua funcionando como filtro ecológico
(muda quais machos estão disponíveis), mas não tem consequência
evolutiva, porque o traço não é transmitido aos filhotes. O mesmo vale
para o Controle, por não haver geração seguinte.

**3. Formação da rede de acasalamentos.** Cada fêmea avalia A_max machos
distintos, sorteados sem reposição entre os disponíveis (ou todos eles,
se houver menos machos do que A_max), numa ordem que é um sorteio novo
para cada fêmea. Para cada macho avaliado, ela o considera aceitável ou
não com uma probabilidade dada pela curva de preferência, que depende da
distância entre o traço dele e o pico dela, e da exigência dela (um
pequeno valor de choosiness s, sorteado de N(2, 0.2) a cada geração e
nunca herdada, em todos os estudos). Depois de avaliar todos, ela
acasala com os k aceitáveis de maior probabilidade de aceite. Se nenhum
for aceitável, fica sem acasalar. A matriz é binária, então um mesmo par
nunca conta duas vezes.

Assim conseguirmos a matriz de quem acasalou com quem, que é a rede
bipartita sobre a qual calculamos as métricas de topologia.

**A regra de escolha mudou nesta rodada, e vale explicar por quê**
(decisão da reunião com o Miudo, inicio Agosto). Até aqui a fêmea
decidia de um em um, na hora, sem comparar nem voltar atrás, e parava
assim que juntava k parceiros. É a regra de umbral fixo, ou busca
sequencial (Janetos 1980; Real 1990), e continua disponível no código
como `regra = "sequencial"`.

O problema é que com A_max = 200 e k = 5, uma fêmea que aceita metade
dos machos junta os 5 parceiros em umas 10 avaliações e nunca vê os
outros 190. A_max deixava de ser o número de machos avaliados e virava
um teto que quase nunca era alcançado, de modo que os cenários A_max =
200 e A_max = 40 podiam ser na prática o mesmo tratamento: o custo de
busca que dizíamos modelar não chegava a ser pago.

Agora a regra é de comparação em pool, ou best-of-n: ela avalia os A_max
machos, todos, e só então escolhe. É a suposição típica de leks e
agregações, em que ela consegue amostrar antes de decidir. A_max passa a
ser literalmente o número de machos avaliados, e k continua sendo um
teto, agora aplicado sobre o conjunto dos que ela achou aceitáveis.

A regra usada fica gravada numa coluna `regra` na saída dos três
estudos, como já fazíamos com `segregacao`.

**4. Fecundidade e paternidade.** Cada fêmea que acasalou produz 50
filhotes, e as que não acasalaram produzem zero. O número de filhotes
não depende de com quantos machos ela acasalou (fecundidade neutra). A
paternidade de cada filhote é sorteada ao acaso entre os parceiros
daquela fêmea, o que equivale a uma competição espermática justa, sem
viés para nenhum macho.

**5. Herança.** Cada característicaherdável do filhote é a média dos
dois pais mais um desvio de segregação, e a esse desvio soma-se um termo
mutacional pequeno (desvio padrão 0.05), sorteado para cada filhote. As
características não herdáveis são simplesmente re-sorteadas na geração
seguinte. O desvio de segregação tem variância igual a metade da
variância parental, e é essa escolha que se chama modelo infinitesimal:
a variação entre irmãos não é um ruído de tamanho fixo escolhido por
nós, é proporcional à variação que existe entre os pais. A variância
usada é a do pool adulto inteiro daquela geração, e não a de cada casal.
A conta está na seção sobre a segregação. – quero estudar mais isto.

**6. Os juvenis da geração seguinte.** Todos os filhotes (cerca de
10.000, quando quase todas as fêmeas acasalam) recebem sexo ao acaso,
metade machos e metade fêmeas. São eles os juvenis da geração seguinte,
e é sobre eles que o passo 2 volta a agir. Não há nenhum corte aqui: a
capacidade de carga é imposta uma vez só, no censo de adultos do passo
2.

O modelo tem portanto duas mortalidades, e a diferença entre elas é o
ponto todo. A viabilidade é seletiva e age só sobre os machos. O censo é
sorteio puro, sem seleção nenhuma, e é a fonte de deriva genética do
modelo. Uma característica só evolui de forma dirigida se alguns pais
colocaram mais filhotes no pote do que outros.

Falta o caso degenerado, que a Erika chamou a atenção e que merece uma
regra explícita. Pode acontecer de o pote não dar para formar a geração
seguinte, seja porque nenhuma fêmea acasalou, seja porque acasalaram tão
poucas que os filhotes não bastam para formar a população adulta (o que
exigiria que menos de 16 das 200 fêmeas acasalassem, ou seja, mais de
92% sem acasalar). A regra que permite identificar quão frequente isso é
agora é a mesma nos três motores: a réplica é encerrada ali, as gerações
já rodadas são mantidas, e a coluna `extincao_gen` guarda em que geração
isso aconteceu. Quando a réplica chega ao fim normalmente,
`extincao_gen` fica NA.

------------------------------------------------------------------------

## Controle

*Variam sigma_p e sigma_z. Nada é herdado.*

Daqui em diante, um estudo por seção. Tudo o que não estiver dito é o
que ficou descrito acima, no ciclo de vida e nos fatores comuns.

Que topologia de rede as regras de acasalamento produzem por si só,
antes de qualquer resposta evolutiva?

Nenhuma característica é herdada. O traço dos machos e o pico de
preferência das fêmeas são sorteados, a seleção natural de viabilidade
filtra os machos (quando está ligada), a rede de acasalamentos se forma,
medem-se as métricas de topologia, e acabou. Não existe geração seguinte
nem feedback. A seleção natural entra aqui como filtro puramente
ecológico: ela muda quais machos estão disponíveis para as fêmeas, mas
não tem consequência evolutiva nenhuma, porque não há geração seguinte
para receber o efeito.

Uma única geração basta, e a razão é simples: sem herança, a geração 2
seria um sorteio independente da geração 1, com exatamente a mesma
distribuição. Rodar 100 gerações seria fazer 100 réplicas disfarçadas.
Rodamos uma só e usamos as réplicas para estimar a variabilidade, o que
torna cada cenário cerca de cem vezes mais barato que nos outros
estudos. É justamente esse desconto que permite cruzar sigma_p com
sigma_z por inteiro.

Ainda assim, ele precisa ser um estudo à parte. A geração 1 dos outros
estudos já é um controle, porque na primeira geração nada evoluiu ainda,
mas cada um cobre apenas uma linha do espaço de parâmetros: - A geração
1 de Fêmeas variando varre sigma_p, mas com sigma_z fixo em 1.0. - A
geração 1 de Machos variando varre sigma_z, mas com sigma_p fixo em 1.0.

As duas se cruzam exatamente no ponto sigma_p = sigma_z = 1.0, que é
literalmente o mesmo cenário nos dois estudos. Juntas, portanto, elas
formam uma cruz no espaço de parâmetros, e as combinações extremas ficam
de fora: nunca se observa, por exemplo, fêmeas muito heterogêneas diante
de machos muito homogêneos, ou o contrário. Como justamente essas
combinações extremas são as mais informativas sobre o que a regra de
acasalamento faz sozinha, vale a pena rodar a superfície inteira.

Poderíamos, em tese, aproveitar a geração 1 de Co-evolução: se ele
cruzasse sigma_p com sigma_z nas condições iniciais, essa primeira
geração daria a superfície completa de graça. O problema é que isso
obrigaria Co-evolução a ter um desenho sete vezes maior por uma razão
que não é dele, porque ali o que interessa é a dinâmica da covariância
entre preferência e traço, e não quanta variância havia no ponto de
partida. Como este controle é barato, sai mais em conta mantê-lo
separado e deixar Co-evolução livre para responder à própria pergunta.

Cruzamento completo de sigma_p (7 valores: 0.2, 0.5, 0.8, 1.0, 1.2, 1.5,
2.0) por sigma_z (os mesmos 7 valores), somado aos mesmos fatores dos
outros estudos: 4 curvas de preferência, 3 valores de A_max, 3 valores
de k e 2 regimes de seleção natural. Com 20 réplicas, isso dá 4 x 7 x 7
x 3 x 3 x 2 x 20 = 70.560 cenários, de uma geração cada.

------------------------------------------------------------------------

## Fêmeas variando

*Varia sigma_p. Evolui o traço do macho.*

Como a variação do pico de preferência entre as fêmeas (sigma_p) afeta a
topologia da rede de acasalamentos e a resposta evolutiva do traço
masculino?

O eixo do experimento é sigma_p, que varia de 0.2 (fêmeas quase todas
iguais no que preferem) a 2.0 (fêmeas bem diferentes entre si). - A
preferência é re-sorteada a cada geração de uma distribuição fixa N(5,
sigma_p). Ela não é herdada e portanto não pode evoluir, por construção.
Isso é intencional: fixa a distribuição de preferências e permite isolar
o efeito da forma da curva de preferência e da largura dessa
distribuição, sem o confundimento de a preferência estar mudando ao
mesmo tempo. - O traço do macho é herdável e portanto livre para
evoluir: os filhotes recebem a média dos pais mais a variância de
segregação, e os dois sexos carregam o traço. A fêmea carrega sem
expressar, o que é o que permite que o traço passe pela linhagem materna
também. - O traço da fêmea, na geração 1, é sorteado da mesma
distribuição N(5, sigma_z_init) que o dos machos. Nos cenários deste
estudo sigma_z_init fica fixo em 1.0.

A escolha da fêmea, aqui, é a causa da seleção. Ela não muda ao longo do
tempo; é ela que gera a pressão seletiva sobre o traço masculino. Se o
traço vai de fato mudar, e quanto, depende da curva de preferência, e é
justamente isso que o estudo mede.

Métricas de topologia da rede (modularidade, aninhamento, centralização
e oportunidade de seleção sexual Is), média e variância do traço dos
machos sobreviventes ao longo das gerações, e a proporção de fêmeas que
ficaram sem acasalar.

------------------------------------------------------------------------

## Machos variando

*Varia sigma_z. Evolui a preferência da fêmea.*

Como a disponibilidade de machos com traços variados (sigma_z) afeta a
resposta evolutiva da preferência feminina?

É o espelho de Fêmeas variando: os papéis se invertem. - O eixo do
experimento é sigma_z, que varia de 0.2 (machos quase todos parecidos) a
2.0 (machos muito variados). - O traço do macho passa a ser ambiental: é
re-sorteado a cada geração de N(5, sigma_z) e não é herdado. A leitura
biológica é de dependência de condição, ou seja, o macho expressa aquele
traço por causa do ambiente em que se desenvolveu, e não por causa dos
genes que vai transmitir. - O pico de preferência da fêmea passa a ser
herdável e bi-parental, portanto livre para evoluir: os dois sexos
carregam p (o macho carrega sem expressar, do mesmo modo que no Fêmeas
variando a fêmea carrega o traço sem expressar) e o filhote recebe a
média dos pais mais a variância de segregação.

O papel da escolha da fêmea se inverte: ela deixa de ser a causa da
seleção e passa a ser o alvo dela. A força seletiva que age sobre a
preferência é ecológica, não sexual: é a disponibilidade de machos. É a
analogia que a Erika propôs, de que a planta não escolhe, mas a
disponibilidade de plantas gera seleção sobre a preferência do herbívoro
que escolhe. O que pode evoluir é o pico p, ou seja, qual valor de traço
a fêmea prefere; a exigência (choosiness) continua fixa.

Há uma condição necessária para o estudo funcionar. Para que exista
seleção sobre a preferência é preciso que haja variância de sucesso
reprodutivo entre as fêmeas. Se todas deixassem o mesmo número de
filhotes, nenhuma preferência seria mais bem-sucedida que outra e a
preferência apenas derivaria. Por isso tiramos a regra de escape: agora
uma fêmea que não aceita nenhum macho fica sem acasalar e deixa zero
filhotes. A fecundidade continua neutra (quem acasalou deixa sempre o
mesmo número de filhotes, independentemente de com quantos machos
acasalou), como tínhamos combinado.

Há uma assimetria estrutural entre os dois estudos que precisa ser
declarada no paper. Em Fêmeas variando, sigma_p é um parâmetro imposto:
a distribuição de preferências é re-sorteada com aquela largura a cada
uma das 100 gerações, então o tratamento continua valendo até o fim. Em
Machos variando, sigma_z também é imposto a cada geração (o traço é
re-sorteado), mas sigma_p_init é apenas condição inicial, fixada em 1.0
em todos os cenários: da geração 2 em diante a largura da distribuição
de preferências é o que a seleção e a deriva fizerem dela. Os dois
estudos são espelhos no que diz respeito ao eixo do experimento, que é
imposto nos dois casos, mas não no que diz respeito à característica que
evolui. Foi exatamente por causa dessa assimetria que descartamos a
primeira versão do experimento inverso (`Fase_MachoVariando.R`), em que
o eixo era sigma_z_init, ou seja, uma condição inicial e não uma
propriedade permanente da população. Esse script continua no repositório
apenas como registro dessa tentativa, e não é um dos quatro estudos.

AS variáveis resposta sao as mesmas métricas de topologia da rede, mais
a média e a variância do pico de preferência ao longo das gerações, e a
proporção de fêmeas sem acasalar, que aqui deixa de ser apenas
descritiva e passa a ser o indicador direto da força de seleção agindo
sobre a preferência.

------------------------------------------------------------------------

## Co-evolução (proposta)

*Evoluem os dois. Os dois sigmas são apenas condição inicial.*

O que acontece quando as duas características são herdáveis ao mesmo
tempo?

Aqui tanto o traço do macho e a preferência são herdáveis, e cada
indivíduo carrega os dois genótipos: o macho carrega o pico de
preferência sem expressar, e a fêmea carrega o traço sem expressar. A
expressão continua sendo dimórfica (só o macho mostra z, só a fêmea usa
p), mas a transmissão é bi-parental para as duas características.

Aqui acho que além da média de cada característica e o foco precisaria
ser a covariância genética entre elas, cov(z, p). O acasalamento
assortativo constrói essa covariância: fêmeas que preferem machos com
traço alto acasalam com machos de traço alto, e os filhotes desses
casais herdam juntos os genes da preferência e os genes do traço. Uma
vez que essa associação existe, a seleção que age sobre o traço arrasta
a preferência junto, mesmo sem nenhuma seleção agindo diretamente sobre
a preferência (Fisherian runaway).

Podemos pensar em uma previsão sobre a variância inicial. No Controle,
em Fêmeas variando e em Machos variando, sigma é um parâmetro imposto e
por isso vale do começo ao fim. Em Co-evolução isso é impossível... como
as duas características são herdáveis, impor a variância significaria
re-sortear os valores a cada geração, e re-sortear é exatamente o que
impede a herança. Os dois sigmas só podem ser condição inicial.

Será que a resposta à seleção é proporcional à variância genética
disponível? com pouca variância de partida o sistema responde devagar,
com muita responde rápido? como o mecanismo de Fisher é um ciclo de
retroalimentação, a velocidade inicial pode decidir se ele chega a se
acender. Se a covariância cresce devagar demais, a seleção natural puxa
o traço de volta para phi (5) antes que o ciclo se estabeleça, e a
seleção também vai erodindo a própria variância que alimentaria a
resposta.

Sera que podemos esperar uma variância inicial abaixo da qual o runaway
não acontece e acima da qual acontece, e não uma resposta que cresça
suavemente com sigma_init. O limiar deve depender da curva de
preferência, sendo mais baixo na sigmoide, que é a única direcional, e
deve subir quando a seleção natural está ligada, porque ela é a força
que compete com o ciclo.

Se estamos procurnando um limiar, será que três níveis bem separados de
variância inicial (baixa, média, alta) bastam para localizá-lo? aqui
podemos usar a análise do Controle para ver quais combinacoes sao mais
interessantes.

Chute iniciais de como as quatro curvas de preferência devem se
comportar: - Aleatória: a probabilidade de aceite não depende de z nem
de p, então o acasalamento não é assortativo e cov(z, p) deve ficar em
torno de zero o tempo todo. - Sigmoide: é a curva onde o runaway pode
aparecer, porque o aceite cresce monotonicamente com z. Fêmeas de pico
alto são as mais exigentes em termos absolutos, acasalam com os machos
de traço mais alto, e aqui a covariância aumentaria, né? - Gaussiana:
gera acasalamento assortativo forte, porque cada fêmea acasala com
machos parecidos com o seu próprio pico, e portanto pode gerar a maior
covariância. - U-shaped: gera acasalamento dissortativo, ou seja, seria
a única curva em que a preferência e o traço podem ser puxados em
direções opostas.


---

## Uma ideia que estou tendo: como fixar sigma em Co-evolução

Isto ainda não é decisão, é uma coisa que estou pensando e que queria discutir
com vocês.

Nos outros três estudos sigma é re-aplicado a cada geração, mas em Co-evolução
não dá para fazer isso: as duas características são herdáveis, e re-sortear é
exatamente o que impede a herança. Então os dois sigmas só podem ser condição
inicial, e da geração 2 em diante a dispersão vira o que a seleção e a deriva
fizerem dela.

Minha ideia é usar três níveis bem separados, 0.5, 1.0 e 2.0, mas cruzados entre
os dois sexos em vez de ao longo da diagonal. A diagonal prenderia a assimetria
em zero, e é justamente a assimetria que a análise do Controle mostrou ser o que
manda. Neste cruzamento a assimetria e a variabilidade total ficam
descorrelacionadas (r = 0), porque cada assimetria positiva tem o seu espelho
negativo com a mesma norma, e aí dá para estimar os dois efeitos separadamente.

| sigma_p | sigma_z | assimetria | |
|---|---|---|---|
| 2.0 | 0.5 | -1.39 | fêmeas variadas, machos homogêneos |
| 1.0 | 0.5 | -0.69 | |
| 2.0 | 1.0 | -0.69 | |
| 0.5 | 0.5 | 0 | a diagonal |
| 1.0 | 1.0 | 0 | a diagonal |
| 2.0 | 2.0 | 0 | a diagonal |
| 0.5 | 1.0 | +0.69 | |
| 1.0 | 2.0 | +0.69 | |
| 0.5 | 2.0 | +1.39 | fêmeas homogêneas, machos variados |

Da geração 2 em diante a assimetria deixaria de ser imposta e passaria a ser
medida, a partir do que já gravamos: `0.5 * log(varz_pop / varp_pop)`. Entraria
na análise como covariável geração a geração, e a pergunta passa a ser se a
relação que o Controle encontrou se mantém quando as duas características
evoluem. Se mantiver ou não, é resultado.

O raciocínio completo, com os números da análise diagonal que me levaram à
assimetria, está em `NOTA_material_removido_2026-08-16.md`. Aqueles números são
da rodada com a regra sequencial e precisam ser refeitos.
