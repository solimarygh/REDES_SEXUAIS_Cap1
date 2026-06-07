# =====================================================================
# FIX: limpa cenários "stale" do backup da Fase5_MiudoV2
#
# Diagnóstico: ~90 combinações ficaram registradas com apenas 10 gerações
# (provavelmente de um teste rápido com generations=10 que populou o backup
# antes da rodada completa com generations=100). A lógica de retomada do
# Fase4_TodasAsCurvas.R pula índices já preenchidos, então esses cenários
# nunca foram refeitos com 100 gerações.
#
# Este script:
#   1) Recria a grade idêntica à usada em Fase4_TodasAsCurvas.R
#   2) Identifica entradas do backup com nrow != generations (100)
#   3) Zera essas entradas (NULL) e regrava o backup
#   4) Você roda Fase4_TodasAsCurvas.R de novo — ele retoma e refaz só essas
# =====================================================================

source("01_metricas_e_utilitarios.R")
suppressPackageStartupMessages({ library(dplyr) })

GENERATIONS_ESPERADAS <- 100

diretorios <- configurar_diretorios("Fase5_MiudoV2")
arquivo_backup <- file.path(diretorios$dados, "backup_lista_fase5_miudov2.rds")

lista_fase4 <- readRDS(arquivo_backup)
cat("Backup carregado:", length(lista_fase4), "entradas\n")

# Grade idêntica à do Fase4_TodasAsCurvas.R (mesma ordem!)
valores_sigma_p <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
n_replicas <- 30
cenarios_fase4 <- expand.grid(
  tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
  sigma_p         = valores_sigma_p,
  encounters_n    = c(200, 40, 10),
  k_fixo          = c(5L, 10L, 20L),
  selecao_natural = c(TRUE, FALSE),
  replica         = 1:n_replicas
)
stopifnot(length(lista_fase4) == nrow(cenarios_fase4))

# Identifica entradas incompletas/stale
idx_stale <- which(sapply(lista_fase4, function(x) is.null(x) || nrow(x) != GENERATIONS_ESPERADAS))

cat("\nCenários a re-rodar (incompletos):", length(idx_stale), "\n")
print(cenarios_fase4[idx_stale, ])

if (length(idx_stale) > 0) {
  lista_fase4[idx_stale] <- list(NULL)
  saveRDS(lista_fase4, arquivo_backup)
  cat("\nBackup atualizado — essas", length(idx_stale),
      "entradas foram zeradas.\n",
      "Agora rode novamente: source('Fase4_TodasAsCurvas.R')\n",
      "Ele vai pular o que já está pronto e refazer só essas.\n")
} else {
  cat("\nNenhuma entrada incompleta encontrada. Nada a fazer.\n")
}
