# =====================================================================
# Script 13: gera o anexo reduzido, com os Estudos 1 e 2 apenas
# =====================================================================
# O Relatório Científico de 30/08 a 31/12 de 2025 relata dois estudos, e o
# Material suplementar completo documenta quatro. Anexar o completo diria ao
# revisor que o período cobriu mais do que cobriu.
#
# Este script recorta o completo em vez de manter um segundo documento escrito
# à mão. A razão é simples de enunciar: dois arquivos com o mesmo texto
# divergem na primeira correção que se faça num só deles. Aqui existe uma
# fonte, Material_Suplementar.Rmd, e o anexo reduzido é derivado dela.
#
# Uso:
#     Rscript 13_Anexo_Estudos1e2.R
#     Rscript -e 'rmarkdown::render("Material_Suplementar_Estudos1e2.Rmd")'
#
# O arquivo gerado NÃO deve ser editado à mão: a próxima execução o sobrescreve.
# Correções vão no Material_Suplementar.Rmd, ou nos remendos abaixo.
# =====================================================================

FONTE  <- "Material_Suplementar.Rmd"
DESTINO <- "Material_Suplementar_Estudos1e2.Rmd"

# O corte: tudo a partir desta linha sai. As seções 3, 4 e 5 são blocos
# contíguos no fim do documento, de modo que um corte só basta.
CORTE <- "# 3. Machos variando"

