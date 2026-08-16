# Material tirado da nota, para revisar depois

Este arquivo guarda o trecho que saiu de `NOTA_quatro_estudos.md` em 16 de agosto
de 2026, quando a nota foi enxugada para ficar legível para a Erika e o Miudo.
Nada aqui foi descartado por estar errado: saiu por ser detalhe demais para o
documento de leitura, ou por tratar de decisões que ainda não foram tomadas.

Está preservado com o formato original, tabelas incluídas, para poder voltar
inteiro à nota, ir para os Métodos do paper, ou virar material suplementar.

**O que vale revisar aqui, em ordem de urgência:**

1. **Os quatro pontos de desenho da Co-evolução**, que continuam sem decidir: o
   gradiente de k, se três níveis de variância inicial bastam, se vale registrar
   `cov_casais` além de `cov_zp`, e o que fazer com a explosão numérica do traço.
2. **A proposta de medir a assimetria em vez de impô-la**, com as nove
   combinações cruzadas de sigma_init, que era o desenho que sairia da análise
   diagonal.
3. **A tabela de parâmetros e a lista de métricas**, que provavelmente têm de
   voltar em alguma forma, porque são referência de consulta.
4. **A tabela de correspondência com o código**, idem: é o que permite verificar
   cada afirmação da nota.

Atenção a uma coisa ao reaproveitar: os números da análise diagonal vêm da
rodada com a regra sequencial. Com o best-of-n eles precisam ser refeitos antes
de irem para qualquer lugar definitivo.

---

O que o Controle mostrou (`10_Analise_Diagonal.R`, sobre os 70.560
cenários da superfície completa): a divergência entre as quatro curvas
de preferência, medida como a distância média ao centroide delas no
espaço das quatro métricas padronizadas, foi modelada em função da
posição no plano. O regime de busca domina: A_max, k e seleção natural
sozinhos explicam R\^2 = 0.679. Sobre essa base, o que cada termo de
dispersão acrescenta é:

| Termo | R\^2 parcial (dentro do regime de busca) | R\^2 (agregado nas 49 células) |
|------------------------|------------------------|------------------------|
| Assimetria, `log(sigma_z / sigma_p)` | **0.428** | **0.639** |
| Descasamento, `abs(log(sigma_p / sigma_z))` | 0.103 | 0.154 |
| Máximo, `max(sigma_p, sigma_z)` | 0.049 | 0.074 |
| Variabilidade total, `sqrt(sigma_p^2 + sigma_z^2)` | 0.020 | 0.030 |

Ou seja: o que importa não é quanta variabilidade existe, é de que lado
ela está. A divergência é máxima quando as fêmeas são homogêneas e os
machos variados. Das 37 células cuja divergência ultrapassa o máximo
alcançado pela diagonal, todas têm sigma_p baixo e sigma_z alto, e
nenhuma o contrário. A leitura biológica é direta. Quando todas as
fêmeas querem a mesma coisa, a geometria da curva se traduz sem ruído em
quem acasala com quem; quando as fêmeas discordam entre si, a variação
individual delas borra a assinatura. E é preciso haver machos variados
para que exista algo a discriminar.

Repare na diferença entre as duas primeiras linhas da tabela. As duas
medem a repartição entre os sexos, mas o descasamento em valor absoluto
trata como equivalentes duas situações biologicamente opostas, fêmeas
homogêneas com machos variados e o contrário, e por isso subestima as
duas. É preciso medir com sinal.

Saiu daí um resultado colateral que vale para o paper. O espalhamento da
poliandria realizada entre as curvas acrescenta R\^2 parcial de 0.0097,
e somado à assimetria acrescenta 0.0003, com AIC pior. A divergência
entre curvas de preferência não é, portanto, um artefato de densidade de
rede. A ressalva é que o modelo base já contém A_max e k, que são os
maiores determinantes do grau realizado, então o que este teste mostra é
que a densidade residual não explica nada. Não é uma análise de mediação
completa.

Só que nada disso pode ser imposto em Co-evolução. Como as duas
características são herdáveis, os dois sigmas são apenas condição
inicial (ver a previsão sobre a variância inicial, acima), e a
assimetria da geração 50 não é a que fixamos na geração 1.

Isso não anula o resultado do Controle, muda o seu papel. Ele é um fato
sobre a regra de acasalamento, não sobre o desenho: dada uma população
com estas dispersões, as curvas divergem isto. Vale em qualquer geração
de qualquer estudo, porque as quatro usam a mesma `mate_with_survivors`.
O que deixa de valer é usá-lo para desenhar a grade de sigma_init.

A proposta, então, é medir em vez de impor. A assimetria realizada é
calculável a cada geração a partir do que já gravamos:

```         
assimetria_realizada(t) = 0.5 * log( varz_pop(t) / varp_pop(t) )
```

Ela entra na análise como covariável geração a geração, e a pergunta
passa a ser se a relação que o Controle encontrou se mantém quando as
duas características evoluem. Manter-se ou não é resultado.

Para a condição inicial bastam três níveis bem separados de variância
(0.5, 1.0 e 2.0), porque o que se procura ali é o limiar de ignição
descrito acima, e não uma curva de resposta. Mas os três níveis vão
cruzados entre os dois sexos, e não ao longo da diagonal. A razão é que
a geração 1 de Co-evolução é uma situação de tipo controle, onde a
assimetria inicial afeta de verdade a rede que se forma, e a pergunta em
aberto é se esse efeito se propaga ou se dissolve. Só o cruzamento
permite perguntá-lo; a diagonal fixaria a assimetria inicial em zero e a
pergunta desapareceria.

As nove combinações, ordenadas pela assimetria. As duas colunas da
direita são as grandezas definidas no vocabulário: a norma diz quanta
variação há, a assimetria diz de que lado está.

| sigma_p | sigma_z | Assimetria log(sigma_z/sigma_p) | Norma sqrt(sigma_p^2+sigma_z^2) |   |
|---------------|---------------|---------------|---------------|---------------|
| 2.0 | 0.5 | -1.39 | 2.06 | fêmeas muito variadas, machos homogêneos |
| 1.0 | 0.5 | -0.69 | 1.12 |  |
| 2.0 | 1.0 | -0.69 | 2.24 |  |
| 0.5 | 0.5 | 0.00 | 0.71 | a diagonal, pouca variação |
| 1.0 | 1.0 | 0.00 | 1.41 | a diagonal, média |
| 2.0 | 2.0 | 0.00 | 2.83 | a diagonal, muita |
| 0.5 | 1.0 | +0.69 | 1.12 |  |
| 1.0 | 2.0 | +0.69 | 2.24 |  |
| 0.5 | 2.0 | +1.39 | 2.06 | fêmeas homogêneas, machos variados |

