# Co-evolução: os primeiros testes, e o que eles ensinaram

Setembro de 2026. Esta nota registra a primeira rodada de testes do Estudo 4,
que ainda não é o estudo. Nada aqui é resultado biológico: é o que descobrimos
sobre o próprio modelo ao tentar botá-lo para andar. Escrevi porque três das
coisas que apareceram mudam decisões que já tínhamos tomado.

Os scripts são `00_teste_coevolucao.R`, `00_teste_runaway_gaussiana.R`,
`01_coevolucao_diagnostico_e_estudo.R` e `02_inflacao_variancia_nos_estudos.R`.
Os dados ficaram em `Resultados_Artigo/Fase_Coevolucao/Dados/`.

---

## O ponto de partida

O motor de co-evolução existia como rascunho desde julho, nunca rodado. A
diferença dele para os outros três é que cada indivíduo carrega as duas
características e a expressão é que é dimórfica: só o macho mostra z, só a fêmea
usa p. A grandeza central deixa de ser a média de cada uma e passa a ser a
covariância genética entre elas.

Antes de rodar, o rascunho foi atualizado com as decisões que os outros estudos
já tinham tomado: segregação infinitesimal, censo de adultos por
`selecionar_machos_adultos`, caso degenerado registrado em `extincao_gen`, e a
regra de escolha como parâmetro. Também entrou uma coluna `fuga_gen`, que marca
a primeira geração em que a média do traço passa de três vezes phi, porque sem
ela uma réplica pode explodir e correr até o fim sem avisar.

E havia um erro que teria derrubado a primeira geração: `female_p` era lido do
censo das fêmeas antes de o censo ser sorteado. Em t = 1 o objeto nem existia,
e de t = 2 em diante seria o das fêmeas da geração anterior.

---

## O que os testes mostraram, em ordem

### 1. A covariância sobrevive, e a cadeia causal funciona

O erro mais perigoso deste estudo é silencioso: se z e p forem amostrados
separadamente na hora de formar os juvenis, `cov(z, p)` vira zero e o runaway
desaparece por programação, não por biologia, sem nenhuma mensagem de erro. O
teste verifica isso pedindo que a curva gaussiana acumule covariância positiva,
e ela acumula.

As quatro curvas se comportaram como a teoria prevê: aleatória em torno de
zero, gaussiana positiva, u-shaped negativa. E a correlação entre `cov_casais`
(o acasalamento assortativo) e `cov_zp` (a covariância genética que ele
constrói) deu 0.98 entre as curvas, o que confirma que a cadeia causal está
ligada na ordem certa.

### 2. O que parecia um runaway não era

Numa réplica da gaussiana sem seleção natural, as duas médias saíram de 5 e
terminaram perto de 9, juntas, com `cov_zp` = 14.5. Com cara de Fisher. Mas com
n = 1 não sustenta nada, e a confirmação com dez réplicas derrubou a leitura:

- as duas médias andam juntas (correlação 0.98 entre réplicas) — a favor
- o deslocamento é 31 vezes o da curva aleatória — a favor
- **mas as dez réplicas subiram, todas** — contra

Na linha de equilíbrios de Lande não há lado preferido. Metade deveria subir e
metade descer. Dez de dez é assimetria de alguma coisa, não Fisher.

E a coluna que contava a história era outra: a variância do traço foi de 1 para
58.6. Não era a média se deslocando, era a variância explodindo e arrastando a
média junto. `cor_zp` ficou em 0.38 enquanto `cov_zp` chegava a 22: a
covariância era grande porque as variâncias eram enormes, não porque o
acoplamento fosse forte.

### 3. A causa: a segregação se realimenta

O diagnóstico separou os dois suspeitos ligando e desligando cada um, sempre com
a mesma semente entre os braços:

| braço | desloc. | subiram | var final | cov_zp | cor_zp |
|---|---|---|---|---|---|
| como está | 6.22 | 10/10 | 58.6 | 22.57 | 0.38 |
| phi longe do zero | 26.91 | 0/10 | 218.4 | 75.31 | 0.34 |
| segregação fixa | 0.60 | 5/10 | 0.6 | 0.55 | 0.83 |
| os dois desligados | 0.60 | 5/10 | 0.6 | 0.55 | 0.83 |

