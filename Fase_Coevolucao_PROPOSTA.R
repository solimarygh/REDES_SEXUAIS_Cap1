# =====================================================================
# ESTUDO 4: CO-EVOLUÇÃO — PROPOSTA, ainda não discutida
# =====================================================================
# ATENÇÃO: este arquivo NÃO é o estudo, é a proposta escrita.
#
# Ele existe para tirar 250 linhas de código de dentro da
# NOTA_quatro_estudos.md, que é um documento de leitura. A discussão do
# desenho continua lá, na seção de Co-evolução; aqui está só o código que
# ela propõe.
#
# O motor que roda hoje é o rascunho antigo, Fase_Coevolucao.R, que ainda
# tem ruído fixo, viabilidade depois do censo e nenhum bloco de desenho.
# Quando os quatro pontos em aberto da nota estiverem decididos, este
# arquivo substitui aquele e vira Fase_Coevolucao.R de verdade.
#
# Por isso nada aqui roda ao dar source: é texto executável, não um estudo.
# =====================================================================

if (FALSE) {

  # =====================================================================
  # ESTUDO 4: CO-EVOLUÇÃO — traço do macho e preferência da fêmea, ambos herdáveis
  # =====================================================================
  source("01_metricas_e_utilitarios.R")

  suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

  # ---------------------------------------------------------------------
  # Reprodução com DUAS características herdáveis
  # ---------------------------------------------------------------------
  # O ponto crítico está no final: as vagas da próxima geração são sorteadas
  # UMA VEZ, por ÍNDICE, e os dois vetores são indexados pelo MESMO idx. Assim o
  # z e o p de um mesmo filhote continuam juntos, e cov(z, p) sobrevive.
  produce_offspring_coevo <- function(M, male_z_surv, male_p_surv,
                                      female_z_gen, female_p_gen,
                                      N_males_next = 200, N_females_next = 200,
                                      fecundidade_base = 50,
                                      segregacao = c("infinitesimal", "fixa"),
                                      eps_sd = 0.2, mut_sd = 0.05) {
    segregacao <- match.arg(segregacao)
    n_femeas <- ncol(M)

    # Fecundidade neutra: quem acasalou deixa F filhotes; quem não acasalou, 0.
    acasalaram   <- colSums(M) > 0
    num_filhotes_por_femea <- ifelse(acasalaram, fecundidade_base, 0)
    total_filhotes         <- sum(num_filhotes_por_femea)
    # CASO DEGENERADO: mesma regra dos outros estudos
    if (total_filhotes < 2 * (N_males_next + N_females_next)) return(NULL)

    moms <- rep(seq_len(n_femeas), times = num_filhotes_por_femea)
    dads <- vapply(moms, function(mom) {
      parceiros <- which(M[, mom] == 1L)
      if (length(parceiros) > 1) sample(parceiros, 1) else parceiros[1]
    }, integer(1))

    # Herança de ponto médio das DUAS características, do MESMO casal.
    # É aqui que a covariância nasce: se o acasalamento foi assortativo, os pais
    # de um mesmo filhote têm z e p correlacionados, e o filhote herda os dois.
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
    # ponto médio que carrega a associação. Isso é o comportamento correto.
    z_filhotes <- pmax(0, midparent_z + desvio_segregacao(c(male_z_surv, female_z_gen)))
    p_filhotes <- pmax(0, midparent_p + desvio_segregacao(c(male_p_surv, female_p_gen)))

    # TODOS os filhotes são juvenis; o sexo é atribuído ao acaso, 1:1. É AQUI que a
    # covariância sobrevive: um único sorteio de índices, e os dois vetores
    # indexados pelo MESMO idx, para que z e p de um mesmo filhote fiquem juntos.
    # A capacidade de carga é imposta só no censo adulto da geração seguinte.
    idx  <- sample.int(total_filhotes)
    meio <- total_filhotes %/% 2
    i_m <- idx[seq_len(meio)]
    i_f <- idx[(meio + 1):(2 * meio)]

    list(male_z_juv   = z_filhotes[i_m], male_p_juv   = p_filhotes[i_m],
         female_z_juv = z_filhotes[i_f], female_p_juv = p_filhotes[i_f])
  }

  # ---------------------------------------------------------------------
  # Loop evolutivo da co-evolução
  # ---------------------------------------------------------------------
  simulate_coevolucao <- function(generations = 100, N_machos = 200, N_femeas = 200,
                                  sigma_z_init = 1.0, sigma_p_init = 1.0,
                                  sigma_s = 0.2, phi = 5, gamma = 0.2,
                                  tipo_selecao = "gaussian", encounters_n = 200,
                                  selecao_natural = TRUE, k_fixo = NULL,
                                  fecundidade_base = 50, eps_sd = 0.2,
                                  segregacao = c("infinitesimal", "fixa"), mut_sd = 0.05,
                                  regra = c("best_of_n", "sequencial")) {
    segregacao <- match.arg(segregacao)
    regra      <- match.arg(regra)
    # O pool de juvenis não é parâmetro livre: é o que a fecundidade produz.
    N_juvenis <- N_femeas * fecundidade_base %/% 2

    # Os DOIS sexos carregam as DUAS características. A expressão é que é dimórfica:
    # só o macho mostra z, só a fêmea usa p. Os machos entram como JUVENIS: a
    # viabilidade age sobre eles e o censo adulto fica sempre em N_machos.
    male_z_juv   <- pmax(0, rnorm(N_juvenis, phi, sigma_z_init))
    male_p_juv   <- pmax(0, rnorm(N_juvenis, phi, sigma_p_init))  # carregada, não expressa
    female_z_juv <- pmax(0, rnorm(N_juvenis, phi, sigma_z_init))  # carregada, não expressa
    female_p_juv <- pmax(0, rnorm(N_juvenis, phi, sigma_p_init))

    out <- vector("list", generations)
    extincao_gen <- NA_integer_   # geração em que a réplica foi encerrada; NA = chegou ao fim

    for (t in seq_len(generations)) {

      female_p <- female_p_gen                                     # HERDADA (evolui)
      female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s)) # choosiness fixa

      # (1) Censo de adultos constante. A viabilidade age sobre os machos JUVENIS
      # e sobram sempre N_machos adultos. Em Co-evolução ela volta a ter consequência
      # evolutiva (o traço é herdado) e é a única força que age DIRETAMENTE contra
      # a exageração do traço. selecionar_machos_adultos devolve ÍNDICES, então o
      # par (z, p) do mesmo macho viaja junto.
      idx_adultos  <- selecionar_machos_adultos(male_z_juv, N_machos, phi, gamma, selecao_natural)
      male_z_surv  <- male_z_juv[idx_adultos]
      male_p_surv  <- male_p_juv[idx_adultos]
      # Fêmeas não passam por viabilidade: censo por sorteio aleatório, MESMO índice
      # para z e p, senão a covariância dentro de cada fêmea se perde.
      idx_f        <- sample.int(length(female_z_juv), N_femeas)
      female_z_gen <- female_z_juv[idx_f]
      female_p_gen <- female_p_juv[idx_f]

      # (2) Rede de acasalamentos (sem regra de escape)
      M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                               encounters_n = encounters_n, k_fixo = k_fixo,
                               regra = regra)
      metrics <- calc_metrics_from_M(M, k_alvo = k_fixo)

      # (3) Registro. A GRANDEZA CENTRAL deste estudo é cov(z, p) no pool
      # genotípico: é ela que mede o quanto preferência e traço estão associados,
      # e portanto o quanto a seleção sobre um arrasta o outro.
      # Pool genotípico = CENSO ADULTO (N_machos + N_femeas), balanceado entre os
      # sexos. Atenção: aqui, ao contrário de Machos variando, a seleção de viabilidade
      # NÃO é neutra em relação a p, porque z e p estão correlacionados. Usar o
      # censo adulto é o correto: é a população que de fato se reproduz.
      pool_z <- c(male_z_surv, female_z_gen)
      pool_p <- c(male_p_surv, female_p_gen)
      out[[t]] <- data.frame(
        generation = t, tipo_selecao = tipo_selecao, segregacao = segregacao,
        sigma_z_init = sigma_z_init, sigma_p_init = sigma_p_init,
        encounters_n = encounters_n,
        k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
        selecao_natural = selecao_natural,
        zbar_pop = mean(pool_z), varz_pop = var(pool_z),
        pbar_pop = mean(pool_p), varp_pop = var(pool_p),
        cov_zp   = cov(pool_z, pool_p),
        cor_zp   = suppressWarnings(cor(pool_z, pool_p)),
        # a covariância entre os PARES que de fato acasalaram, que é o passo
        # anterior na cadeia causal: é ela que gera a covariância genética
        cov_casais = {
          pares <- which(M == 1L, arr.ind = TRUE)
          if (nrow(pares) > 1) cov(male_z_surv[pares[, 1]], female_p[pares[, 2]]) else NA_real_
        },
        zbar_males = mean(male_z_surv), varz_males = var(male_z_surv),
        pbar_femeas = mean(female_p),   varp_femeas = var(female_p),
        n_machos_surv = length(male_z_surv),   # pool disponível: covariável de densidade
        metrics
      )

      # (4) Próxima geração: as duas características, pareadas
      off <- produce_offspring_coevo(M, male_z_surv, male_p_surv,
                                     female_z_gen, female_p_gen,
                                     N_machos, N_femeas,
                                     fecundidade_base = fecundidade_base,
                                     segregacao = segregacao,
                                     eps_sd = eps_sd, mut_sd = mut_sd)
      if (is.null(off)) { extincao_gen <- t; break }   # encerra e registra onde parou
      male_z_juv   <- off$male_z_juv
      male_p_juv   <- off$male_p_juv
      female_z_juv <- off$female_z_juv
      female_p_juv <- off$female_p_juv
    }

    df_out <- dplyr::bind_rows(out)
    df_out$extincao_gen <- extincao_gen
    df_out
  }

  # =====================================================================
  # DESENHO EXPERIMENTAL: três níveis de variância inicial
  # =====================================================================
  if (!exists("COEVO_SO_FUNCOES") || !isTRUE(COEVO_SO_FUNCOES)) {

    diretorios <- configurar_diretorios("Fase_Coevolucao")
    cat("Iniciando Co-evolução (traço e preferência herdáveis)...\n")

    # Três níveis bem separados, CRUZADOS entre os dois sexos. Não é um gradiente
    # fino de propósito: aqui sigma é só condição inicial e o que se procura é o
    # LIMIAR de ignição do ciclo de Fisher, não uma curva de resposta.
    # O cruzamento (e não a diagonal) é o que permite perguntar se PARTIR
    # assimétrico muda a trajetória. A assimetria das gerações seguintes não é
    # imposta, é MEDIDA a partir de varz_pop e varp_pop (ver o texto).
    valores_sigma <- c(0.5, 1.0, 2.0)
    n_replicas    <- 20

    cenarios <- expand.grid(
      tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
      sigma_p_init    = valores_sigma,
      sigma_z_init    = valores_sigma,
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
    cat(sprintf("Réplicas: %d a %d  (%d cenários)\n", REP_MIN, REP_MAX, nrow(cenarios)))

    arquivo_backup      <- file.path(diretorios$dados, paste0("backup_Coevolucao", sufixo_rep, ".rds"))
    arquivo_final       <- file.path(diretorios$dados, paste0("resultados_Coevolucao", sufixo_rep, ".rds"))
    arquivo_backup_full <- file.path(diretorios$dados, "backup_Coevolucao.rds")

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

    SEED_BASE <- 2030   # semente própria deste estudo
    N_CORES   <- as.integer(Sys.getenv("N_CORES", unset = "5"))

    simular_i <- function(i) {
      res <- simulate_coevolucao(
        generations     = 100,
        N_machos        = 200,
        N_femeas        = 200,
        tipo_selecao    = as.character(cenarios$tipo_selecao[i]),
        sigma_p_init    = cenarios$sigma_p_init[i],
        sigma_z_init    = cenarios$sigma_z_init[i],
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
    df_coevo <- bind_rows(lista[!sapply(lista, is.null)])
    saveRDS(df_coevo, arquivo_final)
    cat("\nCo-evolução (co-evolução) concluído! Dados salvos em:", arquivo_final, "\n")
    cat(sprintf("Total de linhas: %d\n", nrow(df_coevo)))
  }

}
