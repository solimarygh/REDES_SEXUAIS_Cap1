# O que mudou no modelo, e por quê

Resumo das mudanças desde a nossa última conversa, com o motivo de cada uma. Estão ordenadas
pelo que mais afeta a leitura da topologia das redes, que é onde eu queria a sua opinião.

A descrição completa e atualizada do desenho está em `NOTA_quatro_estudos.md`. Aqui está só o
que mudou e por quê.

---

## 1. O k não é o número de parceiros, é um teto

**Como era descrito.** k era "com quantos machos cada fêmea acasala", com os níveis 5, 10 e 20.

**O que o código sempre fez.** A fêmea acasala com `min(k, machos que ela aceitou entre os A_max
avaliados)`. Ela para quando atinge k OU quando esgota os machos que conseguiu avaliar, o que
vier primeiro. Como a amostragem é sem reposição, ela nunca acasala com mais machos do que
avaliou. Com A_max = 10 e k = 20, o teto é inalcançável por construção.

**E morde bem antes do limite aritmético,** porque ela não acasala com os dez que avaliou, e sim
com os que aceitou entre esses dez. A taxa de aceite depende da curva de preferência: com s = 2 e
sigma_p = sigma_z = 1, é de cerca de 0.33 na gaussiana, 0.50 na aleatória e na sigmoide, e 0.67
na U-shaped. Medindo a poliandria realizada com A_max = 10:

| Curva de preferência | k = 5 | k = 10 | k = 20 |
|---|---|---|---|
| Gaussiana | 3.32 | 3.56 | 3.51 |
| Aleatória | 4.45 | 5.15 | 5.10 |
| U-shaped | 4.78 | 6.55 | 6.89 |

**Por que isso é sério.** Duas coisas. A primeira é que as células k = 10 e k = 20 com A_max = 10
não são dois tratamentos distintos, são o mesmo: em nenhuma delas o teto é atingido, e o que
sobra é "ela acasala com quem aceitar entre dez machos". A segunda, e mais grave, é que o grau
realizado difere sistematicamente ENTRE CURVAS com o mesmo k nominal, por um fator de dois. Como
densidade de arestas afeta modularidade, aninhamento e centralização, isso é um confundimento
direto sobre a hipótese de que a forma da curva deixa assinatura topológica.

**O que fizemos.** Passamos a gravar a poliandria realizada (grau médio das fêmeas que
acasalaram), a proporção que atingiu o teto e o número de arestas. Nenhuma dessas colunas existia
antes, e nenhuma podia ser recuperada da saída antiga, porque o Is é calculado sobre os machos e
não permite reconstruir o grau das fêmeas. Foi a razão mais forte para refazer as simulações.

**E reenquadramos o k como apetite, não como cota.** A fêmea busca até k parceiros; quantos
consegue depende da disponibilidade e da própria seletividade. A poliandria passa a ser variável
resposta. Isso converte as células "degeneradas" nas mais interessantes: A_max = 10 com k = 20 é
poliandria frustrada, querer muitos parceiros e encontrar dez, e comparada com A_max = 200 e
k = 20 é exatamente o teste da hipótese de restrição de amostragem.

**Uma coisa boa no meio disso.** Com A_max = 200 está tudo limpo: todas as curvas atingem o k e o
grau realizado é idêntico entre elas (5.00, 10.00, 20.00). Ou seja, existe uma condição em que a
densidade está equiparada por construção e a comparação entre curvas pode ser lida sem
contaminação.

---

## 2. O pool de machos não era constante

**Como era.** A seleção natural de viabilidade agia sobre os 200 machos adultos. Quem não
sobrevivia saía, e os que sobravam acasalavam.

**O problema, e ele só existia com a seleção natural LIGADA.** Com ela desligada o código fazia
`survive <- rep(TRUE, N_machos)` e os 200 machos passavam todos, então o pool era constante. Com
ela ligada, a fração que sobrevive é `1 / sqrt(1 + 2 gamma sigma_z^2)`, e o número de machos
disponíveis caía com sigma_z:

| sigma_z | 0.2 | 0.5 | 0.8 | 1.0 | 1.2 | 1.5 | 2.0 |
|---|---|---|---|---|---|---|---|
| Machos disponíveis (de 200) | 198 | 191 | 178 | 169 | 159 | 145 | 124 |

