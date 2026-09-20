---
title: "Material suplementar: metodologia"
subtitle: "O modelo, o ciclo de vida e o desenho dos quatro estudos de simulação"
author: "Solimary García Hernández, Erika M. Santana, Paulo R. Guimarães Jr."
output:
  html_document:
    theme: flatly
    toc: true
    toc_depth: 2
    toc_float:
      collapsed: false
      smooth_scroll: true
    self_contained: true
editor_options: 
  markdown: 
    wrap: 72
---

Este documento é o anexo de metodologia do relatório. Descreve o modelo de
simulação, o ciclo de vida, as variáveis resposta e o desenho dos quatro
estudos, com as decisões que o desenho exigiu e a justificação de cada uma. Os
resultados estão no anexo correspondente, "Material suplementar".

O objetivo de o separar é que os quatro estudos compartilham exatamente o mesmo
motor, e descrever esse motor uma vez só torna explícito que as diferenças
entre eles vêm apenas do que de fato muda no desenho.

## Vocabulário

Alguns termos aparecem sempre com o mesmo sentido:

*Traço do macho (z):* a característica sexualmente selecionada, que só os
machos expressam.

*Preferência da fêmea (p):* o pico da função de preferência de cada fêmea. Não
confundir com a exigência (choosiness, s), que é o quão estrita ela é em torno
desse pico e fica fixa em todos os estudos.

*Curva de preferência:* a regra que traduz p em probabilidade de aceitar um
macho de traço z. São quatro, descritas mais adiante, e nenhuma evolui.

*sigma_p e sigma_z:* a dispersão do pico de preferência entre as fêmeas e a do
traço entre os machos.

*Norma e assimetria:* `sqrt(sigma_p^2 + sigma_z^2)` e `log(sigma_z / sigma_p)`.
É o mesmo par (sigma_p, sigma_z) em outras coordenadas, e serve para separar duas
perguntas que estavam se confundindo: quanta variação existe, e de que lado ela
está. A análise do Controle mostrou que a segunda é a que importa.

*Característica herdável, re-sorteada e ambiental:* herdável é transmitida aos
filhotes. Re-sorteada é sorteada de novo a cada geração da mesma distribuição, e
por construção não pode responder à seleção. "Ambiental" é o mesmo mecanismo com
leitura de dependência de condição: o macho expressa aquele z por causa do
ambiente em que se desenvolveu, e não o transmite.

*Parâmetro imposto e condição inicial:* imposto é re-aplicado a cada geração e
vale até o fim da réplica; condição inicial vale só na geração 1. Em Fêmeas
variando os sete níveis de sigma_p são impostos e sigma_z_init é condição inicial
(1.0); em Machos variando é o espelho. Nesse aspecto os dois são simétricos, mas
há uma assimetria real noutro ponto: a seleção natural age sobre z nos dois, e em
Fêmeas variando isso significa competir com a seleção sexual sobre a
característica que evolui, enquanto em Machos variando ela age sobre uma
característica ambiental e não tem consequência evolutiva nenhuma. A preferência
nunca recebe seleção natural.

*Combinação, réplica e cenário:* combinação é um ponto concreto do desenho, ou
seja um valor fixado para cada fator. Réplica é uma repetição da mesma
combinação com outra semente, e são 20 por combinação. Cenário é uma réplica de
uma combinação, de modo que quando se diz "70.560 cenários" as réplicas já
estão contadas dentro.

Uma advertência de leitura: em algumas análises interessa comparar as quatro
curvas de preferência mantendo todo o resto igual, e aí o objeto de comparação é
a combinação dos *outros* fatores, com as quatro curvas dentro dela. Onde isso
acontece, está dito.

*A_max:* quantos machos distintos cada fêmea avalia antes de decidir. É o custo
ecológico da busca, e assume os valores 200, 40 e 10.

*k, e a poliandria realizada:* k é o número de parceiros que a fêmea busca (5,
10 ou 20), mas ela para quando o atinge ou quando esgota os A_max avaliados, o
que vier primeiro. Ou seja, k é teto e não cota, e a poliandria realizada,
quantos parceiros ela de fato conseguiu, é variável resposta.