Com segregação fixa a direção vira aleatória, a variância fica contida e o
deslocamento cai de 6.22 para 0.60. Que os dois últimos braços deem resultados
idênticos fecha o argumento: quando a variância não infla, onde phi está deixa
de importar, porque o truncamento em zero nunca chega a morder.

A causa é o laço que já estava anotado como limitação da implementação, agora
com evidência. Com preferência gaussiana o acasalamento é fortemente
assortativo, o que gera desequilíbrio de ligamento positivo e faz a variância
TOTAL subir. Como a nossa segregação usa `var(c(male_z_surv, female_z_gen))`,
que é a total, mais variância gera mais variância. O modelo infinitesimal
estrito acompanha a variância génica, que sob acasalamento assortativo não se
infla assim, e é ela que deveria governar a segregação.

Vale reparar em `cor_zp`: 0.83 com a variância contida, contra 0.38 sem.
**O acoplamento genuíno entre preferência e traço é mais forte quando o
artefato não está lá.** A inflação estava mascarando o sinal, não produzindo-o.

Um pedaço continua sem explicação: com phi = 50 as dez réplicas vão para baixo,
e a variância infla ainda mais. Não tenho mecanismo para essa direção.

### 4. E a boa notícia: isso não contamina os outros estudos

A pergunta seguinte era óbvia e preocupante. Fêmeas variando usa exatamente a
mesma segregação, e a curva gaussiana gera exatamente o mesmo assortamento.
Estaria o mesmo laço lá, contaminando o que já rodamos?

Não está. Nos dados de Fêmeas variando, sem seleção natural e com A_max = 200,
a variância do traço na geração 100 fica em 1.23 na gaussiana contra 1.04 na
aleatória, partindo de 1. Nada parecido com o 58.6 da co-evolução.

**A razão é o que faz a diferença entre os dois estudos.** Em Fêmeas variando a
preferência é re-sorteada a cada geração de N(5, sigma_p), e isso é uma âncora
externa: a variância do traço converge para ela e para. Em Co-evolução a
preferência também é herdável, então as duas podem derivar juntas, não há
âncora, e o laço não tem o que o segure.

Ou seja, o problema é específico do Estudo 4, e é específico justamente por
causa do que o define. Explica também por que nunca tínhamos visto isto.

### 5. De quebra, a diagonal se sustenta

A "diagonal" que tinha aparecido na exploração — o sigma_z da geração 100
acompanhando o sigma_p imposto, sob a gaussiana — estava na lista de coisas a
conferir, justamente sob a suspeita de ser este mesmo laço. Não é:

| sigma_p | var final | sigma_z final |
|---|---|---|
| 0.2 | 0.05 | 0.21 |
| 0.5 | 0.23 | 0.48 |
| 1.0 | 0.86 | 0.93 |
| 1.5 | 2.02 | 1.42 |
| 2.0 | 3.63 | 1.90 |

A correlação entre sigma_p e o sigma_z final é 1.00, e a razão
var_final / sigma_p² fica entre 0.83 e 1.15 ao longo de um gradiente de dez
vezes. Mas o que decide é a direção: com sigma_p = 0.2 a variância CAIU de 1.0
para 0.05, e com sigma_p = 2.0 SUBIU para 3.63.

Um laço de inflação sem freio só pode ir para cima. Isto converge dos dois
lados, o que é a assinatura de um equilíbrio e não de uma fuga. A diagonal é
resultado, e agora com mecanismo: sob preferência estabilizadora, a dispersão
do traço converge para a dispersão dos picos de preferência.

### 6. Uma previsão minha que falhou

Eu esperava que a curva u-shaped ficasse com variância baixa, porque gera
acasalamento dissortativo. É a mais alta de todas: 2.54 na geração 100, com um
pico de 7.19 na geração 20 antes de assentar.

Confundi dois mecanismos. O acasalamento dissortativo reduz o desequilíbrio de
ligamento, mas a seleção disruptiva infla a variância diretamente, e aqui manda
o segundo. É biologia, não artefato, e a subida seguida de queda tem cara de
uma população que se espalha e depois encontra o seu equilíbrio.

