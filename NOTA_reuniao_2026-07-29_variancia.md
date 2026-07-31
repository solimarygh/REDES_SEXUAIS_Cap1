# Nota de trabalho (29/07/2026): mudanças no modelo e um achado sobre a variância genética

Resumo do que mudamos no código e de um problema que descobrimos ao testar, que afeta
a interpretação dos dois modelos (o original e o espelho). Escrito para discutirmos juntos.

---

## 1. Mudanças implementadas

**Regra de escape removida (nos dois modelos).** Antes, se uma fêmea avaliava os machos e
não aceitava nenhum, ela acasalava "na marra" com o último avaliado. Na prática, toda fêmea
acasalava e, como a fecundidade é neutra (50 filhotes para quem acasalou), todas tinham
exatamente o mesmo sucesso reprodutivo. Sem variância de fitness entre fêmeas não existe
seleção possível sobre a preferência. Agora, a fêmea que não aceita nenhum macho fica sem
acasalar e deixa 0 filhotes. Mantivemos a fecundidade neutra, como tínhamos combinado.

**Amostragem sem reposição.** Antes a fêmea sorteava A_max machos com reposição, de modo que
com A_max = 200 ela via em média só 126 machos distintos. Agora A_max é literalmente o número
de machos distintos avaliados.

**Nova variável: proporção de fêmeas sem acasalar.** É o indicador direto da força de seleção
agindo sobre a preferência. As fêmeas sem acasalar são excluídas do cálculo das métricas de
rede (entrariam como nós isolados e inflariam tribos e modularidade), mas os machos com grau
zero continuam entrando, porque são o sinal da seleção sexual (Is).

**Modelo espelho implementado** (`Fase_Espelho.R`), separado do motor original: traço do macho
ambiental (re-sorteado a cada geração, não herdado) e preferência da fêmea herdável e
bi-parental (os dois sexos carregam p, o macho sem expressar).

---

## 2. O achado: a variância genética colapsa por causa da herança, não da biologia

Ao rodar o espelho, a variância da preferência caiu de 1.0 (valor inicial) para 0.08 e ficou
travada ali, em todas as combinações testadas de sigma_z, A_max e curva de preferência. A
proporção de fêmeas sem acasalar ficou em zero, ou seja, não havia seleção nenhuma.

O número 0.08 não é coincidência. Com herança de ponto médio mais um ruído fixo:

    V' = V/2 + eps^2   ->   equilíbrio V* = 2 * eps^2 = 2 * (0.2)^2 = 0.08

A herança de ponto médio (blending) corta a variância pela metade a cada geração, e a única
coisa que a repõe é o termo de ruído fixo (eps = 0.2). O corte pela metade acontece porque não
há acasalamento assortativo no traço herdado: no espelho, o macho é escolhido pelo seu z
(ambiental), que não diz nada sobre o p que ele carrega, então mãe e pai não são correlacionados
em p e a covariância entre eles é exatamente zero.

**Isso também acontece no modelo original.** Verificamos nos dados já rodados: na geração 100,
a variância do traço masculino é praticamente a mesma em todos os valores de sigma_p.

| sigma_p | var(z) na geração 100 |
|---------|------------------------|
| 0.2     | 0.075 |
| 0.5     | 0.077 |
| 0.8     | 0.080 |
| 1.0     | 0.081 |
| 1.2     | 0.082 |
| 1.5     | 0.082 |
| 2.0     | 0.081 |

Ou seja, o traço masculino começa com variância 1.0 e colapsa para 0.08 em poucas gerações,
independentemente de sigma_p. O mesmo mecanismo (o pai e a mãe não são correlacionados no z
que transmitem, porque o z da fêmea é independente da preferência dela, que é re-sorteada).

**Por que isso importa.** A hipótese H2 fala em "resgate de variância genética" por redes
modulares. Com esse piso mecânico, o que estamos medindo são desvios de poucos pontos
percentuais em torno de 0.08, e não a manutenção da variância inicial. As diferenças relativas
entre curvas de preferência podem continuar sendo sinal biológico real, mas o enquadramento
absoluto precisa mudar.

**Um detalhe dos Métodos.** O texto atual chama esse termo de "segregation variance", citando
Falconer & Mackay, e diz que ele garante que a variação genética seja "continuously
replenished". Isso é tecnicamente verdade, mas ele repõe até 0.08, ou seja, cerca de doze vezes
menos que a variância inicial. Além disso, em Falconer a variância de segregação é proporcional
à variância parental (V_A/2), e não uma constante. Se mantivermos o ruído fixo, seria mais
correto chamá-lo de entrada mutacional e declarar que a variância se estabiliza em 2*eps^2.