O pool encolhia 37% ao longo do gradiente, e isso muda as DIMENSÕES da matriz sobre a qual as
métricas são calculadas. Modularidade, aninhamento e centralização dependem do tamanho da matriz,
não só da sua densidade, então uma tendência ao longo de sigma_z já estaria contaminada só por
isso.

**Uma correção sobre o efeito na densidade.** Numa versão anterior deste resumo eu escrevia que o
mesmo número de arestas se repartia entre menos machos, e que o grau médio dos machos subia de
5.1 para 8.1. Isso não se sustenta: o número de fêmeas na rede também não é constante, porque as
que não acasalam são excluídas do cálculo, e o número de arestas cai com sigma_z, já que a taxa
de aceite diminui quando os machos são mais dispersos. Numerador e denominador caem os dois, e
sem medir não dá para dizer qual ganha. O que fica é o argumento das dimensões, que basta.

**E há uma distinção que vale registrar.** As fêmeas que somem da rede somem por um resultado
biológico que queremos medir: elas não acasalaram, e isso está gravado à parte. Os machos que
sumiam sumiam por um artefato de onde nós tínhamos colocado o passo da viabilidade, em quantidade
que dependia justamente do eixo do experimento.

**Onde mordia.** No estudo em que sigma_p varia, pouco, porque ali sigma_z fica fixo. Mas no
controle e no estudo do espelho mordia de frente, porque neles sigma_z é justamente o eixo do
experimento: qualquer tendência das métricas ao longo desse eixo, nos cenários com seleção
natural, estaria contaminada.

**E o pior é que o confundimento estava alinhado com o contraste que interessa.** Como o pool só
encolhia com a seleção natural ligada, comparar os dois regimes não comparava apenas "há seleção"
contra "não há": comparava também "há menos machos" contra "há 200". Um artefato de densidade
teria se apresentado como um efeito da seleção natural.

Isso tem um lado prático bom: para a metade do desenho sem seleção natural, o censo constante é
uma mudança cosmética. O código antigo entregava 200 machos e o novo entrega 200 machos, com a
mesma distribuição.

**O que fizemos.** A viabilidade passou a agir sobre os JUVENIS, antes do censo de adultos. Cada
geração, todos os filhotes recebem sexo ao acaso, a viabilidade age sobre os machos juvenis, e o
censo fixa a população adulta em 200 de cada sexo. A seleção continua mudando QUAIS machos estão
disponíveis, que é o efeito que interessa, e deixou de mudar QUANTOS, que era o confundimento.
Biologicamente é a formulação mais comum, mortalidade de viabilidade sobre juvenis e censo de
adultos.

Gravamos também `n_machos_surv` a cada geração, para que a afirmação de que o censo foi sempre
200 seja verificável nos dados e não suposta.

---

## 3. A regra de escape saiu

**Como era.** Se a fêmea avaliava os machos e não aceitava nenhum, ela acabava acasalando com o
último avaliado. Nenhuma fêmea ficava sem acasalar.

**O problema.** A fecundidade é neutra: quem acasalou deixa 50 filhotes, independentemente de com
quantos machos. Somando as duas regras, TODAS as fêmeas tinham exatamente o mesmo sucesso
reprodutivo. Sem variância de sucesso entre fêmeas não existe seleção possível sobre a
preferência, e o modelo espelho (onde a preferência é o que evolui) era impossível por
construção.

**O que fizemos.** Agora quem não aceita ninguém fica sem acasalar e deixa zero filhotes. A
fecundidade continua neutra, como tínhamos combinado.

**Consequência para as redes.** Passam a existir fêmeas de grau zero. Elas são excluídas do
cálculo das métricas de topologia, porque entrariam como nós isolados e inflariam artificialmente
a modularidade, e são contabilizadas à parte numa coluna própria. Os machos de grau zero, ao
contrário, continuam entrando no cálculo, porque eles são justamente o sinal da seleção sexual.
Essa assimetria é deliberada e vale discutir.

---

## 4. Segregação infinitesimal