---

## A correção, e o que ela revelou

A saída escolhida foi a primeira das duas: acompanhar a variância génica à
parte. Ela entrou como um terceiro modo, `segregacao = "genica"`, que virou o
default da co-evolução, com os outros dois mantidos para comparação.

O que a torna possível é uma propriedade do próprio modelo infinitesimal: a
seleção **não altera** a variância génica. São infinitos locos de efeito
infinitesimal, então as frequências alélicas mal se movem e só a deriva e a
mutação a mudam. Isso dá uma dinâmica simples e defensável:

    var_genica <- var_genica * (1 - 1/(2*Ne)) + mut_sd^2

Assim a variância TOTAL continua livre para inflar sob acasalamento
assortativo, que é biologia real, mas deixa de realimentar a segregação.

O Ne não é suposto: sai do número de filhos que cada pai de fato deixou, pela
fórmula do tamanho efetivo por variância no sucesso reprodutivo, combinando os
dois sexos. Com seleção sexual forte poucos machos podem gerar quase tudo, e
isso muda a velocidade de erosão por um fator grande.

O diagnóstico rodou de novo com os quatro braços, e o modo génico passou:

| braço | desloc. | subiram | var total | var génica | Ne | cor_zp |
|---|---|---|---|---|---|---|
| variância total | 6.22 | 10/10 | 58.6 | — | — | 0.38 |
| phi longe do zero | 26.91 | 0/10 | 218.4 | — | — | 0.34 |
| segregação fixa | 0.60 | 5/10 | 0.6 | — | — | 0.83 |
| **variância génica** | **1.33** | **5/10** | **3.6** | **1.1** | **347** | **0.71** |

Direção aleatória entre réplicas e variância contida, que era o que faltava.

Três coisas que valem para além de "funcionou".

**O desequilíbrio de ligamento virou uma quantidade medível.** No modo génico a
variância total fica em 3.6 e a génica em 1.1, e a distância entre as duas é o
desequilíbrio que o acasalamento assortativo gerou. Antes as duas estavam
fundidas num número só, e era isso que permitia o laço. Agora dá para reportar
o quanto cada curva de preferência gera de desequilíbrio, que é uma resposta a
mais e não um problema.

**O acoplamento genuíno estava sendo mascarado, não produzido.** A correlação
entre traço e preferência é 0.71 com a variância contida contra 0.38 sem, e
chega a 0.83 no modo de ruído fixo, em que a variância é mínima. Ou seja, o
sinal fica mais limpo quanto menos ruído de segregação há, e a covariância
enorme do modo antigo era efeito das variâncias grandes e não de acoplamento
forte.

**E a dinâmica não morreu junto com o artefato.** O modo génico se desloca mais
que o de ruído fixo, 1.33 contra 0.60, mas em direção aleatória. Havia o risco
de a correção matar o fenômeno junto com o problema, e não foi o caso: sobra
movimento, e agora sem lado preferido.

Um detalhe de leitura: nas linhas dos outros três modos a coluna da variância
génica mostra o valor inicial e o Ne aparece vazio. Não é erro, é que nesses
modos a génica nunca é atualizada.

E o Ne deu 347 num censo de 400, bem mais alto do que eu esperava. Faz sentido
para a gaussiana, em que cada fêmea escolhe machos próximos do seu próprio pico
e os picos diferem, então a paternidade se reparte. Sob a sigmoide, em que
todas querem os mesmos machos, é de esperar que despenque. A seção seguinte
mostra que não despencou, e por quê.

---

## O estudo rodou

Os 12.960 cenários do desenho da proposta rodaram em 17,5 horas, sem uma única
falha e sem nenhuma réplica encerrada antes da geração 100. São 1.296.000
linhas em `resultados_Coevolucao_genica_completo.rds`, e a leitura está em
`03_analise_coevolucao.R`.