*As quatro métricas de topologia:* calculadas sobre a rede bipartita de
acasalamentos: modularidade, aninhamento (NODF), centralização e oportunidade de
seleção sexual (Is). As definições exatas estão na seção das métricas.

*Divergência entre curvas de preferência:* construída para a análise do
Controle. Fixados todos os fatores menos a curva de preferência, mede o quanto
as quatro curvas se afastam do centro comum delas no espaço das quatro métricas
de estrutura. Vale zero se as quatro produzem a mesma topologia, e cresce quanto
mais elas se separam.

As métricas entram padronizadas, porque vêm em escalas diferentes e sem isso a
de maior variância dominaria a distância. A padronização é feita uma vez só
sobre a tabela inteira, e não dentro de cada combinação: se fosse por
combinação, cada uma seria reescalada pela própria dispersão e as combinações
deixariam de ser comparáveis entre si, que é justamente a pergunta.

*Regra de escape:* regra da versão antiga, já removida: a fêmea que não
aceitava ninguém acabava acasalando à força com o último avaliado. Como a
fecundidade é neutra, isso deixava todas com o mesmo sucesso reprodutivo, e sem
variância de sucesso não há seleção sobre a preferência. Agora quem não aceita
ninguém fica sem acasalar.

*Variância de segregação:* usamos o modelo infinitesimal, em que o desvio do
filhote em relação à média dos pais tem variância proporcional à variância
parental, e não um ruído de tamanho fixo arbitrado. A seção sobre a herança
explica a consequência dessa escolha para a interpretação.

## Os quatro estudos

Todos os estudos compartilham o mesmo ciclo de vida e as mesmas quatro
curvas de preferência. O que muda entre eles é quais características são
herdadas, ou seja, quais delas estão livres para responder à seleção.
Cada estudo isola uma peça diferente do sistema:

| Estudo | O que varia | Traço do macho (z) | Preferência da fêmea (p) | O que o estudo isola |
|----|----|----|----|----|
| Controle | sigma_p e sigma_z | sorteado | sorteada | o efeito das curvas de preferência sozinhas, sem nenhuma resposta evolutiva |
| Fêmeas variando | sigma_p | herdável, livre para evoluir | re-sorteada | como a heterogeneidade de preferência afeta a resposta evolutiva do traço |
| Machos variando | sigma_z | re-sorteado (ambiental) | herdável, livre para evoluir | como a disponibilidade de machos afeta a resposta evolutiva da preferência |
| Co-evolução | os dois, só como condição inicial | herdável, livre para evoluir | herdável, livre para evoluir | o feedback entre as duas (mecanismo de Fisher) |

Nos três primeiros estudos o que varia é um parâmetro imposto, que vale do
começo ao fim. Em Co-evolução isso é impossível, pelas razões explicadas na
seção daquele estudo.

Um ponto que convém sublinhar: "livre para evoluir" descreve o desenho, não o
resultado. Em vários cenários a característica herdável pode
simplesmente não mudar. O exemplo mais claro é a curva de preferência
aleatória, em que as fêmeas não discriminam entre machos: ali o traço
continua sendo herdável, mas como nenhuma seleção sexual age sobre ele,
ele apenas deriva ao acaso. A comparação entre curvas de preferência é
justamente o que revela quando a herdabilidade se traduz em mudança
evolutiva e quando não.

A comparação entre os estudos ajuda a entender o sistema:

-   A diferença entre Fêmeas variando e o Controle mostra o que a
    resposta evolutiva do traço acrescenta.
-   A diferença entre Machos variando e o Controle mostra o que a
    resposta evolutiva da preferência acrescenta.
-   A Co-evolução mostra o que emerge quando as duas evoluem juntas, que
    não é a soma dos anteriores.

------------------------------------------------------------------------

## O que é comum aos quatro estudos