São cinco valores de assimetria e seis de variabilidade total. As três
linhas do meio são a diagonal que havíamos proposto: percorre a norma de
0.71 a 2.83 e deixa a assimetria presa em zero, exatamente ao contrário
do que interessa. A última linha é o canto onde o Controle encontrou a
divergência máxima, e o desenho diagonal a deixaria de fora por
completo.

Neste desenho a assimetria com sinal e a norma ficam exatamente
descorrelacionadas (r = 0), porque cada assimetria positiva tem o seu
espelho negativo com a mesma norma e as contribuições se cancelam. Os
dois efeitos podem então ser estimados separadamente, sem colinearidade,
que era o risco de qualquer redução. Um limite honesto: as assimetrias
extremas (mais e menos 1.39) só aparecem com norma 2.06, e não há como
evitar isso com três níveis.

O desenho fica em 4 curvas x 9 combinações x 3 A_max x 3 k x 2 regimes x
20 réplicas = 12.960 cenários, cerca de um quinto a mais que Fêmeas
variando e Machos variando, e menos de um quinto da superfície completa.

E daqui sai uma previsão que liga as duas coisas. Em Co-evolução o traço
está sob seleção de viabilidade e sob seleção sexual, enquanto a
preferência não recebe seleção direta nenhuma. Se sigma_z erodir mais
depressa que sigma_p, a assimetria realizada deriva para valores
negativos, e o Controle diz que essa é a região de divergência baixa. A
previsão é que a assinatura topológica das curvas de preferência se
desvaneça ao longo das gerações, a menos que o runaway se acenda e
reponha variância no traço. A persistência da assinatura seria, ela
mesma, um indicador de que o ciclo de Fisher está ativo.

### Código proposto

O código está em `Fase_Coevolucao_PROPOSTA.R`, e não aqui, para esta
nota continuar sendo um documento de leitura. Nada nele roda ao dar
source: é a proposta escrita, não o estudo.

Ele substitui o conteúdo de `Fase_Coevolucao.R` quando os quatro pontos
abaixo estiverem decididos. O motor reaproveita tudo o que já existe em
`01_metricas_e_utilitarios.R` (`mate_with_survivors`,
`calc_metrics_from_M`, `selecionar_machos_adultos`, `rodar_cenarios`), e
o que é novo em relação ao rascunho são as quatro decisões do modelo, o
registro da covariância dentro dos casais (`cov_casais`) e o bloco de
desenho experimental.

Dois pontos do código que vale ter em mente ao lê-lo. O primeiro é que
os filhotes são amostrados por índice, com um único sorteio, e os
vetores de z e de p são indexados pelo mesmo `idx`: é isso que mantém o
par de cada filhote junto e permite a covariância existir. O segundo é
que o pool genotípico registrado é o censo adulto, e não a população
pré-seleção, porque aqui a viabilidade sobre os machos deixa de ser
neutra em relação a p, já que z e p estão correlacionados.

**Quatro pontos para discutir antes de rodar.**

**1. O gradiente de k**, que é o mais urgente. Como está detalhado na
seção sobre a interação entre A_max, k e a curva de preferência, das
nove células do cruzamento A_max por k, as com A_max = 10 e k igual a 10
ou 20 não são tratamentos distintos: nelas o k nunca é atingido e o que
sobra é sempre "ela acasala com quem aceitar entre dez machos". Copiar o
desenho de Fêmeas variando e Machos variando gastaria cenários em
células que não separam nada. Três saídas, em ordem crescente de
ambição: (a) manter o cruzamento como está, para conservar a
comparabilidade com os outros estudos, e apenas declarar a limitação;
(b) substituir o k fixo por um k proporcional a A_max, de modo que o
gradiente de poliandria seja o mesmo em todos os níveis de custo de
busca; (c) deixar o k de fora de Co-evolução, já que ele foi varrido nos
outros dois, e usar os cenários economizados para outra coisa. A opção
(a) é a mais conservadora; a (c) é a que aproveita melhor o tempo.

**2. Os três níveis de variância inicial bastam?** A previsão é de
limiar e não de dose, o que justifica três níveis bem separados. Mas se
o limiar cair entre dois deles, saberemos que existe e não onde está.
Vale acrescentar um quarto nível, ou é melhor localizá-lo depois, com
uma varredura fina só na curva de preferência onde ele aparecer?

**3. A `cov_casais`**, que mede a covariância entre traço e preferência
dentro dos casais que efetivamente acasalaram. É o passo anterior na
cadeia causal, acasalamento assortativo primeiro e covariância genética
depois, e permite separar os dois. Vale registrar as duas ou é
redundante?

**4. A explosão numérica.** Se o runaway aparecer com a curva sigmoide e
sem seleção natural, o traço pode crescer sem limite. Em Fêmeas variando
e Machos variando isso não acontecia porque só uma característica
evoluía. Talvez valha registrar um indicador de fuga, por exemplo a
geração em que a média do traço passa de algum múltiplo de phi, em vez
de deixar a réplica correr até a geração 100 sem aviso.

**Estado.** Motor rascunhado em `Fase_Coevolucao.R`, com os pontos de
atualização listados acima ainda pendentes. Nada rodado, aguardando a
discussão dos quatro pontos de desenho.

------------------------------------------------------------------------

## A interação entre A_max, k e a curva de preferência

Este ponto precisa ficar explícito porque afeta a leitura de todos os
estudos já rodados e, principalmente, a escolha de parâmetros de
Co-evolução, que ainda está aberta.

O parâmetro k não é o número de parceiros, é um teto. O número de
parceiros que uma fêmea de fato consegue é

```         
parceiros = min( k , número de machos que ela aceitou entre os A_max avaliados )
```

e, como a amostragem é sem reposição, ela nunca pode acasalar com mais
machos do que os que avaliou. Nos cenários com A_max = 10 e k = 20,
portanto, o k é inalcançável por construção: o máximo absoluto é 10.
Isso não é um defeito do modelo, é exatamente o custo de busca que
queremos representar, mas significa que o efeito de k não pode ser lido
isoladamente do de A_max.

E o teto morde muito antes do que o limite aritmético sugere, porque ela
não acasala com os dez que avaliou, acasala com os que aceitou entre
esses dez. Com A_max = 10 e uma taxa média de aceite de 0.5, o número
esperado de aceites é 5: mesmo o cenário k = 5 já fica no limite, e o
cenário k = 10 exigiria que ela aceitasse todos os dez.