A primeira coisa a conferir era se a correção aguentava em escala. Aguentou: na
gaussiana sem seleção natural, 818 réplicas de 1.620 subiram, 50,5%. O que no
diagnóstico eram 5 de 10 são agora metade de mil seiscentas. A aleatória dá 54%,
uma sobra pequena que é o truncamento em zero, com deslocamento de 0.45 em cem
gerações. E as 1.510 réplicas com fuga do traço estão concentradas em duas
curvas, 1.260 na sigmoide e 250 na u-shaped, ambas sem seleção natural. Fuga
concentrada numa preferência é aquela preferência, não uma assimetria do motor.

### O desequilíbrio de ligamento separa dois mecanismos

Na geração 100, sem seleção natural:

| curva | var total | var génica | LD | razão |
|---|---|---|---|---|
| gaussiana | 3.29 | 1.71 | 1.58 | 1.92 |
| u-shaped | 2.20 | 1.74 | 0.45 | 1.26 |
| sigmoide | 1.64 | 1.66 | -0.02 | 0.99 |
| aleatória | 1.75 | 1.77 | -0.02 | 0.99 |

A gaussiana é a única que empilha desequilíbrio, e a única com covariância
genética: `cov_zp` = 2.12 e `cor_zp` = 0.41, contra 0.04 da sigmoide e zero da
aleatória. `cov_casais` vem sempre à frente de `cov_zp` ao longo das gerações
(1.5 contra 1.2 na geração 20), que é a ordem que Fisher prevê.

A sigmoide dá exatamente a mesma razão que a aleatória. Isso não é falha de
nada: sob a sigmoide todas as fêmeas querem o mesmo, independentemente do seu
próprio p, então o acasalamento é direcional mas não assortativo, e sem
assortamento não há desequilíbrio. A sigmoide produz fuga do traço sem o
mecanismo de Fisher, e vê-se na preferência, que fica parada em 5.73 enquanto o
traço vai a 24.84.

São dois regimes distintos que antes estavam misturados num número só, e é a
separação entre total e génica que permite enxergá-los.

### As curvas apagam a própria estrutura

Este é o resultado que eu não esperava. Sob a sigmoide, sem seleção natural, ao
longo das gerações:

| geração | zbar − pbar | I_s | centralização | var do traço |
|---|---|---|---|---|
| 1 | 0.0 | 7.41 | 0.185 | 1.74 |
| 5 | 2.8 | 8.40 | 0.197 | 1.34 |
| 10 | 5.8 | 7.01 | 0.183 | 1.32 |
| 25 | 11.8 | 3.54 | 0.112 | 1.49 |
| 50 | 16.2 | 0.69 | 0.053 | 1.60 |
| 100 | 19.1 | 0.15 | 0.027 | 1.64 |

A distância entre traço e preferência cresce sem parar, o I_s e a centralização
desabam atrás dela, e a variância do traço não se mexe. Não é perda de variação:
é a média do traço saindo do intervalo em que a sigmoide discrimina. Com zbar
dezenove unidades acima de pbar, a curva vale praticamente 1 para qualquer
macho, e a rede da geração 100 fica indistinguível da aleatória, com nenhuma
fêmea sem acasalar e grau médio no teto de k.

Repare na geração 5: o I_s sobe de 7.41 para 8.40 antes de cair. A seleção
sexual primeiro se intensifica e depois destrói a própria base.

A u-shaped chega ao mesmo fim por outro caminho. A distância entre traço e
preferência só vai a 3.2, então não é a média que escapa. É a variância, que
salta de 1.74 para 3.83 em dez gerações. Como a u-shaped aceita machos distantes
do próprio p, alargar a distribuição faz com que toda fêmea encontre machos
distantes, e o I_s cai de 3.89 para 0.26 do mesmo jeito.

Duas curvas, dois caminhos, o mesmo destino: uma desloca a média para fora da
faixa em que a preferência distingue, a outra alarga a distribuição até que todo
mundo passe. A estrutura de rede que os Estudos 2 e 3 medem com o traço fixo é
transitória, e quando o traço pode evoluir ela se apaga sozinha. É exatamente o
que só o Estudo 4 podia mostrar.

### A gaussiana, e o efeito Bulmer

