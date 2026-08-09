# =====================================================================
# ESTUDO 1: CONTROLE NULO — nenhuma característica é herdada
# =====================================================================
# Nem o traço do macho nem a preferência da fêmea são herdados: os dois são
# re-sorteados a cada geração. A rede de acasalamentos se forma, medimos a
# topologia, e acabou. Não há feedback evolutivo nenhum.
#
# POR QUE UMA ÚNICA GERAÇÃO BASTA
# Sem herança, a geração 2 seria um sorteio independente da geração 1, com
# exatamente a mesma distribuição. Rodar 100 gerações seria só fazer 100 réplicas
# disfarçadas. Por isso rodamos UMA geração e usamos as réplicas para estimar a
# variabilidade. Isso torna este estudo ~100x mais barato que os demais, e é o que
# permite cruzar sigma_p x sigma_z por inteiro (7 x 7) sem custo proibitivo.
#
# POR QUE ELE PRECISA SER INDEPENDENTE
# A geração 1 do Estudo 2 já é este controle, mas só ao longo da linha sigma_z = 1.0.
# A geração 1 do Estudo 3 idem, ao longo da linha sigma_p = 1.0. Juntas elas formam
# uma cruz no espaço de parâmetros (que se cruza exatamente em sigma_p = sigma_z = 1),
# e deixam as combinações extremas de fora: nunca se vê, por exemplo, fêmeas muito
# heterogêneas diante de machos muito homogêneos. Este script preenche a superfície
# inteira.
#
# O QUE ELE RESPONDE
# Que topologia as regras de acasalamento produzem SOZINHAS, antes de qualquer
# resposta evolutiva. É a linha de base contra a qual os Estudos 2, 3 e 4 são lidos:
# a diferença entre cada um deles e este controle é exatamente o que a evolução
# acrescentou.
# =====================================================================

source("01_metricas_e_utilitarios.R")   # reusa mate_with_survivors e calc_metrics_from_M

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# ---------------------------------------------------------------------
# Uma única geração, sem herança
# ---------------------------------------------------------------------
simulate_controle <- function(N_machos = 200, N_femeas = 200,
                              sigma_z = 1.0, sigma_p = 1.0, sigma_s = 0.2,
                              phi = 5, gamma = 0.2,
                              tipo_selecao = "gaussian", encounters_n = 200,
                              selecao_natural = TRUE, k_fixo = NULL,
                              fecundidade_base = 50) {

  # (1) Sorteio da população: nada vem de geração anterior.
  # Os machos são sorteados como JUVENIS, porque é sobre eles que a viabilidade
  # age. O tamanho do pool é o mesmo dos outros estudos, ou seja, o que a
  # fecundidade produziria, para que o censo adulto seja comparável entre eles.
  N_juvenis  <- N_femeas * fecundidade_base %/% 2
  male_z_juv <- pmax(0, rnorm(N_juvenis, phi, sigma_z))
  female_p   <- pmax(0, rnorm(N_femeas, phi, sigma_p))
  female_s   <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))

  # (2) Censo de adultos constante (mesma regra dos outros estudos).
  # Aqui a seleção natural é puramente um filtro ecológico: muda quais machos
  # estão disponíveis, mas não tem consequência evolutiva porque não existe
  # geração seguinte. E, com o censo constante, ela também não muda quantos são.
  idx_adultos <- selecionar_machos_adultos(male_z_juv, N_machos, phi, gamma, selecao_natural)
  male_z_surv <- male_z_juv[idx_adultos]

  # (3) Rede de acasalamentos (mesma função dos outros estudos, sem regra de escape)
  M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                           encounters_n = encounters_n, k_fixo = k_fixo)
  metrics <- calc_metrics_from_M(M, k_alvo = k_fixo)

  data.frame(
    tipo_selecao = tipo_selecao,
    sigma_p = sigma_p, sigma_z = sigma_z,
    encounters_n = encounters_n,
    k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
    selecao_natural = selecao_natural,
    zbar_males = mean(male_z_surv), varz_males = var(male_z_surv),
    pbar_femeas = mean(female_p),   varp_femeas = var(female_p),
    n_machos_surv = length(male_z_surv),
    metrics
  )
}

