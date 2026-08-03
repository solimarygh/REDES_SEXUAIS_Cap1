# Os quatro estudos complementares

Nota de trabalho para discussão com Erika e Paulo (Miudo). Aqui está descrito
**o que cada estudo faz**, não os resultados. Os resultados preliminares vão numa
segunda rodada, depois que a gente concordar que o desenho está claro.

---

## A lógica: por que quatro estudos

Todos os estudos compartilham o mesmo ciclo de vida e as mesmas quatro curvas de
preferência. O que muda entre eles é **quem herda o quê**, ou seja, qual característica
está livre para evoluir. Cada estudo isola uma peça diferente do sistema:

| | Traço do macho (z) | Preferência da fêmea (p) | O que o estudo isola |
|---|---|---|---|
| **1. Sem evolução** | ambiental | congelada | o efeito das regras de acasalamento, sem evolução nenhuma |
| **2. Fêmeas variando** | herdável, EVOLUI | congelada | como a heterogeneidade de preferência molda a evolução do traço |
| **3. Machos variando** | ambiental | herdável, EVOLUI | como a disponibilidade de machos molda a evolução da preferência |
| **4. Co-evolução** | herdável, EVOLUI | herdável, EVOLUI | o feedback entre os dois (Fisher) |

A comparação entre eles é o que dá o poder inferencial: a diferença entre o estudo 2 e
o estudo 1 é o que a evolução do traço acrescenta; a diferença entre o 3 e o 1 é o que
a evolução da preferência acrescenta; e o estudo 4 mostra o que emerge quando os dois
evoluem juntos, que não é a soma dos anteriores.

---

## Estudo 1. Sem evolução (controle nulo)

**Pergunta.** Que topologia de rede as regras de acasalamento produzem por si só, antes
de qualquer resposta evolutiva?

**Como funciona.** Nada é herdado. A cada geração, tanto o traço dos machos quanto a
preferência das fêmeas são re-sorteados das mesmas distribuições. A rede se forma, mede-se
a topologia, e a geração seguinte recomeça do zero. Não há feedback.

**Por que importa.** É a linha de base contra a qual os outros estudos são lidos. Sem ele,
não dá para separar "esta topologia vem da regra de escolha" de "esta topologia vem da
evolução que já aconteceu".

**Observação prática.** Como nada é herdado, cada geração é uma amostra independente das
demais. Isso significa que a **geração 1 do Estudo 2 já é este controle** (com sigma_z fixo
em 1.0): na primeira geração nada evoluiu ainda. Ou seja, o controle sai de graça dos dados
que já temos, e vem pareado (mesmas réplicas, mesmas sementes), o que é estatisticamente
mais forte do que rodar um controle separado.

**Estado.** Disponível nos dados do Estudo 2. Só faria sentido rodar um script próprio se a
gente quisesse cruzar sigma_p x sigma_z na ausência de evolução, o que hoje não está em
nenhuma hipótese.

---

## Estudo 2. Fêmeas variando: sigma_p varia, o traço z evolui

**Pergunta.** Como a variação de preferência entre fêmeas (sigma_p) molda a topologia da
rede de acasalamentos e a evolução do traço masculino?

**Como funciona.**
- O eixo do experimento é **sigma_p**, que varia de 0.2 a 2.0.
- A preferência é **congelada**: a cada geração os valores de p são re-sorteados de
  N(phi, sigma_p). Ela não evolui. Isso é intencional, para isolar o efeito da forma e da
  largura da distribuição de preferências sem o confundimento da co-evolução.
- O traço z é **herdável** e evolui: os filhotes herdam a média dos pais mais a variância
  de segregação, e os dois sexos carregam o traço (a fêmea carrega sem expressar).

**Aqui a escolha da fêmea é o MOTOR da seleção**: ela não evolui, ela causa a evolução do
traço masculino.

**Variáveis resposta.** Métricas de rede (modularidade, aninhamento, centralização,
oportunidade de seleção sexual Is), média e variância do traço masculino, e a proporção de
fêmeas que ficaram sem acasalar.

**Estado.** Concluído. 15.120 cenários (4 curvas x 7 sigma_p x 3 A_max x 3 k x 2 regimes de
seleção natural x 30 réplicas), 100 gerações cada, sem falhas.

---

## Estudo 3. Machos variando: sigma_z varia, a preferência p evolui

**Pergunta.** Como a disponibilidade de machos com traços variados (sigma_z) molda a
evolução da preferência feminina?

**Como funciona.** É o espelho do Estudo 2. Os papéis se invertem:
- O eixo do experimento é **sigma_z**, que varia de 0.2 a 2.0.
- O traço do macho passa a ser **ambiental**: é re-sorteado a cada geração de
  N(phi, sigma_z) e não é herdado. Representa dependência de condição, não genética.