Sob a gaussiana a distância entre zbar e pbar é 0.0 em todas as gerações, com e
sem seleção natural. Traço e preferência andam amarrados, que é o acoplamento de
Fisher visto de outro ângulo.

E a variância do traço na geração 100 é 3.29 sem seleção natural contra 1.38 com
ela. É o efeito Bulmer de manual: o acasalamento assortativo gera desequilíbrio
positivo, a seleção natural gera negativo, e os dois se cancelam em boa parte.
Antes de separar total de génica não tínhamos como enxergar isso.

### Por que a previsão do Ne falhou

Eu esperava que o Ne despencasse sob a sigmoide. Na geração 100 ele dá 377 de
400, igual ao da aleatória. A previsão não errou o mecanismo, errou o momento:
na geração 100 já não sobrou seleção nenhuma sob a sigmoide, então não há o que
concentrar a paternidade. Na geração 5, com I_s em 8.40, a história tem de ser
outra, e a trajetória do Ne agora está na tabela da seção 7 do script.

Com seleção natural, aí sim: o Ne da sigmoide cai para 178, 0.44 do censo, e o
I_s se mantém em 1.92. A viabilidade segura o traço perto de phi, a preferência
continua discriminando, e a assinatura da seleção sexual fica de pé. A leitura
que se insinua é que a seleção natural não apaga a assinatura da seleção sexual:
é ela que impede o traço de fugir e, com isso, a mantém.

### O que o censo bloqueia

Essa última leitura ainda não pode ser reportada. Sob a sigmoide com seleção
natural a centralização não cai, sobe, de 0.181 para 0.374. Mas as células de
sigmoide com seleção natural são exatamente as 670 em que o censo adulto
encurta, de um total de 776 em todo o estudo (as outras 106 são u-shaped, também
com seleção natural). Com dois ou cinco machos adultos, uma rede é centralizada
por construção, e não dá para distinguir o resultado do artefato.

A cota deixou de ser um pendente e passou a bloquear um resultado.

---

## A revisão do motor, com o estudo já rodado

Com os resultados na mão, reli o motor inteiro contra o resto do projeto, à
procura de coisas que fossem de implementação e não de biologia. Achei uma que
compromete um número que eu já tinha reportado como resultado, duas
consequências do buraco do censo que não tínhamos visto, e uma lista de escolhas
de desenho que são legítimas mas precisam estar declaradas nos Métodos.

### O Ne estava sobrestimado, e justo onde importa

A primeira versão calculava assim:

    k <- tabulate(pais); k <- k[k > 0]
    N <- length(k)

Duas coisas erradas, e as duas puxando o Ne para cima exatamente nos cenários de
seleção sexual forte, que são os que queríamos medir.

Os zeros contam. A fórmula de Crow pede N igual ao número de adultos daquele
sexo, com os que não deixaram filho nenhum incluídos no k. São eles que geram a
variância que derruba o Ne, e `k[k > 0]` os descartava. Vale reparar que o I_s,
em `safe_opportunity_sexual_selection`, sempre contou os machos de grau zero:
era por isso que as duas medidas discordavam na tabela, e a discordância não era
biológica, era de critério sobre quem conta como adulto.

O k era de zigotos, e não de filhos que chegaram a adultos. Com fecundidade
plana toda fêmea acasalada deixa exatamente 50, de modo que a variância entre
fêmeas era zero por construção e Ne_f virava simplesmente o número de fêmeas
acasaladas. Mas a deriva de verdade neste modelo está no sorteio dos 200 machos
e das 200 fêmeas entre milhares de juvenis, e esse passo o k de zigotos não
enxergava.

A correção conta filhos que chegaram a ADULTO, com os zeros. Isso obriga a
calcular o Ne depois do censo seguinte, então a parentela agora viaja de
`produce_offspring_coevo` até o próximo censo, e o Ne fecha ali junto com a
erosão da génica. O consumo de números aleatórios não mudou, então o que muda é
a coluna Ne e, muito de leve, a trajetória da génica.

Sobre o alcance disto: como a erosão é desprezível em cem gerações (2Ne é da
ordem de 700), a dinâmica do estudo não muda. O que não se pode reportar são os
valores de Ne da rodada de setembro. Os 377 da sigmoide e os 178 com seleção
natural saem daquele cálculo.