**O que descobrimos.** Ao rodar o espelho, a variância da preferência caía de 1.0 para 0.08 e
ficava travada ali, em TODAS as combinações de sigma_z, A_max e curva de preferência. O número
não era coincidência. Com herança de ponto médio mais um ruído fixo eps:

    V' = V/2 + eps^2   ->   equilíbrio  V* = 2 eps^2 = 2 (0.2)^2 = 0.08

O blending corta a variância pela metade a cada geração, e a única coisa que a repunha era o
ruído fixo que nós escolhemos. Conferimos nos dados do modelo original e acontecia o mesmo: na
geração 100, a variância do traço era 0.08 para qualquer valor de sigma_p.

**Por que importa.** O piso era imposto por nós, não emergente. Qualquer resultado sobre
manutenção de variância genética estava medindo desvios de poucos pontos percentuais em torno de
um valor que nós tínhamos fixado.

**O que fizemos.** Adotamos o modelo infinitesimal: o desvio de segregação passou a ser
proporcional à variância parental, em vez de um ruído de tamanho fixo.

**A conta, passo a passo.** Cada filhote recebe

    z_filhote = (z_pai + z_mae)/2 + D

O primeiro termo é a média dos dois pais. Se os pais forem tomados ao acaso na população, cada um
com variância V, então

    Var( (z_pai + z_mae)/2 ) = (V + V)/4 = V/2

ou seja, a média de dois números varia menos que um número sozinho. É por isso que o blending,
sozinho, corta a variância pela metade a cada geração.

O segundo termo, D, é o desvio de segregação: o quanto cada filhote se afasta da média dos pais,
porque calhou de receber uma metade dos genes de cada um e não a outra. É ele que faz irmãos
diferirem entre si. E toda a diferença entre os dois modelos está em quanto vale a sua variância.

**Com ruído fixo,** Var(D) = eps^2, um número que nós escolhemos e que não depende de nada:

    V' = V/2 + eps^2

Repetindo isso geração após geração, V converge para o ponto fixo onde V* = V*/2 + eps^2, ou seja
V* = 2 eps^2. Com eps = 0.2 dá 0.08, que é exatamente o que víamos.

**No modelo infinitesimal,** Var(D) = V/2, proporcional à variância que existe entre os pais:

    V' = V/2 + V/2 = V

A metade que o blending tira é exatamente a metade que a segregação repõe.

**A intuição de por que o infinitesimal é o certo.** Com ruído fixo, uma população em que todos os
pais fossem idênticos ainda produziria filhotes variados, do nada. Isso é impossível: se não há
variação entre os pais, não pode haver variação entre irmãos. O infinitesimal respeita isso,
porque faz a variação entre irmãos ser proporcional à que existe na população. É o resultado
clássico de Falconer e Mackay: um pai transmite metade dos seus genes ao acaso, e a variância
entre os gametas que ele pode produzir é V_A/2.

No código isso é `desvio <- rnorm(n, 0, sqrt(var_pais / 2))`, mais um termo mutacional pequeno
(`mut_sd = 0.05`) que repõe o que a deriva remove ao longo de muitas gerações.

A variância deixa então de erodir sozinha e passa a ser determinada só pela seleção e pela
deriva. O modo antigo continua no código para comparação, e o modo usado fica gravado numa coluna
da saída de cada simulação.

---

## 5. O desenho virou quatro estudos, com um controle novo

A estrutura que estava implícita ficou explícita. Os quatro compartilham o mesmo ciclo de vida e
as mesmas quatro curvas de preferência, e diferem apenas em quais características são herdadas:

| Estudo | O que varia | Traço do macho | Preferência da fêmea |
|---|---|---|---|
| Controle | sigma_p e sigma_z | sorteado | sorteada |
| Fêmeas variando | sigma_p | herdável | re-sorteada |
| Machos variando | sigma_z | ambiental | herdável |
| Co-evolução | os dois, só condição inicial | herdável | herdável |

**O controle é novo.** Nada é herdado, roda uma única geração, e cruza sigma_p com sigma_z por
inteiro (7 por 7). Sem herança, a geração 2 seria um sorteio independente com a mesma
distribuição, então rodar 100 gerações seria só fazer 100 réplicas disfarçadas. Isso o torna
cerca de cem vezes mais barato e é o que permite cobrir a superfície completa.

