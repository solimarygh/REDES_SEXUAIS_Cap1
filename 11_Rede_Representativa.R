# =====================================================================
# A RÉPLICA REPRESENTATIVA DE UMA CÉLULA, E A SUA REDE
# =====================================================================
#     source("11_Rede_Representativa.R")
#     r <- rede_representativa("1", sigma_z = 2.0, sigma_p = 0.2)
#     desenhar_rede(preparar_rede(r$M), r$rotulo)
#
# As figuras conceituais geravam uma população nova a cada chamada. Isso mostra
# um mecanismo, mas o número no rótulo não é o número que o estudo reporta.
# Aqui a rede desenhada é a de uma réplica que REALMENTE rodou:
#
#   1. Nos dados já salvos, dentro da célula pedida, procura a réplica cuja
#      métrica está mais perto da média da célula. É o mesmo critério do
#      06_Rede_Representativa_e_3Atos.R.
#   2. Reconstrói a grade de cenários exatamente como o script de produção a
#      montou, e daí sai o índice global daquela réplica.
#   3. A semente é seed_base + índice global, que é como rodar_cenarios semeia.
#      Roda o motor DE VERDADE com essa semente e pede a rede de volta.
#   4. CONFERE: a métrica da rede reproduzida tem de bater com a que está
#      guardada. Se não bater, a rede não é aquela réplica, e a função avisa em
#      vez de deixar passar uma figura que não corresponde ao número.
#
# O passo 4 é o que torna isto confiável. Sem ele, qualquer descompasso entre a
# grade reconstruída aqui e a do script de produção passaria despercebido.
# =====================================================================

source("01_metricas_e_utilitarios.R")
if (!exists("simulate_controle")) { CONTROLE_SO_FUNCOES <- TRUE; source("Fase_Controle.R") }
if (!exists("simulate_espelho"))  { ESPELHO_SO_FUNCOES  <- TRUE; source("Fase_Espelho.R") }
if (!exists("simulate_coevolucao")) { COEVO_SO_FUNCOES  <- TRUE; source("Fase_Coevolucao.R") }
suppressPackageStartupMessages({ library(dplyr) })

