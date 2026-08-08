# Nota de trabalho (08/08/2026): o que mudou desde 29/07

Continuação da nota anterior (`NOTA_reuniao_2026-07-29_variancia.md`). Aquela terminava com
quatro perguntas em aberto. Esta conta o que decidimos sobre elas, e três problemas de desenho
que apareceram depois, ao conferir o texto contra o código linha a linha. Os três são do mesmo
tipo: parâmetros que descrevíamos como se fossem uma coisa e que o código fazia ser outra.

Escrito para discutirmos na próxima reunião. A descrição completa e atualizada do desenho está
em `NOTA_quatro_estudos.md`.

---

## 1. As perguntas da nota anterior, respondidas

**Adotamos a segregação infinitesimal.** Vale para os dois motores, por consistência, e é o
padrão agora (`segregacao = "infinitesimal"`). O modo antigo continua no código
(`segregacao = "fixa"`) para comparação, e o modo usado fica gravado numa coluna da saída de cada
simulação, para não haver dúvida depois sobre o que gerou cada arquivo.

Com isso some o piso artificial de 0.08. A variância genética deixa de ter ponto de retorno e
passa a ser determinada só pela seleção e pela deriva, com o termo mutacional pequeno
(`mut_sd = 0.05`) repondo o que a deriva remove. A ressalva da nota anterior, de que estávamos
vendo um sinal truncado porque `eps_p = 0.7` limitava a variância a 0.98, deixa de existir.

Isso obriga a re-rodar tudo, como estava previsto. E como três problemas novos apareceram depois
(seções 3, 4 e 5), aproveitamos o mesmo recorrido para resolver os quatro de uma vez.

**A pergunta 4 continua aberta**, e é a que mais me interessa levar para a reunião: no espelho,
a média da preferência não tem para onde ir, porque os machos estão sempre centrados em 5. O
resultado está todo na variância. Faz sentido manter assim, ou queremos um cenário em que a média
também possa evoluir?

---

## 2. O desenho virou quatro estudos

A estrutura que estava implícita ficou explícita. São quatro estudos que compartilham o mesmo
ciclo de vida e as mesmas quatro curvas de preferência, e diferem apenas em quais características
são herdadas, ou seja, quais estão livres para responder à seleção:

| Estudo | Traço do macho (z) | Preferência da fêmea (p) | O que isola |
|---|---|---|---|
| 1. Sem evolução | sorteado | sorteada | as regras de acasalamento sozinhas |
| 2. Fêmeas variando | herdável | re-sorteada | a resposta evolutiva do traço |
| 3. Machos variando | ambiental | herdável | a resposta evolutiva da preferência |
| 4. Co-evolução | herdável | herdável | o feedback entre as duas |

**O Estudo 1 é novo** (`Fase_Controle.R`). É o controle nulo: nada é herdado, roda uma única
geração, mede a topologia e acaba. Como não há herança, a geração 2 seria um sorteio independente
com a mesma distribuição, então rodar 100 gerações seria só fazer 100 réplicas disfarçadas. Isso
o torna cerca de cem vezes mais barato que os demais, e é o que permite cruzar sigma_p com
sigma_z por inteiro, os 7 por 7 valores.

Ele precisa ser independente porque a geração 1 dos Estudos 2 e 3 já é um controle, mas cada uma
só cobre uma linha: o Estudo 2 varre sigma_p com sigma_z fixo em 1.0, o Estudo 3 varre sigma_z
com sigma_p fixo em 1.0. Juntas formam uma cruz e deixam de fora as combinações extremas, que são
justamente as mais informativas: nunca se vê fêmeas muito heterogêneas diante de machos muito
homogêneos.

**Descartamos a primeira versão do experimento inverso** (`Fase_MachoVariando.R`). Nela o eixo era
sigma_z_init, ou seja, uma condição inicial, enquanto no Estudo 2 sigma_p é re-imposto a cada
geração. Os dois não eram espelhos, eram assimétricos por construção. O arquivo ficou no
repositório só como registro. O `Fase_Espelho.R` que o substituiu tem sigma_z imposto a cada
geração, e aí sim o eixo do experimento é comparável entre os dois estudos.

Sobra uma assimetria menor, que vale declarar nos Métodos em vez de esconder: no Estudo 3,
sigma_p_init é condição inicial e não parâmetro imposto. Os dois estudos são espelhos no eixo do
experimento, mas não na característica que evolui, e isso é inevitável.

---

## 3. Problema descoberto: k não é o número de parceiros, é um teto

Este é o mais sério dos três, porque afeta a leitura da H1.

Descrevíamos k como o número de parceiros de cada fêmea. O que o código faz é

    parceiros = min( k , machos aceitos entre os A_max avaliados )

Ela para quando atinge k ou quando esgota os A_max machos, o que vier primeiro. Como a amostragem
agora é sem reposição, ela nunca pode acasalar com mais machos do que avaliou. Com A_max = 10 e
k = 20, o teto é inalcançável por construção.

