# =====================================================================
# ESTUDO 5: UMA IST NA REDE SEXUAL, EM UMA TEMPORADA
# =====================================================================
# Primeira parte do Objetivo 2 do projeto: uma doença que se transmite por
# contato sexual e que altera a atratividade do macho infectado.
#
# POR QUE UMA TEMPORADA BASTA PARA O RELATÓRIO
# Numa temporada não se vê a resposta evolutiva, mas vê-se o DIFERENCIAL DE
# SELEÇÃO sobre o traço: a diferença entre a média de z pesada pelo sucesso de
# acasalamento e a média de todos os machos. É a medida clássica, é o que a
# equação do criador transforma em resposta esperada, e sai de uma temporada
# só. Ou seja, dá para medir a rede, medir a epidemia e medir a pressão
# seletiva que a epidemia gera. O que fica para as gerações é conferir se a
# previsão se cumpre.
#
# COMO A INFECÇÃO ENTRA NA ESCOLHA
# O sinal que a fêmea avalia não é z, é z + h. O macho infectado carrega
# h = h_I, que pode ser negativo (a doença o deixa menos atraente, que é o caso
# clássico de Hamilton e Zuk), zero, ou positivo (manipulação parasitária).
# Isso não exige mexer em mate_with_survivors: basta passar z + h como vetor de
# traços. O diferencial de seleção, esse sim, é sempre calculado sobre o z
# verdadeiro, porque é ele que se herda.
#
# A TEMPORADA, EM RONDAS
# A temporada é dividida em rondas. Em cada uma, toda fêmea faz uma escolha
# best-of-n completa entre os machos, com o h daquele momento, e copula com
# quem escolheu. As arestas se acumulam: a rede da temporada é a união das
# rondas. Se ela escolher o mesmo macho outra vez, a aresta é a mesma e o que
# houve foi outra cópula com o mesmo par, que é como o plano descreve.
#
# Daí sai uma coisa que vale reparar: o NÚMERO DE PARCEIROS DISTINTOS deixa de
# ser o parâmetro k e passa a ser um resultado. Com preferência estável a fêmea
# volta aos mesmos machos e a rede quase não cresce; quando a infecção muda
# quem é atraente, ela troca, e a rede cresce. É a retroalimentação ficando
# visível.
#
# A transmissão acontece sobre as arestas ATIVADAS na ronda, nos dois sentidos.
# Depois vem a recuperação: no SIS o infectado volta a suscetível, no SIR passa
# a recuperado e não se infecta mais.
# =====================================================================