O agravante é que a taxa de aceite depende da curva de preferência, o
que transforma uma interação entre dois fatores de desenho numa
interação com a variável de interesse do paper. Tomando s = 2 e sigma_p
= sigma_z = 1.0, a probabilidade média de aceite por macho avaliado é
aproximadamente:

| Curva de preferência | Fórmula                       | Aceite médio |
|----------------------|-------------------------------|--------------|
| Aleatória            | P = 0.5                       | 0.50         |
| Sigmoide             | P = 1 / (1 + exp(-s (z - p))) | 0.50         |
| Gaussiana            | P = exp(-s (z - p)\^2)        | 0.33         |
| U-shaped             | P = 1 - exp(-s (z - p)\^2)    | 0.67         |

(Para a gaussiana, a diferença z - p tem variância sigma_z\^2 +
sigma_p\^2, e a média de exp(-s d\^2) para d normal de variância v é 1 /
sqrt(1 + 2 s v). A u-shaped é o complemento.)

Os números medidos (`00_teste_motores.R`, uma réplica por célula, sem
seleção natural). Em cada célula, a poliandria realizada e, entre
parênteses, a proporção que atingiu o k nominal:

| A_max | curva     | k = 5       | k = 10       | k = 20       |
|-------|-----------|-------------|--------------|--------------|
| 200   | gaussiana | 4.98 (100%) | 9.91 (98%)   | 19.68 (95%)  |
| 200   | aleatória | 5.00 (100%) | 10.00 (100%) | 20.00 (100%) |
| 200   | U-shaped  | 5.00 (100%) | 10.00 (100%) | 20.00 (100%) |
| 40    | gaussiana | 4.83 (93%)  | 9.15 (79%)   | 13.08 (10%)  |
| 40    | aleatória | 5.00 (100%) | 10.00 (100%) | 18.91 (62%)  |
| 40    | U-shaped  | 5.00 (100%) | 10.00 (100%) | 19.90 (94%)  |
| 10    | gaussiana | 3.32 (26%)  | 3.56 (0%)    | 3.51 (0%)    |
| 10    | aleatória | 4.45 (66%)  | 5.15 (0%)    | 5.10 (0%)    |
| 10    | U-shaped  | 4.78 (84%)  | 6.55 (4%)    | 6.89 (0%)    |

Os números seguem uma regra simples: a poliandria realizada é
aproximadamente `min(k, A_max x taxa de aceite)`. Confira na faixa de
A_max = 10, onde o teto nunca ata: 10 x 0.33 = 3.3 contra 3.56 medido na
gaussiana, 10 x 0.50 = 5.0 contra 5.15 na aleatória, 10 x 0.67 = 6.7
contra 6.55 na U-shaped. É de passagem uma validação do motor, que se
comporta como a teoria prevê.

A conclusão prática é forte: com A_max = 10, as células k = 10 e k = 20
não são dois tratamentos distintos de poliandria, são o mesmo
tratamento, que na prática é "ela acasala com quem aceitar entre dez
machos". O gradiente de poliandria simplesmente não existe nessa faixa
de A_max. E com A_max = 40 o problema não desapareceu de todo: na curva
gaussiana só 10% das fêmeas chega a k = 20, enquanto na U-shaped chegam
94%.

Com A_max = 200, em compensação, está tudo limpo. Todas as curvas
atingem o k, e o grau realizado é idêntico entre elas (5.00, 10.00,
20.00), ou seja, a densidade da rede está equiparada. Isso dá um caminho
analítico direto, descrito na seção sobre as hipóteses.

Uma nota metodológica: as estimativas analíticas que fizemos antes
destes números (21%, 2%, 92%, 99% nas células críticas) erraram de forma
sistemática, sempre para baixo na gaussiana e para cima na U-shaped. O
cálculo binomial trata todas as fêmeas como iguais, mas o pico p varia
entre elas: uma fêmea com p perto de 5, onde estão quase todos os
machos, aceita muito mais que a média, e uma com p extremo aceita muito
menos. Isso gera sobredispersão, e as caudas é justamente onde o teto é
ou não atingido. Valem os números medidos.

Duas consequências para a análise, então.

Primeira, o k realizado difere sistematicamente entre curvas de
preferência, o que é um confundimento direto sobre a H1. Se a gaussiana
e a u-shaped produzem topologias diferentes, uma parte dessa diferença
pode vir simplesmente de as fêmeas da u-shaped terem mais parceiros, e
não da geometria da escolha. Densidade de arestas afeta modularidade,
aninhamento e centralização.

Segunda, o efeito de A_max e o de k estão parcialmente confundidos entre
si, então nenhum dos dois pode entrar num modelo como fator aditivo sem
o termo de interação, e a interpretação de qualquer coeficiente marginal
de k é enganosa.

Uma ressalva sobre esses números: são aproximações analíticas com s fixo
em 2, ignorando o truncamento em zero, a variação de s entre fêmeas e o
efeito da seleção natural, que estreita a distribuição dos machos e
portanto aumenta a taxa de aceite da gaussiana. Servem para mostrar a
ordem de grandeza do problema, não como estimativa exata.

A decisão que tomamos foi tratar k como apetite, e não como cota. A
fêmea busca até k parceiros; quantos consegue depende da disponibilidade
e da própria seletividade. A poliandria realizada passa a ser variável
resposta, e não parâmetro. Três razões sustentam isso. É o que o código
sempre fez, porque `matings_per_female` é condição de parada e não cota
garantida. Converte as células degeneradas nas mais interessantes: A_max
= 10 com k = 20 não é lixo, é poliandria frustrada, e comparada com
A_max = 200 e k = 20 é exatamente o teste da H3. E é mais defensável
biologicamente, porque nenhum organismo tem garantido o seu número de
parceiros.

O reenquadramento exige medir, e por isso `calc_metrics_from_M` passou a
gravar `grau_medio_femeas` (a poliandria realizada),
`prop_femeas_atingiu_k` e `arestas`. Nenhuma delas podia ser recuperada
dos dados antigos: o Is é calculado sobre os machos e não permite
reconstruir o grau das fêmeas. Foi a razão mais forte para refazer os
três estudos.

O desenho fatorial fica intacto, os 3 por 3 de A_max e k. Chegou a ser
proposto cortar a célula A_max = 10 com k = 10, por ser estatisticamente
indistinguível de k = 20, mas a proposta foi retirada: agora que a
poliandria realizada é medida, a convergência entre as duas células é
justamente a evidência de que k é apetite e não cota. Manter o fatorial
balanceado vale mais que os 11% de computação economizados.

