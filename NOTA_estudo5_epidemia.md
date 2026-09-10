# Estudo 5: uma IST na rede sexual. O que aprendemos ao construir o motor

Setembro de 2026. Esta nota registra a construção do Estudo 5, que é a primeira
parte do Objetivo 2 do plano de trabalho do segundo ano de bolsa. O motor está
em `Fase_Epidemia.R`.

O que segue não é resultado biológico: é o que descobrimos sobre o próprio
modelo ao tentar montá-lo. Escrevo porque três das coisas que apareceram
mudaram o desenho, e a quarta ainda está aberta.

---

## O que o estudo é, e por que uma temporada basta

O plano prevê acoplar um módulo epidemiológico à rede sexual: uma doença que se
transmite por contato e que altera a atratividade do macho infectado. O
relatório para a FAPESP vence em três semanas, então a pergunta era o que cabe
nesse prazo.

A primeira ideia foi adaptar o Estudo 2 e rodar uma geração só. Isso não serve:
uma geração do Estudo 2 já existe, é o Estudo 1. O Controle roda exatamente uma
geração e cruza sigma_p x sigma_z por inteiro, e a linha sigma_z = 1.0 daquela
superfície é a geração 1 do Estudo 2. Seria um recorte do que já temos, não um
estudo novo.

O que cabe, e é novo, é a primeira fatia do Objetivo 2. E uma temporada basta
por uma razão que vale para o relatório: numa temporada não se vê a resposta
evolutiva, mas vê-se o **diferencial de seleção** sobre o traço, que é a média
de z pesada pelo sucesso reprodutivo menos a média de z na população (Lande &
Arnold 1983). A equação do criador o transforma em resposta esperada. Ou seja,
dá para medir a rede, medir a epidemia, e medir a pressão seletiva que a
epidemia gera. O que fica para 2026 é conferir se a previsão se cumpre ao longo
das gerações.

---

## As decisões de desenho, e quem as tomou

Quatro curvas de preferência e 100 réplicas, para ficar consistente com os
outros estudos. Os níveis de sigma_p (0.5, 1.0, 1.5), os três sinais de h_I e o
par SIS/SIR vêm do plano de trabalho.

**h_I** é quanto a infecção altera o sinal que a fêmea avalia. O macho
infectado é visto como se tivesse z + h_I. Como o traço se sorteia de N(5, 1),
h_I = -1 subtrai uma desvio-padrão inteiro: um macho infectado com z = 6 é
visto como se tivesse 5.

Um ponto que vale insistir: **h muda o que a fêmea vê, não o que o macho
transmite aos filhos**. Por isso o diferencial de seleção é sempre calculado
sobre o z verdadeiro. Se fosse sobre z + h estaríamos medindo seleção sobre uma
coisa que não se herda.

A estrutura da temporada foi decisão da Soly, e é melhor do que a que eu tinha
proposto. Cada ronda é uma **semana**; a temporada são 20 semanas, uns quatro
meses. Numa semana a fêmea não inspeciona a população inteira: encontra ao
acaso um punhado de machos, avalia cada um, e acasala com o melhor entre os que
aceitou.

---

## O que erramos, e o que consertamos

### 1. Eu media o efeito da doença na ordem causal errada

A primeira versão comparava o grau dos machos infectados com o dos suscetíveis,
na rede acumulada, com o estado de infecção do fim da temporada. O teste deu
infectados com 76 parceiras e suscetíveis com 1.5.

Isso não é o efeito da doença: é causalidade invertida. Sob a sigmoide os
machos de z alto acasalam com quase todo mundo, e por isso são os primeiros a
se infectar. "Estar infectado" virou consequência do sucesso, não causa dele.

A correção é comparar o que o macho ganhou **naquela semana** contra o estado
que ele tinha **no início dela**, e registrar junto o z médio de cada grupo,
para o confundidor ficar à vista.

E há uma lição maior: mesmo corrigida, essa comparação dentro da temporada
continua confundida pelo traço. **A estimativa causal do efeito de h é o
contraste ENTRE células**, com o mesmo sigma_p, a mesma curva e a mesma
semente, mudando só h_I. É o desenho que dá a resposta, e não uma coluna.

