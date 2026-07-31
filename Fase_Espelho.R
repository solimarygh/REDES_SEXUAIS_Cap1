# =====================================================================
# MODELO ESPELHO — a PREFERÊNCIA da fêmea evolui; o traço do macho é ambiental
# =====================================================================
# Decisões da reunião com Erika e Miudo (2026-07):
#
#  - No modelo original, a escolha da fêmea é o MOTOR da seleção sobre o traço
#    do macho. Aqui ela inverte de papel: a escolha ESTÁ SOB SELEÇÃO, é a
#    característica que evolui.
#
#  - A força seletiva que age sobre a preferência é ECOLÓGICA: a disponibilidade
#    de machos com traços variados (sigma_z). Analogia da Erika: a planta não
#    "escolhe", mas a disponibilidade de plantas gera seleção sobre a preferência
#    do herbívoro que escolhe.
#
#  - O que evolui é o PICO p (que valor de traço a fêmea prefere), não a
#    choosiness s. A resposta é a média e a variância de p ao longo das gerações.
#
# O QUE MUDA EM RELAÇÃO AO MOTOR ORIGINAL (simulate_evolution):
#   1. Traço do macho z: AMBIENTAL. Re-sorteado de N(phi, sigma_z) a cada
#      geração (não é herdado) — é dependência de condição, não genética.
#   2. Preferência p: HERDÁVEL e bi-parental. Os dois sexos carregam p (o macho
#      carrega sem expressar) e o filhote herda (p_pai + p_mae)/2 + mutação.
#   3. Sem regra de escape (já corrigido no motor compartilhado): fêmeas que não
#      aceitam nenhum macho ficam com 0 filhotes. É isso que gera variância de
#      fitness entre fêmeas e permite a seleção sobre p.
#   4. Fecundidade NEUTRA mantida: toda fêmea que acasalou deixa F filhotes,
#      independente de com quantos machos acasalou.
# =====================================================================

source("01_metricas_e_utilitarios.R")   # reusa mate_with_survivors, calc_metrics_from_M, ensure_min_survivors

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# ---------------------------------------------------------------------
# Reprodução: herda a PREFERÊNCIA (bi-parental), não o traço
# ---------------------------------------------------------------------
produce_offspring_espelho <- function(M, male_p_surv, female_p_gen,
                                      N_males_next = 200, N_females_next = 200,
                                      fecundidade_base = 50, eps_p = 0.2) {
  n_femeas <- ncol(M)

  # Fecundidade neutra: quem acasalou deixa F filhotes; quem não acasalou, 0.
  acasalaram   <- colSums(M) > 0
  num_filhotes <- ifelse(acasalaram, fecundidade_base, 0)
  total_juv    <- sum(num_filhotes)

  if (total_juv == 0) return(NULL)   # ninguém acasalou: cenário degenerado

  moms <- rep(seq_len(n_femeas), times = num_filhotes)
  dads <- vapply(moms, function(mom) {
    parceiros <- which(M[, mom] == 1L)
    if (length(parceiros) > 1) sample(parceiros, 1) else parceiros[1]
  }, integer(1))

  # Herança de ponto médio da PREFERÊNCIA + mutação
  p_juv <- pmax(0, (male_p_surv[dads] + female_p_gen[moms]) / 2 + rnorm(total_juv, 0, eps_p))

  # Capacidade de carga: mortalidade aleatória até as vagas
  vagas <- min(N_males_next + N_females_next, total_juv)
  idx   <- sample(seq_len(total_juv), size = vagas, replace = FALSE)
  meio  <- floor(vagas / 2)
  if (meio < 1) return(NULL)

  list(male_p_next   = p_juv[idx[1:meio]],
       female_p_next = p_juv[idx[(meio + 1):(2 * meio)]])
}