Fica uma dúvida de inferência causal, para levar ao Miudo. Se o grau
realizado depende da curva de preferência, e o usamos como covariável
para comparar curvas, estamos controlando por um mediador e não por um
confundidor: a curva causa o grau realizado e a topologia, então
controlar remove parte do efeito causal que queremos medir. A saída
provável é reportar as duas coisas, o efeito total da curva e o efeito
líquido de densidade, declarando que respondem a perguntas diferentes.

------------------------------------------------------------------------

## O tamanho do pool de machos não é constante

Esta seção nasceu de uma observação sobre o rótulo de A_max, mas o
problema de fundo acabou sendo outro, e maior.

Comecemos pelo que não é um problema. Descrevemos os níveis de A_max
como "100%, 20% e 5% de N = 200". Os rótulos percentuais estão errados
quando a seleção natural está ligada, mas o tratamento em si continua
comparável: A_max = 40 quer dizer "ela avalia 40 machos" com a seleção
ligada ou desligada, e A_max = 200 quer dizer "ela avalia todos os
disponíveis" nos dois casos, porque o código faz
`min(A_max, número de sobreviventes)`. A correção aqui é só de rótulo:
descrever A_max em número absoluto de machos avaliados, e não em
porcentagem. O que muda é a interpretação de A_max = 200, que não é um
terceiro ponto equidistante num gradiente, e sim a condição de
saturação, "sem restrição de busca". Por isso A_max deve entrar nos
modelos como fator, nunca como covariável contínua.

O problema de verdade é outro, e só existia com a seleção natural
ligada. Com ela desligada, o código fazia
`survive <- rep(TRUE, N_machos)` e os 200 machos passavam todos, de modo
que o pool era constante. Com ela ligada, o número de machos disponíveis
muda de cenário para cenário, porque a viabilidade remove uma fração que
depende de sigma_z. A fração que sobrevive é aproximadamente
`1 / sqrt(1 + 2 gamma sigma_z^2)`, ou seja, com gamma = 0.2:

| sigma_z                       | 0.2 | 0.5 | 0.8 | 1.0 | 1.2 | 1.5 | 2.0 |
|-------------------------------|-----|-----|-----|-----|-----|-----|-----|
| Machos sobreviventes (de 200) | 198 | 191 | 178 | 169 | 159 | 145 | 124 |

O pool encolhe 37% ao longo do gradiente, e isso muda as dimensões da
matriz sobre a qual as métricas são calculadas. Modularidade,
aninhamento e centralização dependem do tamanho da matriz, e não apenas
da sua densidade, então qualquer tendência ao longo de sigma_z já
estaria contaminada só por isso, sem nenhuma relação com a escolha
feminina.

Convém tomar cuidado com o argumento de densidade, que é mais fraco do
que parece. Seria tentador dizer que o mesmo número de arestas se
reparte entre menos machos e que o grau médio dos machos sobe, mas isso
não se sustenta, por duas razões. O número de fêmeas na rede também não
é constante, porque as que não acasalam são excluídas do cálculo das
métricas. E o número de arestas cai com sigma_z, porque a taxa de aceite
diminui quando os machos estão mais dispersos: mesmo depois da
viabilidade estreitar a distribuição, o desvio padrão dos sobreviventes
ainda sobe de cerca de 0.20 para cerca de 1.24 ao longo do gradiente.
Numerador e denominador caem os dois, e sem medir não dá para afirmar
qual ganha.

Há uma distinção importante entre os dois sumiços. As fêmeas somem da
rede por um resultado biológico que queremos medir, o de não terem
acasalado, e ele fica gravado à parte em `prop_femeas_sem_acasalar`. Os
machos sumiam por um artefato de onde tínhamos colocado o passo da
viabilidade, e em quantidade que dependia justamente do eixo do
experimento.

Onde isso morde: em Fêmeas variando pouco, porque sigma_z fica fixo em
1.0 e o pool é estável. No Controle e em Machos variando morde de
frente, porque ali sigma_z é o eixo do experimento, e parte de qualquer
tendência das métricas ao longo dele, nos cenários com seleção natural
ligada, era só o pool encolhendo.

Pior ainda, o confundimento estava alinhado com o contraste que
interessa. Como o pool só encolhia com a seleção natural ligada,
comparar os dois regimes não comparava apenas "há seleção" contra "não
há": comparava também "há menos machos" contra "há 200". Um artefato de
densidade teria se apresentado como um efeito da seleção natural, que é
o pior lugar possível para ele estar.

O lado prático disso é bom: para a metade do desenho sem seleção
natural, o censo constante é uma mudança cosmética. O código antigo
entregava 200 machos e o novo entrega 200 machos, com a mesma
distribuição.

A solução foi o censo de adultos constante. A seleção de viabilidade
passou a agir sobre juvenis, antes do censo. Cada geração começa com
vários machos juvenis por vaga, a viabilidade age sobre eles, e o censo
adulto fica sempre em 200 machos. A seleção natural continua mudando
quais machos estão disponíveis, que é o efeito que nos interessa, e
deixa de mudar quantos, que era o confundimento. Biologicamente é a
formulação mais comum, aliás: a mortalidade de viabilidade age sobre
juvenis e o censo é de adultos.

Vale registrar as duas alternativas que foram descartadas, porque o
argumento pode voltar.

Registrar e controlar, ou seja, gravar `n_machos_surv` e usá-lo como
covariável nos modelos. Custo zero e sem mudar o modelo, mas deixa o
confundimento na estrutura dos dados e obriga a confiar num ajuste
estatístico para algo que dá para resolver na origem. Foi a recomendação
inicial, feita quando ainda supúnhamos que os três estudos não seriam
refeitos. A partir do momento em que o recorrido completo entrou em
cena, ela deixou de fazer sentido. A coluna `n_machos_surv` continua
sendo gravada, mas agora como verificação e não como correção.

Redefinir A_max como proporção do pool. Tornaria o custo de busca
comparável entre regimes, mas não resolve o problema principal, que é a
densidade, e além disso deixaria A_max e o tamanho do pool colineares
por construção.

Sobre a comparabilidade entre estudos, que foi a objeção original ao
censo constante: mudar a regra faria Co-evolução deixar de ser
comparável com Controle, Fêmeas variando e Machos variando, e a
inferência inteira depende dessa comparação, já que a diferença entre
Co-evolução e o Controle é o que a co-evolução acrescentou, e essa
subtração não vale se os dois também diferirem na demografia. A objeção
era correta, mas valia apenas enquanto os três primeiros estudos
ficassem como estavam. Como o recorrido completo vai acontecer de
qualquer maneira, o censo constante passa a valer para os quatro e a
comparabilidade fica intacta.

