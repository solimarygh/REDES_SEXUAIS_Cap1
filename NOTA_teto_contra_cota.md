# O censo de machos: teto contra cota

Setembro de 2026. Esta nota registra o que a rodada comparativa mostrou sobre a
decisão que estava pendente desde agosto, e que era a última coisa segurando
metade dos resultados dos Estudos 2 e 4.

Os dados saem de `05_teto_contra_cota.R`, que lê as duas rodadas e não simula
nada. A metade COM seleção natural do Estudo 2 rodou duas vezes, uma sob cada
regime, com a MESMA semente por cenário, de modo que cada célula tem a sua
gêmea e a comparação é pareada.

---

## A decisão que estava em aberto

Com a regra best-of-n, nas curvas sigmoide e disruptiva com seleção natural
ligada, o traço se afasta tanto do ótimo ecológico que a viabilidade
`V = exp(-gamma (z - phi)^2)` desaba para todos ao mesmo tempo. Nessas células
a rede saiu de 200 fêmeas por dois ou três machos, e as métricas de topologia
deixaram de ser comparáveis com as das outras.

São duas leituras possíveis do mesmo 200:

**Teto.** 200 é um máximo. Cada juvenil sobrevive com probabilidade V de forma
independente, e o censo é quem sobrou. A viabilidade é mortalidade absoluta e o
tamanho da população é um resultado do modelo.

**Cota.** 200 é a capacidade de suporte. Sorteia-se sempre 200 juvenis com peso
proporcional a V, de modo que a seleção decide QUAIS machos ocupam as vagas e
nunca QUANTAS vagas há. A população fica regulada por densidade.

---

## 1. A centralização era artefato

Este era o resultado que estava bloqueado: sob a sigmoide com seleção natural,
a centralização subia de 0.18 para 0.37 ao longo das gerações. Nas células em
que o teto encurtava o censo:

| | teto | cota |
|---|---|---|
| centralização | 0.586 | 0.186 |
| censo de machos | 38 | 200 |

Com a cota ela não sobe: despenca. **Era o censo curto.** Com 38 machos uma
rede é centralizada por construção, e era isso que estávamos medindo.

O resultado morreu, e é bom que tenha morrido antes de ser escrito.

---

## 2. E o que ficou no lugar dele é melhor

Nas mesmas células, o I_s vai de 0.50 com o teto para **6.95 com a cota**.

As duas métricas apontam para lados opostos, e a razão é a que a Soly tinha
levantado dias antes ao perguntar se as métricas são comparáveis entre redes de
tamanhos diferentes. Elas normalizam de formas diferentes:

Com 38 machos e 200 fêmeas, todos os machos acasalam muito, então a
desigualdade entre eles é baixa (I_s = 0.50). Mas a centralização, que se
normaliza pelo máximo possível para aquele tamanho de rede, sai alta.

Com 200 machos, a sigmoide deixa uns poucos monopolizarem: desigualdade enorme
(I_s = 6.95), mas repartida sobre 400 nós, então a centralização normalizada
sai baixa.

**O I_s aguenta a mudança de tamanho da rede; a centralização não.** Isso tem de
ir para os Métodos, e resolve de forma concreta a dúvida que estava aberta.

O resultado reportável passa a ser o I_s: com a população completa de 200
machos, a sigmoide com seleção natural gera uma oportunidade de seleção sexual
de quase 7.

---

## 3. Uma previsão minha que falhou, e o que ela revelou

Eu tinha escrito que com a cota a seleção natural conteria mais o traço, porque
passaria a agir sobre 200 vagas disputadas em vez de sobre um punhado de
sobreviventes. É o contrário:

| zbar da sigmoide | teto | cota |
|---|---|---|
| geração 100 | 9.40 | 12.79 |

Com a cota o traço vai MAIS longe do ótimo.

A razão é o ponto de fundo desta nota. **A cota transforma a seleção natural em
relativa.** As 200 vagas se preenchem sempre, com os melhores que houver. Se a
população inteira derivou para z = 12, a cota preenche as 200 vagas com os
melhores daquele grupo ruim. Não há mortalidade absoluta freando nada.

Com o teto há: mata quase todos, e ainda que o canal seja estreito, alguma
coisa contém.

Isso tem nome na literatura e não é detalhe de implementação: **cota é seleção
branda e teto é seleção dura**. Não são duas maneiras de programar a mesma
coisa, são dois modelos biológicos distintos de como a viabilidade age. Sob
seleção branda o tamanho da população é constante e a viabilidade só reordena
quem ocupa as vagas; sob seleção dura a viabilidade mata em termos absolutos e
o tamanho da população responde.

**É esta a decisão para levar ao Miudo**, e não a pergunta técnica de como
manter o censo em 200. As duas opções são defensáveis e dizem coisas
diferentes sobre a biologia do sistema.

---

## 4. O que não muda, que serve de conferência

Sob a curva aleatória e sob a gaussiana os dois regimes dão praticamente o
mesmo (centralização 0.022 contra 0.022, e 0.028 contra 0.029). Era o esperado:
nessas curvas o traço não se afasta o bastante para a viabilidade desabar, o
censo nunca encurta, e os dois regimes percorrem o mesmo caminho.

Serve como verificação de que a comparação está medindo o que deve.

E, na metade SEM seleção natural, os dois regimes são idênticos e não
parecidos: `selecionar_machos_adultos` devolve por outro caminho de código,
antes de chegar à parte da cota, uma amostra aleatória de 200. Por isso a
metade sem seleção natural não precisou ser rodada de novo.

---

## 5. Números da rodada

Das 3.780 células emparelhadas na geração 100, **1.109 (29,3%) tinham censo
curto sob o teto**. É bem mais do que os 6% que tínhamos contado sobre o
desenho inteiro, porque ali as células sem seleção natural entravam na conta e
elas nunca encurtam.

Um aviso sobre os dados: o teto tem 378.000 linhas e a cota 504.000, ou seja
3.780 células contra 5.040. **Faltam 1.260 células à rodada de setembro**,
provavelmente réplicas que não terminaram. A comparação pareada usa só as que
existem nas duas, então continua válida, mas vale saber antes de citar qualquer
número do lado do teto.

---

## O que fica para decidir

1. Cota ou teto, que é escolher entre seleção branda e seleção dura. Com os
   números na mão, e não em abstrato.
2. Se ficar o teto, se `gamma` precisa afrouxar para que a viabilidade não
   desabe. Se ficar a cota, `gamma` deixa de ser crítico, porque só reordena.
3. Trocar a centralização pelo I_s como métrica de concentração do sucesso, ou
   reportar as duas explicando por que discordam. A segunda me parece mais
   honesta e mais interessante.
4. Completar as 1.260 células que faltam à rodada do teto, se a comparação for
   entrar no paper.
