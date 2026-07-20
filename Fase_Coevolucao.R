# =====================================================================
# MOTOR DE CO-EVOLUÇÃO (preferência HERDÁVEL) + validação rápida
# ---------------------------------------------------------------------
# NÃO altera o motor atual (01_metricas_e_utilitarios.R), que continua
# sendo o CONTROLE "sem co-evolução". Aqui a preferência p vira genótipo
# herdável carregado pelos DOIS sexos; o acasalamento assortativo constrói
# a covariância genética cov(z, p) — o motor do Fisherian runaway.
#
# Grandeza central da análise: cov_zp (Lande 1981 / Kirkpatrick 1982),
# NÃO as médias por sexo.
# =====================================================================

source("01_metricas_e_utilitarios.R")   # reusa mate_with_survivors, calc_metrics_from_M, ensure_min_survivors

# ---------------------------------------------------------------------
# Reprodução COM herança pareada de (z, p)
# Diferença-chave vs. produce_offspring atual: herda TAMBÉM p, e amostra
# ÍNDICES de juvenis (não valores soltos) para manter z e p do MESMO
# indivíduo juntos — senão a covariância p-z se perde.
# ---------------------------------------------------------------------
produce_offspring_coev <- function(M, male_z_surv, male_p_surv, female_z_gen, female_p_gen,
                                   N_males_next = 200, N_females_next = 200,
                                   fecundidade_base = 50, eps_sd = 0.2, eps_p = 0.2) {
  n_femeas <- ncol(M)
  acasalaram      <- colSums(M) > 0
  num_filhotes    <- ifelse(acasalaram, fecundidade_base, 0)
  total_juveniles <- sum(num_filhotes)

  if (total_juveniles == 0)
    return(list(male_z_next = male_z_surv,  male_p_next = male_p_surv,
                female_z_next = female_z_gen, female_p_next = female_p_gen))

  moms <- rep(seq_len(n_femeas), times = num_filhotes)
  dads <- vapply(moms, function(mom) {
    parceiros <- which(M[, mom] == 1L)
    if (length(parceiros) > 1) sample(parceiros, 1) else parceiros[1]
  }, integer(1))

  z_dads <- male_z_surv[dads]; z_moms <- female_z_gen[moms]
  p_dads <- male_p_surv[dads]; p_moms <- female_p_gen[moms]

  # herança de ponto médio + mutação, para z E p
  z_juv <- pmax(0, (z_dads + z_moms) / 2 + rnorm(total_juveniles, 0, eps_sd))
  p_juv <- pmax(0, (p_dads + p_moms) / 2 + rnorm(total_juveniles, 0, eps_p))

  vagas <- min(N_males_next + N_females_next, total_juveniles)
  idx   <- sample(seq_len(total_juveniles), size = vagas, replace = FALSE)  # índices → (z,p) pareados!
  meio  <- floor(vagas / 2)
  im  <- idx[1:meio]
  iff <- idx[(meio + 1):(2 * meio)]

  list(male_z_next = z_juv[im],   male_p_next = p_juv[im],
       female_z_next = z_juv[iff], female_p_next = p_juv[iff])
}

# ---------------------------------------------------------------------
# Loop evolutivo COM co-evolução
# ---------------------------------------------------------------------
simulate_coevolution <- function(
    generations = 100, N_machos = 200, N_femeas = 200,
    sigma_z_init = 1.0, sigma_p_init = 1.0, sigma_s = 0.2,
    tipo_selecao = "gaussian", encounters_n = 200,
    phi = 5, phi_p = 5, gamma = 0.2, eps_sd = 0.2, eps_p = 0.2,
    selecao_natural = TRUE, k_fixo = NULL) {

  # Inicialização: AMBOS os sexos carregam (z, p)
  male_z_gen   <- pmax(0, rnorm(N_machos, phi,   sigma_z_init))
  male_p_gen   <- pmax(0, rnorm(N_machos, phi_p, sigma_p_init))  # macho carrega p (não expressa)
  female_z_gen <- pmax(0, rnorm(N_femeas, phi,   sigma_z_init))  # fêmea carrega z (não expressa)
  female_p_gen <- pmax(0, rnorm(N_femeas, phi_p, sigma_p_init))

  out <- vector("list", generations)

  for (t in seq_len(generations)) {

    female_p <- female_p_gen                    # HERDADA (não re-sorteada — esta é a mudança)
    female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))

    if (selecao_natural) {
      V <- exp(-gamma * (male_z_gen - phi)^2)   # seleção de viabilidade só no traço z
      survive <- runif(N_machos) <= V
      survive <- ensure_min_survivors(survive, V, min_surv = 2)
    } else {
      survive <- rep(TRUE, N_machos)
    }
    male_z_surv <- male_z_gen[survive]
    male_p_surv <- male_p_gen[survive]          # p acompanha o macho sobrevivente

    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                             encounters_n = encounters_n, k_fixo = k_fixo)
    metrics <- calc_metrics_from_M(M)

    # ── A GRANDEZA CENTRAL: covariância genética p-z na população inteira ──
    pool_z <- c(male_z_gen, female_z_gen)
    pool_p <- c(male_p_gen, female_p_gen)
    cov_zp <- cov(pool_z, pool_p)

    out[[t]] <- data.frame(
      generation = t, tipo_selecao = tipo_selecao,
      sigma_p_init = sigma_p_init, sigma_z_init = sigma_z_init,
      encounters_n = encounters_n,
      k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
      selecao_natural = selecao_natural,
      zbar = mean(pool_z), pbar = mean(pool_p),         # médias genotípicas poolizadas
      zbar_males = mean(male_z_surv),
      var_z = var(pool_z), var_p = var(pool_p),
      cov_zp = cov_zp,                                  # ← foco da análise
      metrics
    )

    off <- produce_offspring_coev(M, male_z_surv, male_p_surv, female_z_gen, female_p_gen,
                                  N_machos, N_femeas, eps_sd = eps_sd, eps_p = eps_p)
    male_z_gen   <- off$male_z_next;   male_p_gen   <- off$male_p_next
    female_z_gen <- off$female_z_next; female_p_gen <- off$female_p_next
  }

  dplyr::bind_rows(out)
}