Em resumo, as decisões de modelo desta rodada foram quatro: 1.
Amostragem sem reposição. A_max passa a ser literalmente o número de
machos distintos que a fêmea avalia. Antes, com reposição, ela
reencontrava o mesmo macho várias vezes e via menos machos distintos do
que o parâmetro sugeria. 2. Sem regra de escape. Antes, uma fêmea que
não aceitasse ninguém acasalava com o último macho avaliado, de modo que
todas acasalavam. Agora ela fica sem acasalar e deixa zero filhotes. Sem
essa mudança não existiria variância de sucesso reprodutivo entre
fêmeas, e o Machos variando seria impossível. 3. Fecundidade neutra. A
poliandria não aumenta o número de filhotes; ela só distribui a
paternidade entre os parceiros. 4. Variância de segregação proporcional
(modelo infinitesimal de Falconer e Mackay). O desvio dos filhotes em
relação à média dos pais tem variância igual a metade da variância
parental, em vez de um ruído fixo. A conta está logo abaixo. O modo
antigo continua disponível no código (`segregacao = "fixa"`) para
comparação, e o modo usado fica registrado numa coluna da saída de cada
simulação.

A conta da segregação, passo a passo. Cada filhote recebe

```         
z_filhote = (z_pai + z_mae)/2 + D
```

O primeiro termo é a média dos dois pais. Se os pais forem tomados ao
acaso na população, cada um com variância V, então
`Var((z_pai + z_mae)/2) = (V + V)/4 = V/2`: a média de dois números
varia menos que um número sozinho. É por isso que a herança de ponto
médio, sozinha, corta a variância pela metade a cada geração.

O segundo termo, D, é o desvio de segregação: o quanto cada filhote se
afasta da média dos pais, por ter calhado de receber uma metade dos
genes de cada um e não a outra. É ele que faz irmãos diferirem entre si,
e toda a diferença entre os dois modos está em quanto vale a sua
variância.

Com ruído fixo, `Var(D) = eps^2`, um número que nós escolhemos e que não
depende de nada. Então `V' = V/2 + eps^2`, e repetindo isso geração após
geração V converge para o ponto fixo `V* = V*/2 + eps^2`, ou seja
`V* = 2 eps^2`. Com eps = 0.2 dá 0.08, que é exatamente o valor em que a
variância travava.

No modelo infinitesimal, `Var(D) = V/2`, proporcional à variância que
existe entre os pais. Então `V' = V/2 + V/2 = V`: a metade que o
blending tira é exatamente a metade que a segregação repõe.

O infinitesimal é o certo por um motivo que se vê num caso limite. Com
ruído fixo, uma população em que todos os pais fossem idênticos ainda
produziria filhotes variados, do nada. Isso é impossível: se não há
variação entre os pais, não pode haver variação entre irmãos. O
infinitesimal respeita isso, porque faz a variação entre irmãos ser
proporcional à que existe na população. É o resultado clássico de
Falconer e Mackay: um pai transmite metade dos seus genes ao acaso, e a
variância entre os gametas que ele pode produzir é V_A/2.

No código isso é `rnorm(n, 0, sqrt(var_pais / 2))`, mais um termo
mutacional pequeno (`mut_sd = 0.05`) que repõe o que a deriva remove ao
longo de muitas gerações.

O que a mudança comprou não foi mais variância, foi que o equilíbrio
passasse a depender da seleção. Com ruído fixo, `V* = 2 eps^2` dava o
mesmo em todos os cenários: a mesma curva de preferência, o mesmo
sigma_p, com ou sem seleção natural, sempre 0.08. A pergunta da H2 tinha
a resposta escrita de antemão, e a resposta era "não" por construção.
Aumentar eps não resolveria nada: mudaria o número e manteria o
artefato, porque o piso continuaria sendo idêntico em todo lado. Com o
infinitesimal, cada curva de preferência, cada sigma e cada regime de
seleção natural chegam a um equilíbrio diferente, e é isso que torna a
H2 respondível.

Sobre o valor da mutação: com `mut_sd = 0.05`, a entrada mutacional por
geração é 0.0025. Com uma variância do traço da ordem de 1, isso dá uma
heredabilidade mutacional em torno de 2.5 x 10\^-3, que está na faixa
empiricamente reportada para caracteres quantitativos, entre 10\^-3 e
10\^-2. Não é um número escolhido ao acaso. A ressalva é que a
heredabilidade mutacional se define sobre a variância ambiental, e aqui
o traço não tem componente ambiental separada, então a comparação é
aproximada.

Há uma limitação da nossa implementação que precisa ser declarada. O
resultado `Var(D) = V_A/2` não vale sempre: ele supõe acasalamento
aleatório, equilíbrio de ligamento e pais não aparentados. Três
situações o quebram, e as três estão presentes aqui. O acasalamento
assortativo gera desequilíbrio de ligamento positivo, e a variância
total da população passa a ser maior que a génica, sendo a génica a que
governa a segregação. A seleção gera desequilíbrio negativo (efeito
Bulmer) e empurra na direção contrária. E em população finita a
segregação decai com o parentesco acumulado, como `(1 - F) V_A/2`.

O nosso `var_pais <- var(c(male_z_surv, female_z_gen))` usa a variância
total realizada do pool parental, com os machos já pós-seleção,
misturando as duas componentes em vez de separá-las. O modelo
infinitesimal estrito acompanha a variância génica à parte.

Os dois desvios vão em sentidos opostos e se compensam em parte, mas não
se compensam igual nas quatro curvas de preferência, porque cada uma
gera uma quantidade diferente de acasalamento assortativo: a gaussiana
gera muito, a aleatória nenhum. Isso poderia produzir diferenças
aparentes de manutenção de variância entre curvas que fossem de
implementação e não biológicas, bem em cima da H2. É verificável
implementando a versão estrita num subconjunto de cenários e comparando,
e está na lista de perguntas para o Miudo.

Quanto às réplicas, são 20 nesta rodada de exploração e mais na rodada
final. São 20 e não mais porque os problemas que motivaram o recorrido
(o teto de k, o pool de machos, o caso degenerado) são vieses
sistemáticos e não ruído: mais réplicas não os tocariam.

------------------------------------------------------------------------

## Parâmetros do modelo

| Símbolo | O que é | Valor |
|------------------------|------------------------|------------------------|
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

Todos os cenários são reprodutíveis: a semente de cada um é
`semente base + índice global do cenário`, definida dentro da tarefa.
Isso vale mesmo quando as réplicas são repartidas entre máquinas
diferentes, porque o índice usado é o do desenho completo e não o da
fatia.

