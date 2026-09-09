# =====================================================================
# PRECALCULA AS REDES QUE AS FIGURAS DESENHAM
# =====================================================================
#     Rscript 12_Preparar_redes_das_figuras.R
#
# As figuras de rede mostram réplicas que realmente rodaram, e reconstruir uma
# réplica dos Estudos 2, 3 ou 4 custa cem gerações de simulação. Isso não pode
# acontecer dentro do knit de um documento: um documento lê resultados, não os
# produz. Este script roda todas as reconstruções de uma vez e as deixa no
# cache, e daí em diante os documentos apenas leem.
#
# Rode isto depois de qualquer rodada nova, ou depois de mexer num motor. O
# cache se invalida sozinho quando um arquivo de motor muda, então nesse caso
# basta rodar de novo.
#
# São umas dezenas de reconstruções de cem gerações: conte alguns minutos.
# =====================================================================

source("11_Rede_Representativa.R")

CURVAS <- c("uniform", "gaussian", "sigmoid", "u-shaped")
SIGMAS <- c(0.2, 2.0)          # as duas pontas dos gradientes
AMAX   <- c(10L, 200L)         # os dois extremos do regime de busca
KS     <- c(5L, 20L)

feito <- 0L; falhou <- character(0)
pedir <- function(...) {
  r <- tryCatch(rede_representativa(..., verboso = FALSE),
                error = function(e) { message("  erro: ", conditionMessage(e)); NULL })
  if (is.null(r)) falhou <<- c(falhou, paste(unlist(list(...)), collapse = " ")) else feito <<- feito + 1L
  invisible(r)
}

cat("\n== Estudo 1: os quatro cantos, curva por curva ==\n")
for (cv in CURVAS) {
  cat("  ", cv, "\n")
  for (sz in SIGMAS) for (sp in SIGMAS)
    pedir("1", sigma_z = sz, sigma_p = sp, tipo_selecao = cv,
          encounters_n = 200L, k_fixo = 5L, selecao_natural = FALSE)
}

cat("\n== Estudo 1: os regimes de busca, curva por curva ==\n")
for (cv in CURVAS) {
  cat("  ", cv, "\n")
  for (A in AMAX) for (k in KS)
    pedir("1", sigma_z = 1.0, sigma_p = 1.0, tipo_selecao = cv,
          encounters_n = A, k_fixo = k, selecao_natural = FALSE)
}

# Estas são as caras: cada uma é uma réplica de cem gerações, e são duas
# gerações da MESMA réplica, pedidas juntas de propósito.
cat("\n== Estudos 2 e 3: a rede da geração 1 contra a da 100 ==\n")
for (cv in CURVAS) {
  cat("  ", cv, "\n")
  for (sg in SIGMAS) {
    pedir("2", sigma_p = sg, tipo_selecao = cv, encounters_n = 200L,
          k_fixo = 5L, selecao_natural = FALSE, capturar = c(1L, 100L))
    pedir("3", sigma_z = sg, tipo_selecao = cv, encounters_n = 200L,
          k_fixo = 5L, selecao_natural = FALSE, capturar = c(1L, 100L))
  }
}

cat(sprintf("\n%d redes no cache, em %s\n", feito, ARQUIVO_CACHE_REDES))
if (length(falhou)) {
  cat(sprintf("%d pedidos sem resultado (sem dados, ou conferência falhada):\n", length(falhou)))
  cat(paste0("  ", falhou, collapse = "\n"), "\n")
  cat("Nas figuras, esses painéis caem para uma população gerada na hora, e o\n")
  cat("rodapé do painel avisa.\n")
}