Antes de descrever cada estudo, o que todos compartilham. Os quatro usam
exatamente o mesmo ciclo de vida, as mesmas quatro curvas de preferência
e os mesmos fatores cruzados, e é por isso que as diferenças entre eles
podem ser atribuídas ao que de fato muda: quais características são
herdadas. Cada seção de estudo mais adiante descreve só o que aquele
estudo altera.

População. 200 machos e 200 fêmeas, gerações discretas e não
sobrepostas, tamanho populacional constante. Cem gerações por réplica em
Fêmeas variando, Machos variando e Co-evolução; uma geração no Controle.

As quatro curvas de preferência. P_ij é a probabilidade de a fêmea i
aceitar o macho j, onde s é a exigência dela, p é o pico dela e z é o
traço dele. Todas partem do mesmo pico médio, de modo que as diferenças
entre elas vêm da geometria da curva e não de as fêmeas quererem coisas
diferentes em média:

-   Aleatória (nula): P = 0.5, constante. A fêmea aceita qualquer macho
    com a mesma probabilidade. Serve de controle: aqui não existe
    seleção sexual, então qualquer mudança no traço é deriva.
-   Gaussiana (estabilizadora): P = exp(-s (z - p)\^2). A fêmea aceita
    machos cujo traço está próximo do seu pico, e rejeita tanto os muito
    maiores quanto os muito menores.
-   Sigmoide (direcional): P = 1 / (1 + exp(-s (z - p))). A fêmea aceita
    machos cujo traço supera o seu pico, e quanto mais o supera, mais
    provável é o aceite.
-   U-shaped (disruptiva): P = 1 - exp(-s (z - p)\^2). A fêmea evita
    machos parecidos com o seu pico e aceita os que estão distantes
    dele, para mais ou para menos.

Fatores cruzados em todos os estudos:

-   A_max: quantos machos distintos cada fêmea consegue avaliar antes de
    decidir (200, 40 ou 10, em número absoluto). Representa o custo
    ecológico de procurar parceiro. O nível 200 é a condição de
    saturação, "sem restrição de busca", e não um terceiro ponto
    equidistante do gradiente. Ver a seção sobre o tamanho do pool de
    machos: os rótulos percentuais que usávamos antes eram enganosos.
-   k: quantos parceiros cada fêmea idealmente se acasalaria (5, 10 ou
    20).
-   Seleção natural de viabilidade sobre o traço do macho, ligada ou
    desligada.

------------------------------------------------------------------------

## O ciclo de vida, passo a passo

Cada geração segue sempre a mesma sequência nos quatro estudos. O que
muda entre os estudos é apenas quais características são herdadas no
passo 5.

1. Ponto de partida. Todas as distribuições são centradas em phi =
5, que é ao mesmo tempo a média inicial do traço, a média inicial do
pico de preferência e o ótimo da seleção natural. Os machos começam com
traço sorteado de N(5, sigma_z) e as fêmeas com pico de preferência
sorteado de N(5, sigma_p). Todos os valores são truncados em zero, ou
seja, nem o traço nem a preferência podem ser negativos.

2. Seleção natural de viabilidade (ligada ou desligada), e o censo de adultos.
A seleção de viabilidade age sobre os juvenis, antes do censo
de adultos. Quando ela está ligada, cada um dos cerca de 5.000 juvenis
machos sobrevive com probabilidade

```         
V = exp(-gamma * (z - phi)^2),  com gamma = 0.2
```

ou seja, quanto mais o traço se afasta do ótimo ecológico phi = 5, menor
a chance de sobreviver. Entre os juvenis que sobrevivem, sorteiam-se ao
acaso os 200 que formam o censo adulto de machos. As fêmeas não passam
por viabilidade: sorteiam-se 200 ao acaso.

A ordem dos dois passos é o que faz a diferença. Como a seleção age
antes do censo, o número de machos disponíveis para acasalar deveria ser
sempre 200, com ou sem seleção natural e para qualquer valor de sigma_z:
ela muda quais machos estão disponíveis, que é o efeito que nos
interessa, e não quantos, que seria um confundimento de densidade. Na
versão anterior a viabilidade agia depois do censo, o pool caía de 198
para 124 ao longo do gradiente de sigma_z, e isso sozinho mexia em Is,
centralização e aninhamento. A seção "O tamanho do pool de machos não é
constante" do registro de desenvolvimento do modelo documenta essa versão
anterior e o que ela produzia.