source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# ---------------------------------------------------------------------
# Uma temporada
# ---------------------------------------------------------------------
simulate_epidemia <- function(N_machos = 200, N_femeas = 200,
                              sigma_z = 1.0, sigma_p = 1.0, sigma_s = 0.2,
                              phi = 5, gamma = 0.2,
                              tipo_selecao = "gaussian",
                              encounters_n = 200, k_fixo = 5L,
                              rodadas = 5L,
                              # a doença
                              modelo = c("SIS", "SIR"),
                              h_I = 0,          # efeito da infecção no sinal
                              beta = 0.3,       # transmissão por aresta ativada
                              gamma_rec = 0.1,  # recuperação por ronda
                              prev0 = 0.05,     # prevalência inicial
                              # a viabilidade fica DESLIGADA por padrão: este
                              # estudo é de uma temporada, não há resposta
                              # evolutiva para a seleção natural modular, e
                              # assim o censo é sempre N por construção.
                              selecao_natural = FALSE,
                              regra = c("best_of_n", "sequencial")) {

  modelo <- match.arg(modelo)
  regra  <- match.arg(regra)

  # ---- a população -------------------------------------------------
  N_juvenis   <- N_femeas * 50 %/% 2
  male_z_juv  <- pmax(0, rnorm(N_juvenis, phi, sigma_z))
  idx_adultos <- selecionar_machos_adultos(male_z_juv, N_machos, phi, gamma, selecao_natural)
  male_z      <- male_z_juv[idx_adultos]
  n_m         <- length(male_z)

  female_p <- pmax(0, rnorm(N_femeas, phi, sigma_p))
  # A exigência é sorteada UMA vez e vale a temporada toda: é a mesma fêmea em
  # todas as rondas. Se fosse re-sorteada, a troca de parceiro entre rondas
  # poderia ser dela e não da doença, e o efeito de h ficaria confundido.
  female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))

  # ---- estado epidemiológico: 0 = S, 1 = I, 2 = R ------------------
  estado_m <- rep(0L, n_m)
  estado_f <- rep(0L, N_femeas)
  semente_m <- sample.int(n_m, max(1L, round(prev0 * n_m)))
  semente_f <- sample.int(N_femeas, max(1L, round(prev0 * N_femeas)))
  estado_m[semente_m] <- 1L
  estado_f[semente_f] <- 1L
  ja_infectado_m <- estado_m == 1L   # incidência acumulada
  ja_infectado_f <- estado_f == 1L

  M_acum <- matrix(0L, nrow = n_m, ncol = N_femeas)   # a rede da temporada
  copulas <- matrix(0L, nrow = n_m, ncol = N_femeas)  # quantas vezes cada par
  out <- vector("list", rodadas)

  for (r in seq_len(rodadas)) {

    # (1) A escolha desta ronda, com o sinal corrigido pela infecção.
    # z + h é o que a fêmea avalia; z é o que o macho transmite aos filhos.
    z_efetivo <- male_z + ifelse(estado_m == 1L, h_I, 0)
    M_ronda <- mate_with_survivors(z_efetivo, female_p, female_s, tipo_selecao,
                                   encounters_n = encounters_n, k_fixo = k_fixo,
                                   regra = regra)

    M_acum  <- pmax(M_acum, M_ronda)     # a rede acumula
    copulas <- copulas + M_ronda         # a aresta pode ser reativada

    # (2) Transmissão sobre as arestas ativadas nesta ronda, nos dois sentidos.
    # Só o suscetível pode ser infectado; no SIR o recuperado (2) está imune.
    pares <- which(M_ronda == 1L, arr.ind = TRUE)
    if (nrow(pares)) {
      # Os dois sentidos se decidem sobre o estado do INÍCIO da ronda. Sem
      # isto, quem se infecta no primeiro sentido já contagia no segundo dentro
      # da mesma ronda, e a transmissão fica assimétrica entre os sexos só por
      # causa da ordem em que o código está escrito.
      m0 <- estado_m; f0 <- estado_f

      cand <- pares[m0[pares[, 1]] == 1L & f0[pares[, 2]] == 0L, , drop = FALSE]
      if (nrow(cand)) estado_f[cand[runif(nrow(cand)) < beta, 2]] <- 1L

      cand <- pares[f0[pares[, 2]] == 1L & m0[pares[, 1]] == 0L, , drop = FALSE]
      if (nrow(cand)) estado_m[cand[runif(nrow(cand)) < beta, 1]] <- 1L
    }
    ja_infectado_m <- ja_infectado_m | estado_m == 1L
    ja_infectado_f <- ja_infectado_f | estado_f == 1L

    # (3) Recuperação, depois da transmissão: quem se infectou nesta ronda
    # ainda não pode se curar nela.
    inf_m <- which(estado_m == 1L); inf_f <- which(estado_f == 1L)
    alvo  <- if (modelo == "SIS") 0L else 2L
    if (length(inf_m)) estado_m[inf_m[runif(length(inf_m)) < gamma_rec]] <- alvo
    if (length(inf_f)) estado_f[inf_f[runif(length(inf_f)) < gamma_rec]] <- alvo

    # (4) Registro. As métricas de rede e a seleção são sobre a rede ACUMULADA,
    # que é a rede da temporada até aqui.
    metrics <- calc_metrics_from_M(M_acum, k_alvo = k_fixo)
    sel     <- diferencial_de_selecao(male_z, M_acum)

    out[[r]] <- data.frame(
      ronda = r, tipo_selecao = tipo_selecao, modelo = modelo, regra = regra,
      sigma_p = sigma_p, sigma_z = sigma_z, encounters_n = encounters_n,
      k_fixo = as.integer(k_fixo), rodadas = as.integer(rodadas),
      h_I = h_I, beta = beta, gamma_rec = gamma_rec, prev0 = prev0,
      selecao_natural = selecao_natural,

      # --- a epidemia ---
      prev_machos   = mean(estado_m == 1L),
      prev_femeas   = mean(estado_f == 1L),
      prev_total    = mean(c(estado_m, estado_f) == 1L),
      incid_acum    = mean(c(ja_infectado_m, ja_infectado_f)),
      recuperados   = mean(c(estado_m, estado_f) == 2L),

      # --- a rede ---
      # parceiros distintos por fêmea, que aqui é resposta e não parâmetro:
      # com preferência estável ela volta aos mesmos machos, e com a infecção
      # mexendo em quem é atraente, ela troca.
      parceiros_distintos = mean(colSums(M_acum)),
      copulas_por_femea   = mean(colSums(copulas)),
      n_machos_surv       = n_m,
      metrics,

      # --- a seleção sobre o traço ---
      S_traco    = sel$S,        # diferencial de seleção, em unidades de z
      i_traco    = sel$i,        # padronizado pelo desvio de z
      zbar_pop   = mean(male_z),
      zbar_pares = sel$zbar_pares,
      varz_pop   = var(male_z),

      # --- o efeito direto de h: infectados acasalam mais ou menos? ---
      grau_infectados   = if (any(estado_m == 1L)) mean(rowSums(M_acum)[estado_m == 1L]) else NA_real_,
      grau_suscetiveis  = if (any(estado_m == 0L)) mean(rowSums(M_acum)[estado_m == 0L]) else NA_real_
    )
  }

  df <- bind_rows(out)
  # "grande epidemia" pelo critério do plano: pelo menos 15% da população
  # infectada em algum momento.
  df$grande_epidemia <- max(df$incid_acum) >= 0.15
  df
}