# ---------------------------------------------------------------------
# O registro: para cada estudo, como a grade foi montada, qual foi a semente,
# onde estão os dados e como se chama o motor.
# ---------------------------------------------------------------------
# Estes valores TÊM de acompanhar os scripts de produção. Se um desenho mudar
# lá e não aqui, o passo 4 acusa: a métrica reproduzida deixa de bater.
ESTUDOS <- list(

  "1" = list(
    nome = "Controle", seed_base = 2029, geracoes = 1L,
    pasta = "Resultados_Artigo/Fase_Controle/Dados", padrao = "Controle_bestOfN",
    grade = function() expand.grid(
      tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
      sigma_p         = c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0),
      sigma_z         = c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0),
      encounters_n    = c(200, 40, 10),
      k_fixo          = c(5L, 10L, 20L),
      selecao_natural = c(TRUE, FALSE),
      replica         = 1:20),
    rodar = function(cen, gen) simulate_controle(
      N_machos = 200, N_femeas = 200,
      tipo_selecao = as.character(cen$tipo_selecao), sigma_p = cen$sigma_p,
      sigma_z = cen$sigma_z, encounters_n = cen$encounters_n,
      k_fixo = cen$k_fixo, selecao_natural = cen$selecao_natural,
      return_details = TRUE)),

  "2" = list(
    nome = "Fêmeas variando", seed_base = 2026, geracoes = 100L,
    pasta = "Resultados_Artigo/Fase5_MiudoV2/Dados", padrao = "Femeas_bestOfN",
    grade = function() expand.grid(
      tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
      sigma_p         = c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0),
      encounters_n    = c(200, 40, 10),
      k_fixo          = c(5L, 10L, 20L),
      selecao_natural = c(TRUE, FALSE),
      replica         = 1:20),
    rodar = function(cen, gen) simulate_evolution(
      generations = 100, N_machos = 200, N_femeas = 200,
      tipo_selecao = as.character(cen$tipo_selecao), sigma_p = cen$sigma_p,
      encounters_n = cen$encounters_n, k_fixo = cen$k_fixo,
      selecao_natural = cen$selecao_natural, return_details = gen)),

  "3" = list(
    nome = "Machos variando", seed_base = 2028, geracoes = 100L,
    pasta = "Resultados_Artigo/Fase_Espelho/Dados", padrao = "Espelho_bestOfN",
    grade = function() expand.grid(
      tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
      sigma_z         = c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0),
      encounters_n    = c(200, 40, 10),
      k_fixo          = c(5L, 10L, 20L),
      selecao_natural = c(TRUE, FALSE),
      replica         = 1:20),
    rodar = function(cen, gen) simulate_espelho(
      generations = 100, N_machos = 200, N_femeas = 200,
      tipo_selecao = as.character(cen$tipo_selecao), sigma_z = cen$sigma_z,
      sigma_p_init = 1.0, encounters_n = cen$encounters_n, k_fixo = cen$k_fixo,
      selecao_natural = cen$selecao_natural, return_details = gen)),

  # A metade SEM seleção natural, que é a que está fechada. A grade tem de ser a
  # do arquivo lido: COEVO_NS=sem gera só selecao_natural = FALSE.
  "4" = list(
    nome = "Co-evolução", seed_base = 2030, geracoes = 100L,
    pasta = "Resultados_Artigo/Fase_Coevolucao/Dados",
    padrao = "Coevolucao_genica_neAdulto_sem_completo",
    grade = function() expand.grid(
      tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
      sigma_p_init    = c(0.5, 1.0, 2.0),
      sigma_z_init    = c(0.5, 1.0, 2.0),
      encounters_n    = c(200, 40, 10),
      k_fixo          = c(5L, 10L, 20L),
      selecao_natural = FALSE,
      replica         = 1:20),
    rodar = function(cen, gen) simulate_coevolucao(
      generations = 100, tipo_selecao = as.character(cen$tipo_selecao),
      sigma_p_init = cen$sigma_p_init, sigma_z_init = cen$sigma_z_init,
      encounters_n = cen$encounters_n, k_fixo = cen$k_fixo,
      selecao_natural = cen$selecao_natural, segregacao = "genica",
      return_details = gen))
)

# ---------------------------------------------------------------------
# Leitura dos dados de um estudo, guardada em cache: quem chama isto numa
# figura de quatro painéis não precisa reler o .rds quatro vezes.
# ---------------------------------------------------------------------
.cache_dados <- new.env(parent = emptyenv())

dados_do_estudo <- function(estudo) {
  if (!is.null(.cache_dados[[estudo]])) return(.cache_dados[[estudo]])
  e <- ESTUDOS[[estudo]]
  arqs <- list.files(e$pasta, full.names = TRUE,
                     pattern = sprintf("^(backup|resultados)_.*%s.*\\.rds$", e$padrao))
  if (!length(arqs)) return(NULL)
  ler <- function(a) {
    o <- readRDS(a)
    if (is.data.frame(o)) o else bind_rows(o[!vapply(o, is.null, logical(1))])
  }
  df <- distinct(bind_rows(lapply(arqs, ler)))
  .cache_dados[[estudo]] <- df
  df
}