### Duas consequências do buraco do censo que não tínhamos visto

A primeira apaga um tratamento. Em `mate_with_survivors`,
`n_aval <- min(encounters_n, n_m)`. Quando o censo cai para cinco machos, A_max
passa a ser 5 em todas as células, não importa se o tratamento dizia 200. O
buraco não mexe só em N: ele desliga o gradiente de A_max onde morde.

A segunda está na própria válvula de segurança. Quando sobrevivem menos de dois
machos, `selecionar_machos_adultos` devolve `order(V, decreasing = TRUE)[1:2]`,
ou seja os dois melhores por viabilidade, de forma determinista. É um evento de
seleção por truncamento escondido dentro de uma salvaguarda.

### O piso em zero

`pmax(0, .)` em z e em p é um limite reflectante. Com phi = 5 e sigma 1 quase não
morde, mas é a explicação do 54% da curva aleatória subindo em vez de 50%, e
provavelmente do 62% da u-shaped. Como z e p são valores de característica em
unidades arbitrárias, deixá-los ir a negativo não tem problema biológico nenhum e
tiraria esse viés. Se preferirmos manter a não negatividade, o natural é trabalhar
em escala logarítmica. Desconfio que esteja aqui também o mistério do braço com
phi = 50, mas não confirmei.

### Uma correção ao que eu tinha dito

Eu tinha afirmado que a preferência não está sob seleção direta. Está. Com a
gaussiana, `exp(-s(z-p)^2)` com s perto de 2 e sigma_p = 2, uma fêmea de p
extremo tem probabilidade quase nula de aceitar alguém e fica sem acasalar. Os
dados mostram: 8.3% de fêmeas sem acasalar na gaussiana contra 0.0% na
aleatória. Isso é seleção estabilizadora sobre p em direção à média de z, e é o
mecanismo por trás da diagonal e de `zbar - pbar` dar exatamente zero na
gaussiana.

### Escolhas de desenho para declarar nos Métodos

Não há custo direto da preferência além do risco de não acasalar, e com
A_max = 200 esse risco quase desaparece. O modelo fica então no regime da linha
de equilíbrios de Lande. É uma escolha legítima, mas desde Pomiankowski (1991) o
esperado é que um custo colapse a linha num ponto, então vale dizer que se optou
por não pôr.

A exigência `s` é re-sorteada a cada geração para cada fêmea, não é herdável e
não tem consistência individual. A preferência tem dois componentes e só um
co-evolui.

A paternidade se reparte uniformemente entre os machos com que a fêmea copulou,
de modo que o ranking por P_ij, que decide com quem ela acasala, é descartado na
hora de repartir filhos. Uma alternativa natural seria paternidade proporcional a
P_ij. Isto é pergunta para o Miudo, não erro.

A fecundidade é plana: acasalada são 50 filhotes, com um macho ou com vinte. Não
há benefício de poliandria, o que é coerente com o modelo fisheriano puro, mas
precisa estar dito.

A sigmoide e a u-shaped são funções não limitadas em z. Sem seleção natural o
modelo não tem equilíbrio, e a fuga só para quando a curva satura. As células de
sigmoide sem seleção natural não são um cenário biológico, são o modelo saindo
do seu domínio. Isso não invalida o resultado da erosão da estrutura, ao
contrário: é exatamente o que aquele resultado diz.

E a esquina A_max = 10 com k = 10 ou k = 20 não tem escolha nenhuma: a fêmea
avalia dez e pode aceitar dez ou vinte, então o teto nunca aperta. São controles
involuntários.

### O que revisei e está certo

A covariância sobrevive. O sorteio de vagas é por índice e os dois vetores são
indexados pelo mesmo `idx`. É o erro silencioso mais perigoso do estudo e não
está lá.

A dinâmica do desequilíbrio de ligamento é correta. A variância dos filhos é
var(midparent) mais var_génica/2, e sob acasalamento assortativo a covariância
entre pai e mãe entra em var(midparent). Ou seja, o desequilíbrio é reconstruído
a cada geração pelo acasalamento e decai em direção à génica pela segregação, que
é o que deve acontecer.