# ---------------------------------------------------------------------
# Loop evolutivo do espelho
# ---------------------------------------------------------------------
simulate_espelho <- function(generations = 100, N_machos = 200, N_femeas = 200,
                             sigma_z = 1.0,          # dispersão dos machos (AMBIENTAL, o eixo do experimento)
                             sigma_p_init = 1.0,     # dispersão inicial da preferência (condição inicial)
                             sigma_s = 0.2, phi = 5, gamma = 0.2, eps_p = 0.2,
                             tipo_selecao = "gaussian", encounters_n = 200,
                             selecao_natural = TRUE, k_fixo = NULL,
                             fecundidade_base = 50) {

  # Preferência: genótipo herdável carregado pelos DOIS sexos
  male_p_gen   <- pmax(0, rnorm(N_machos, phi, sigma_p_init))   # macho carrega p sem expressar
  female_p_gen <- pmax(0, rnorm(N_femeas, phi, sigma_p_init))

  out <- vector("list", generations)

  for (t in seq_len(generations)) {

    # (1) Traço do macho: AMBIENTAL — re-sorteado toda geração, não herdado
    male_z_gen <- pmax(0, rnorm(N_machos, phi, sigma_z))

    female_p <- female_p_gen                                     # HERDADA (evolui)
    female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))  # choosiness fixa (não evolui)

    # (2) Seleção de viabilidade: filtro ecológico sobre quem está disponível
    if (selecao_natural) {
      V <- exp(-gamma * (male_z_gen - phi)^2)
      survive <- runif(N_machos) <= V
      survive <- ensure_min_survivors(survive, V, min_surv = 2)
    } else {
      survive <- rep(TRUE, N_machos)
    }
    male_z_surv <- male_z_gen[survive]
    male_p_surv <- male_p_gen[survive]

    # (3) Rede de acasalamentos (sem regra de escape)
    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                             encounters_n = encounters_n, k_fixo = k_fixo)
    metrics <- calc_metrics_from_M(M)

    # (4) Registro: o foco é a distribuição da PREFERÊNCIA
    pool_p <- c(male_p_gen, female_p_gen)
    out[[t]] <- data.frame(
      generation = t, tipo_selecao = tipo_selecao,
      sigma_z = sigma_z, sigma_p_init = sigma_p_init,
      encounters_n = encounters_n,
      k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
      selecao_natural = selecao_natural,
      pbar_pop    = mean(pool_p),      varp_pop    = var(pool_p),     # genótipo (os dois sexos)
      pbar_femeas = mean(female_p),    varp_femeas = var(female_p),   # preferência expressa
      zbar_males  = mean(male_z_surv), varz_males  = var(male_z_surv),
      metrics
    )

    # (5) Próxima geração: herda a preferência
    off <- produce_offspring_espelho(M, male_p_surv, female_p_gen,
                                     N_machos, N_femeas,
                                     fecundidade_base = fecundidade_base, eps_p = eps_p)
    if (is.null(off)) break   # ninguém acasalou: encerra a réplica
    male_p_gen   <- off$male_p_next
    female_p_gen <- off$female_p_next
  }

  dplyr::bind_rows(out)
}

# =====================================================================
# DESENHO EXPERIMENTAL (espelho do experimento da fêmea)
# =====================================================================
if (sys.nframe() == 0) {   # só roda se o script for executado direto

  diretorios <- configurar_diretorios("Fase_Espelho")
  cat("Iniciando Fase Espelho (a preferência evolui)...\n")

  valores_sigma_z <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
  n_replicas      <- 10   # RODADA DE TESTE. Subir p/ 100 na rodada final.

  cenarios <- expand.grid(
    tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
    sigma_z         = valores_sigma_z,   # disponibilidade de machos: o eixo do experimento
    encounters_n    = c(200, 40, 10),
    k_fixo          = c(5L, 10L, 20L),
    selecao_natural = c(TRUE, FALSE),
    replica         = 1:n_replicas
  )

  arquivo_backup <- file.path(diretorios$dados, "backup_Espelho.rds")
  arquivo_final  <- file.path(diretorios$dados, "resultados_Espelho.rds")

  if (file.exists(arquivo_backup)) {
    lista <- readRDS(arquivo_backup)
    cat("Backup encontrado! Retomando as simulações...\n")
    if (length(lista) != nrow(cenarios)) length(lista) <- nrow(cenarios)
  } else {
    lista <- vector("list", nrow(cenarios))
    cat("Nenhum backup encontrado. Iniciando do zero.\n")
  }

  SEED_BASE <- 2028   # semente própria deste experimento

  for (i in 1:nrow(cenarios)) {
    if (!is.null(lista[[i]])) next
    if (i %% 20 == 0 || i == 1)
      cat(sprintf("Rodando cenário %d de %d (%.1f%%)\n",
                  i, nrow(cenarios), (i / nrow(cenarios)) * 100))

    set.seed(SEED_BASE + i)

    res <- tryCatch({
      simulate_espelho(
        generations     = 100,
        N_machos        = 200,
        N_femeas        = 200,
        tipo_selecao    = as.character(cenarios$tipo_selecao[i]),
        sigma_z         = cenarios$sigma_z[i],
        sigma_p_init    = 1.0,
        encounters_n    = cenarios$encounters_n[i],
        k_fixo          = cenarios$k_fixo[i],
        selecao_natural = cenarios$selecao_natural[i]
      )
    }, error = function(e) {
      cat("Erro no cenário", i, ":", conditionMessage(e), "\n"); NULL
    })

    if (!is.null(res) && nrow(res) > 0) {
      res$replica <- cenarios$replica[i]
      lista[[i]]  <- res
    }

    if (i %% 20 == 0) saveRDS(lista, arquivo_backup)
  }

  saveRDS(lista, arquivo_backup)
  df_espelho <- bind_rows(lista[!sapply(lista, is.null)])
  saveRDS(df_espelho, arquivo_final)
  cat("\nFase Espelho concluída! Dados salvos em:", arquivo_final, "\n")
}
