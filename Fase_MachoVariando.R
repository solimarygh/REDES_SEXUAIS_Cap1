# =====================================================================
# SCRIPT FASE: MACHOS VARIANDO
# Experimento inverso a Fase5_MiudoV2:
#   - sigma_p FIXO em 1.0 (variação de preferência feminina constante)
#   - sigma_z_init VARIANDO (variação do traço masculino inicial)
#
# Pergunta: como a variação no traço masculino (σz) molda a rede de
# acasalamento e a evolução do traço, mantendo fixa a preferência feminina?
# =====================================================================

source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

diretorios <- configurar_diretorios("Fase_MachoVariando")

# =====================================================================
# 2) DESENHO EXPERIMENTAL
# =====================================================================
cat("Iniciando Fase Machos Variando...\n")

# ### CAMBIO vs FÊMEA: aqui o eixo que varia é sigma_z_init (não sigma_p).
# sigma_z_init varia nos mesmos níveis que sigma_p variava antes
valores_sigma_z <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
n_replicas      <- 30   # RODADA DE EXPLORAÇÃO (sem regra de escape). Final: 100.

cenarios <- expand.grid(
  tipo_selecao  = c("uniform", "gaussian", "sigmoid", "u-shaped"),
  sigma_z_init  = valores_sigma_z,      # ### σz VARIA  (na fêmea aqui ia sigma_p)
  encounters_n  = c(200, 40, 10),       # nº ABSOLUTO de machos distintos avaliados (ver nota sobre o pool não ser constante)
  k_fixo        = c(5L, 10L, 20L),
  selecao_natural = c(TRUE, FALSE),
  replica       = 1:n_replicas
)
# sigma_p é passado fixo em 1.0 para simulate_evolution

# ---------------------------------------------------------------------
# REPARTO ENTRE MÁQUINAS (REP_MIN / REP_MAX)
# Permite rodar um subconjunto de réplicas em cada máquina sem duplicar trabalho.
# O índice GLOBAL de cada cenário é guardado ANTES de filtrar, para que a semente
# (seed_base + idx_global) seja a mesma que numa corrida única e inteira.
# Ex.:  REP_MIN=1 REP_MAX=12 Rscript ...   |   REP_MIN=13 REP_MAX=30 Rscript ...
# ---------------------------------------------------------------------
cenarios$idx_global <- seq_len(nrow(cenarios))
REP_MIN <- as.integer(Sys.getenv("REP_MIN", unset = "1"))
REP_MAX <- as.integer(Sys.getenv("REP_MAX", unset = as.character(n_replicas)))
cenarios <- cenarios[cenarios$replica >= REP_MIN & cenarios$replica <= REP_MAX, ]
sufixo_rep <- if (REP_MIN == 1 && REP_MAX == n_replicas) "" else sprintf("_rep%d-%d", REP_MIN, REP_MAX)
cat(sprintf("Réplicas: %d a %d  (%d cenários)\n", REP_MIN, REP_MAX, nrow(cenarios)))

arquivo_backup <- file.path(diretorios$dados, paste0("backup_MachoVariando_semEscape", sufixo_rep, ".rds"))
arquivo_final  <- file.path(diretorios$dados, paste0("resultados_MachoVariando_semEscape", sufixo_rep, ".rds"))

# Se este intervalo ainda não tem backup próprio, aproveita o que já foi calculado
# numa corrida inteira: o backup completo é indexado pelo índice GLOBAL, então
# basta extrair as posições deste intervalo. Evita recalcular o que já existe.
arquivo_backup_full <- file.path(diretorios$dados, "backup_MachoVariando_semEscape.rds")

if (file.exists(arquivo_backup)) {
  lista <- readRDS(arquivo_backup)
  cat("Backup encontrado! Retomando as simulações...\n")
  if (length(lista) != nrow(cenarios)) length(lista) <- nrow(cenarios)
} else if (sufixo_rep != "" && file.exists(arquivo_backup_full)) {
  full_lst <- readRDS(arquivo_backup_full)
  lista <- full_lst[cenarios$idx_global]
  rm(full_lst); gc()
  cat(sprintf("Aproveitando %d cenários já prontos do backup completo.\n",
              sum(!vapply(lista, is.null, logical(1)))))
} else {
  lista <- vector("list", nrow(cenarios))
  cat("Nenhum backup encontrado. Iniciando do zero.\n")
}

SEED_BASE <- 2027  # semente diferente do experimento original

# =====================================================================
# 3) LOOP DE SIMULAÇÃO
# =====================================================================
N_CORES <- as.integer(Sys.getenv("N_CORES", unset = "5"))

simular_i <- function(i) {
  res <- simulate_evolution(
    generations     = 100,
    N_machos        = 200,
    N_femeas        = 200,
    tipo_selecao    = as.character(cenarios$tipo_selecao[i]),
    ### MUDANÇA PRINCIPAL vs FÊMEA: sigma_p FIXO, sigma_z_init VARIA
    sigma_p         = 1.0,
    sigma_z_init    = cenarios$sigma_z_init[i],
    encounters_n    = cenarios$encounters_n[i],
    k_fixo          = cenarios$k_fixo[i],
    selecao_natural = cenarios$selecao_natural[i],
    return_details  = FALSE
  )
  res$replica <- cenarios$replica[i]
  res
}

lista <- rodar_cenarios(cenarios, lista, arquivo_backup, simular_i,
                        n_cores = N_CORES, seed_base = SEED_BASE,
                        idx_global = cenarios$idx_global)

saveRDS(lista, arquivo_backup)
df <- bind_rows(lista[!sapply(lista, is.null)])
saveRDS(df, arquivo_final)
cat("\nFase Machos Variando concluída! Dados salvos em:", arquivo_final, "\n")
cat(sprintf("Total de linhas: %d\n", nrow(df)))