Duas ressalvas sobre reprodutibilidade, que valem para os Métodos. A
primeira é de plataforma: ao rodar o mesmo teste com a mesma semente no
Mac e no servidor Linux, um valor divergiu na segunda casa decimal (5.10
contra 5.09), enquanto as outras 24 comparações saíram idênticas. A
explicação provável é uma diferença de um bit na implementação de
`exp()`, virando uma comparação de aceite que estava no limite. Não é
erro nem viés, cada réplica continua sendo um sorteio válido do modelo,
mas significa que a reprodução exata exige a mesma plataforma, e que
re-simular um cenário para extrair a rede deve ser feito na máquina que
o gerou. A segunda é de versão: a semente só reproduz os dados junto com
o código que os gerou, e o motor mudou várias vezes. Por isso vale
etiquetar o commit de cada rodada.

------------------------------------------------------------------------

## As métricas de topologia da rede

Calculadas a cada geração sobre a rede bipartita de acasalamentos:

-   **Modularidade.** O quanto a rede se divide em grupos que acasalam
    preferencialmente entre si. Calculada com o algoritmo de Louvain
    sobre a projeção não dirigida da rede bipartita. A alternativa seria
    a modularidade bipartida do pacote `bipartite`, que é mais
    defensável mas centenas de vezes mais lenta, e inviável no número de
    redes que geramos. Vale confirmar com o Miudo se a escolha se
    sustenta.

-   **Aninhamento (NODF).** O quanto os parceiros dos machos menos
    procurados são um subconjunto dos parceiros dos machos mais
    procurados, ou seja, o quanto existe uma hierarquia.

-   **Centralização.** O quanto os acasalamentos se concentram em poucos
    indivíduos. Calculada sobre todos os nós, machos e fêmeas juntos.

-   **Oportunidade de seleção sexual (Is).** A variância no número de
    parceiras por macho dividida pelo quadrado da média. Mede o quanto o
    sucesso reprodutivo é desigual entre os machos.

-   **Proporção de fêmeas sem acasalar.** Variável nova nesta rodada. É
    descritiva nos Estudos 1 e 2, mas em Machos variando é o indicador
    direto da força de seleção agindo sobre a preferência.

-   **Poliandria realizada (`grau_medio_femeas`).** O grau médio das
    fêmeas que acasalaram, ou seja, quantos parceiros elas de fato
    conseguiram. Atenção ao denominador: esta média exclui as fêmeas que
    não acasalaram, enquanto `prop_femeas_atingiu_k` é calculada sobre
    TODAS. Os dois denominadores são diferentes de propósito, e como
    `prop_femeas_sem_acasalar` também é gravada, qualquer das duas pode
    ser recalculada na base que se preferir. Sob o reenquadramento de k
    como apetite (ver a seção sobre a interação entre A_max, k e a curva
    de preferência), esta é a variável de poliandria do paper, e não o k
    nominal.

-   **Proporção que atingiu o teto (`prop_femeas_atingiu_k`).** Quantas
    fêmeas chegaram ao k que buscavam. Mede diretamente o quanto o teto
    foi vinculante em cada cenário.

-   **Arestas (`arestas`).** O total de acasalamentos da rede, ou seja,
    a densidade.

-   **Censo adulto de machos (`n_machos_surv`).** Deve ser sempre 200
    com o censo constante; fica gravado como verificação.

-   **Geração de encerramento (`extincao_gen`).** NA quando a réplica
    chegou ao fim.

Quando a rede é pequena ou degenerada demais para uma métrica fazer
sentido (por exemplo, menos de dois machos ou menos de duas cópulas para
o NODF), a métrica devolve NA em vez de zero. Isso é deliberado:
devolver zero introduziria um viés, fazendo parecer que a topologia foi
medida e deu zero, quando na verdade ela não pôde ser medida.

Uma última decisão de cálculo, que é fácil esquecer depois. As fêmeas
que não acasalaram são excluídas do cálculo das métricas de topologia,
porque entrariam como nós isolados e inflariam artificialmente a
modularidade e o número de subgrupos; elas são contabilizadas
separadamente, na proporção de fêmeas sem acasalar. Já os machos com
zero acasalamentos ficam no cálculo, porque eles são justamente o sinal
da seleção sexual (é a variação no sucesso deles que o Is mede).

------------------------------------------------------------------------

## As hipóteses, e qual estudo testa cada uma

Esta formulação substitui a que está em `Paper_JEB_Cl.Rmd` e nos
Métodos, que foi escrita antes de termos o controle e que precisa ser
atualizada. A mudança principal é que nenhuma hipótese se compromete
mais com uma direção que os dados possam desmentir: as direções passam a
ser resultados.

### H1. Os determinantes da estrutura da rede

**A estrutura da rede de acasalamento é determinada por fatores que
atuam em três níveis, e a questão é qual deles domina e como
interagem.**

| Nível | O que é | Fatores |
|------------------------|------------------------|------------------------|
| A regra | como a fêmea escolhe | as quatro curvas de preferência |
| O material | quanta variação existe para escolher | sigma_p, sigma_z, ou os dois |
| A ecologia | quanto se pode buscar e quem está disponível | A_max, k, seleção natural |

Quem testa: o **Controle**, que é o único desenho que cruza os três
níveis por inteiro.

É uma hipótese exploratória, mas não é uma lista: ela é falsificável
porque qualquer um dos três níveis poderia dominar, e cada resposta
conta uma história diferente. Se a regra dominar, a escolha feminina
desenha a rede. Se a ecologia dominar, o custo de buscar importa mais do
que o que as fêmeas querem.

Falta dizer onde entra a variação no pico das preferências femininas,
que é a pergunta que originou o capítulo. Ela é o nível do material,
junto com sigma_z. A literatura quase sempre atribui uma única função de
preferência a toda a população, e por isso não pode nem formular a
pergunta de o que acontece quando as fêmeas discordam entre si. Deixar
sigma_p variar é o que permite fazê-la, e cruzar sigma_p com sigma_z é o
que permite responder se a heterogeneidade feminina tem significado
absoluto ou apenas relativo à variabilidade dos machos.

### H2. A topologia não é epifenômeno

**A topologia da rede prediz a trajetória evolutiva da característica
que estiver livre para evoluir.**

-   **H2a**, com Fêmeas variando: prediz a trajetória do traço do macho.
-   **H2b**, com Machos variando: prediz a trajetória da preferência da
    fêmea.

O espelho deixa de ser uma curiosidade e passa a ser replicação interna:
se a relação for da rede e não da característica em particular, ela tem
que aparecer nos dois lados. Aparecer só num deles também é resultado, e
dos interessantes.

