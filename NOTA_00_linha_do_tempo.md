# As notas em ordem: o que se decidiu, e quando

Este documento reúne em ordem cronológica o que está registrado nas notas de
trabalho do projeto. Não as substitui: cada uma continua com o detalhe, as
tabelas e os números, e esta serve para saber onde procurar e para recuperar o
fio de por que o desenho é como é.

A leitura de conjunto mostra um padrão. Quase todas as decisões do projeto
vieram de descobrir que uma coisa que descrevíamos de um jeito era, no código,
outra — k como cota e não teto, o pool de machos suposto constante e não sendo,
a variância de segregação suposta proporcional e sendo fixa. Nenhuma apareceu
sozinha: apareceram ao conferir o texto contra o código, ou ao calibrar antes de
rodar.

---

## Índice

| data | nota | o que fecha |
|---|---|---|
| jul/2026 | `NOTA_coevolucao_followup.md` | rascunho do motor de co-evolução, antes de existir |
| 29/07/2026 | `NOTA_reuniao_2026-07-29_variancia.md` | a variância genética colapsava por causa da herança |
| 08/08/2026 | `NOTA_reuniao_2026-08-08_desenho.md` | o desenho vira quatro estudos; três defeitos corrigidos |
| 16/08/2026 | `NOTA_material_removido_2026-08-16.md` | arquivo do que saiu da nota de leitura |
| set/2026 | `NOTA_quatro_estudos.md` | descrição corrente do desenho (referência, não cronologia) |
| 08/09/2026 | `NOTA_coevolucao_primeiros_testes.md` | a segregação se realimentava no Estudo 4 |
| 09/09/2026 | `NOTA_teto_contra_cota.md` | a decisão do censo: cota, seleção branda |
| 09/09/2026 | `NOTA_estudo5_epidemia.md` | o motor da IST, e por que precisou de parcerias |
| 24/09/2026 | `NOTA_regime_censo_nas_figuras.md` | o regime de censo não chegava à reconstrução |

---

## Julho de 2026 — o motor de co-evolução, no papel

`NOTA_coevolucao_followup.md` é um rascunho, escrito antes de qualquer teste, de
como mudar o motor para que a preferência feminina co-evolua com o traço
masculino. A ideia central: cada indivíduo passa a carregar os **dois**
genótipos, e a expressão é que é dimórfica — só o macho mostra z, só a fêmea usa
p. O acasalamento assortativo correlaciona os dois geneticamente, e essa
covariância é o motor do runaway.

O precedente já estava no código: as fêmeas sempre carregaram um z não expresso.
Fazer os machos carregarem uma p não expressa é o espelho disso.

Ficou como plano. O modelo de preferência congelada seguiu como controle.

---

## 29 de julho de 2026 — a variância genética não caía por biologia

Ao rodar o modelo espelho pela primeira vez, a variância da preferência caiu de
1.0 para **0.08** e travou ali, em todas as combinações testadas. Nenhuma fêmea
ficava sem acasalar, ou seja, não havia seleção nenhuma.

O número não era coincidência. Com herança de ponto médio mais um ruído fixo:

```
V' = V/2 + eps²   →   equilíbrio V* = 2·eps² = 2·(0.2)² = 0.08
```

A herança de ponto médio corta a variância pela metade a cada geração, e a única
coisa que a repunha era um ruído de tamanho fixo escolhido por nós. E o mesmo
acontecia no modelo original: na geração 100, a variância do traço masculino era
praticamente idêntica nos sete valores de σp, entre 0.075 e 0.082.

**Por que importava:** a hipótese do resgate de variância genética por redes
modulares estava sendo medida como desvios de poucos pontos percentuais em torno
de um piso que era artefato da implementação, e não manutenção da variância
inicial.

A mesma nota registra três mudanças de modelo feitas antes disso, e que
continuam valendo:

- **A regra de escape foi removida.** Antes, a fêmea que não aceitava ninguém
  acasalava à força com o último avaliado. Como a fecundidade é neutra, isso
  dava a todas o mesmo sucesso reprodutivo, e sem variância de sucesso não há
  seleção possível sobre a preferência. Agora quem não aceita ninguém fica sem
  acasalar.
- **A amostragem passou a ser sem reposição.** Antes, com A_max = 200, a fêmea
  via em média 126 machos distintos. Agora A_max é literalmente o número de
  machos distintos avaliados.
