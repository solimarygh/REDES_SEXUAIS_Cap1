---
title: "Plano de Trabalho para Segundo Ano de Bolsa de Pós-Doutorado"
subtitle: "Papel das redes de interações sexuais na evolução de traços sob seleção sexual"
author: 
  - name: "Beneficiária: Solimary García Hernández"
    affiliation: "Processo FAPESP nº 2024/18754-6"
  - name: "Supervisor: Prof. Dr. Paulo R. Guimarães Jr."
    affiliation: "Processo FAPESP nº 2024/02198-7"
date: "`r Sys.Date()`"
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float: true
    number_sections: true
    theme: flatly
    highlight: tango
  pdf_document:
    toc: true
    toc_depth: 3
    number_sections: true
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
library(knitr)
```

# Objetivo do Projeto de Pesquisa Original

**Objetivo 2:** Explorar se e como uma doença que se espalha por contato e altera a atratividade do sexo escolhido impacta a formação das redes sexuais e a seleção sobre a característica do sexo escolhido.

Este objetivo foi adiado para o segundo ano (2026). A integração de um módulo epidemiológico para simular doenças sexualmente transmissíveis, conforme foi previsto na proposta original, seria viável mediante parceria com a Dra. Erika Santos. Nos últimos meses temos realizado reuniões com a Dra. Santos para discutir o escopo do trabalho, e felizmente chegamos a uma proposta que integra o conhecimento que ela desenvolveu durante o pós-doutorado com o mesmo supervisor. Neste documento, focarei na descrição dos planos para o segundo ano de pós-doutorado.

---

# Redes Sexuais e Dispersão de Doenças: Implicações para a Evolução de Traços Sexualmente Selecionados

## Resumo

A interação entre redes sexuais, a dinâmica de transmissão de doenças e a seleção sexual representam um campo de estudo crucial para a compreensão da evolução de traços em populações animais. O nosso projeto de pós-doutorado explora essa interface complexa, investigando como a variação na preferência de parceiros (nas fêmeas) e a presença de doenças que alteram a atratividade (dos machos) impactam a formação de redes sexuais e a evolução de características sexualmente selecionadas. Este documento contextualiza o papel das redes sexuais, dos modelos epidemiológicos e da relação entre infecção, atratividade e seleção sexual, dando uma visão geral/preliminar do plano de modelagem eco-epidemiológico que se acopla ao modelo de evolução de traços que tem sido desenvolvido ao longo do primeiro ano.

---

## Introdução

### Redes Sexuais e a Dispersão de Doenças

As redes sexuais, que descrevem os padrões de acasalamento e contato entre indivíduos em uma população, são fundamentais para entender a dinâmica de transmissão de infecções sexualmente transmissíveis (ISTs) e outras doenças infecciosas [1, 2]. A estrutura dessas redes — incluindo o número médio de parceiros, a heterogeneidade na quantidade de conexões (grau), a formação de grupos (clusterização) e a distância média entre os indivíduos — influencia diretamente a velocidade e o padrão de disseminação de patógenos [3, 4].

Modelos epidemiológicos mais simples, que assumem que todos os indivíduos se misturam de forma homogênea, frequentemente ignoram essas heterogeneidades e as correlações no estado de infecção entre vizinhos na rede, o que pode levar a previsões enviesadas sobre o curso de uma epidemia [3]. De fato, a dinâmica de formação dos casais, especialmente no contexto de doenças sexualmente transmissíveis, molda a rede de contato efetiva por onde a doença se espalha [1]. A partir das análises da primeira fase do projeto, sabemos que uma maior variação na preferência das fêmeas ($\sigma_c$) tende a aumentar a heterogeneidade da rede sexual. Agora, a questão é explorar a interação desse $\sigma_c$ com a atratividade do macho — quando a atratividade dele é influenciada por uma doença sexualmente transmissível.

### Modelos Epidemiológicos em Redes Sexuais: SIR e SIS

Modelos compartimentais, como o SIR (*Suscetível-Infectado-Recuperado*) e o SIS (*Suscetível-Infectado-Suscetível*), são ferramentas clássicas para descrever a propagação de doenças. A aplicação desses modelos sobre redes de contato explícitas permite capturar a estrutura de interações de forma muito mais realista [5, 6].

### Infecção, Atratividade e Seleção Sexual

A teoria da seleção sexual prevê que traços que sinalizam boa condição genética ou resistência a patógenos devem ser favorecidos [8]. A Hipótese de Hamilton & Zuk (1982), um pilar neste campo, propõe que ornamentos sexuais secundários (como a plumagem colorida de aves) evoluíram para permitir que as fêmeas avaliem a resistência dos machos a parasitas [9, 10]. Esta ideia está alinhada ao Princípio do Handicap de Zahavi (1975), que postula que sinais honestos devem ser custosos, de modo que apenas indivíduos de alta qualidade possam arcar com seu custo de produção e manutenção [11].

No nosso projeto, queremos explorar tanto cenários onde a infecção diminui a atratividade do macho infectado ($h_I < 0$), o que é consistente com a teoria clássica e diversas evidências empíricas [12], quanto cenários onde a infecção aumenta a atratividade do macho infectado ($h_I > 0$). Este último pode ocorrer, por exemplo, por meio de manipulação parasitária de sinais ou comportamentos do hospedeiro [13]. Este plano experimental nos permite testar as condições sob as quais a variação na preferência da fêmea favorece ou prejudica a dispersão de doenças [8] e como a estrutura da rede sexual modula a operação da seleção sexual [6, 7].

O projeto original propõe o uso de um modelo SIR para simular o espalhamento da doença. No entanto, considerando a natureza das ISTs, consideramos que o modelo SIS pode ser implementado como um cenário alternativo. A simulação da epidemia ocorrerá até que a doença se extinga, atinja um estado endêmico (no caso do SIS) ou se transforme em uma grande epidemia, definida como um surto que infecta pelo menos 15% da população, um limiar metodológico validado em estudos de modelagem de surtos.

---

## Descrição Biológica do Modelo

O modelo representa uma população com dois sexos e escolha sexual centrada nas fêmeas. Cada fêmea possui um critério de escolha $c$ e cada macho expressa um traço $z$. A compatibilidade fêmea-macho é resumida por $P_{ij}$, que pode assumir uma forma direcional (logística, favorecendo valores maiores de $z$ em relação a $c$) ou estabilizadora (gaussiana em torno de $z \approx c$). Dessa forma, a preferência feminina estrutura a rede de contatos e, em última instância, os acasalamentos.

A dinâmica ocorre em temporadas reprodutivas bem delimitadas (próprias de espécies sazonais). Cada temporada é discretizada em micro-passos que representam encontros; ao final da temporada ocorre o evento de acasalamento. A rede de contatos é bipartida (Machos-Fêmeas) e simples (uma aresta por par). Para maior realismo, no início, definimos um limite de parceiros por indivíduo, o que implica promiscuidade moderada/poliginia limitada dentro da estação. Embora a aresta seja única, ela pode ser ativada repetidas vezes ao longo da temporada, capturando múltiplas cópulas com a mesma dupla.

Na versão base, cada fêmea realiza um acasalamento efetivo ao término da temporada (monandria efetiva para paternidade), critério que pode ser relaxado em extensões com poliandria efetiva. Entre temporadas, a população mantém tamanho fixo (coortes de gerações discretas, sem sobreposição): após o acasalamento, os traços e critérios são atualizados por herança aditiva com mutação (filhos machos herdam $z$ do pai; filhas herdam $c$ da mãe), e inicia-se a temporada seguinte com o mesmo $N$.

A infecção é modelada como uma IST de transmissão por contato pareado: só pode ser transmitida quando a aresta está ativa em um micro-passo. Empregamos um esquema SIR/SIS. A infecção afeta a condição/atratividade por meio do termo $h$, de modo que o estado infeccioso pode reduzir, não alterar ou aumentar a probabilidade de contato/acasalamento:

$$h_I < 0, \quad h_I = 0, \quad h_I > 0$$

Esse acoplamento permite avaliar hipóteses de dependência de condição: como a doença modula o emparelhamento, reconfigura a arquitetura da rede (grau, densidade, aninhamento, modularidade, centralidade) e retroalimenta a seleção sexual (efeito na evolução do *trait* $z$).

A probabilidade de cópula ($P_{ij}$) entre uma fêmea $i$ e um macho $j$ reflete o quão bem o sinal do macho $z$, agora modificado pela condição de saúde $h$, corresponde à preferência da fêmea $c$:

* **Seleção Direcional (função logística):**
  $$P_{ij} = \frac{1}{1 + \exp(-((z_j + h_j) - c_i))}$$

* **Seleção Estabilizadora (função gaussiana):**
  $$P_{ij} = \exp\left(-((z_j + h_j) - c_i)^2\right)$$

---

## Cenários a Testar

```{r cenarios-tabela, echo=FALSE}
cenarios <- data.frame(
  `Fator Experimental` = c(
    "Variância da preferência feminina $\\sigma_c$",
    "Regime de Seleção",
    "Efeito da infecção no trait $z$ dos machos",
    "Tipo de Modelo"
  ),
  Níveis = c(
    "0.5, 1, 1.5",
    "Direcional, Estabilizadora",
    "Positivo: $h_I > 0$<br>Neutro: $h_I = 0$<br>Negativo: $h_I < 0$",
    "SIR ou SIS"
  ),
  Justificativa = c(
    "Investigar como a variação na preferência modula os resultados.",
    "Comparar os efeitos de diferentes formas de seleção sobre a evolução do trait do macho.",
    "Doenças/infecções nem sempre têm um efeito negativo na atratividade dos machos. O $h$ dos infectados ($h_I$) tem sinal positivo, negativo ou neutro.",
    "Investigar se o tipo de modelo de dispersão de doença pode criar diferentes padrões."
  ),
  check.names = FALSE
)