# ---------------------------------------------------------------------
# Os remendos. Cada um é um par (procurar, substituir), e o script PARA se
# algum não for encontrado — é o que impede que uma edição no documento fonte
# produza aqui, em silêncio, um anexo que ainda fala de quatro estudos.
# ---------------------------------------------------------------------
REMENDOS <- list(

  # --- identificação do documento -----------------------------------
  list(
    de = 'subtitle: "Estrutura de redes de acasalamento sob escolha de parceiro: os quatro estudos de simulação"',
    para = 'subtitle: "Estrutura de redes de acasalamento sob escolha de parceiro: os Estudos 1 e 2"'
  ),
  list(
    de = "/* Os cinco estudos são os cabeçalhos de nível 1, e é por eles que se navega.",
    para = "/* Os estudos são os cabeçalhos de nível 1, e é por eles que se navega."
  ),

  # --- nota de escopo, logo na abertura -----------------------------
  list(
    de = "# Introdução\n",
    para = paste0(
      "# Introdução\n\n",
      "Este anexo acompanha o Relatório Científico do período de 30 de agosto a\n",
      "31 de dezembro de 2025 e documenta os dois estudos concluídos nele: o\n",
      "Estudo 1, que mede a estrutura da rede numa geração, e o Estudo 2, que\n",
      "acompanha a evolução do traço masculino ao longo de cem gerações. As duas\n",
      "extensões desenvolvidas depois, o Estudo 3 e a Co-evolução, constarão do\n",
      "anexo do Relatório Científico Final.\n"
    )
  ),

  # --- a seção que apresenta os estudos ------------------------------
  list(
    de = paste0(
      "# Os quatro estudos\n\n",
      "Os quatro compartilham exatamente o mesmo ciclo de vida, as mesmas quatro\n",
      "curvas e os mesmos fatores ecológicos. O que muda entre eles é quais\n",
      "características são herdadas, ou seja, quais estão livres para responder à\n",
      "seleção. Cada um isola uma peça do sistema.\n"
    ),
    para = paste0(
      "# Os dois estudos deste anexo\n\n",
      "Os dois compartilham exatamente o mesmo ciclo de vida, as mesmas quatro\n",
      "curvas e os mesmos fatores ecológicos. O que muda entre eles é quais\n",
      "características são herdadas, ou seja, quais estão livres para responder à\n",
      "seleção. Cada um isola uma peça do sistema.\n\n",
      "A tabela traz os quatro, com a indicação de onde cada um é relatado: os\n",
      "Estudos 1 e 2 neste anexo, e os dois seguintes no anexo do Relatório\n",
      "Científico Final. Ficam aqui para situar os dois primeiros no desenho\n",
      "completo.\n"
    )
  ),

  # --- a tabela diz qual estudo e relatado onde ----------------------
  # A frase acima ja o dizia, mas quem consulta a tabela nao volta ao
  # paragrafo. A coluna do nome leva a marca.
  list(
    de = paste0(
      "| 1. Controle | σp e σz | sorteado | sorteada | a estrutura que as curvas de preferência produzem sozinhas, sem resposta evolutiva |\n",
      "| 2. Fêmeas variando | σp | herdável | re-sorteada | como a heterogeneidade de preferência afeta a evolução do traço |\n",
      "| 3. Machos variando | σz | re-sorteado | herdável | como a variedade de machos disponíveis afeta a evolução da preferência |\n",
      "| 4. Co-evolução | os dois, só como condição inicial | herdável | herdável | o feedback entre as duas características |\n"
    ),
    para = paste0(
      "| 1. Controle *(neste anexo)* | σp e σz | sorteado | sorteada | a estrutura que as curvas de preferência produzem sozinhas, sem resposta evolutiva |\n",
      "| 2. Fêmeas variando *(neste anexo)* | σp | herdável | re-sorteada | como a heterogeneidade de preferência afeta a evolução do traço |\n",
      "| 3. Machos variando *(relatório final)* | σz | re-sorteado | herdável | como a variedade de machos disponíveis afeta a evolução da preferência |\n",
      "| 4. Co-evolução *(relatório final)* | os dois, só como condição inicial | herdável | herdável | o feedback entre as duas características |\n"
    )
  ),
  list(
    de = paste0(
      "O Controle roda uma geração, porque sem herança a segunda geração seria um\n",
      "sorteio independente com a mesma distribuição. Cada cenário exige assim cerca de\n",
      "cem vezes menos tempo de computação do que nos outros três, que rodam 100\n",
      "gerações, e é essa economia que permite cruzar σp com σz por inteiro.\n"
    ),
    para = paste0(
      "O Controle roda uma geração, porque sem herança a segunda geração seria um\n",
      "sorteio independente com a mesma distribuição. Cada cenário exige assim cerca de\n",
      "cem vezes menos tempo de computação do que no Estudo 2, que roda 100 gerações,\n",
      "e é essa economia que permite cruzar σp com σz por inteiro.\n"
    )
  ),
  list(
    de = paste0(
      "Nos Estudos 2 e 3 a característica que não é herdada é re-sorteada a cada\n",
      "geração da mesma distribuição. O procedimento mantém a dispersão fixa no valor\n",
      "do tratamento durante as 100 gerações e impede que ela mude ao mesmo tempo que a\n",
      "outra, o que confundiria a interpretação. No Estudo 4 ele não se aplica, porque\n",
      "re-sortear é o que impede a herança, e ali os dois sigmas são apenas condição\n",
      "inicial.\n"
    ),
    para = paste0(
      "No Estudo 2 a característica que não é herdada, a preferência da fêmea, é\n",
      "re-sorteada a cada geração da mesma distribuição. O procedimento mantém a\n",
      "dispersão fixa no valor do tratamento durante as 100 gerações e impede que ela\n",
      "mude ao mesmo tempo que a outra, o que confundiria a interpretação.\n"
    )
  ),

  # --- a tabela de cobertura sai do anexo ---------------------------
  # Com dois estudos a tabela nao acrescenta nada: Estudo, Eixo e "O que evolui"
  # repetem a tabela da secao anterior, Rodada e Geracoes ja estao ditas em
  # prosa, e Situacao e "concluido" nas duas linhas. O unico dado novo e a
  # contagem de cenarios, que passa para a frase seguinte, interpolada da mesma
  # funcao n_cen() e portanto medida e nao escrita a mao.
  #
  # As duas funcoes auxiliares ficam: n_cen() e usada logo abaixo, e n_ger()
  # nao custa nada. Por isso o remendo troca so o tibble, e nao o bloco inteiro.
  list(
    de = paste0(
      "tibble(\n",
      '  Estudo     = c("Controle", "Fêmeas variando", "Machos variando", "Co-evolução"),\n',
      '  Eixo       = c("σp × σz (superfície)", "σp", "σz", "os dois, herdáveis"),\n',
      '  `O que evolui` = c("nada", "o traço do macho (z)", "a preferência da fêmea (p)", "os dois"),\n',
      "  Rodada     = c(rodada_de(ct), rodada_de(d), rodada_de(esp),\n",
      '                 if (ok(co)) "bestOfN" else "-"),\n',
      "  Gerações   = c(n_ger(ct), n_ger(d), n_ger(esp), n_ger(co)),\n",
      '  Cenários   = c(n_cen(ct, c("sigma_p", "sigma_z")), n_cen(d, "sigma_p"),\n',
      '                 n_cen(esp, "sigma_z"), n_cen(co, c("sigma_p_init", "sigma_z_init"))),\n',
      '  Situação   = c(if (ok(ct)) "concluído" else "sem dados",\n',
      '                 if (ok(d))  "concluído" else "sem dados",\n',
      '                 if (ok(esp)) "concluído" else "sem dados",\n',
      '                 if (ok(co)) "concluído" else "não rodado")\n',
      ') %>% kable(caption = "O que está neste documento. Cenários inclui as 20 réplicas de cada combinação de parâmetros.")\n'
    ),
    para = ""
  ),

  # --- a contagem de cenarios passa para a prosa --------------------
  list(
    de = paste0(
      "Uma *combinação* é um ponto concreto do desenho, ou seja um valor fixado para\n",
      "cada um dos seis fatores, e um *cenário* é uma réplica dessa combinação. Os\n",
      "fatores já foram definidos acima, um a um; a tabela os reúne com os seus\n",
      "níveis, para consulta:\n"
    ),
    para = paste0(
      "Uma *combinação* é um ponto concreto do desenho, ou seja um valor fixado para\n",
      "cada um dos seis fatores, e um *cenário* é uma réplica dessa combinação. São\n",
      "`r n_cen(ct, c(\"sigma_p\", \"sigma_z\"))` cenários no Estudo 1, de uma geração\n",
      "cada, e `r n_cen(d, \"sigma_p\")` no Estudo 2, de cem gerações cada, com as 20\n",
      "réplicas já contadas dentro dos dois números. Os fatores já foram definidos\n",
      "acima, um a um; a tabela os reúne com os seus níveis, para consulta:\n"
    )
  ),

  # --- os níveis que cada estudo visita ------------------------------
  list(
    de = paste0(
      "Os dois sigmas se cruzam por inteiro apenas no Controle (Estudo 1). No Estudo 2 σp percorre\n",
      "os sete níveis e σz é condição inicial fixada em 1.0; no Estudo 3 é o espelho.\n",
      "No Estudo 4 os dois são condição inicial, com três níveis cada, 0.5, 1.0 e 2.0.\n"
    ),
    para = paste0(
      "Os dois sigmas se cruzam por inteiro apenas no Controle (Estudo 1). No Estudo 2 σp percorre\n",
      "os sete níveis e σz é condição inicial fixada em 1.0.\n"
    )
  ),

  # --- a figura do desenho sai do anexo ------------------------------
  # O esquema das condições iniciais tem quatro painéis, e dois deles são dos
  # estudos que não estão aqui. Fora isso, o que ele mostra para os dois que
  # ficam - o Controle cruza a grade inteira, o Estudo 2 percorre uma coluna -
  # já está dito na frase acima e volta a ser dito, com dados em vez de esquema,
  # na abertura da seção do Controle. Sai a figura e sai o parágrafo que a
  # apresenta.
  list(
    de = paste0(
      "A figura abaixo mostra sobre que parte desse espaço os cenários estão\n",
      "distribuídos. O contraste entre os painéis segue da razão de custo já dada: só o\n",
      "Controle, que roda uma geração, pode medir a superfície inteira. A grade é a\n",
      "mesma nos quatro, e em vermelho estão as condições iniciais que\n",
      "aquele estudo visita: o Controle cruza a grade inteira, os dois espelhos\n",
      "percorrem uma coluna ou uma linha, com o outro eixo fixado em 1.0, e a\n",
      "co-evolução parte do cruzamento de três níveis em cada eixo.\n",
      "\n",
      "A figura é um esquema do desenho, e não saída da simulação.\n",
      "\n",
      "```{r fig-desenho, fig.width=10, fig.height=8}\n",
      "figura_desenho()\n",
      "```\n"
    ),
    para = ""
  ),

  # --- a seccao 1.2 sai do anexo ------------------------------------
  # Decisao de escopo. Os cortes mostram a mesma informacao da 1.1 em linhas em
  # vez de cores, e a secao fica no Material suplementar completo.
  list(
    de = paste0(
      "## 1.2 Cortes ao longo de σz {.tabset}\n",
      "\n",
      "Nesta seção mostramos a mesma informação da anterior, mas em linhas em vez de\n",
      "cores, o que facilita a leitura dos valores. Cada linha corresponde a um nível de σp: as\n",
      "escuras são populações de fêmeas homogêneas, as claras de fêmeas heterogêneas.\n",
      "\n",
      "A forma do conjunto de linhas responde a uma pergunta estatística direta. Se\n",
      "forem paralelas, σp e σz agem de forma aditiva. Se se cruzarem ou abrirem em\n",
      "leque, há interação entre os dois, ou seja, o efeito da variação entre machos\n",
      "depende de quanta variação existe entre fêmeas.\n",
      "\n",
      "```{r ct-cortes, results='asis', fig.width=12, fig.height=10}\n",
      "if (!ok(ct)) cat(\"\\n*Sem dados do Controle.*\\n\") else\n",
      "render_tabs(function(kk, amax, ns)\n",
      "  plot_cortes(ct, kk, amax, ns, quais_metricas,\n",
      "              rotulo(\"CONTROLE — cortes ao longo de σz\", ns, amax, kk)))\n",
      "```\n",
      "\n"
    ),
    para = ""
  ),

  # --- renumeracao depois da saida da 1.2 ---------------------------
  # Sem isto a barra lateral do anexo mostraria 1.1, 1.3, 1.4, com um buraco
  # que so se explica olhando o documento completo. A referencia cruzada da
  # seccao 2.3 acompanha.
  list(de = "## 1.3 O acesso ao acasalamento, do lado das fêmeas {.tabset}",
       para = "## 1.2 O acesso ao acasalamento, do lado das fêmeas {.tabset}"),
  list(de = "## 1.4 O acesso ao acasalamento, do lado dos machos {.tabset}",
       para = "## 1.3 O acesso ao acasalamento, do lado dos machos {.tabset}"),
  list(de = "seção 1.3, mas agora com evolução.",
       para = "seção 1.2, mas agora com evolução."),

  # --- o regime de busca sai do anexo -------------------------------
  # Decisao de escopo, nao de conteudo: a secao fica no Material suplementar
  # completo. Aqui sai o paragrafo que a apresenta, o cabecalho e o bloco que
  # desenha as quatro abas.
  list(
    de = paste0(
      "A figura anterior varia a composição da população. A seguinte varia o outro\n",
      "nível do desenho, o regime de busca, que nos resultados é o que mais pesa.\n",
      "Agora a composição da população é a mesma nos quatro painéis, e o que muda é\n",
      "quantos machos cada fêmea avalia e quantos pode aceitar. Cada painel traz esses\n",
      "dois números do tratamento e, ao lado, a poliandria realizada, que é quantos\n",
      "parceiros as fêmeas de fato conseguiram: é ela, e não o k nominal, que diz o\n",
      "quanto a escolha foi seletiva naquela combinação.\n",
      "\n",
      "### O regime de busca, curva por curva {.tabset}\n",
      "\n",
      "```{r ct-rede-busca, results='asis', fig.width=9, fig.height=9}\n",
      "for (cv in CURVAS) {\n",
      "  cat(\"\\n\\n#### \", labels_4[[cv]], \"\\n\\n\", sep = \"\")\n",
      "  figura_busca(tipo = cv)\n",
      "  cat(\"\\n\\n\")\n",
      "}\n",
      "```\n",
      "\n"
    ),
    para = ""
  ),

  # --- não carregar os dados que o anexo não usa ----------------------
  # São milhões de linhas em cada um, e sem eles o render fica muito mais leve.
  # com_derivadas() devolve NULL sem tocar em nada, de modo que a linha
  # seguinte continua válida.
  list(
    de = 'esp <- carregar_rodada("Resultados_Artigo/Fase_Espelho/Dados",  "Espelho")',
    para = 'esp <- NULL   # Estudo 3: fora deste anexo, e não se carrega o que não se usa'
  ),
  # O bloco da Co-evolução fica no arquivo mas dentro de if (FALSE), para que o
  # remendo continue a ser um só e o código não precise ser apagado. Renomear a
  # variável não bastaria: o local() rodaria igual e leria os arquivos.
  list(
    de = 'co <- local({',
    para = paste0('co <- NULL   # Co-evolução: idem\n',
                  'if (FALSE) local({   # bloco original, mantido inativo\n')
  )
)