E morde bem antes do limite aritmético, porque ela não acasala com os dez que avaliou, e sim com
os que aceitou entre esses dez. A taxa de aceite depende da curva de preferência: com s = 2 e
sigma_p = sigma_z = 1, é de cerca de 0.33 na gaussiana, 0.50 na aleatória e na sigmoide, e 0.67
na U-shaped. Cruzando com A_max, a proporção aproximada de fêmeas que atinge o k nominal é:

| A_max | k = 5 | k = 10 | k = 20 |
|---|---|---|---|
| 200 | ~100% todas as curvas | ~100% todas | ~100% todas |
| 40 | ~100% todas | 90% gaussiana, ~100% resto | 2% gaussiana, 56% aleatória, 99% U-shaped |
| 10 | 21% gaussiana, 62% aleatória, 92% U-shaped | ~0% todas | impossível |

Duas consequências. A primeira é que o k realizado difere sistematicamente entre curvas de
preferência, o que é um confundimento direto sobre a H1: se a gaussiana e a U-shaped produzem
topologias diferentes, parte dessa diferença pode vir de as fêmeas da U-shaped terem mais
parceiros, e não da geometria da escolha, já que densidade de arestas afeta modularidade,
aninhamento e centralização. A segunda é que A_max e k estão parcialmente confundidos entre si, e
nenhum dos dois pode entrar num modelo como efeito principal aditivo.

**O ponto que mudou minha maneira de ver isto:** não é um defeito de implementação que se possa
consertar. É uma impossibilidade lógica. Uma fêmea que só encontra dez machos não pode acasalar
com vinte. Busca restrita e poliandria alta são incompatíveis, e nenhuma reparametrização
resolve. E A_max = 10 não é negociável, porque é literalmente a H3.

**A proposta é reenquadrar k como apetite, não como cota.** A fêmea busca até k parceiros; quantos
consegue depende da disponibilidade e da própria seletividade. A poliandria realizada passa a ser
uma variável resposta, não um parâmetro. Três razões:

É o que o código sempre fez. `matings_per_female` é uma condição de parada, não uma cota
garantida, e chamá-lo de "número de parceiros" sempre foi impreciso.

Converte as células degeneradas nas mais interessantes. A combinação A_max = 10 com k = 20 não é
lixo, é poliandria frustrada: quer muitos parceiros e só encontra dez. Comparada com A_max = 200
e k = 20, é exatamente o teste da H3.

É mais defensável biologicamente. Nenhum organismo tem garantido o seu número de parceiros.

Em troca, exige medir. Foram acrescentadas três colunas: `grau_medio_femeas` (a poliandria
realizada), `prop_femeas_atingiu_k` (quantas chegaram ao teto) e `arestas` (a densidade da rede).
Nenhuma delas existia, e nenhuma pode ser recuperada dos dados já rodados: o Is é calculado sobre
os machos e não permite reconstruir o grau das fêmeas. Esta é a razão mais forte para re-rodar.

**Uma dúvida que gostaria de discutir com o Miudo.** Se o grau realizado depende da curva de
preferência, e o metemos como covariável para comparar curvas, estamos controlando por um
mediador e não por um confundidor: a curva causa o grau realizado e a topologia, então controlar
remove parte do efeito causal que queremos medir. Minha intuição é reportar as duas coisas, o
efeito total da curva e o efeito líquido de densidade, e dizer que respondem a perguntas
diferentes. Mas é um problema de inferência causal em redes e prefiro ouvir ele antes.

---

## 4. Problema descoberto: o pool de machos não era constante

A seleção natural de viabilidade agia sobre os 200 machos adultos, então o número de machos
disponíveis para acasalar caía com sigma_z. A fração que sobrevive é `1 / sqrt(1 + 2 gamma
sigma_z^2)`, ou seja, com gamma = 0.2:

| sigma_z | 0.2 | 0.5 | 0.8 | 1.0 | 1.2 | 1.5 | 2.0 |
|---|---|---|---|---|---|---|---|
| Machos disponíveis (de 200) | 198 | 191 | 178 | 169 | 159 | 145 | 124 |

O pool encolhia 37% ao longo do gradiente. Como o número de fêmeas e o k não mudavam, o mesmo
número de arestas se repartia entre menos machos: com k = 5, o grau médio dos machos subia de
cerca de 5.1 para cerca de 8.1. Isso mexe sozinho em Is, centralização e aninhamento, sem
nenhuma relação com a escolha feminina.

E morde exatamente onde dói: no Estudo 2 pouco, porque sigma_z fica fixo em 1.0, mas no Estudo 1
e no Estudo 3 de frente, porque ali sigma_z é o eixo do experimento. Parte de qualquer tendência
das métricas ao longo de sigma_z, nos cenários com seleção natural ligada, era só o pool
encolhendo. Além disso, o contraste entre seleção natural ligada e desligada diferia em duas
coisas ao mesmo tempo: na distribuição do traço e no tamanho do pool.

