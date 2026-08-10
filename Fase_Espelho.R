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
                                      fecundidade_base = 50, eps_sd = 0.2,
                                      segregacao = c("infinitesimal", "fixa"),
                                      mut_sd = 0.05) {
  segregacao <- match.arg(segregacao)
  n_femeas <- ncol(M)

  # Fecundidade neutra: quem acasalou deixa F filhotes; quem não acasalou, 0.
  acasalaram   <- colSums(M) > 0
  num_filhotes_por_femea <- ifelse(acasalaram, fecundidade_base, 0)
  total_filhotes         <- sum(num_filhotes_por_femea)

  # CASO DEGENERADO — mesma regra do Estudo 2 (ver comentário em produce_offspring):
  # ou ninguém acasalou, ou os filhotes não bastam para preencher as vagas com N
  # constante. Nos dois casos NULL, e quem chama encerra a réplica registrando a
  # geração em extincao_gen.
  if (total_filhotes < 2 * (N_males_next + N_females_next)) return(NULL)

  moms <- rep(seq_len(n_femeas), times = num_filhotes_por_femea)
  dads <- vapply(moms, function(mom) {
    parceiros <- which(M[, mom] == 1L)
    if (length(parceiros) > 1) sample(parceiros, 1) else parceiros[1]
  }, integer(1))

  # Herança de ponto médio da PREFERÊNCIA
  p_dads <- male_p_surv[dads]
  p_moms <- female_p_gen[moms]
  midparent <- (p_dads + p_moms) / 2

  if (segregacao == "fixa") {
    # Ruído FIXO. Cuidado: o blending corta a variância pela metade a cada
    # geração, então V converge para o equilíbrio 2*eps_sd^2 — um "ponto de
    # retorno" imposto por nós, independente da seleção.
    desvio <- rnorm(total_filhotes, 0, eps_sd)

  } else {
    # MODELO INFINITESIMAL (Falconer & Mackay): a variância de segregação é
    # proporcional à variância parental (V_A/2), então V' = V/2 + V/2 = V.
    # A variância deixa de erodir sozinha e passa a ser determinada só pela
    # seleção e pela deriva. O termo mutacional pequeno (mut_sd) repõe o que a
    # deriva remove, evitando que a variância se perca a longo prazo.
    var_pais <- var(c(male_p_surv, female_p_gen))
    if (!is.finite(var_pais) || var_pais < 0) var_pais <- 0
    desvio <- rnorm(total_filhotes, 0, sqrt(var_pais / 2)) + rnorm(total_filhotes, 0, mut_sd)
  }

  p_filhotes <- pmax(0, midparent + desvio)

  # Capacidade de carga: mortalidade aleatória até as vagas.
  # Aqui o sorteio é por ÍNDICE e não por valor. Com uma única característica os
  # dois são equivalentes; a forma por índice está aqui porque é a que o Estudo 4
  # exige (lá z e p do mesmo filhote precisam viajar juntos).
  idx  <- sample.int(total_filhotes)
  meio <- total_filhotes %/% 2

  list(male_p_juv   = p_filhotes[idx[seq_len(meio)]],
       female_p_juv = p_filhotes[idx[(meio + 1):(2 * meio)]])
}