- **A proporção de fêmeas sem acasalar** entrou como variável resposta, que é o
  indicador direto da seleção sobre a preferência.

A decisão ficou em aberto: manter o ruído fixo e corrigir a descrição nos
Métodos, ou adotar o modelo infinitesimal, em que o desvio de segregação é
proporcional à variância parental e a variância deixa de ter ponto de retorno.

---

## 8 de agosto de 2026 — o desenho vira quatro estudos

**A decisão anterior foi tomada: segregação infinitesimal**, para os dois
motores. O piso de 0.08 desaparece e a variância passa a ser determinada só pela
seleção e pela deriva. Obrigou a re-rodar tudo.

**A estrutura implícita ficou explícita.** Quatro estudos que compartilham o
mesmo ciclo de vida e as mesmas quatro curvas, e diferem apenas em quais
características são herdadas. O Estudo 1, o Controle, é novo: nada é herdado,
roda uma geração só, e por isso é cem vezes mais barato — o que permite cruzar
σp com σz por inteiro, os sete por sete. Precisa ser independente porque a
geração 1 dos Estudos 2 e 3 cobre apenas uma linha cada, e as duas juntas formam
uma cruz que deixa de fora justamente as combinações extremas.

E três defeitos de desenho, todos do mesmo tipo — parâmetros descritos como uma
coisa que o código fazia ser outra:

**k não é o número de parceiros, é um teto.** O código faz
`parceiros = min(k, machos aceitos entre os A_max avaliados)`. Com A_max = 10 e
k = 20 o teto é inalcançável por construção, e morde bem antes do limite
aritmético, porque a fêmea não acasala com os dez que avaliou e sim com os que
aceitou entre esses dez. Medido: com A_max = 10, a poliandria realizada vai de
3.5 na gaussiana a 6.9 na disruptiva, um fator de dois com o mesmo k nominal.

> Não é defeito de implementação: é impossibilidade lógica. Uma fêmea que só
> encontra dez machos não pode acasalar com vinte. A saída foi **reenquadrar k
> como apetite**, com a poliandria realizada virando variável resposta. Isso
> converte as células degeneradas nas mais informativas: A_max = 10 com k = 20 é
> poliandria frustrada, e comparada com A_max = 200 é exatamente o teste da
> hipótese sobre custo de busca.

**O pool de machos não era constante.** A seleção de viabilidade agia sobre os
200 adultos, de modo que o número de machos disponíveis caía com σz — de 198 a
124 ao longo do gradiente, 37% de encolhimento. O mesmo número de arestas se
repartia entre menos machos, e isso mexia sozinho em Is, centralização e
aninhamento. A correção foi mover a viabilidade para **antes** do censo de
adultos: ela muda quais machos estão disponíveis, e deixa de mudar quantos.

**O caso degenerado fabricava dados.** Quando nenhuma fêmea acasalava, o Estudo
2 devolvia a geração anterior — uma coorte de pais imortais — e a população
encolhia em silêncio até produzir NA sem aviso. Agora a réplica é encerrada, as
gerações já rodadas são mantidas, e `extincao_gen` registra onde parou.

Ficou também uma correção de rótulo: A_max deixou de ser descrito como
porcentagem de N e passou a número absoluto, com A_max = 200 lido como ausência
de restrição de busca, e entrando nos modelos como fator e nunca como covariável
contínua.

---

## 16 de agosto de 2026 — o que saiu da nota de leitura

`NOTA_material_removido_2026-08-16.md` guarda o que foi tirado de
`NOTA_quatro_estudos.md` quando esta foi enxugada para ficar legível. Nada saiu
por estar errado: saiu por ser detalhe demais, ou por tratar de decisões ainda
não tomadas. Entre elas continuam os quatro pontos de desenho do Estudo 4, o
mais pesado sendo se o gradiente de k fica ou sai.

---

## 8 de setembro de 2026 — a segregação se realimentava

Primeira rodada de testes do Estudo 4. Numa réplica da gaussiana sem seleção
natural, as duas médias saíram de 5 e subiram juntas, o que parecia runaway. Não
era: na linha de equilíbrios de Lande não há lado preferido, e metade das
réplicas deveria descer. Dez em dez subiram.

O diagnóstico ligou e desligou cada suspeito com a mesma semente:

