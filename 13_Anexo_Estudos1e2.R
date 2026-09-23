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
      "seleção. Cada um isola uma peça do sistema. As duas últimas linhas da\n",
      "tabela são as extensões que virão no relatório final, e estão aqui para\n",
      "situar os dois primeiros no desenho completo.\n"
    )
  ),
  list(
    de = paste0(
      "O Controle roda uma geração, porque sem herança a segunda geração seria um\n",
      "sorteio independente com a mesma distribuição. Isso o torna cerca de cem vezes\n",
      "mais barato que os outros, e é o que permite cruzar σp com σz por inteiro. Os\n",
      "outros três rodam 100 gerações.\n"
    ),
    para = paste0(
      "O Controle roda uma geração, porque sem herança a segunda geração seria um\n",
      "sorteio independente com a mesma distribuição. Isso o torna cerca de cem vezes\n",
      "mais barato, e permite cruzar σp com σz por inteiro. O Estudo 2 roda 100\n",
      "gerações.\n"
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

  # --- a tabela de cobertura -----------------------------------------
  # Sai o que não está no anexo. As colunas que liam `esp` e `co` sairiam
  # vazias de qualquer modo, já que os dois deixam de ser carregados.
  list(
    de = paste0(
      '  Estudo     = c("Controle", "Fêmeas variando", "Machos variando", "Co-evolução"),\n',
      '  Eixo       = c("σp × σz (superfície)", "σp", "σz", "os dois, herdáveis"),\n',
      '  `O que evolui` = c("nada", "o traço do macho (z)", "a preferência da fêmea (p)", "os dois"),\n',
      '  Rodada     = c(rodada_de(ct), rodada_de(d), rodada_de(esp),\n',
      '                 if (ok(co)) "bestOfN" else "-"),\n',
      '  Gerações   = c(n_ger(ct), n_ger(d), n_ger(esp), n_ger(co)),\n',
      '  Cenários   = c(n_cen(ct, c("sigma_p", "sigma_z")), n_cen(d, "sigma_p"),\n',
      '                 n_cen(esp, "sigma_z"), n_cen(co, c("sigma_p_init", "sigma_z_init"))),\n',
      '  Situação   = c(if (ok(ct)) "concluído" else "sem dados",\n',
      '                 if (ok(d))  "concluído" else "sem dados",\n',
      '                 if (ok(esp)) "concluído" else "sem dados",\n',
      '                 if (ok(co)) "concluído" else "não rodado")\n'
    ),
    para = paste0(
      '  Estudo     = c("Controle", "Fêmeas variando"),\n',
      '  Eixo       = c("σp × σz (superfície)", "σp"),\n',
      '  `O que evolui` = c("nada", "o traço do macho (z)"),\n',
      '  Rodada     = c(rodada_de(ct), rodada_de(d)),\n',
      '  Gerações   = c(n_ger(ct), n_ger(d)),\n',
      '  Cenários   = c(n_cen(ct, c("sigma_p", "sigma_z")), n_cen(d, "sigma_p")),\n',
      '  Situação   = c(if (ok(ct)) "concluído" else "sem dados",\n',
      '                 if (ok(d))  "concluído" else "sem dados")\n'
    )
  ),

  # --- os níveis que cada estudo visita ------------------------------
  list(
    de = paste0(
      "Os dois sigmas se cruzam por inteiro apenas no Controle. No Estudo 2 σp percorre\n",
      "os sete níveis e σz é condição inicial fixada em 1.0; no Estudo 3 é o espelho.\n",
      "No Estudo 4 os dois são condição inicial, com três níveis cada, 0.5, 1.0 e 2.0.\n"
    ),
    para = paste0(
      "Os dois sigmas se cruzam por inteiro apenas no Controle. No Estudo 2 σp percorre\n",
      "os sete níveis e σz é condição inicial fixada em 1.0.\n"
    )
  ),

  # --- a figura do desenho, que mostra os quatro painéis --------------
  # A figura fica: é onde se vê que os dois estudos deste anexo ocupam uma
  # parte do plano e não o plano todo. O texto é que passa a dizer quais
  # painéis pertencem a este período.
  list(
    de = paste0(
      "A tabela diz quantos cenários existem; a figura diz sobre que parte do espaço\n",
      "de parâmetros eles estão distribuídos. A grade é a mesma nos quatro painéis, e\n",
      "em vermelho estão as condições iniciais que aquele estudo visita: o\n",
      "Controle cruza a grade inteira, os dois espelhos percorrem uma coluna ou uma\n",
      "linha, com o outro eixo fixado em 1.0, e a co-evolução parte do cruzamento de\n",
      "três níveis em cada eixo.\n"
    ),
    para = paste0(
      "A tabela diz quantos cenários existem; a figura diz sobre que parte do espaço\n",
      "de parâmetros eles estão distribuídos. A grade é a mesma nos quatro painéis, e\n",
      "em vermelho estão as condições iniciais que aquele estudo visita. Os dois\n",
      "painéis de cima são os estudos deste anexo: o Controle cruza a grade inteira e\n",
      "o Estudo 2 percorre uma coluna, com o outro eixo fixado em 1.0. Os dois de\n",
      "baixo são as extensões do relatório final, e ficam na figura para mostrar que\n",
      "parte do plano ainda não foi visitada no período relatado.\n"
    )
  ),
  list(
    de = paste0(
      "O contraste entre os painéis explica a diferença de custo. O Controle mede a\n",
      "superfície inteira porque roda uma geração só; os outros três rodam cem, e por\n",
      "isso percorrem uma linha, uma coluna ou um punhado de pontos de partida.\n"
    ),
    para = paste0(
      "O contraste entre os painéis explica a diferença de custo. O Controle mede a\n",
      "superfície inteira porque roda uma geração só; os outros rodam cem, e por isso\n",
      "percorrem uma linha, uma coluna ou um punhado de pontos de partida.\n"
    )
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
       "\n\nAtualize REMENDOS em ", basename(sys.frame(1)$ofile %||% "13_Anexo_Estudos1e2.R"),
       " antes de gerar o anexo.")

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