Este é o par de hipóteses que carrega o peso de teste direcional do
paper, já que H1 é exploratória.

### H3. A ecologia modula a cadeia inteira

**Restringir a capacidade de amostragem (A_max) erode a assinatura
topológica e, com ela, as suas consequências evolutivas.**

Não tem estudo próprio: A_max está cruzado nos quatro, então H3
atravessa H1, H2 e H4. É a hipótese que liga a ecologia à evolução.

### H4. Com as duas livres, a topologia governa o ciclo de Fisher

**Quando o traço e a preferência são ambos herdáveis, a topologia da
rede determina se a covariância genética entre eles chega a se
acumular.**

Quem testa: **Co-evolução**, que é o único desenho em que essa
covariância pode existir. A previsão de limiar descrita na seção daquele
estudo entra aqui.

### Uma nota sobre o que o Controle pode e não pode fazer

O Controle caracteriza o que a regra de acasalamento faz sozinha, na
superfície inteira. Fêmeas variando e Machos variando mostram o que
sobra disso depois de 100 gerações, cada um ao longo de uma linha.

Não é "derivar aqui e testar independentemente ali". A geração 1 de
Fêmeas variando é exatamente a linha sigma_z = 1.0 do Controle, e a de
Machos variando é a coluna sigma_p = 1.0, por construção do desenho. O
que os estudos evolutivos acrescentam não é uma amostra independente, é
a resposta a uma pergunta diferente: se a assinatura persiste quando a
característica responde à seleção.

O que é exclusivo do Controle são as células fora dessas duas linhas, e
é justamente onde a divergência entre curvas é máxima.

------------------------------------------------------------------------

## Convenção de nomes entre os estudos

Os motores de Fêmeas variando e de Machos variando fazem a mesma coisa
com características diferentes, mas tinham sido escritos em momentos
diferentes e usavam nomes distintos para os mesmos objetos. Isso
dificultava comparar as duas funções lado a lado, que é justamente o que
a gente precisa fazer para explicar o desenho. Os nomes foram
uniformizados assim:

| O que é                       | Nome padrão                               |
|------------------------------------|------------------------------------|
| Filhotes por fêmea            | `num_filhotes_por_femea`                  |
| Total de filhotes na geração  | `total_filhotes`                          |
| Índice da mãe de cada filhote | `moms`                                    |
| Índice do pai de cada filhote | `dads`                                    |
| Valor paterno e materno       | `z_dads` / `z_moms`, `p_dads` / `p_moms`  |
| Média dos pais                | `midparent`                               |
| Desvio de segregação          | `desvio`                                  |
| Variância parental            | `var_pais`                                |
| Valor dos filhotes            | `z_filhotes` / `p_filhotes`               |
| Vagas da próxima geração      | `vagas`                                   |
| Ruído fixo do modo antigo     | `eps_sd` (era `eps_p` em Machos variando) |

A regra é que a letra da característica não muda. Em Machos variando o
que se herda é a preferência, então continua sendo `p_filhotes` e não
`z_filhotes`: a letra diz qual característica é, e é justamente ela que
distingue um estudo do outro. O que se uniformiza é todo o resto do
nome.

Uma assimetria ficou de propósito: `sigma_p` em Fêmeas variando contra
`sigma_p_init` em Machos variando. Os nomes são diferentes porque as
coisas são diferentes, um é parâmetro imposto a cada geração e o outro é
condição inicial, como está explicado na seção de Machos variando.

O sorteio dos sobreviventes agora é por índice nos três motores. Fêmeas
variando sorteava por valor (`sample(z_filhotes, ...)`) e Machos
variando por índice (`sample(seq_len(total_filhotes), ...)`). Com uma
única característica herdável os dois são equivalentes, porque `sample`
sobre um vetor é implementado como sorteio de índices seguido de
indexação, e portanto consome o mesmo RNG. Mas em Co-evolução só a forma
por índice funciona, então o motor de Fêmeas variando foi padronizado
para ela: assim o padrão do código já está correto quando as duas
características entrarem. Como a mudança mexe numa chamada de sorteio,
vale confirmar num cenário com semente fixa que o resultado sai
idêntico.

------------------------------------------------------------------------

## O que olhar primeiro quando a rodada nova terminar

Esta seção é um bilhete para nós mesmos. A rodada anterior, ainda com a
regra sequencial, deixou uma observação que vale conferir assim que a
rodada best-of-n estiver pronta. Nada aqui é resultado: é uma coisa
vista de relance numa figura, com dados que já foram substituídos, e
está escrita só para não se perder.

**A diagonal em Fêmeas variando.** Na seção do plano compartilhado (a
que põe os três estudos sobre a grade do Controle), o painel da curva
gaussiana na geração 100 mostrava as células acomodadas sobre uma
diagonal quase perfeita: cada cenário partia de sigma_z = 1.0 e
terminava com a dispersão do traço aproximadamente igual ao sigma_p que
lhe tinha sido imposto. Nas outras curvas não era assim. Na sigmoide a
dispersão colapsava para perto de 0.5 em quase todos os cenários, na
aleatória ficava em torno de 1.0 com deriva pequena, e na disruptiva
ficava espalhada sem padrão claro.

Se isso se confirmar, tem mecanismo plausível: com preferência
estabilizadora cada fêmea acasala com machos próximos do seu próprio
pico, então o conjunto de machos que se reproduz fica repartido segundo
a distribuição dos picos, e os filhotes herdam essa repartição. Com a
segregação infinitesimal a variância não está presa a piso nenhum e pode
se acomodar onde o acasalamento assortativo a levar. É justamente o tipo
de coisa que o ruído fixo escondia.

E havia um segundo pedaço: a cor daquelas células era aproximadamente a
cor das mesmas células no Controle. Se também se confirmar, a leitura é
que a evolução não produziu uma topologia nova, apenas moveu o sistema
para outro ponto da mesma superfície. Para a H2 e a H3 isso seria uma
afirmação forte.

**A erosão de variância sob a regra nova.** Apareceu no teste de fumaça,
e é a segunda coisa a olhar. Num cenário de dez gerações com a curva
sigmoide, A_max = 40 e k = 5, a variância do traço caiu de 0.69 para
0.12, enquanto na rodada anterior, com a regra sequencial, ela se
sustentava. A explicação é direta: com best-of-n e uma curva direcional,
a fêmea fica com os machos de maior traço entre os que avaliou, e como
todas as fêmeas concordam sobre quem é o melhor, poucos machos
monopolizam. Isso soma seleção por truncamento forte e deriva por número
efetivo de pais pequeno, e as duas coisas erodem variância.