# =====================================================================
# Execução
# =====================================================================
# Os remendos acima têm acentos e sigmas, e num locale que não seja UTF-8 o R
# não consegue nem comparar as cadeias: falha com "regular expression is
# invalid UTF-8". No macOS o locale já é UTF-8; num contêiner pode não ser.
if (!isTRUE(l10n_info()[["UTF-8"]]))
  stop("O locale desta sessão não é UTF-8 (", Sys.getlocale("LC_CTYPE"), "), e os\n",
       "remendos deste script têm acentos. Rode assim:\n\n",
       "    LANG=C.UTF-8 LC_ALL=C.UTF-8 Rscript 13_Anexo_Estudos1e2.R\n")

if (!file.exists(FONTE)) stop("Não encontrei ", FONTE, ". Rode a partir da raiz do repositório.")

texto <- paste(readLines(FONTE, encoding = "UTF-8", warn = FALSE), collapse = "\n")

# 1. O corte
pos <- regexpr(CORTE, texto, fixed = TRUE)
if (pos < 0) stop("Não achei o marcador de corte: ", CORTE,
                  "\nO documento fonte mudou de estrutura. Confira os cabeçalhos de nível 1.")
texto <- substr(texto, 1, pos - 1)

# 2. Os remendos, com verificação de cada um
faltando <- character(0)
for (r in REMENDOS) {
  if (!grepl(r$de, texto, fixed = TRUE)) {
    faltando <- c(faltando, substr(r$de, 1, 70))
    next
  }
  texto <- sub(r$de, r$para, texto, fixed = TRUE)
}
if (length(faltando))
  stop("Estes trechos do documento fonte mudaram e os remendos não se aplicam:\n  - ",
       paste(faltando, collapse = "\n  - "),
       "\n\nAtualize a lista REMENDOS em 13_Anexo_Estudos1e2.R antes de gerar o anexo.",
       call. = FALSE)

# 3. O aviso de arquivo gerado, logo abaixo do YAML
marca <- paste0(
  "<!-- ARQUIVO GERADO por 13_Anexo_Estudos1e2.R a partir de ", FONTE, ".\n",
  "     Não editar à mão: a próxima execução do script sobrescreve o que estiver aqui.\n",
  "     Correções vão no documento fonte, ou nos remendos do script. -->\n"
)
fim_yaml <- regexpr("\n---\n", texto, fixed = TRUE)
texto <- paste0(substr(texto, 1, fim_yaml + 4), marca,
                substr(texto, fim_yaml + 5, nchar(texto)))

writeLines(texto, DESTINO, useBytes = TRUE)

cat("Gerado:", DESTINO, "\n")
cat("Linhas:", length(strsplit(texto, "\n")[[1]]),
    "(fonte tem", length(readLines(FONTE, warn = FALSE)), ")\n")
cat("\nPara renderizar:\n  Rscript -e 'rmarkdown::render(\"", DESTINO, "\")'\n", sep = "")