O número 200 admite duas leituras, e a escolha entre elas não é um detalhe de
implementação. Pode ser um *teto*, em que cada juvenil sobrevive ou não de
forma independente com probabilidade V e o censo é quem sobrou, de modo que a
viabilidade é mortalidade em termos absolutos e o tamanho da população é um
resultado do modelo. Ou pode ser uma *cota*, em que 200 é a capacidade de
suporte do ambiente e se sorteiam sempre 200 juvenis com peso proporcional a V,
de modo que a viabilidade decide quais machos ocupam as vagas e nunca quantas
vagas existem. Na terminologia de Wallace, a primeira é seleção dura e a
segunda seleção branda, com regulação por densidade.

O modelo usa a cota, e a razão é metodológica. Sob o teto, nas curvas em que o
traço se afasta muito do ótimo, a viabilidade absoluta desaba para todos os
juvenis ao mesmo tempo e o censo não chega aos 200: a rede passa a ser
calculada sobre poucas dezenas de machos e as métricas de topologia, que
dependem do tamanho e da densidade da rede, deixam de ser comparáveis entre
combinações. Pior, o gradiente de A_max deixa de valer onde isso acontece,
porque a fêmea avalia `min(A_max, machos disponíveis)`. Com a cota o censo é
constante por construção, e a seleção natural muda a composição do pool de
machos, que é o efeito de interesse, e não a sua densidade, que seria um
confundimento.

Quatro observações:

-   A seleção natural age apenas sobre os machos e apenas sobre o traço,
    nunca sobre a preferência.
-   Quando está desligada, todos os juvenis são equivalentes (V = 1) e o
    censo é um sorteio aleatório, o que isola o efeito puro da escolha
    feminina.
-   Há uma trava de segurança: se menos de 2 juvenis sobrevivessem, os 2
    de maior viabilidade são resgatados, para que a rede nunca fique
    degenerada demais para calcular as métricas. A coluna
    `n_machos_surv` grava o censo efetivo, então qualquer cenário em que
    a trava tenha entrado é identificável na hora.
-   Em Machos variando, em que o traço do macho é ambiental, a seleção
    natural continua funcionando como filtro ecológico (muda quais
    machos estão disponíveis), mas não tem consequência evolutiva,
    porque o traço não é transmitido aos filhotes. O mesmo vale para o
    Controle, por não haver geração seguinte.

3. Formação da rede de acasalamentos. Cada fêmea avalia A_max machos
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

Assim conseguimos a matriz de quem acasalou com quem, que é a rede
bipartita sobre a qual calculamos as métricas de topologia.

A regra de decisão é a de comparação em pool, ou best-of-n: a fêmea avalia os
A_max machos, todos, e só então escolhe entre os que aceitou. É a suposição
típica de leks e agregações, em que a fêmea consegue amostrar antes de decidir.
A_max é portanto literalmente o número de machos avaliados, e k é um teto
aplicado sobre o conjunto dos que ela achou aceitáveis.

A alternativa, implementada e disponível no código como `regra = "sequencial"`,
é a regra de umbral fixo ou busca sequencial (Janetos 1980; Real 1990), em que a
fêmea decide de um em um, sem comparar nem voltar atrás, e para assim que junta
k parceiros. Ela foi descartada porque tornava o gradiente de A_max
inoperante: com A_max = 200 e k = 5, uma fêmea que aceita metade dos machos
junta os cinco parceiros em cerca de dez avaliações e nunca vê os outros 190.
A_max deixava de ser o número de machos avaliados e passava a ser um limite
quase nunca alcançado, de modo que os tratamentos A_max = 200 e A_max = 40
podiam ser na prática o mesmo, e o custo de busca que o desenho pretende
modelar não chegava a ser pago.