# ---------------------------------------------------------------------
# Loop evolutivo do espelho
# ---------------------------------------------------------------------
simulate_espelho <- function(generations = 100, N_machos = 200, N_femeas = 200,
                             sigma_z = 1.0,          # dispersão dos machos (AMBIENTAL, o eixo do experimento)
                             sigma_p_init = 1.0,     # dispersão inicial da preferência (condição inicial)
                             sigma_s = 0.2, phi = 5, gamma = 0.2, eps_sd = 0.2,
                             tipo_selecao = "gaussian", encounters_n = 200,
                             selecao_natural = TRUE, k_fixo = NULL,
                             fecundidade_base = 50,
                             segregacao = c("infinitesimal", "fixa"), mut_sd = 0.05,
                             regra = c("best_of_n", "sequencial")) {
  segregacao <- match.arg(segregacao)
  regra      <- match.arg(regra)
  # O pool de juvenis não é parâmetro livre: é o que a fecundidade produz.
  N_juvenis <- N_femeas * fecundidade_base %/% 2

  # Preferência: genótipo herdável carregado pelos DOIS sexos
  male_p_juv   <- pmax(0, rnorm(N_juvenis, phi, sigma_p_init))  # macho carrega p sem expressar
  female_p_juv <- pmax(0, rnorm(N_juvenis, phi, sigma_p_init))

  out <- vector("list", generations)
  extincao_gen <- NA_integer_   # geração em que a réplica foi encerrada; NA = chegou ao fim

  for (t in seq_len(generations)) {

    # (1) Traço do macho: AMBIENTAL — re-sorteado toda geração, não herdado.
    # Sorteado para todos os JUVENIS, porque é sobre eles que a viabilidade age.
    male_z_juv <- pmax(0, rnorm(length(male_p_juv), phi, sigma_z))

    # (2) Censo de adultos: a viabilidade filtra os juvenis machos e sobram sempre
    # N_machos adultos. O índice é o mesmo para z e p, então o p que cada macho
    # carrega acompanha o macho certo. As fêmeas não passam por viabilidade, então
    # o censo delas é um sorteio aleatório entre as juvenis.
    idx_adultos  <- selecionar_machos_adultos(male_z_juv, N_machos, phi, gamma, selecao_natural)
    male_z_surv  <- male_z_juv[idx_adultos]
    male_p_surv  <- male_p_juv[idx_adultos]
    female_p_gen <- female_p_juv[sample.int(length(female_p_juv), N_femeas)]

    female_p <- female_p_gen                                     # HERDADA (evolui)
    female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))  # choosiness fixa (não evolui)

    # (3) Rede de acasalamentos (sem regra de escape)
    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                             encounters_n = encounters_n, k_fixo = k_fixo, regra = regra)
    metrics <- calc_metrics_from_M(M, k_alvo = k_fixo)

    # (4) Registro: o foco é a distribuição da PREFERÊNCIA.
    # O pool genotípico é o CENSO ADULTO (200 machos + 200 fêmeas), e não o pool
    # de juvenis, para ficar balanceado entre os sexos. Como no espelho o traço z
    # é ambiental e independente de p, a seleção de viabilidade não enviesa p:
    # male_p_surv é uma amostra não enviesada de male_p_juv.
    pool_p <- c(male_p_surv, female_p_gen)
    out[[t]] <- data.frame(
      generation = t, tipo_selecao = tipo_selecao, segregacao = segregacao,
      regra = regra,
      sigma_z = sigma_z, sigma_p_init = sigma_p_init,
      encounters_n = encounters_n,
      k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
      selecao_natural = selecao_natural,
      pbar_pop    = mean(pool_p),      varp_pop    = var(pool_p),     # genótipo (os dois sexos)
      pbar_femeas = mean(female_p),    varp_femeas = var(female_p),   # preferência expressa
      zbar_males  = mean(male_z_surv), varz_males  = var(male_z_surv),
      # Tamanho do pool de machos disponíveis. Não é constante: cai com sigma_z
      # quando a seleção natural está ligada, e isso muda a densidade da rede
      # independentemente de qualquer efeito da escolha feminina. Aqui importa
      # ainda mais que no Estudo 2, porque sigma_z é o eixo do experimento.
      n_machos_surv = length(male_z_surv),
      metrics
    )

    # (5) Próxima geração: herda a preferência
    off <- produce_offspring_espelho(M, male_p_surv, female_p_gen,
                                     N_machos, N_femeas,
                                     fecundidade_base = fecundidade_base, eps_sd = eps_sd,
                                     segregacao = segregacao, mut_sd = mut_sd)
    # Réplica encerrada: guardamos as gerações já rodadas e registramos ONDE parou,
    # para que a perda seja contável na análise em vez de virar uma réplica que
    # some no filtro generation == 100.
    if (is.null(off)) { extincao_gen <- t; break }
    male_p_juv   <- off$male_p_juv
    female_p_juv <- off$female_p_juv
  }

  df_out <- dplyr::bind_rows(out)
  df_out$extincao_gen <- extincao_gen
  df_out
}

# =====================================================================
# DESENHO EXPERIMENTAL (espelho do experimento da fêmea)
# =====================================================================
# Roda o experimento por padrão (tanto com source() quanto com Rscript).
# Se você quiser apenas as funções, defina antes:  ESPELHO_SO_FUNCOES <- TRUE
if (!exists("ESPELHO_SO_FUNCOES") || !isTRUE(ESPELHO_SO_FUNCOES)) {

  diretorios <- configurar_diretorios("Fase_Espelho")
  cat("Iniciando Fase Espelho (a preferência evolui)...\n")

  valores_sigma_z <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
  n_replicas      <- 20   # RODADA DE EXPLORAÇÃO antes da reunião. Final: subir depois.

  cenarios <- expand.grid(
    tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
    sigma_z         = valores_sigma_z,   # disponibilidade de machos: o eixo do experimento
    encounters_n    = c(200, 40, 10),
    k_fixo          = c(5L, 10L, 20L),
    selecao_natural = c(TRUE, FALSE),
    replica         = 1:n_replicas
  )

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

  arquivo_backup <- file.path(diretorios$dados, paste0("backup_Espelho_bestOfN", sufixo_rep, ".rds"))
  arquivo_final  <- file.path(diretorios$dados, paste0("resultados_Espelho_bestOfN", sufixo_rep, ".rds"))

  # Se este intervalo ainda não tem backup próprio, aproveita o que já foi calculado
  # numa corrida inteira: o backup completo é indexado pelo índice GLOBAL, então
  # basta extrair as posições deste intervalo. Evita recalcular o que já existe.
  arquivo_backup_full <- file.path(diretorios$dados, "backup_Espelho_bestOfN.rds")

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

  SEED_BASE <- 2028   # semente própria deste experimento

  N_CORES <- as.integer(Sys.getenv("N_CORES", unset = "5"))

  simular_i <- function(i) {
    res <- simulate_espelho(
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
    if (is.null(res) || nrow(res) == 0) return(NULL)
    res$replica <- cenarios$replica[i]
    res
  }

  lista <- rodar_cenarios(cenarios, lista, arquivo_backup, simular_i,
                          n_cores = N_CORES, seed_base = SEED_BASE,
                          idx_global = cenarios$idx_global)

  saveRDS(lista, arquivo_backup)
  df_espelho <- bind_rows(lista[!sapply(lista, is.null)])
  saveRDS(df_espelho, arquivo_final)
  cat("\nFase Espelho concluída! Dados salvos em:", arquivo_final, "\n")
}