# =====================================================================
# VALIDAÇÃO RÁPIDA: o runaway emerge? (roda ao dar source neste arquivo)
# Esperado:
#   - sigmoid (direcional)  → cov_zp > 0 crescente; zbar e pbar SOBEM juntos (runaway)
#   - uniform (aleatória)   → cov_zp ≈ 0; zbar, pbar planos (sem seleção sexual)
#   - gaussian (estabiliz.) → fica perto de phi (preferência pelo médio)
#   - u-shaped (disruptiva) → bimodalidade / afastamento do médio
# =====================================================================
testar_coevolucao <- function(n_rep = 5, gens = 100) {
  curvas <- c("uniform", "gaussian", "sigmoid", "u-shaped")
  res <- list(); idx <- 1
  for (ts in curvas) for (r in seq_len(n_rep)) {
    set.seed(3000 + idx)
    d <- simulate_coevolution(generations = gens, tipo_selecao = ts,
                              sigma_z_init = 1.0, sigma_p_init = 1.0,
                              encounters_n = 200, k_fixo = 5L, selecao_natural = TRUE)
    d$replica <- r
    res[[idx]] <- d; idx <- idx + 1
  }
  df <- dplyr::bind_rows(res)

  traj <- df %>%
    group_by(tipo_selecao, generation) %>%
    summarise(zbar = mean(zbar), pbar = mean(pbar), cov_zp = mean(cov_zp), .groups = "drop")
  long <- tidyr::pivot_longer(traj, c(zbar, pbar, cov_zp), names_to = "quant", values_to = "valor") %>%
    mutate(quant = recode(quant, zbar = "1. Média do traço (z)",
                          pbar = "2. Média da preferência (p)", cov_zp = "3. Covariância cov(z,p)"))

  cores_4 <- c("uniform"="gray55","gaussian"="#E6B800","sigmoid"="#3BA273","u-shaped"="#9932CC")
  p <- ggplot(long, aes(generation, valor, color = tipo_selecao)) +
    geom_hline(yintercept = 0, linewidth = 0.3, color = "gray70") +
    geom_line(linewidth = 1) +
    facet_wrap(~quant, scales = "free_y") +
    scale_color_manual(values = cores_4) +
    labs(title = "Co-evolução preferência–traço: trajetórias (média de réplicas)",
         subtitle = "cov(z,p) > 0 e z, p subindo juntos = Fisherian runaway (esperado na Sigmoide)",
         x = "Geração", y = "", color = "Curva") +
    theme_light(base_size = 13) + theme(legend.position = "bottom")

  dir.create("Resultados_Artigo/Fase_Coevolucao/Graficos", recursive = TRUE, showWarnings = FALSE)
  ggsave("Resultados_Artigo/Fase_Coevolucao/Graficos/Teste_Coevolucao_trajetorias.png",
         p, width = 11, height = 4.5, dpi = 150, bg = "white")

  cat("\n=== Teste co-evolução — resumo na geração final ===\n")
  print(df %>% filter(generation == max(generation)) %>%
          group_by(tipo_selecao) %>%
          summarise(zbar = round(mean(zbar), 2), pbar = round(mean(pbar), 2),
                    cov_zp = round(mean(cov_zp), 3), .groups = "drop"))
  cat("\nGráfico salvo em: Resultados_Artigo/Fase_Coevolucao/Graficos/Teste_Coevolucao_trajetorias.png\n")
  invisible(df)
}

# Roda a validação ao dar source (leve: 4 curvas x 5 réplicas x 100 gerações)
testar_coevolucao()