A regra usada fica gravada numa coluna `regra` na saída dos quatro estudos.

4. Fecundidade e paternidade. Cada fêmea que acasalou produz 50
filhotes, e as que não acasalaram produzem zero. O número de filhotes
não depende de com quantos machos ela acasalou (fecundidade neutra). A
paternidade de cada filhote é sorteada ao acaso entre os parceiros
daquela fêmea, o que equivale a uma competição espermática justa, sem
viés para nenhum macho.

5. Herança. Cada característica herdável do filhote é a média dos
dois pais mais um desvio de segregação, e a esse desvio soma-se um termo
mutacional pequeno (desvio padrão 0.05), sorteado para cada filhote. As
características não herdáveis são simplesmente re-sorteadas na geração
seguinte. O desvio de segregação tem variância igual a metade da
variância parental, e é essa escolha que se chama modelo infinitesimal:
a variação entre irmãos não é um ruído de tamanho fixo escolhido por
nós, é proporcional à variação que existe entre os pais. A variância
usada é a do pool adulto inteiro daquela geração, e não a de cada casal.

Essa escolha importa para a interpretação. Com um ruído de tamanho fixo, a
variância genética convergiria sempre para o mesmo piso em todos os cenários, e
a pergunta sobre manutenção de variação genética viria com a resposta embutida.
Com segregação infinitesimal, cada combinação de curva e regime chega ao seu
próprio equilíbrio, e é isso que torna a pergunta respondível.

Fica declarada uma limitação da implementação atual: o código usa a variância
total do pool parental e não a variância génica, que sob acasalamento
assortativo não são a mesma quantidade.

6. Os juvenis da geração seguinte. Todos os filhotes (cerca de
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

Falta o caso degenerado, que merece uma regra explícita. Pode acontecer de o pote não dar para formar a geração
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

Que topologia de rede as curvas de preferência produzem por si só,
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
mas cada um cobre apenas uma linha do espaço de parâmetros:

-   A geração 1 de Fêmeas variando varre sigma_p, mas com sigma_z fixo
    em 1.0.
-   A geração 1 de Machos variando varre sigma_z, mas com sigma_p fixo
    em 1.0.

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
iguais no que preferem) a 2.0 (fêmeas bem diferentes entre si).

-   A preferência é re-sorteada a cada geração de uma distribuição fixa
    N(5, sigma_p). Ela não é herdada e portanto não pode evoluir, por
    construção. Isso é intencional: fixa a distribuição de preferências
    e permite isolar o efeito da forma da curva e da largura dessa
    distribuição, sem o confundimento de a preferência estar mudando ao
    mesmo tempo.
-   O traço do macho é herdável e portanto livre para evoluir: os
    filhotes recebem a média dos pais mais a variância de segregação, e
    os dois sexos carregam o traço. A fêmea carrega sem expressar, o que
    é o que permite que o traço passe pela linhagem materna também.
-   O traço da fêmea, na geração 1, é sorteado da mesma distribuição
    N(5, sigma_z_init) que o dos machos. Nos cenários deste estudo
    sigma_z_init fica fixo em 1.0.

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

É o espelho de Fêmeas variando: os papéis se invertem.

-   O eixo do experimento é sigma_z, que varia de 0.2 (machos quase
    todos parecidos) a 2.0 (machos muito variados).
-   O traço do macho passa a ser ambiental: é re-sorteado a cada geração
    de N(5, sigma_z) e não é herdado. A leitura biológica é de
    dependência de condição, ou seja, o macho expressa aquele traço por
    causa do ambiente em que se desenvolveu, e não por causa dos genes
    que vai transmitir.
-   O pico de preferência da fêmea passa a ser herdável e bi-parental,
    portanto livre para evoluir: os dois sexos carregam p (o macho
    carrega sem expressar, do mesmo modo que em Fêmeas variando a fêmea
    carrega o traço sem expressar) e o filhote recebe a média dos pais
    mais a variância de segregação.