De quebra, aquela comparação errada mostrou uma coisa que não é erro nenhum e
que vale como resultado: sob a sigmoide, **o macho sexualmente selecionado é o
super-disseminador**. A seleção sexual não só permite avaliar resistência a
patógenos, como constrói a estrada por onde o patógeno viaja. As colunas
antigas ficaram com o nome `grau_acum_*` por causa disso.

### 2. O teto de parceiros era por ronda, e não por temporada

Com k = 5 por ronda e cinco rondas, uma fêmea podia acumular 25 parceiras
distintas numa temporada. Além de irrealista, contradizia o "limite de
parceiros por indivíduo" do próprio plano, e amarrava duas coisas que deviam
ser independentes: alongar a temporada para ver a epidemia inflava a
promiscuidade sem querer.

Com o teto na temporada, as duas se separam. As **semanas** são a frequência de
cópula e o **teto** é o número de parceiros.

### 3. Parceiros e cópulas não são a mesma coisa

Nos Estudos 1 a 4 a rede é de uma geração e cada aresta é uma cópula. Aqui não:
a fêmea pode reencontrar um macho que já é seu parceiro, e isso é outra cópula
com o mesmo par, não um parceiro novo.

E os dois números fazem coisas diferentes: são as **cópulas** que movem a
epidemia e são os **parceiros** que dão a topologia da rede. Por isso os dois
ficam registrados, e o diferencial de seleção passou a ser pesado pelas
cópulas, porque um macho que copulou dez vezes teve mais sucesso do que um que
copulou uma vez, ainda que os dois apareçam com uma aresta.

Isto derrubou um pressuposto que era invenção minha e que não estava
justificado: que todos os pares copulavam em todas as rondas. Agora cópula é
consequência de encontro.

### 4. A calibração, que quase deixa o estudo vazio

Dois parâmetros que eu tinha escolhido sem pensar quase inutilizaram metade do
desenho, e só se viu porque calibramos antes de rodar.

**beta**, a probabilidade de transmissão por cópula, estava em 0.3. Com isso a
epidemia saturava e as prevalências davam 0.47, 0.46 e 0.47 para os três h_I:
idênticas. O barrido mostrou que **beta = 0.10** é onde os três mais se
separam, e com uma coincidência feliz: com h_I negativo o surto fica em 8%, ou
seja **abaixo** do limiar de 15% que o plano usa para definir "grande
epidemia", e com h neutro ou positivo passa dos 40%. O critério metodológico do
próprio plano vira a linha que separa os cenários.

**gamma**, a recuperação por semana, estava em 0.1 com uma temporada de cinco
semanas. Uma infecção durava dez semanas numa temporada de cinco, então quase
ninguém se curava, e **SIS e SIR davam exatamente o mesmo**: 0.35 e 0.35. Um
dos quatro fatores da tabela de cenários não teria medido nada. Os dois só se
separam a partir de dez semanas.

A lição é geral e vale para os outros estudos: **um fator do desenho pode não
medir nada, e isso não aparece em nenhuma mensagem de erro**. Só aparece se a
gente calibrar antes.

---

## O que ainda está errado, e para onde a literatura aponta

O teste com a estrutura de semanas deu isto, com h_I = 0:

| curva | parceiros | cópulas | semanas em branco | prevalência |
|---|---|---|---|---|
| aleatória | 10.0 | 10.8 | 92% | 0.01 |
| gaussiana | 9.9 | 13.2 | 77% | 0.01 |
| sigmoide | 9.9 | 12.9 | 76% | 0.03 |
| disruptiva | 10.0 | 13.5 | 78% | 0.04 |

As quatro curvas dão exatamente 10 parceiros porque todas as fêmeas chegam ao
teto. E ao chegar lá, o código as proíbe de acrescentar alguém novo; como só
encontram 10 machos de 200 por semana, a chance de que o melhor aceito seja um
dos seus 10 parceiros é de 5%. Daí os 92% de semanas em branco no fim, umas 11
cópulas em 20 semanas, e a epidemia morta.