**Por que ele precisa ser independente.** A geração 1 dos outros estudos já é um controle, mas
cada uma cobre só uma linha: um varre sigma_p com sigma_z fixo em 1.0, o outro varre sigma_z com
sigma_p fixo em 1.0. Juntas formam uma cruz e deixam de fora as combinações extremas, que são
justamente as mais informativas, como se vê no ponto 6.

---

## 6. O primeiro resultado do controle

**O que separa as curvas de preferência não é quanta variabilidade existe, é de que lado ela
está.**

Medimos a divergência entre as quatro curvas de preferência como a distância média ao centroide
delas no espaço das quatro métricas de topologia padronizadas, célula a célula do desenho, e
modelamos essa divergência em função da posição no plano sigma_p por sigma_z.

O regime de busca domina: A_max, k e seleção natural sozinhos explicam R^2 = 0.679. Sobre essa
base, o que cada termo de dispersão acrescenta:

| Termo | R^2 parcial |
|---|---|
| Assimetria, `log(sigma_z / sigma_p)` | **0.428** |
| Descasamento em valor absoluto | 0.103 |
| Máximo entre as duas | 0.049 |
| Variabilidade total, `sqrt(sigma_p^2 + sigma_z^2)` | 0.020 |

A divergência é máxima quando as fêmeas são homogêneas e os machos variados. Das 37 células cuja
divergência ultrapassa tudo o que a diagonal alcança, TODAS têm sigma_p baixo e sigma_z alto, e
nenhuma o contrário.

**A leitura biológica é direta.** Quando todas as fêmeas querem a mesma coisa, a geometria da
curva se traduz sem ruído em quem acasala com quem. Quando as fêmeas discordam entre si, a
variação individual delas borra a assinatura. E é preciso haver machos variados para que exista
algo a discriminar.

**E uma boa notícia.** Essa divergência NÃO é um artefato de densidade de rede. O espalhamento da
poliandria realizada entre as curvas acrescenta R^2 parcial de 0.0097, e somado à assimetria
acrescenta 0.0003, com AIC pior. Com a ressalva de que o modelo base já contém A_max e k, que são
os maiores determinantes do grau realizado, então o que isso mostra é que a densidade residual
não explica nada. Não é uma análise de mediação completa.

---

## O que já rodou

Tudo isto já está implementado e rodado, com o modelo novo, 20 réplicas por cenário. São 20 e não
100 porque os problemas dos pontos 1, 2 e 3 são vieses sistemáticos e não ruído: mais réplicas
não os tocariam. Subimos depois, quando o desenho estiver fechado.

| Estudo | Cenários | Gerações | Estado |
|---|---|---|---|
| Controle | 70.560 | 1 | pronto |
| Fêmeas variando | 10.080 | 100 | pronto |
| Machos variando (o espelho) | 10.080 | 100 | pronto |
| Co-evolução | 12.960 | 100 | desenhado, ainda não rodou |

O espelho é o modelo que combinamos na reunião de julho, com o traço do macho ambiental e a
preferência da fêmea herdável. Está implementado e rodado.

Sem nenhuma falha e sem nenhum cenário encerrado antes das 100 gerações, o que verificamos com
uma coluna nova que grava exatamente isso.

A Co-evolução é a única que falta, e é sobre o desenho dela que as duas perguntas abaixo pesam
mais.

---

## Duas perguntas para você

**1. O problema do mediador.** Se o grau realizado depende da curva de preferência, e o usamos
como covariável para comparar curvas, estamos controlando por um mediador e não por um
confundidor: a curva causa o grau realizado E a topologia, então controlar remove parte do efeito
causal que queremos medir. Minha intuição é reportar as duas coisas, o efeito total da curva e o
efeito líquido de densidade, declarando que respondem a perguntas diferentes. Mas é inferência
causal em redes e prefiro ouvir você antes.

**2. Louvain contra modularidade bipartida.** Continuamos usando `cluster_louvain` do igraph
sobre a projeção não dirigida, e não o `computeModules` do pacote `bipartite`. A razão é de
custo: Louvain leva centésimos de segundo por rede e o computeModules chega a dez segundos, o que
com dezenas de milhares de redes seria inviável. Isso se sustenta na revisão, ou vale pagar o
custo em um subconjunto de cenários para mostrar que as duas concordam?