O papel da escolha da fêmea se inverte: ela deixa de ser a causa da
seleção e passa a ser o alvo dela. A força seletiva que age sobre a
preferência é ecológica, não sexual: é a disponibilidade de machos. Uma analogia
útil é a de um herbívoro e as suas plantas hospedeiras: a planta não escolhe,
mas a disponibilidade de plantas gera seleção sobre a preferência do herbívoro
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
acasalou).

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

As variáveis resposta são as mesmas métricas de topologia da rede, mais
a média e a variância do pico de preferência ao longo das gerações, e a
proporção de fêmeas sem acasalar, que aqui deixa de ser apenas
descritiva e passa a ser o indicador direto da força de seleção agindo
sobre a preferência.

------------------------------------------------------------------------

## Co-evolução

*Evoluem as duas características. Os dois sigmas são apenas condição inicial.*

O que acontece quando as duas características são herdáveis ao mesmo tempo?

Aqui tanto o traço do macho como a preferência são herdáveis, e cada indivíduo
carrega os dois genótipos: o macho carrega o pico de preferência sem expressar,
e a fêmea carrega o traço sem expressar. A expressão continua sendo dimórfica,
só o macho mostra z e só a fêmea usa p, mas a transmissão é bi-parental para as
duas características.

A grandeza central deixa de ser a média de cada característica e passa a ser a
covariância genética entre elas, cov(z, p). O acasalamento assortativo constrói
essa covariância: fêmeas que preferem machos de traço alto acasalam com machos
de traço alto, e os filhotes desses casais herdam juntos os genes da preferência
e os genes do traço. Uma vez que a associação existe, a seleção que age sobre o
traço arrasta a preferência consigo, mesmo sem nenhuma seleção agindo
diretamente sobre ela, que é o mecanismo de Fisher.

Este estudo mede também o desequilíbrio de ligamento, que é a diferença entre a
variância total do traço na população e a variância génica, aquela que a
segregação transmite. É o excesso de variância que o acasalamento não aleatório
acumula sem que exista genótipo novo por trás, vale zero quando o acasalamento
é aleatório, e é uma quantidade que os três estudos anteriores não têm como
mostrar, porque neles apenas uma das duas características é herdada.

### Por que os dois sigmas só podem ser condição inicial

Nos outros três estudos sigma é re-aplicado a cada geração e por isso vale do
começo ao fim. Aqui isso é impossível: as duas características são herdáveis, e
re-sortear os valores é exactamente o que impede a herança. Da geração 2 em
diante a dispersão é o que a seleção e a deriva fizerem dela.

Os níveis são três, 0.5, 1.0 e 2.0, e são *cruzados* entre os dois sexos em vez
de percorridos ao longo da diagonal. A razão é que a diagonal prenderia a
assimetria em zero, e a análise do Controle mostrou que é a assimetria, e não a
variabilidade total, o que determina a topologia. No cruzamento a assimetria e a
variabilidade total ficam descorrelacionadas, porque cada assimetria positiva
tem o seu espelho negativo com a mesma norma, e assim os dois efeitos podem ser
estimados separadamente.

| sigma_p | sigma_z | assimetria |                                    |
|---------|---------|------------|------------------------------------|
| 2.0     | 0.5     | -1.39      | fêmeas variadas, machos homogêneos |
| 1.0     | 0.5     | -0.69      |                                    |
| 2.0     | 1.0     | -0.69      |                                    |
| 0.5     | 0.5     | 0          | a diagonal                         |
| 1.0     | 1.0     | 0          | a diagonal                         |
| 2.0     | 2.0     | 0          | a diagonal                         |
| 0.5     | 1.0     | +0.69      |                                    |
| 1.0     | 2.0     | +0.69      |                                    |
| 0.5     | 2.0     | +1.39      | fêmeas homogêneas, machos variados |

Os três níveis formam uma progressão geométrica de razão 2, de modo que em
escala logarítmica, que é a escala natural de um parâmetro de dispersão, são
equidistantes: a assimetria resultante toma cinco valores igualmente espaçados,
simétricos em torno de zero.