- A preferência passa a ser **herdável** e bi-parental: os dois sexos carregam p (o macho
  carrega sem expressar) e o filhote herda a média dos pais mais a variância de segregação.

**Aqui a escolha da fêmea deixa de ser o motor e passa a ESTAR SOB SELEÇÃO.** A força
seletiva que age sobre ela é ecológica: a disponibilidade de machos. É a analogia que a
Erika propôs: a planta não escolhe, mas a disponibilidade de plantas gera seleção sobre a
preferência do herbívoro que escolhe.

**O que evolui é o pico p** (que valor de traço a fêmea prefere), não a exigência (a
choosiness s continua fixa).

**Uma condição necessária.** Para que exista seleção sobre a preferência é preciso que haja
variância de sucesso reprodutivo entre fêmeas. Por isso tiramos a regra de escape: uma fêmea
que não aceita nenhum macho fica sem acasalar e deixa zero filhotes. A fecundidade continua
neutra (quem acasalou deixa sempre o mesmo número de filhotes, independente de com quantos
machos acasalou), como tínhamos combinado.

**Variáveis resposta.** As mesmas métricas de rede, mais a média e a variância do pico de
preferência, e a proporção de fêmeas sem acasalar (que aqui é o indicador direto da força de
seleção).

**Estado.** Rodando, mesmo desenho fatorial do Estudo 2 com 30 réplicas.

---

## Estudo 4. Co-evolução preferência-traço (planejado)

**Pergunta.** O que acontece quando as duas características evoluem ao mesmo tempo?

**Como funciona.** Traço e preferência são **ambos herdáveis**, e cada indivíduo carrega os
dois genótipos (o macho carrega p sem expressar, a fêmea carrega z sem expressar).

**A grandeza central deixa de ser a média de cada característica e passa a ser a covariância
genética cov(z, p).** É o acasalamento assortativo que constrói essa covariância, e é ela que
faz a preferência "pegar carona" na seleção que age sobre o traço. Esse é o mecanismo do
Fisherian runaway (Lande 1981; Kirkpatrick 1982): a preferência evolui sem estar diretamente
sob seleção, arrastada pela associação genética com o traço.

**Um cuidado de implementação.** Como cada indivíduo carrega duas características que precisam
viajar juntas, os filhotes têm que ser amostrados por índice, não por valor. Se z e p forem
embaralhados separadamente, a covariância é destruída e o runaway desaparece por um erro de
programação, não por biologia.

**Estado.** Motor rascunhado, não rodado.

---

## O que é comum aos quatro

**População.** 200 machos e 200 fêmeas, gerações discretas e não sobrepostas, 100 gerações
por réplica.

**As quatro curvas de preferência.** Aleatória (nula), Gaussiana (a fêmea busca um valor
próximo do seu), Sigmoide (a fêmea prefere valores cada vez maiores) e Disruptiva ou U-shaped
(a fêmea evita o valor médio). A média da distribuição de preferências é a mesma nas quatro,
de modo que as diferenças vêm da geometria da regra, não da localização do ótimo.

**Fatores cruzados.** A_max (quantos machos distintos cada fêmea avalia: 200, 40 ou 10),
k (quantos parceiros por fêmea: 5, 10 ou 20) e seleção natural de viabilidade sobre o traço
(ligada ou desligada).

**Decisões de modelo tomadas nesta rodada.**
1. Amostragem **sem reposição**: A_max é literalmente o número de machos distintos avaliados.
2. **Sem regra de escape**: quem não aceita ninguém fica sem acasalar e deixa zero filhotes.
3. **Fecundidade neutra**: a poliandria não aumenta o número de filhotes, só distribui a
   paternidade.
4. **Variância de segregação proporcional** (modelo infinitesimal de Falconer e Mackay): o
   desvio dos filhotes em relação à média dos pais tem variância igual a metade da variância
   parental, em vez de um ruído fixo. Com ruído fixo, a variância genética erodia até um piso
   artificial e a resposta evolutiva ficava artificialmente comprimida.

**Réplicas.** 30 nesta rodada de exploração, 100 na rodada final.

---

## Como a comparação entre estudos responde as hipóteses

- **H1 (a forma da curva gera assinaturas topológicas distintas).** O Estudo 1 testa isso
  sem o confundimento da evolução; o Estudo 2 mostra se a assinatura persiste depois de 100
  gerações de resposta evolutiva.
- **H2 (a topologia prediz a trajetória evolutiva).** Estudo 2 para o traço, Estudo 3 para a
  preferência.
- **H3 (a restrição de amostragem apaga as assinaturas).** O gradiente de A_max está presente
  nos três estudos rodados, então dá para ver se o efeito do ruído ecológico é o mesmo quando
  quem evolui é o traço ou quando é a preferência.
- **Fisher.** Só o Estudo 4 pode testar, porque é o único onde a covariância genética entre
  preferência e traço pode se acumular.