---

## 3. O modelo espelho funciona quando corrigimos isso

Refizemos o teste usando eps_p = 0.7. Esse valor não é arbitrário: é exatamente sqrt(V/2) para
V = 1, ou seja, é a variância de segregação de Falconer para uma população com V_A = 1. Com ele,
aparece seleção (entre 3% e 20% de fêmeas sem acasalar) e a variância da preferência responde à
disponibilidade de machos.

Resultado com 3 réplicas, curva gaussiana, A_max = 10, k = 5, sem seleção natural:

| sigma_z | var(p) final | fêmeas sem acasalar |
|---------|--------------|---------------------|
| 0.2     | 0.797        | 19.5% |
| 0.5     | 0.792        | 10.2% |
| 0.8     | 0.921        |  8.2% |
| 1.0     | 0.860        |  3.8% |
| 1.2     | 0.865        |  3.0% |
| 1.5     | 0.980        |  7.8% |
| 2.0     | 0.957        |  9.8% |

Duas leituras:

**A variância da preferência aumenta com a disponibilidade de machos.** Com machos concentrados
(sigma_z baixo), só as fêmeas com preferência próxima da média encontram parceiro, a seleção
estabilizadora é forte e a variância é comprimida (0.79). Com machos dispersos, fêmeas com
preferências variadas encontram parceiro, a seleção afrouxa e a variância fica perto do neutro
(0.96). Isso responde diretamente à pergunta que a Erika formulou: como a disponibilidade de
machos com traços variados influencia a evolução da escolha da fêmea.

**A proporção de fêmeas sem acasalar tem forma de U**, com mínimo em sigma_z = 1.0. O fracasso
de acasalamento é menor quando a dispersão dos machos coincide com a dispersão das preferências.

**A média da preferência não se move** (fica em 5 em todos os cenários), o que faz sentido: os
machos estão sempre centrados em 5, então o ótimo da preferência é sempre 5. O resultado do
espelho está na variância, não na média.

Uma ressalva: com eps_p fixo em 0.7, a variância não pode passar de 0.98, então estamos vendo um
sinal truncado (só desvios para baixo).

---

## 4. A decisão que precisamos tomar

O ruído fixo impõe um ponto de retorno: a cada geração o modelo puxa a variância de volta para
2*eps^2. Esse valor fomos nós que escolhemos, não é uma propriedade emergente. É o mesmo tipo de
problema que já tínhamos identificado com sigma_p sendo re-imposto a cada geração.

A alternativa é o modelo infinitesimal clássico, em que o desvio de segregação é proporcional à
variância parental:

    filhote = (p_pai + p_mae)/2 + N(0, sqrt(var_pais/2)) + N(0, mutação pequena)

Assim V' = V/2 + V/2 = V. A variância deixa de erodir sozinha e passa a ser determinada apenas
pela seleção e pela deriva, sem ponto de retorno. O termo mutacional pequeno repõe o que a deriva
remove.

| | Ruído fixo (atual) | Infinitesimal |
|---|---|---|
| Equilíbrio neutro | 2*eps^2, imposto por nós | nenhum, a variância é livre |
| Quem determina a variância final | seleção competindo com o ponto de retorno | seleção e deriva |
| Fidelidade a Falconer | baixa (a variância de segregação deveria ser proporcional) | alta |
| Custo | nenhum | precisa re-rodar tudo |

As duas opções já estão implementadas no código (argumento `segregacao = "fixa"` ou
`"infinitesimal"`), com o comportamento atual como padrão, para podermos comparar antes de
decidir. Se adotarmos o infinitesimal, precisa valer para os dois modelos, por consistência.

---

## 5. Pontos para discutir

1. Adotamos a segregação infinitesimal (mais fiel a Falconer, elimina o piso artificial, mas
   exige re-rodar tudo), ou mantemos o ruído fixo e ajustamos a descrição nos Métodos?
2. Se mantivermos o ruído fixo, concordamos em chamá-lo de entrada mutacional e declarar
   explicitamente que a variância genética se estabiliza em 2*eps^2?
3. Como isso muda o enquadramento da H2 (resgate de variância genética)?
4. No espelho, faz sentido que a resposta seja só a variância da preferência, já que a média não
   tem para onde ir (o ótimo é sempre 5)? Ou queremos um cenário em que a média também possa
   evoluir (por exemplo, machos centrados em um valor diferente do valor inicial da preferência)?