**A correção é mover a seleção de viabilidade para antes do censo de adultos.** Agora sorteamos
machos juvenis em excesso (três por vaga), a viabilidade age sobre eles, e o censo adulto fica
sempre em 200 machos, com ou sem seleção natural. A seleção continua mudando quais machos estão
disponíveis, que é o que queremos, e deixa de mudar quantos, que era o confundimento.
Biologicamente é a formulação mais comum: a mortalidade de viabilidade age sobre juvenis, e o
censo é de adultos.

**Uma nota de rótulo.** Descrevíamos os níveis de A_max como "100%, 20% e 5% de N = 200". Os
tratamentos sempre foram comparáveis, porque o código faz `min(A_max, disponíveis)` e A_max = 40
quer dizer 40 machos nos dois regimes. O que estava errado eram as porcentagens. A_max passa a
ser descrito em número absoluto, e A_max = 200 passa a ser lido como a condição de saturação,
"sem restrição de busca", e não como um terceiro ponto equidistante do gradiente. Por isso ele
entra nos modelos como fator e nunca como covariável contínua.

---

## 5. Problema descoberto: o caso degenerado fabricava dados

Quando nenhuma fêmea acasalava, os dois motores faziam coisas diferentes, e nenhuma das duas
estava certa.

O Estudo 2 devolvia a geração anterior, o que fabrica uma coorte de pais imortais que não
deixaram descendência mas continuam na população. Pior: devolvia só os machos sobreviventes, não
os 200, então a população encolhia em silêncio, e a partir dali o passo de viabilidade reciclava
um vetor mais curto e passava a produzir NA sem nenhum aviso.

O Estudo 3 encerrava a réplica, que é o correto, mas sem deixar registro: ela entrava no conjunto
de dados apenas com menos gerações, e sumia depois no filtro `generation == 100`. Como as réplicas
que falham são as dos cenários mais duros, seria uma perda enviesada.

Agora a regra é a mesma nos dois: a réplica é encerrada, as gerações já rodadas são mantidas, e
a coluna `extincao_gen` guarda em que geração parou (NA quando chegou ao fim). Quantas réplicas
se extinguem por cenário passa a ser um resultado reportável. Esperamos que seja zero em tudo,
mas agora fica verificável em vez de suposto.

---

## 6. O que vai rodar agora

Os três estudos, com 20 réplicas cada. São 20 e não 100 porque o objetivo é ter resultados para a
reunião, e porque os problemas das seções 3, 4 e 5 são vieses sistemáticos e não ruído: mais
réplicas não os tocariam. As 30 anteriores já davam intervalos estreitos. Subimos depois, quando
o desenho estiver fechado.

O desenho fatorial fica intacto, os 3 por 3 de A_max e k. Cheguei a propor cortar a célula
A_max = 10 com k = 10, por ser indistinguível de k = 20, mas voltei atrás: agora que medimos a
poliandria realizada, a convergência entre as duas é justamente a evidência de que k é apetite e
não cota. E manter o fatorial balanceado vale mais que os 11% de computação.

| Estudo | Cenários | Gerações | Arquivo |
|---|---|---|---|
| 1. Controle | 70.560 | 1 | `Fase_Controle.R` |
| 2. Fêmeas variando | 10.080 | 100 | `Fase4_TodasAsCurvas.R` |
| 3. Machos variando | 10.080 | 100 | `Fase_Espelho.R` |

Os arquivos de backup têm nomes novos (`_censoConst`), porque o modelo mudou e os antigos não
servem. Há também um teste de fumaça (`00_teste_motores.R`) que roda um cenário de cada motor e
confere as invariantes, entre elas que o censo adulto fica mesmo em 200 com sigma_z = 2.0 e que a
poliandria realizada nunca passa do teto k. Convém rodá-lo antes de lançar.

---

## 7. Pontos para discutir

1. O reenquadramento de k como apetite, com a poliandria realizada como variável resposta. É a
   decisão que mais muda o que o paper pode afirmar sobre poliandria.
2. O problema do mediador na seção 3: como comparar curvas de preferência quando elas próprias
   determinam a densidade da rede.
3. O censo de adultos constante. Ele torna o contraste de seleção natural mais limpo, mas muda a
   interpretação: a seleção natural deixa de ter qualquer efeito demográfico e passa a ser
   puramente uma força sobre a distribuição do traço.
4. A pergunta 4 da nota anterior, ainda em aberto: no espelho, a resposta está só na variância da
   preferência, porque a média não tem para onde ir. Queremos um cenário em que ela também possa
   evoluir?
5. O desenho do Estudo 4, que ainda não rodou. A proposta é percorrer a diagonal
   sigma_p_init = sigma_z_init em vez da superfície inteira, porque no Estudo 1 a divergência
   entre curvas de preferência dependeu da variabilidade total (R² = 0.539) e praticamente nada
   da repartição entre os sexos (R² = 0.004). O detalhe está em `NOTA_quatro_estudos.md`.