Mas o teto é o sintoma. A causa é mais funda: **o modelo não tem parcerias, tem
encontros soltos**. Cada semana é uma loteria independente, e nada persiste de
uma para a outra.

E é exatamente isso que a literatura de redes sexuais diz que não funciona
assim. O que move uma IST não é o número de contatos, é a **estrutura e a
duração das parcerias**: a concorrência (ter parceiros sobrepostos no tempo) e
quanto elas duram. Um modelo de encontros independentes é a caricatura de
mistura homogênea que essa literatura critica.

As duas referências mais diretas já estão na lista do plano de trabalho:

- **Eames & Keeling (2002)**, *PNAS* 99(20):13330-13335, sobre heterogeneidades
  dinâmicas e de rede na propagação de ISTs, que é a referência [3] do plano.
- **Robinson, Cohen & Colijn (2012)**, *Theoretical Population Biology*
  81(2):89-96, sobre a dinâmica de formação e dissolução de parcerias, que é a
  referência [1].

O arcabouço clássico de formação de pares em epidemiologia de ISTs (Dietz &
Hadeler; Kretzschmar & Dietz sobre concorrência) está citado aqui **de memória
e precisa ser conferido** antes de entrar em qualquer texto: a busca
bibliográfica ficou pendente de autorização.

### A proposta

Acrescentar formação e dissolução de parcerias. Cada fêmea tem um conjunto de
parceiros **atuais**. A cada semana, cada parceria existente copula com certa
probabilidade e se dissolve com outra. Se sobrar espaço abaixo do teto, ela
procura: encontra machos, aplica os dois passos, e pode formar uma parceria
nova.

Isso dá as três coisas que a literatura aponta: cópulas repetidas com o mesmo
parceiro, que é o que transmite; concorrência, vários parceiros ao mesmo tempo;
e rotação, que é o que leva a infecção de um grupo a outro.

E o melhor: **a parte de escolha de parceiro não muda nada**. Continua sendo o
`mate_with_survivors` com os dois passos, a curva de preferência e o h. O que
se acrescenta é a persistência, que é a parte epidemiológica.

Dois parâmetros novos, os dois com significado biológico claro: quantas vezes
por semana copula um casal estabelecido, e quanto dura uma parceria. Os valores
não devem ser inventados por mim: saem da literatura, e essa é a busca que está
pendente.

---

## A regra dos dois passos, e a alternativa que não escolhemos

Uma dúvida que apareceu e vale registrar, porque muda muito os números.

Na regra atual, cada macho encontrado **passa ou não passa por separado**, com a
sua própria probabilidade P_ij, e só depois, entre os que passaram, a fêmea fica
com o de maior P. A semana fica em branco quando nenhum dos encontrados passa, e
a probabilidade disso é o produto de (1 - P) sobre os encontrados. Com dez
machos de P = 0.1 cada, 35% das semanas ficam vazias.

A alternativa considerada era identificar o melhor dos encontrados e só então
decidir sobre ele. Com os mesmos dez machos de P = 0.1, isso daria 10% de
semanas com acasalamento em vez de 65%. É uma diferença enorme, e não é um
detalhe de implementação: a primeira diz que a fêmea avalia cada macho contra o
seu critério e fica com o melhor dos aceitáveis; a segunda diz que ela só
considera o melhor.

Ficamos com a de dois passos, porque é a dos Estudos 1 a 4, o que mantém a
comparabilidade, e porque faz mais sentido que uma fêmea que encontrou dez
machos considere mais de um.

---

## O que fica em aberto

1. Implementar formação e dissolução de parcerias, e recalibrar beta com a
   estrutura nova, porque com parcerias persistentes o número de cópulas sobe
   muito e o beta atual passa a ser alto demais.
2. Fazer a busca bibliográfica para os valores de duração de parceria e
   frequência de cópula, em vez de escolhê-los a olho.
3. Decidir entre uma infecção aguda (gamma alto, temporada curta) e uma crônica
   (gamma baixo, temporada longa). É uma afirmação sobre que doença estamos
   modelando e vai nos Métodos.
4. `encontros = 10` foi escolha minha: quantos machos uma fêmea encontra numa
   semana é o tipo de número que a Soly julga melhor do que eu.
