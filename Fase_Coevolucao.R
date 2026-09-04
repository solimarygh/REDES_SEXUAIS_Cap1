# =====================================================================
# ESTUDO 4: CO-EVOLUÇÃO — traço do macho e preferência da fêmea, ambos herdáveis
# =====================================================================
# Este arquivo é o motor. O desenho experimental ainda não está decidido
# (os quatro pontos em aberto estão em NOTA_material_removido_2026-08-16.md),
# então aqui só ficam as funções, e quem monta um desenho é o teste:
#
#     Rscript 00_teste_coevolucao.R
#
# O que muda em relação aos outros três estudos: cada indivíduo carrega AS
# DUAS características, e a expressão é que é dimórfica (só o macho mostra z,
# só a fêmea usa p). A grandeza central deixa de ser a média de cada uma e
# passa a ser a covariância genética entre elas, cov(z, p), que é o que o
# acasalamento assortativo constrói e o que faz a seleção sobre uma arrastar
# a outra (Lande 1981; Kirkpatrick 1982).
#
# Esta versão substitui o rascunho anterior, que tinha ruído de segregação
# fixo, viabilidade depois do censo e nenhum registro do caso degenerado.
# =====================================================================

source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({ library(dplyr) })

# ---------------------------------------------------------------------
# Reprodução com DUAS características herdáveis
# ---------------------------------------------------------------------
# O ponto crítico está no final: as vagas da próxima geração são sorteadas
# UMA VEZ, por ÍNDICE, e os dois vetores são indexados pelo MESMO idx. Assim
# o z e o p de um mesmo filhote continuam juntos, e cov(z, p) sobrevive. Se
# fossem embaralhados separadamente, a covariância seria destruída e o
# runaway desapareceria por erro de programação, sem nenhuma mensagem.
produce_offspring_coevo <- function(M, male_z_surv, male_p_surv,
                                    female_z_gen, female_p_gen,
                                    N_males_next = 200, N_females_next = 200,
                                    fecundidade_base = 50,
                                    segregacao = c("infinitesimal", "fixa"),
                                    eps_sd = 0.2, mut_sd = 0.05) {
  segregacao <- match.arg(segregacao)
  n_femeas <- ncol(M)

  # Fecundidade neutra: quem acasalou deixa F filhotes; quem não acasalou, 0.
  acasalaram             <- colSums(M) > 0
  num_filhotes_por_femea <- ifelse(acasalaram, fecundidade_base, 0)
  total_filhotes         <- sum(num_filhotes_por_femea)
  # Caso degenerado: mesma regra dos outros estudos.
  if (total_filhotes < 2 * (N_males_next + N_females_next)) return(NULL)

  moms <- rep(seq_len(n_femeas), times = num_filhotes_por_femea)
  dads <- vapply(moms, function(mom) {
    parceiros <- which(M[, mom] == 1L)
    if (length(parceiros) > 1) sample(parceiros, 1) else parceiros[1]
  }, integer(1))

  # Herança de ponto médio das DUAS características, do MESMO casal. É aqui
  # que a covariância nasce: se o acasalamento foi assortativo, os pais de um
  # mesmo filhote têm z e p correlacionados, e o filhote herda os dois.
  z_dads <- male_z_surv[dads]; z_moms <- female_z_gen[moms]
  p_dads <- male_p_surv[dads]; p_moms <- female_p_gen[moms]
  midparent_z <- (z_dads + z_moms) / 2
  midparent_p <- (p_dads + p_moms) / 2

  desvio_segregacao <- function(valores_pais) {
    if (segregacao == "fixa") return(rnorm(total_filhotes, 0, eps_sd))
    var_pais <- var(valores_pais)
    if (!is.finite(var_pais) || var_pais < 0) var_pais <- 0
    rnorm(total_filhotes, 0, sqrt(var_pais / 2)) + rnorm(total_filhotes, 0, mut_sd)
  }

  # Os desvios de segregação de z e de p são independentes entre si: a
  # segregação embaralha cada característica separadamente, e é a herança de
  # ponto médio que carrega a associação entre elas.
  z_filhotes <- pmax(0, midparent_z + desvio_segregacao(c(male_z_surv, female_z_gen)))
  p_filhotes <- pmax(0, midparent_p + desvio_segregacao(c(male_p_surv, female_p_gen)))

  # Todos os filhotes viram juvenis, com sexo ao acaso 1:1.
  idx  <- sample.int(total_filhotes)
  meio <- total_filhotes %/% 2
  i_m  <- idx[seq_len(meio)]
  i_f  <- idx[(meio + 1):(2 * meio)]

  list(male_z_juv   = z_filhotes[i_m], male_p_juv   = p_filhotes[i_m],
       female_z_juv = z_filhotes[i_f], female_p_juv = p_filhotes[i_f])
}