Não é um defeito, é o que a regra faz. Mas importa para a H2, porque a
resposta à seleção é proporcional à variância disponível: se ela se
esgotar cedo, a trajetória do traço trava por falta de material e não
por equilíbrio entre forças. Vale olhar a variância ao longo das 100
gerações e ver se ela estabiliza num valor próprio de cada cenário, que
é o que o modelo infinitesimal deveria dar, ou se continua caindo até o
piso mutacional em todos eles. Se for o segundo caso, o valor de
`mut_sd` volta para a mesa.

**Três coisas para conferir antes de acreditar na diagonal.**

Primeiro, se o padrão sobrevive à mudança de regra. Com best-of-n a
fêmea passa a avaliar os A_max machos e a ficar com os melhores entre os
aceitáveis, o que muda a intensidade da seleção sexual e pode muito bem
mover a diagonal, ou desfazê-la.

Segundo, o afastamento da média. Naquela figura ele chegava a 4.63,
quase certamente na sigmoide, onde a média do traço vai para perto de 10
enquanto as preferências continuam sendo re-sorteadas em torno de 5.
Onde isso acontece, a célula não é comparável com o Controle, porque lá
os dois sexos estão sempre centrados em phi. A figura agora reporta esse
afastamento por curva justamente para separar os painéis em que a
comparação vale.

Terceiro, se a diagonal é mesmo diagonal ou um efeito do arredondamento.
A dispersão medida é encaixada nos sete níveis da grade para a figura
sair legível, e convém confirmar o padrão com os valores contínuos antes
de escrever qualquer coisa.

------------------------------------------------------------------------

## O censo de machos sob a regra nova, e o que fazer com ele

Esta seção é sobre uma consequência do best-of-n que só apareceu quando
os dados da rodada nova ficaram prontos. Não é um erro de programação: a
função do censo foi escrita supondo um regime em que o traço fica perto
de phi, e a regra nova empurrou o sistema para fora desse regime.

**O que aconteceu.** Com o best-of-n a seleção sexual ficou bem mais
forte, que era a intenção. Na curva sigmoide isso leva a média do traço
para longe do ótimo ecológico, e como a viabilidade é
`V = exp(-gamma (z - phi)^2)`, ela desaba para todo mundo ao mesmo
tempo. O passo de aceitação e rejeição passa a não devolver praticamente
ninguém, entra a trava de segurança dos 2 machos, e a rede daquela
geração vira 200 fêmeas por 2 machos. Modularidade, aninhamento e
centralização calculados sobre uma matriz dessas não são comparáveis com
os das outras células.

Onde bate: apenas no estudo das fêmeas, e dentro dele apenas nas curvas
sigmoide e u-shaped com seleção natural ligada. No Controle e em Machos
variando o traço é sorteado de novo a cada geração, sempre centrado em
phi, então a viabilidade nunca chega perto de zerar e o censo fica nos
200 em todos os cenários.

**O que 200 deve ser, afinal.** A pergunta de fundo é como tratar a
capacidade de suporte da população, e há duas leituras.

Como **cota**, a população está sempre na capacidade de suporte: os 200
adultos são sempre sorteados, com probabilidade proporcional à
viabilidade, e a seleção decide quais machos e nunca quantos. As redes
ficam sempre comparáveis entre si. Como **teto**, a capacidade de
suporte é um limite que a população pode não alcançar quando está mal
adaptada, o que é biologicamente mais honesto, mas devolve redes de 200
fêmeas por 2 machos.

É a mesma discussão que tivemos sobre k, e vale reparar em que ela se
resolve para o outro lado. Com k decidimos que era teto e não cota,
porque a poliandria realizada continua sendo uma quantidade que se lê e
se reporta. Aqui não: um censo de 2 machos não é uma variável resposta
que se interprete junto com a topologia, é uma condição que impede a
medição.

**O que vamos testar.** A cota, implementada como sorteio sem reposição
de exatamente 200 juvenis com peso proporcional a V. Dois argumentos a
favor. Fica simétrico com o que já fazemos com as fêmeas, que também têm
censo exato de 200 por sorteio, e a única diferença entre os sexos passa
a ser a que interessa, que é a seleção agir sobre eles. E torna a
viabilidade relativa em vez de absoluta: em vez de ninguém sobreviver,
sobrevivem os menos mal adaptados, que é o que acontece numa população
real mal adaptada.

No regime saudável as duas formas são quase a mesma coisa, o que ajuda a
decidir: aceitar e rejeitar e depois sub-amostrar uniformemente entre os
sobreviventes equivale a sortear direto com peso V. A cota não muda a
biologia do que já vínhamos fazendo, é a versão exata e sem ponto de
quebra da mesma coisa.

Na prática são cinco linhas, e o sorteio é feito em escala logarítmica
porque V pode chegar à casa de 1e-40 e estourar por baixo:

```         
chaves <- log(-log(runif(n))) + gamma * (z_juv - phi)^2
order(chaves)[seq_len(N_adultos)]
```

**Duas ressalvas antes de fechar o assunto.**

A primeira é que a mudança altera o fluxo de números aleatórios, então
os três estudos precisam ser refeitos juntos para o conjunto sair de uma
única versão do motor.

A segunda é sobre gamma, e ainda está em aberto. Com gamma = 0.2 e a
regra nova a mortalidade fica altíssima e mesmo assim o traço continua
subindo, o que à primeira vista sugere que a viabilidade está fraca
demais. Mas matar muito e segurar o traço não são a mesma coisa: o que
freia o traço é a diferença de sobrevivência entre indivíduos, e quando
sobram dois machos essa diferença passa a se expressar por um canal
estreito demais. As fêmeas, que também carregam z, nunca passam por
viabilidade nenhuma. Ou seja, parte do escape pode vir do censo ter
colapsado e não de gamma ser pequeno. Só dá para saber depois de rodar
com a cota, e por isso a decisão sobre gamma fica para depois dessa
rodada.

------------------------------------------------------------------------

## Correspondência com o código

Esta nota foi conferida contra os scripts. A tabela abaixo diz onde
verificar cada bloco.

| Afirmação da nota | Onde verificar |
|------------------------------------|------------------------------------|
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
| Co-evolução: rascunho do motor, ainda sem desenho experimental | `Fase_Coevolucao.R` |
| Co-evolução: a versão proposta, que ainda não é o estudo | `Fase_Coevolucao_PROPOSTA.R` |
| Primeira versão descartada do experimento inverso | `Fase_MachoVariando.R`, mantido só como registro |