knitr::kable(cenarios, format = "markdown", caption = "Resumo dos fatores experimentais e justificativas.")
```

---

## Resultados Esperados

Como queremos investigar o efeito de $\sigma_c$ + efeito da Doença na rede de acasalamentos e evolução do *trait* do macho $z$, vamos coletar:

1. **Métricas evolutivas** do *trait* sob seleção sexual.
2. **Métricas da estrutura** da rede sexual.
3. **Métricas da evolução** da epidemia.

Ao final das simulações, disponibilizarei um conjunto padronizado de análises para cada métrica de rede avaliada: grau médio, modularidade e aninhamento (NODF). Para cada métrica, apresentarei gráficos comparativos (semelhantes à análise preliminar de grau médio vs. $\sigma_c$ avaliando a Geração 1 vs. Geração 10). Assim, sem antecipar padrões específicos, essas análises permitirão avaliar:

* (i) como cada métrica-resposta varia com $\sigma_c$ dentro de cada regime de seleção e cenário de $h$;
* (ii) como os regimes de seleção direcional e estabilizadora diferem para os mesmos níveis de $\sigma_c$;
* (iii) como a arquitetura da rede e a prevalência se transformam entre a primeira e a última geração.

Todos os resultados serão disponibilizados em tabelas de efeitos, além de arquivos CSV reproduzíveis com *seeds* e parâmetros, garantindo a reprodutibilidade das inferências.

Por fim, planejo apresentar os resultados finais no **ISBE 2026** que será realizado na Itália, além de considerar outras oportunidades, como o **ESEB Congress 2026**, **Evolution Meetings 2026** e **EcoNet2026**, tudo mediante extensão da bolsa.

---

## Cronograma

O cronograma abaixo contempla a execução completa do Objetivo 2, integrando redes sexuais, dinâmica epidemiológica e evolução de traços sob seleção sexual, seguindo alinhamento com a proposta original. Ele permite concluir a fase eco-epidemiológica, gerar produtos científicos de impacto e apresentar os resultados no ISBE 2026, garantindo o máximo retorno científico do apoio da FAPESP.

```{r cronograma-tabela, echo=FALSE}
cronograma <- data.frame(
  Trimestre = c(
    "1º Trimestre (Jan - Mar / 2026)",
    "2º Trimestre (Abr - Jun / 2026)",
    "3º Trimestre (Jul - Set / 2026)",
    "4º Trimestre (Out - Dez / 2026)"
  ),
  `Principais Atividades` = c(
    "Implementação do módulo epidemiológico acoplado às redes sexuais; integração do efeito da infecção na atratividade dos machos; testes preliminares das simulações e definição final dos cenários.",
    "Execução das simulações completas em todos os cenários; cálculo das métricas de rede e epidemiológicas; organização de bases reproduzíveis.",
    "Análises eco-epidemiológicas e evolutivas; produção de figuras e tabelas finais; redação da versão inicial do manuscrito e preparação da apresentação para o ISBE 2026.",
    "Revisão e submissão do artigo científico; apresentação dos resultados no ISBE 2026 e elaboração do relatório científico final para a FAPESP."
  ),
  check.names = FALSE
)