# ---------------------------------------------------------------------
# Loop evolutivo
# ---------------------------------------------------------------------
simulate_coevolucao <- function(generations = 100, N_machos = 200, N_femeas = 200,
                                sigma_z_init = 1.0, sigma_p_init = 1.0,
                                sigma_s = 0.2, phi = 5, gamma = 0.2,
                                tipo_selecao = "gaussian", encounters_n = 200,
                                selecao_natural = TRUE, k_fixo = NULL,
                                fecundidade_base = 50, eps_sd = 0.2,
                                segregacao = c("infinitesimal", "fixa"), mut_sd = 0.05,
                                regra = c("best_of_n", "sequencial"),
                                fuga_mult = 3) {
  segregacao <- match.arg(segregacao)
  regra      <- match.arg(regra)
  N_juvenis  <- N_femeas * fecundidade_base %/% 2

  # Os DOIS sexos carregam AS DUAS características. Os machos entram como
  # juvenis porque é sobre eles que a viabilidade age.
  male_z_juv   <- pmax(0, rnorm(N_juvenis, phi, sigma_z_init))
  male_p_juv   <- pmax(0, rnorm(N_juvenis, phi, sigma_p_init))  # carregada, não expressa
  female_z_juv <- pmax(0, rnorm(N_juvenis, phi, sigma_z_init))  # carregada, não expressa
  female_p_juv <- pmax(0, rnorm(N_juvenis, phi, sigma_p_init))

  out          <- vector("list", generations)
  extincao_gen <- NA_integer_   # geração em que a réplica foi encerrada; NA = chegou ao fim
  fuga_gen     <- NA_integer_   # primeira geração em que o traço passou de fuga_mult * phi

  for (t in seq_len(generations)) {

    # (1) Censo de adultos. selecionar_machos_adultos devolve ÍNDICES, então o
    # par (z, p) do mesmo macho viaja junto. As fêmeas não passam por
    # viabilidade, mas o censo delas também é por índice, senão a covariância
    # dentro de cada fêmea se perderia.
    idx_adultos  <- selecionar_machos_adultos(male_z_juv, N_machos, phi, gamma, selecao_natural)
    male_z_surv  <- male_z_juv[idx_adultos]
    male_p_surv  <- male_p_juv[idx_adultos]

    idx_f        <- sample.int(length(female_z_juv), N_femeas)
    female_z_gen <- female_z_juv[idx_f]
    female_p_gen <- female_p_juv[idx_f]

    # A preferência expressa é a das fêmeas adultas desta geração, então tem
    # de vir DEPOIS do censo. No rascunho esta linha estava antes, e na
    # geração 1 o objeto ainda nem existia.
    female_p <- female_p_gen
    female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))  # choosiness, não evolui

    # (2) Rede de acasalamentos
    M       <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                                   encounters_n = encounters_n, k_fixo = k_fixo,
                                   regra = regra)
    metrics <- calc_metrics_from_M(M, k_alvo = k_fixo)

    # (3) Registro. O pool genotípico é o censo adulto, os dois sexos juntos,
    # porque é a população que de fato se reproduz. Aqui, ao contrário do
    # estudo dos machos, a viabilidade NÃO é neutra em relação a p: como z e p
    # estão correlacionados, selecionar por z arrasta p junto. É exatamente o
    # efeito que queremos medir.
    pool_z <- c(male_z_surv, female_z_gen)
    pool_p <- c(male_p_surv, female_p_gen)

    if (is.na(fuga_gen) && mean(pool_z) > fuga_mult * phi) fuga_gen <- t

    out[[t]] <- data.frame(
      generation = t, tipo_selecao = tipo_selecao,
      segregacao = segregacao, regra = regra,
      sigma_z_init = sigma_z_init, sigma_p_init = sigma_p_init,
      encounters_n = encounters_n,
      k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
      selecao_natural = selecao_natural,
      zbar_pop = mean(pool_z), varz_pop = var(pool_z),
      pbar_pop = mean(pool_p), varp_pop = var(pool_p),
      cov_zp   = cov(pool_z, pool_p),
      cor_zp   = suppressWarnings(cor(pool_z, pool_p)),
      # A covariância entre os PARES que de fato acasalaram. É o passo anterior
      # na cadeia causal: primeiro o acasalamento assortativo, depois a
      # covariância genética. Registrar as duas permite separá-las.
      cov_casais = {
        pares <- which(M == 1L, arr.ind = TRUE)
        if (nrow(pares) > 1) cov(male_z_surv[pares[, 1]], female_p[pares[, 2]]) else NA_real_
      },
      zbar_males  = mean(male_z_surv), varz_males  = var(male_z_surv),
      pbar_femeas = mean(female_p),    varp_femeas = var(female_p),
      n_machos_surv = length(male_z_surv),
      metrics
    )

    # (4) Próxima geração: as duas características, pareadas
    off <- produce_offspring_coevo(M, male_z_surv, male_p_surv,
                                   female_z_gen, female_p_gen,
                                   N_machos, N_femeas,
                                   fecundidade_base = fecundidade_base,
                                   segregacao = segregacao,
                                   eps_sd = eps_sd, mut_sd = mut_sd)
    if (is.null(off)) { extincao_gen <- t; break }
    male_z_juv   <- off$male_z_juv
    male_p_juv   <- off$male_p_juv
    female_z_juv <- off$female_z_juv
    female_p_juv <- off$female_p_juv
  }

  df_out <- dplyr::bind_rows(out)
  df_out$extincao_gen <- extincao_gen
  df_out$fuga_gen     <- fuga_gen
  df_out
}

# =====================================================================
# O desenho experimental ainda não está decidido, então este arquivo não
# roda nada sozinho: quem monta um desenho pequeno é 00_teste_coevolucao.R.
# =====================================================================
if (!exists("COEVO_SO_FUNCOES") || !isTRUE(COEVO_SO_FUNCOES)) {
  cat("Fase_Coevolucao.R carregado (só as funções).\n")
  cat("Para o primeiro teste:  Rscript 00_teste_coevolucao.R\n")
}