Da geração 2 em diante a assimetria deixa de ser imposta e passa a ser medida,
`0.5 * log(varz_pop / varp_pop)`, e entra nas análises como covariável geração a
geração. A pergunta passa a ser se a relação que o Controle encontrou se mantém
quando as duas características evoluem.

### O que se esperava de cada curva de preferência

As previsões a seguir foram formuladas antes de o estudo rodar, e ficam
registradas porque parte delas se confirmou e parte não:

-   Aleatória: a probabilidade de aceite não depende de z nem de p, então o
    acasalamento não é assortativo e cov(z, p) deve ficar em torno de zero o
    tempo todo.
-   Gaussiana: gera acasalamento assortativo forte, porque cada fêmea acasala
    com machos parecidos com o seu próprio pico, e portanto deve gerar a maior
    covariância.
-   Sigmoide: é a curva onde o runaway poderia aparecer, porque o aceite cresce
    monotonicamente com z, e esperava-se que a covariância aumentasse.
-   Disruptiva: gera acasalamento dissortativo, e seria a única curva em que a
    preferência e o traço podem ser puxados em direções opostas.

Esperava-se também um limiar de variância inicial abaixo do qual o runaway não
acontece, em vez de uma resposta que cresça suavemente com sigma inicial, mais
baixo na sigmoide por ser a única direcional e mais alto com seleção natural
ligada, porque ela compete com o ciclo. Os resultados estão no anexo de
resultados.

## As variáveis resposta

De cada rede de acasalamentos registram-se duas famílias de quantidades, que
convém não confundir. As *métricas de estrutura* descrevem como as arestas
estão arranjadas: modularidade, calculada com o algoritmo de Louvain sobre a
projeção unimodal; aninhamento, pelo índice NODF; centralização de grau; e a
oportunidade de seleção sexual, Is, que é a variância no número de parceiras
entre os machos dividida pelo quadrado da média, ou seja o quadrado do
coeficiente de variação da distribuição de grau deles.

Os *descritores da rede* dizem quantas arestas existem e sobre quantos
indivíduos, e não descrevem arranjo nenhum:

-   `conectancia`: a fração dos pares possíveis que acasalaram, ou seja arestas
    dividido por machos vezes fêmeas. Numa rede bipartida o denominador é esse,
    e não n(n−1)/2, porque os pares macho-macho e fêmea-fêmea são
    estruturalmente impossíveis.
-   `n_machos_surv`: o censo adulto de machos, que sob a cota é 200 por
    construção e serve de verificação.
-   `grau_medio_femeas` e `grau_medio_machos`: a poliandria realizada e o seu
    espelho, a média de parceiros entre os indivíduos que acasalaram, de cada
    lado da rede.
-   `prop_femeas_sem_acasalar` e `prop_machos_sem_acasalar`: as duas pontas
    dessas distribuições. A primeira é a medida direta da força de seleção
    agindo sobre a preferência feminina, porque uma fêmea que não aceita
    ninguém deixa zero descendentes.
-   `prop_femeas_atingiu_k`: que fração das fêmeas alcançou o teto de parceiros.
-   `machos_avaliados_medio`, `machos_aceitos_medio` e `taxa_aceite`: quantos
    machos cada fêmea chegou a ver, quantos aceitaria entre esses e a razão
    entre os dois. Estes três separam as três coisas que limitam a poliandria e
    que de outro modo só se observam somadas: a busca, a exigência da curva de
    preferência e o teto k.

A distinção entre as duas famílias não é cosmética. As métricas de estrutura
dependem dos descritores, e nenhuma delas é comparável entre redes de tamanho ou
densidade muito diferentes, de modo que os descritores entram nas análises como
covariáveis e não como respostas. É também a razão metodológica da escolha da
cota descrita acima.

Nos estudos evolutivos registram-se além disso, geração a geração, a média e a
variância da característica herdável, e na Co-evolução a covariância e a
correlação entre traço e preferência, a variância génica de cada uma e o tamanho
efetivo da população.
