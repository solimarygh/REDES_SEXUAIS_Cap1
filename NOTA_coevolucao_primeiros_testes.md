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

## Onde isto deixa o Estudo 4

O motor está de pé e os testes estruturais passam, mas ele **não pode rodar como
está**: com as duas características livres, a segregação alimentada pela
variância total não tem freio, e qualquer resultado sairia contaminado. Uma
rodada dos 12.960 cenários foi lançada e interrompida por isso.

Duas saídas, e a escolha é uma pergunta para o Miudo:

**Acompanhar a variância génica à parte.** É o que o modelo infinitesimal
estrito faz. A variância de segregação deixaria de ser recalculada da variância
total realizada a cada geração e passaria a seguir a sua própria dinâmica, com
erosão por deriva e entrada por mutação. É a correção certa, e a mais trabalhosa.

**Estimar a génica a partir da total e do assortamento observado.** Sob
acasalamento assortativo há uma relação clássica entre as duas (Wright 1921;
Crow e Felsenstein 1968), e nós já gravamos `cov_casais`, que dá a correlação
entre os pares. Seria uma correção barata usando o que já temos, ao custo de
depender de um resultado de equilíbrio que a nossa população pode não ter
alcançado.

Os quatro pontos de desenho do Estudo 4 continuam abertos e estão em
`NOTA_material_removido_2026-08-16.md`. Mas nenhum deles importa antes deste:
não adianta discutir o gradiente de k num motor que infla a variância sozinho.

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