# ---------------------------------------------------------------------
# O diferencial de seleção sobre o traço do macho
# ---------------------------------------------------------------------
# S = média de z pesada pelo sucesso de acasalamento menos a média de z na
# população. É a medida clássica (Lande & Arnold 1983), e a equação do criador
# a transforma em resposta esperada: R = h^2 * S. Por isso uma temporada já diz
# alguma coisa sobre evolução, mesmo sem gerações.
#
# i = S / sd(z) é o mesmo em unidades de desvio-padrão, que é o que permite
# comparar entre células com variâncias diferentes.
diferencial_de_selecao <- function(z, M) {
  sucesso <- rowSums(M)
  if (sum(sucesso) == 0 || length(z) < 2) {
    return(list(S = NA_real_, i = NA_real_, zbar_pares = NA_real_))
  }
  zbar_pares <- sum(z * sucesso) / sum(sucesso)
  S <- zbar_pares - mean(z)
  s_z <- sd(z)
  list(S = S, i = if (is.finite(s_z) && s_z > 0) S / s_z else NA_real_,
       zbar_pares = zbar_pares)
}

# =====================================================================
# DESENHO EXPERIMENTAL
# =====================================================================
# Roda o experimento por padrão. Para só as funções:  EPIDEMIA_SO_FUNCOES <- TRUE
if (!exists("EPIDEMIA_SO_FUNCOES") || !isTRUE(EPIDEMIA_SO_FUNCOES)) {

  diretorios <- configurar_diretorios("Fase_Epidemia")
  cat("Estudo 5: uma IST na rede sexual, em uma temporada.\n")

  n_replicas <- 100L

  cenarios <- expand.grid(
    tipo_selecao = c("uniform", "gaussian", "sigmoid", "u-shaped"),
    sigma_p      = c(0.5, 1.0, 1.5),   # os níveis do plano de trabalho
    h_I          = c(-1, 0, 1),        # em unidades de sigma_z, que é 1.0
    modelo       = c("SIS", "SIR"),
    replica      = seq_len(n_replicas),
    stringsAsFactors = FALSE
  )
  cenarios$idx_global <- seq_len(nrow(cenarios))

  cat(sprintf("%s cenários de uma temporada (%d células x %d réplicas).\n",
              format(nrow(cenarios), big.mark = "."),
              nrow(cenarios) / n_replicas, n_replicas))

  SEED_BASE <- 2031   # semente própria deste estudo
  N_CORES   <- as.integer(Sys.getenv("N_CORES", unset = "5"))

  arquivo_backup <- file.path(diretorios$dados, "backup_Epidemia.rds")
  arquivo_final  <- file.path(diretorios$dados, "resultados_Epidemia.rds")

  lista <- if (file.exists(arquivo_backup)) {
    l <- readRDS(arquivo_backup)
    cat("Backup encontrado, retomando.\n")
    if (length(l) != nrow(cenarios)) length(l) <- nrow(cenarios)
    l
  } else {
    cat("Nenhum backup, começando do zero.\n")
    vector("list", nrow(cenarios))
  }

  simular_i <- function(i) {
    res <- simulate_epidemia(
      tipo_selecao = as.character(cenarios$tipo_selecao[i]),
      sigma_p      = cenarios$sigma_p[i],
      h_I          = cenarios$h_I[i],
      modelo       = as.character(cenarios$modelo[i])
    )
    if (is.null(res) || nrow(res) == 0) return(NULL)
    res$replica <- cenarios$replica[i]
    res
  }

  lista <- rodar_cenarios(cenarios, lista, arquivo_backup, simular_i,
                          n_cores = N_CORES, seed_base = SEED_BASE,
                          idx_global = cenarios$idx_global)

  saveRDS(lista, arquivo_backup)
  df <- bind_rows(lista[!vapply(lista, is.null, logical(1))])
  saveRDS(df, arquivo_final)

  cat(sprintf("\nConcluído: %s linhas em %s\n",
              format(nrow(df), big.mark = "."), arquivo_final))
  cat(sprintf("Censo de machos: %s\n",
              paste(range(df$n_machos_surv), collapse = " a ")))
  cat(sprintf("Grandes epidemias (pelo menos 15%% infectados): %.1f%% das réplicas\n",
              100 * mean(df$grande_epidemia[df$ronda == max(df$ronda)])))
}