| braço | deslocamento | subiram | var. final | cor(z,p) |
|---|---|---|---|---|
| como estava | 6.22 | 10/10 | 58.6 | 0.38 |
| segregação fixa | 0.60 | 5/10 | 0.6 | **0.83** |

**A causa:** com preferência gaussiana o acasalamento é fortemente assortativo,
o que gera desequilíbrio de ligamento positivo e faz a variância **total** subir.
A segregação usava `var(c(male_z_surv, female_z_gen))`, que é a total — mais
variância gerava mais variância. O modelo infinitesimal estrito acompanha a
variância **génica**, que sob acasalamento assortativo não infla assim.

E um detalhe que vale mais que o defeito: **a correlação genuína entre
preferência e traço é maior quando o artefato não está lá** — 0.83 contra 0.38.
A inflação estava mascarando o sinal, não produzindo-o.

**A boa notícia:** não contamina os outros estudos. Em Fêmeas variando a
preferência é re-sorteada a cada geração, o que serve de âncora e não deixa o
laço se fechar. O problema é específico do Estudo 4, e específico justamente por
ele ser o único em que as duas características evoluem.

Com a correção o desenho completo rodou: 12.960 cenários em 17,5 horas, sem uma
falha. Depois de uma correção no cálculo do Ne, a metade sem seleção natural
rodou de novo, 6.480 cenários em seis horas, e serviu de verificação — tudo
reproduziu a rodada anterior fora a coluna corrigida.

Fica sem explicação um braço do diagnóstico: com φ = 50 as dez réplicas vão para
baixo e a variância infla ainda mais.

---

## 9 de setembro de 2026 — o censo: teto ou cota

A decisão estava pendente desde agosto e era a última coisa segurando metade dos
resultados dos Estudos 2 e 4. Sob as curvas sigmoide e disruptiva com seleção
natural, o traço se afasta tanto do ótimo ecológico que a viabilidade desaba
para todos ao mesmo tempo, e a rede saía de 200 fêmeas por dois ou três machos.

Duas leituras do mesmo 200: **teto**, em que cada juvenil sobrevive de forma
independente e o censo é quem sobrou; **cota**, em que 200 é a capacidade de
suporte e a seleção decide quais machos ocupam as vagas, nunca quantas há.

**O resultado que estava bloqueado morreu, e é bom que tenha morrido antes de
ser escrito.** A centralização que subia de 0.18 para 0.37 sob a sigmoide era
artefato do censo curto: com 38 machos uma rede é centralizada por construção.

| | teto | cota |
|---|---|---|
| centralização | 0.586 | 0.186 |
| censo de machos | 38 | 200 |

**E o que ficou no lugar é melhor.** Nas mesmas células, o Is vai de 0.50 com o
teto para **6.95** com a cota. As duas métricas apontam para lados opostos
porque normalizam de formas diferentes, e a conclusão vai para os Métodos: **o
Is aguenta a mudança de tamanho da rede, a centralização não.**

**Uma previsão falhou, e revelou o ponto de fundo.** Esperava-se que com a cota
a seleção natural contivesse mais o traço; é o contrário — vai mais longe, de
9.40 para 12.79. A cota torna a seleção natural **relativa**: as 200 vagas se
preenchem sempre, com os melhores que houver, ainda que o grupo inteiro seja
ruim. Isso tem nome: **cota é seleção branda e teto é seleção dura**, dois
modelos biológicos distintos e não duas formas de programar a mesma coisa.

A verificação: sob a aleatória e a gaussiana os dois regimes dão praticamente o
mesmo, porque ali o traço não se afasta o bastante para a viabilidade desabar.

---

## 9 de setembro de 2026 — o motor da epidemia

Construção do Estudo 5, a primeira fatia do Objetivo 2. Uma temporada basta,
porque nela não se vê a resposta evolutiva mas vê-se o **diferencial de
seleção**, que a equação do criador converte em resposta esperada.

Quatro descobertas, todas de construção e não de biologia:

**A ordem causal estava invertida.** A primeira versão comparava o grau dos
machos infectados com o dos suscetíveis usando o estado do fim da temporada. Sob
a sigmoide, os machos de z alto acasalam com quase todos e por isso são os
primeiros a se infectar: estar infectado virou consequência do sucesso, não
causa. A estimativa causal do efeito de h é o contraste **entre** células, com a
mesma semente, mudando só h — é o desenho que responde, não uma coluna.