knitr::kable(cronograma, format = "markdown", caption = "Cronograma detalhado de execução do segundo ano de bolsa.")
```

---

## Referências

1. **Robinson, K., Cohen, T., & Colijn, C.** (2012). The dynamics of sexual contact networks: effects on disease spread and control. *Theoretical Population Biology*, 81(2), 89–96.
2. **Naffeti, B. S., Ayoub, H. H., & Abu-Raddad, L. J.** (2025). Quantifying population-level sexual risk behavior through HSV-2 transmission dynamics in the United States, 1950–2020. *Scientific Reports*, 15(1), 34521.
3. **Eames, K. T., & Keeling, M. J.** (2002). Modeling dynamic and network heterogeneities in the spread of sexually transmitted diseases. *PNAS*, 99(20), 13330–13335.
4. **Read, J. M., & Keeling, M. J.** (2003). Disease evolution on networks: the role of contact structure. *Proc. R. Soc. B*, 270(1516), 699–708.
5. **Miller, J. C.** (2017). Mathematical models of SIR disease spread with combined non-sexual and sexual transmission routes. *Infectious Disease Modelling*, 2(1), 35–55.
6. **McDonald, G. C., James, R., Krause, J., & Pizzari, T.** (2013). Sexual networks: measuring sexual selection in structured, polyandrous populations. *Phil. Trans. R. Soc. B*, 368(1613), 20120356.
7. **McDonald, G. C., & Pizzari, T.** (2018). Structure of sexual networks determines the operation of sexual selection. *PNAS*, 115(1), E53–E61.
8. **Joye, P., & Kawecki, T. J.** (2019). Sexual selection favours good or bad genes for pathogen resistance depending on males' pathogen exposure. *Proc. R. Soc. B*, 286(1902), 20190226.
9. **Hamilton, W. D., & Zuk, M.** (1982). Heritable true fitness and bright birds: a role for parasites? *Science*, 218(4570), 384–387.
10. **Sridhar, H.** (2020). Revisiting Hamilton and Zuk 1982. *Reflections on Papers Past*.
11. **Zahavi, A.** (1975). Mate selection — a selection for a handicap. *Journal of Theoretical Biology*, 53(1), 205–214.
12. **Palen, P. R., Ceballos, A. L., & Peretti, A. V.** (2023). Gut parasites infection increases mate rejection in a species with indirect sperm transfer. *Ethology*, 129(9), 454–460.
13. **Aavani, P., et al.** (2022). When sexual selection in hosts benefits parasites. *Trends in Parasitology*, 38(7), 541–544.