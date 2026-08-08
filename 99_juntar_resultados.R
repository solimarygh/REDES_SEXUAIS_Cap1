# =====================================================================
# JUNTAR OS PEDAÇOS RODADOS EM MÁQUINAS DIFERENTES
# =====================================================================
# Quando um estudo é repartido com REP_MIN/REP_MAX, cada máquina gera um arquivo
# com sufixo (_rep1-14, _rep15-20, ...). Este script encontra todos os pedaços de
# cada estudo, junta e confere se o desenho ficou completo.
#
#   Rscript 99_juntar_resultados.R
#
# Aceita tanto o backup (lista de data.frames, com NULLs onde faltou) quanto o
# arquivo final (data.frame já montado), então funciona mesmo se uma máquina
# ainda não tiver terminado.
# =====================================================================

suppressPackageStartupMessages({ library(dplyr) })

juntar_estudo <- function(pasta, prefixo, n_replicas_esperado) {
  arquivos <- list.files(pasta, pattern = paste0("^", prefixo, ".*\\.rds$"), full.names = TRUE)
  if (length(arquivos) == 0) {
    cat(sprintf("  nenhum arquivo com prefixo '%s' em %s\n", prefixo, pasta))
    return(NULL)
  }

  pedacos <- list()
  for (a in arquivos) {
    obj <- readRDS(a)
    df <- if (is.data.frame(obj)) {
      obj
    } else if (is.list(obj)) {
      validos <- !vapply(obj, is.null, logical(1))
      cat(sprintf("  %s: %d de %d cenários prontos\n", basename(a), sum(validos), length(obj)))
      if (!any(validos)) next
      bind_rows(obj[validos])
    } else next
    pedacos[[a]] <- df
  }

  if (length(pedacos) == 0) return(NULL)
  df <- bind_rows(pedacos)

  # Um cenário pode aparecer em mais de um arquivo (por exemplo o backup e o
  # final da mesma máquina). Como a semente é set.seed(seed_base + idx_global),
  # as linhas duplicadas são idênticas, então basta remover as repetições.
  df <- distinct(df)

  cat(sprintf("  -> %d linhas, %d réplicas distintas\n", nrow(df), dplyr::n_distinct(df$replica)))
  faltam <- setdiff(seq_len(n_replicas_esperado), sort(unique(df$replica)))
  if (length(faltam) > 0) {
    cat(sprintf("  ATENÇÃO: faltam as réplicas %s\n", paste(faltam, collapse = ", ")))
  }
  df
}

N_REPLICAS <- 20

cat("\n=== ESTUDO 1: controle ===\n")
d1 <- juntar_estudo("Resultados_Artigo/Fase_Controle/Dados", "backup_Controle_censoConst", N_REPLICAS)

cat("\n=== ESTUDO 2: fêmeas variando ===\n")
d2 <- juntar_estudo("Resultados_Artigo/Fase4_TodasAsCurvas/Dados", "backup_Femeas_censoConst", N_REPLICAS)

cat("\n=== ESTUDO 3: machos variando ===\n")
d3 <- juntar_estudo("Resultados_Artigo/Fase_Espelho/Dados", "backup_Espelho_censoConst", N_REPLICAS)

dir.create("Resultados_Artigo/Reunidos", recursive = TRUE, showWarnings = FALSE)
if (!is.null(d1)) saveRDS(d1, "Resultados_Artigo/Reunidos/Estudo1_controle.rds")
if (!is.null(d2)) saveRDS(d2, "Resultados_Artigo/Reunidos/Estudo2_femeas.rds")
if (!is.null(d3)) saveRDS(d3, "Resultados_Artigo/Reunidos/Estudo3_machos.rds")

# ---------------------------------------------------------------------
# Conferências que valem a pena antes de analisar
# ---------------------------------------------------------------------
conferir <- function(df, nome) {
  if (is.null(df)) return(invisible(NULL))
  cat(sprintf("\n--- %s ---\n", nome))
  cat(sprintf("  censo adulto: %s (esperado só 200)\n",
              paste(sort(unique(df$n_machos_surv)), collapse = ", ")))
  if ("extincao_gen" %in% names(df)) {
    n_ext <- sum(!is.na(df$extincao_gen))
    cat(sprintf("  linhas de réplicas encerradas antes do fim: %d\n", n_ext))
  }
  cat(sprintf("  poliandria realizada: média %.2f, máximo %.2f\n",
              mean(df$grau_medio_femeas, na.rm = TRUE),
              max(df$grau_medio_femeas, na.rm = TRUE)))
  cat(sprintf("  fêmeas sem acasalar: máximo %.1f%%\n",
              100 * max(df$prop_femeas_sem_acasalar, na.rm = TRUE)))
}
conferir(d1, "Estudo 1"); conferir(d2, "Estudo 2"); conferir(d3, "Estudo 3")

cat("\nArquivos reunidos em Resultados_Artigo/Reunidos/\n")