De quebra, a comparação errada mostrou um resultado que não é erro: sob a
sigmoide, **o macho sexualmente selecionado é o super-disseminador**. A seleção
sexual não só permite avaliar resistência a patógenos: constrói a estrada por
onde o patógeno viaja.

**Parceiros e cópulas não são a mesma coisa.** São as cópulas que movem a
epidemia e os parceiros que dão a topologia. Os dois passaram a ser registrados,
e o diferencial de seleção passou a ser pesado pelas cópulas.

**A calibração quase deixou o estudo vazio.** Com β = 0.3 a epidemia saturava e
as prevalências dos três níveis de h davam 0.47, 0.46 e 0.47 — idênticas. E com
γ = 0.1 numa temporada de cinco semanas quase ninguém se curava, de modo que SIS
e SIR davam exatamente o mesmo: um dos quatro fatores do desenho não mediria
nada. **A lição vale para todos os estudos: um fator pode não medir nada, e isso
não aparece em nenhuma mensagem de erro — só aparece se calibrarmos antes.**

**E o defeito de fundo: o modelo não tinha parcerias, tinha encontros soltos.**
Cada semana era uma loteria independente. A literatura de redes sexuais é
explícita em que o que move uma IST não é o número de contatos, mas a estrutura e
a duração das parcerias — a concorrência e a rotação. A proposta que saiu daqui,
e que foi implementada depois, foi acrescentar formação e dissolução de
parcerias, sem tocar na parte de escolha de parceiro.

---

## 24 de setembro de 2026 — o regime de censo não chegava às figuras

No Material suplementar, as abas com seleção natural do tópico 2.0 vinham todas
vazias. Não faltavam dados: faltava passar o regime de censo à reconstrução.

`rede_representativa()` não guarda as redes — volta a simular a réplica a partir
da semente, e depois compara a métrica reproduzida com a guardada. A metade com
seleção natural foi produzida com `CENSO=cota`, mas a reconstrução rodava sempre
com o default, `"teto"`. População diferente, métrica diferente, e a verificação
recusava a rede, fazendo o que devia fazer.

As simulações não precisaram ser refeitas: o defeito estava na reconstrução para
as figuras, não na produção.

O detalhe completo, incluindo duas hipóteses erradas pelo caminho e o que de
fato explicava um render de 91 minutos, está em
`NOTA_regime_censo_nas_figuras.md`.

---

## O que está decidido

- **Segregação infinitesimal**, nos dois motores, com a variância **génica** e
  não a total governando a segregação no Estudo 4.
- **Sem regra de escape**: quem não aceita ninguém não acasala.
- **Amostragem sem reposição**: A_max é o número de machos distintos avaliados.
- **k é apetite, não cota**, e a poliandria realizada é variável resposta.
- **A viabilidade age antes do censo**, de modo que o censo adulto é 200 por
  construção.
- **Cota, e não teto**: seleção branda, com regulação por densidade.
- **O Is é a métrica que aguenta comparação entre redes de tamanhos
  diferentes**; a centralização não.
- **Réplicas que se extinguem são registradas**, não descartadas em silêncio.

## O que continua aberto

- No Estudo 3, a média da preferência não tem para onde ir, porque os machos
  estão sempre centrados em 5, e o resultado está todo na variância. Faz sentido
  manter assim, ou queremos um cenário em que a média também possa evoluir?
  *(aberta desde 29/07)*
- Controlar pela densidade da rede ao comparar curvas de preferência é controlar
  por um **mediador**, e não por um confundidor. Reportar o efeito total e o
  efeito líquido, dizendo que respondem a perguntas diferentes, foi a intuição
  proposta, mas é um problema de inferência causal em redes. *(aberta desde
  08/08)*
- Os quatro pontos de desenho do Estudo 4, em
  `NOTA_material_removido_2026-08-16.md`, com o gradiente de k como o mais
  pesado.
- No diagnóstico do Estudo 4, o braço com φ = 50 em que as dez réplicas vão para
  baixo continua sem mecanismo.
- No Estudo 1, o aninhamento prediz a exageração do traço com sinal **invertido**
  e firme. Sem explicação, e a análise com a conectância como covariável é o
  próximo passo para saber se é artefato de densidade.
