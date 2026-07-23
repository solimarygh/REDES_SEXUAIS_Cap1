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
n_replicas      <- 100

cenarios <- expand.grid(
  tipo_selecao  = c("uniform", "gaussian", "sigmoid", "u-shaped"),
  sigma_z_init  = valores_sigma_z,      # ### σz VARIA  (na fêmea aqui ia sigma_p)
  encounters_n  = c(200, 40, 10),       # 100%, 20%, 5% de N=200
  k_fixo        = c(5L, 10L, 20L),
  selecao_natural = c(TRUE, FALSE),
  replica       = 1:n_replicas
)
# sigma_p é passado fixo em 1.0 para simulate_evolution

arquivo_backup <- file.path(diretorios$dados, "backup_MachoVariando.rds")
arquivo_final  <- file.path(diretorios$dados, "resultados_MachoVariando.rds")

if (file.exists(arquivo_backup)) {
  lista <- readRDS(arquivo_backup)
  cat("Backup encontrado! Retomando as simulações...\n")
  if (length(lista) != nrow(cenarios)) length(lista) <- nrow(cenarios)
} else {
  lista <- vector("list", nrow(cenarios))
  cat("Nenhum backup encontrado. Iniciando do zero.\n")
}

SEED_BASE <- 2027  # semente diferente do experimento original

# =====================================================================
# 3) LOOP DE SIMULAÇÃO
# =====================================================================
for (i in 1:nrow(cenarios)) {

  if (!is.null(lista[[i]])) next

  if (i %% 20 == 0 || i == 1)
    cat(sprintf("Rodando cenário %d de %d (%.1f%%)\n",
                i, nrow(cenarios), (i / nrow(cenarios)) * 100))

  set.seed(SEED_BASE + i)

  res <- tryCatch({
    simulate_evolution(
      generations     = 100,
      N_machos        = 200,
      N_femeas        = 200,
      tipo_selecao    = cenarios$tipo_selecao[i],
      ### ================================================================
      ### MUDANÇA PRINCIPAL vs o experimento da FÊMEA (Fase4_TodasAsCurvas.R)
      ###   FÊMEA:  sigma_p = VARIA        |  sigma_z_init = 1.0 (default)
      ###   MACHO:  sigma_p = 1.0 (FIXO)   |  sigma_z_init = VARIA   ← invertido
      ### O motor (simulate_evolution) é o mesmo; só troca qual sigma varia.
      ### ================================================================
      sigma_p         = 1.0,                       # FIXO  (era o eixo que variava na fêmea)
      sigma_z_init    = cenarios$sigma_z_init[i],  # VARIA (era fixo/1.0 na fêmea)
      encounters_n    = cenarios$encounters_n[i],
      k_fixo          = cenarios$k_fixo[i],
      selecao_natural = cenarios$selecao_natural[i],
      return_details  = FALSE
    )
  }, error = function(e) {
    cat("Erro no cenário", i, ":", conditionMessage(e), "\n")
    return(NULL)
  })

  if (!is.null(res)) {
    res$replica <- cenarios$replica[i]
    lista[[i]]  <- res
  }

  if (i %% 20 == 0) saveRDS(lista, arquivo_backup)
}

# Exportação Final
saveRDS(lista, arquivo_backup)
df <- bind_rows(lista[!sapply(lista, is.null)])
saveRDS(df, arquivo_final)
cat("\nFase Machos Variando concluída! Dados salvos em:", arquivo_final, "\n")
cat(sprintf("Total de linhas: %d\n", nrow(df)))