A variância génica fica praticamente congelada em cem gerações, então na prática
o modelo é de V_A constante, o pressuposto padrão de Lande. Defensável, e a
declarar.

A expressão limitada por sexo está certa: os dois sexos transmitem as duas
características, cada um expressa uma, e a resposta à seleção fica dividida por
dois como deve. As condições iniciais sorteiam z e p independentemente, então
cov(z, p) parte de zero e tudo o que aparece foi o acasalamento que construiu.

E a armadilha do `sample(x, 1)` com x de comprimento 1 está corretamente blindada
na linha dos `dads`.

---

## Onde isto deixa o Estudo 4

Com a correção da variância génica o motor passou no diagnóstico e o desenho
completo rodou, 12.960 cenários em 17,5 horas sem uma falha. Com a correção do
Ne está rodando de novo a metade SEM seleção natural, 6.480 cenários.

A razão de ser só essa metade: todas as células em que o censo adulto encurta são
de seleção natural ligada, porque com ela desligada o censo é uma amostra
aleatória de 200 e o buraco nem é tocado. Essa metade é imune à decisão da cota e
pode ser fechada antes dela, e é onde vivem quase todos os resultados. A outra
metade se roda uma vez só, depois de decidida a cota, em vez de duas.

Os quatro pontos de desenho do Estudo 4 continuam abertos e estão em
`NOTA_material_removido_2026-08-16.md`. O mais pesado é o gradiente de k: se ele
sair de Co-evolução, como uma das saídas propunha, o desenho cai para 4.320
cenários. Vale ter a opinião do Miudo antes da rodada definitiva, mas já não é
impedimento para esta.

Uma armadilha que valeu a lição: ao relançar com o motor corrigido, o script
achou o backup da tentativa anterior, feita com a variância total, e começou a
completá-lo. Teria produzido um conjunto com 6.480 cenários de um motor e 6.480
do outro. É o mesmo cuidado que já tínhamos tomado ao renomear censoConst para
bestOfN, e que não tinha sido aplicado aqui. O nome do arquivo agora carrega o
modo de segregação.

Fica também uma coisa sem explicação, que não bloqueia mas incomoda: no braço
com phi = 50 as dez réplicas vão todas para baixo, e a variância infla ainda
mais que no braço original. Não tenho mecanismo para essa direção.

---

## E o que muda na lista de perguntas

A pergunta 6 da lista para o Miudo era se a variância total no lugar da génica
poderia produzir diferenças aparentes entre curvas que fossem de implementação
e não biológicas, bem em cima da H2. Ela agora tem duas metades com respostas
diferentes:

Nos três estudos já rodados, **não é uma ameaça**. A âncora externa da
preferência re-sorteada segura o laço, a gaussiana infla 1.2 vezes contra 1.0
da aleatória, e a diagonal converge dos dois lados. Continua valendo declarar a
limitação nos Métodos, mas ela não põe os resultados em risco.

Na co-evolução, **é bloqueante**, e passa a ser a primeira coisa a resolver.

E a revisão do motor acrescentou três perguntas novas, todas de desenho e não de
implementação:

A cota do censo, que já estava na lista, agora vem junto com o piso em zero,
porque as duas mexem no mesmo bloco de células e faz sentido decidir as duas de
uma vez. Sobre o piso: z e p são valores de característica em unidades
arbitrárias, então deixá-los ir a negativo não custa nada e tira um viés
mensurável. Vale confirmar que ninguém prefere a leitura de "tamanho não pode ser
negativo".

A paternidade repartida uniformemente entre os machos com que a fêmea copulou,
contra paternidade proporcional a P_ij. A primeira separa escolha de parceiro de
sucesso de fertilização, a segunda junta as duas. É uma decisão biológica sobre o
que o modelo está representando.

O custo da preferência. Sem ele o modelo fica na linha de equilíbrios de Lande
por construção, e a ausência de fuga na gaussiana é em parte um resultado dessa
escolha. Se quisermos poder dizer alguma coisa sobre estabilidade, um custo
pequeno muda a pergunta.