# ---------------------------------------------------------------------
# A função principal
# ---------------------------------------------------------------------
# `...` são as colunas que definem a célula, com os nomes que o estudo usa:
#   estudo 1: sigma_z, sigma_p, encounters_n, k_fixo, selecao_natural, tipo_selecao
#   estudo 2: sigma_p, ...   estudo 3: sigma_z, ...   estudo 4: sigma_*_init, ...
# O que não for dado fica no default abaixo.
rede_representativa <- function(estudo, ..., metrica = "Modularity",
                                geracao = NULL, verboso = TRUE) {
  estudo <- as.character(estudo)
  e <- ESTUDOS[[estudo]]
  if (is.null(e)) stop("Estudo desconhecido: ", estudo)

  dados <- dados_do_estudo(estudo)
  if (is.null(dados)) return(NULL)   # sem dados, quem chama decide o que fazer

  grade <- e$grade()
  grade$idx_global <- seq_len(nrow(grade))

  # A célula: o que foi pedido, mais os defaults para o resto.
  pedido <- list(...)
  padrao <- list(tipo_selecao = "gaussian", encounters_n = 200,
                 k_fixo = 5L, selecao_natural = FALSE)
  for (nm in names(padrao)) if (is.null(pedido[[nm]])) pedido[[nm]] <- padrao[[nm]]
  pedido <- pedido[names(pedido) %in% names(grade)]

  filtra <- function(df) {
    keep <- rep(TRUE, nrow(df))
    for (nm in names(pedido)) {
      col <- df[[nm]]
      if (is.factor(col)) col <- as.character(col)
      alvo <- pedido[[nm]]
      keep <- keep & (if (is.numeric(col)) abs(col - alvo) < 1e-8 else col == alvo)
    }
    df[keep, , drop = FALSE]
  }

  # A geração de referência: a última, salvo pedido em contrário.
  gen <- if (!is.null(geracao)) as.integer(geracao) else e$geracoes
  celula <- filtra(dados)
  if ("generation" %in% names(celula)) celula <- celula[celula$generation == gen, , drop = FALSE]
  celula <- celula[!is.na(celula[[metrica]]), , drop = FALSE]
  if (!nrow(celula)) return(NULL)

  # Se a chamada não fixou todas as colunas do desenho, a "célula" é na verdade
  # um conjunto de células, e a média percorre todas elas. Não é erro, mas quem
  # lê a figura precisa saber.
  chaves <- setdiff(names(grade), c("replica", "idx_global"))
  soltas <- setdiff(chaves, names(pedido))
  if (length(soltas) && verboso)
    cat(sprintf("  aviso: %s não foi fixado, então a média percorre esses níveis.\n",
                paste(soltas, collapse = ", ")))

  # A réplica representativa: a mais próxima da média da célula.
  media   <- mean(celula[[metrica]])
  escolha <- celula[which.min(abs(celula[[metrica]] - media)), ]

  # A linha da grade é procurada com os valores da PRÓPRIA réplica escolhida, e
  # não com o que a chamada pediu. Assim ela fica sempre completamente
  # especificada, mesmo que a chamada tenha deixado alguma coluna solta.
  linha <- grade
  for (nm in chaves) {
    if (!nm %in% names(escolha)) next
    col <- linha[[nm]]; if (is.factor(col)) col <- as.character(col)
    alvo <- escolha[[nm]]; if (is.factor(alvo)) alvo <- as.character(alvo)
    linha <- linha[if (is.numeric(col)) abs(col - alvo) < 1e-8 else col == alvo, , drop = FALSE]
  }
  linha <- linha[linha$replica == escolha$replica, , drop = FALSE]
  if (nrow(linha) != 1) {
    warning("Não consegui localizar a célula na grade do estudo ", estudo,
            ": a grade reconstruída aqui não corresponde à do script de produção.")
    return(NULL)
  }

  semente <- e$seed_base + linha$idx_global
  set.seed(semente)
  res <- e$rodar(linha, gen)
  rede <- if (!is.null(res$rede)) res$rede else res[[paste0("gen", gen)]]
  if (is.null(rede)) {
    warning("O motor do estudo ", estudo, " não devolveu a rede da geração ", gen, ".")
    return(NULL)
  }

  # O passo que garante que a figura corresponde ao número.
  obtido   <- rede$metrics[[metrica]]
  esperado <- escolha[[metrica]]
  confere  <- isTRUE(abs(obtido - esperado) < 1e-8)
  if (!confere) {
    warning(sprintf(
      "Estudo %s: a rede reproduzida NÃO é a réplica dos dados (%s obtido %.4f, guardado %.4f). A figura não corresponde ao número.",
      estudo, metrica, obtido, esperado))
    return(NULL)
  }
  if (verboso)
    cat(sprintf("  estudo %s, réplica %d, geração %d, semente %d: %s = %.3f (média da célula %.3f)\n",
                estudo, escolha$replica, gen, semente, metrica, obtido, media))

  list(M = rede$M, metrics = rede$metrics, replica = escolha$replica,
       geracao = gen, semente = semente, media_celula = media, confere = confere,
       rotulo = sprintf("réplica %d de %d, a mais próxima da média da célula",
                        escolha$replica, nrow(celula)))
}