# =====================================================================
# DESENHO EXPERIMENTAL: a superfície sigma_p x sigma_z completa
# =====================================================================
if (!exists("CONTROLE_SO_FUNCOES") || !isTRUE(CONTROLE_SO_FUNCOES)) {

  diretorios <- configurar_diretorios("Fase_Controle")
  cat("Iniciando Estudo 1: controle nulo (sem herança, uma geração)...\n")

  valores_sigma <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
  n_replicas    <- 20   # RODADA DE EXPLORAÇÃO antes da reunião. Final: subir depois.

  cenarios <- expand.grid(
    tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
    sigma_p         = valores_sigma,   # os DOIS eixos cruzados: esta é a diferença
    sigma_z         = valores_sigma,   # em relação à geração 1 dos Estudos 2 e 3
    encounters_n    = c(200, 40, 10),
    k_fixo          = c(5L, 10L, 20L),
    selecao_natural = c(TRUE, FALSE),
    replica         = 1:n_replicas
  )

  cenarios$idx_global <- seq_len(nrow(cenarios))
  REP_MIN <- as.integer(Sys.getenv("REP_MIN", unset = "1"))
  REP_MAX <- as.integer(Sys.getenv("REP_MAX", unset = as.character(n_replicas)))
  cenarios <- cenarios[cenarios$replica >= REP_MIN & cenarios$replica <= REP_MAX, ]
  sufixo_rep <- if (REP_MIN == 1 && REP_MAX == n_replicas) "" else sprintf("_rep%d-%d", REP_MIN, REP_MAX)
  cat(sprintf("Réplicas: %d a %d  (%d cenários, 1 geração cada)\n",
              REP_MIN, REP_MAX, nrow(cenarios)))

  arquivo_backup <- file.path(diretorios$dados, paste0("backup_Controle_censoConst", sufixo_rep, ".rds"))
  arquivo_final  <- file.path(diretorios$dados, paste0("resultados_Controle_censoConst", sufixo_rep, ".rds"))
  arquivo_backup_full <- file.path(diretorios$dados, "backup_Controle_censoConst.rds")

  if (file.exists(arquivo_backup)) {
    lista <- readRDS(arquivo_backup)
    cat("Backup encontrado! Retomando...\n")
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

  SEED_BASE <- 2029   # semente própria deste estudo
  N_CORES   <- as.integer(Sys.getenv("N_CORES", unset = "5"))

  simular_i <- function(i) {
    res <- simulate_controle(
      N_machos        = 200,
      N_femeas        = 200,
      tipo_selecao    = as.character(cenarios$tipo_selecao[i]),
      sigma_p         = cenarios$sigma_p[i],
      sigma_z         = cenarios$sigma_z[i],
      encounters_n    = cenarios$encounters_n[i],
      k_fixo          = cenarios$k_fixo[i],
      selecao_natural = cenarios$selecao_natural[i]
    )
    res$replica <- cenarios$replica[i]
    res
  }

  # blocos maiores: cada cenário aqui é ~100x mais rápido que nos outros estudos
  lista <- rodar_cenarios(cenarios, lista, arquivo_backup, simular_i,
                          n_cores = N_CORES, seed_base = SEED_BASE,
                          tamanho_bloco = N_CORES * 400,
                          idx_global = cenarios$idx_global)

  saveRDS(lista, arquivo_backup)
  df_controle <- bind_rows(lista[!sapply(lista, is.null)])
  saveRDS(df_controle, arquivo_final)
  cat("\nEstudo 1 (controle) concluído! Dados salvos em:", arquivo_final, "\n")
  cat(sprintf("Total de linhas: %d\n", nrow(df_controle)))
}
