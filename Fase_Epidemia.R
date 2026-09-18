# =====================================================================
# ESTUDO 5: UMA IST NA REDE SEXUAL, AO LONGO DE UMA TEMPORADA
# =====================================================================
# Primeira parte do Objetivo 2 do projeto: uma doença que se transmite por
# contato sexual e que altera a atratividade do macho infectado.
#
# POR QUE UMA TEMPORADA BASTA PARA O RELATÓRIO
# Numa temporada não se vê a resposta evolutiva, mas vê-se o DIFERENCIAL DE
# SELEÇÃO sobre o traço: a diferença entre a média de z pesada pelo sucesso de
# acasalamento e a média de todos os machos. É a medida clássica (Lande &
# Arnold 1983), é o que a equação do criador transforma em resposta esperada, e
# sai de uma temporada só. Dá para medir a rede, medir a epidemia e medir a
# pressão seletiva que a epidemia gera. O que fica para as gerações é conferir
# se a previsão se cumpre.
#
# COMO A INFECÇÃO ENTRA NA ESCOLHA
# O sinal que a fêmea avalia não é z, é z + h. O macho infectado carrega
# h = h_I, que pode ser negativo (a doença o deixa menos atraente, o caso
# clássico de Hamilton e Zuk), zero, ou positivo (manipulação parasitária).
# Isso não exige mexer em mate_with_survivors: basta passar z + h como vetor de
# traços. O diferencial de seleção, esse sim, é sempre calculado sobre o z
# verdadeiro, porque é ele que se herda: h muda o que a fêmea vê, não o que o
# macho transmite aos filhos.
#
# A TEMPORADA, AS SEMANAS E AS PARCERIAS
# Cada ronda é uma SEMANA da temporada reprodutiva. Dentro de uma semana a
# fêmea NÃO inspeciona a população inteira, e não parte do zero: ela tem um
# conjunto de parcerias VIGENTES, que copulam e se dissolvem, e só procura
# parceiro novo se houver espaço abaixo do teto de parcerias simultâneas.
#
# Cada semana, para cada fêmea, nesta ordem:
#   1. cada parceria vigente copula com probabilidade `cop_semana`;
#   2. cada parceria vigente se dissolve com probabilidade 1 / `dur_parceria`;
#   3. se o número de parcerias vigentes ficou abaixo de `concorrencia`, ela
#      encontra `encontros` machos ao acaso, aplica a regra de dois passos, e
#      forma UMA parceria nova com o melhor entre os que aceitou, copulando.
#
# POR QUE AS PARCERIAS PRECISAM SER EXPLÍCITAS
# A primeira versão deste motor não as tinha: cada semana a fêmea sorteava
# machos do zero, e uma cópula repetida com o mesmo macho só acontecia por
# azar de reencontro. Medindo, a razão entre cópulas e parceiros ficava em 1.3
# a 1.45, ou seja praticamente uma cópula por parceria, e isso não é uma IST:
# é um modelo de contato instantâneo, em que a estrutura temporal da rede não
# faz nada. Baixar o teto de parceiros não resolvia, porque a razão se mantinha
# plana em 1.4 para qualquer teto; só aumentavam as semanas vazias. Com as
# parcerias explícitas a razão passa a 3 a 5, que é o regime em que uma IST tem
# a sua dinâmica característica.
#
# A CONCORRÊNCIA É O PARÂMETRO QUE MANDA
# Medido sobre o próprio modelo, com duração 5 semanas e cópula 0.7 por semana,
# a incidência acumulada ao fim da temporada vai de 16% com uma parceria
# simultânea a 53% com duas, 80% com três e 93% com quatro. É o resultado
# clássico da epidemiologia de redes sexuais, e aqui sai como resultado e não
# como escolha de calibração.
#
# A REGRA DE DOIS PASSOS, NA BUSCA
# O passo 3 usa exatamente a regra dos Estudos 1 a 4, o que mantém a
# comparabilidade: cada macho encontrado passa ou não passa POR SEPARADO, com a
# sua própria probabilidade P_ij, e só depois, entre os que passaram, ela fica
# com o de maior P. Se nenhum passar, não se forma parceria nova naquela
# semana. A alternativa considerada e descartada era identificar o melhor dos
# encontrados e só então decidir sobre ele; faz mais sentido que uma fêmea que
# encontrou dez machos considere mais de um.
#
# A DIFERENÇA IMPORTANTE EM RELAÇÃO AOS OUTROS ESTUDOS: número de PARCEIROS e
# número de CÓPULAS deixam de ser a mesma coisa. Nos Estudos 1 a 4, em que a
# rede é de uma geração, cada aresta é uma cópula. Aqui a fêmea pode ter poucos
# parceiros e muitas cópulas. E os dois números fazem coisas diferentes: são as
# CÓPULAS que movem a epidemia, e são os PARCEIROS que dão a topologia da rede.
# Por isso os dois ficam registrados.
#
# A transmissão acontece sobre as cópulas DA SEMANA, nos dois sentidos e
# decidida sobre o estado do início da semana. Depois vem a recuperação: no SIS
# o infectado volta a suscetível, no SIR passa a recuperado e não se infecta
# mais.
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
                              # quantos machos ela ENCONTRA por semana. É o
                              # análogo de A_max, mas na escala de uma semana e
                              # não de uma geração inteira.
                              encontros = 10L,
                              # AS PARCERIAS. `concorrencia` é o teto de
                              # parcerias SIMULTÂNEAS, que substitui o teto de
                              # parceiros da temporada da versão anterior: é a
                              # concorrência, e é o parâmetro que mais move a
                              # epidemia. `dur_parceria` é a duração média em
                              # semanas, e `cop_semana` a probabilidade de um
                              # casal estabelecido copular numa semana.
                              #
                              # Os três valores abaixo dão, na medição, cerca de
                              # 8 parceiros e 33 cópulas por fêmea na temporada,
                              # ou seja 4 cópulas por parceria.
                              concorrencia  = 2L,
                              dur_parceria  = 5,
                              cop_semana    = 0.7,
                              # 20 semanas: uma temporada reprodutiva de cerca
                              # de quatro meses, contada em semanas.
                              rodadas = 20L,
                              # a doença
                              modelo = c("SIS", "SIR"),
                              h_I = 0,          # efeito da infecção no sinal
                              # beta e gamma_rec calibrados sobre o próprio
                              # modelo, com as parcerias já implementadas: dão
                              # cerca de 32% de incidência acumulada e 17% de
                              # prevalência ao fim da temporada, o que passa o
                              # critério de "grande epidemia" do plano (15%) e
                              # deixa espaço para h_I mover nos dois sentidos.
                              # O período infeccioso é 1/gamma_rec = 10 semanas,
                              # metade da temporada, de modo que a recuperação
                              # acontece e o contraste SIS contra SIR tem
                              # conteúdo. Com o beta de 0.10 da versão anterior,
                              # e sem parcerias, a epidemia se extinguia.
                              beta = 0.15,      # transmissão por cópula
                              gamma_rec = 0.10, # recuperação por semana
                              prev0 = 0.05,     # prevalência inicial
                              # a viabilidade fica DESLIGADA por padrão: é uma
                              # temporada só, não há resposta evolutiva para a
                              # seleção natural modular, e assim o censo é
                              # sempre N por construção.
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
  # todas as semanas. Se fosse re-sorteada, uma troca de parceiro poderia ser
  # dela e não da doença, e o efeito de h ficaria confundido.
  female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))

  # ---- estado epidemiológico: 0 = S, 1 = I, 2 = R ------------------
  estado_m <- rep(0L, n_m)
  estado_f <- rep(0L, N_femeas)
  estado_m[sample.int(n_m, max(1L, round(prev0 * n_m)))] <- 1L
  estado_f[sample.int(N_femeas, max(1L, round(prev0 * N_femeas)))] <- 1L
  ja_infectado_m <- estado_m == 1L   # incidência acumulada
  ja_infectado_f <- estado_f == 1L

  M_acum  <- matrix(0L, nrow = n_m, ncol = N_femeas)  # toda parceria já formada
  atuais  <- matrix(0L, nrow = n_m, ncol = N_femeas)  # as parcerias VIGENTES
  copulas <- matrix(0L, nrow = n_m, ncol = N_femeas)  # quantas vezes cada par
  out <- vector("list", rodadas)

  for (r in seq_len(rodadas)) {

    # (1) A semana. O estado do INÍCIO fica guardado porque é ele que governa a
    # escolha desta semana, e é contra ele que o efeito de h tem de ser medido.
    estado_m_ini <- estado_m
    z_efetivo <- male_z + ifelse(estado_m == 1L, h_I, 0)

    M_semana <- matrix(0L, nrow = n_m, ncol = N_femeas)
    vig <- which(atuais == 1L, arr.ind = TRUE)

    # (2) As parcerias vigentes copulam, e depois dissolvem-se. A ordem
    # importa: uma parceria que se dissolve nesta semana ainda copulou nela.
    if (nrow(vig)) {
      copulou <- runif(nrow(vig)) < cop_semana
      if (any(copulou)) M_semana[vig[copulou, , drop = FALSE]] <- 1L
      solta <- runif(nrow(vig)) < 1 / dur_parceria
      if (any(solta)) atuais[vig[solta, , drop = FALSE]] <- 0L
    }

    # (3) Quem tem espaço abaixo do teto de parcerias simultâneas procura. A
    # busca é a regra de dois passos dos Estudos 1 a 4: mate_with_survivors com
    # k_fixo = 1 sorteia os `encontros` machos sem reposição, aplica P_ij a cada
    # um e devolve o de maior P entre os aceitos. Se o escolhido já for parceiro
    # vigente, nada acontece: ele já copulou no passo 2, com a sua própria
    # probabilidade.
    com_espaco <- colSums(atuais) < as.integer(concorrencia)
    if (any(com_espaco)) {
      M_busca <- mate_with_survivors(z_efetivo, female_p, female_s, tipo_selecao,
                                     encounters_n = encontros, k_fixo = 1L,
                                     regra = regra)
      novos <- M_busca == 1L & atuais == 0L
      novos[, !com_espaco] <- FALSE
      if (any(novos)) {
        atuais[novos]   <- 1L
        M_semana[novos] <- 1L
      }
    }

    M_acum  <- pmax(M_acum, M_semana)   # toda parceria já formada
    copulas <- copulas + M_semana       # quantas vezes cada par copulou

    # (3) Transmissão sobre as cópulas DESTA semana, nos dois sentidos.
    pares <- which(M_semana == 1L, arr.ind = TRUE)
    if (nrow(pares)) {
      # Os dois sentidos se decidem sobre o estado do INÍCIO da semana. Sem
      # isto, quem se infecta no primeiro sentido já contagia no segundo dentro
      # da mesma semana, e a transmissão fica assimétrica entre os sexos só por
      # causa da ordem em que o código está escrito.
      m0 <- estado_m; f0 <- estado_f

      cand <- pares[m0[pares[, 1]] == 1L & f0[pares[, 2]] == 0L, , drop = FALSE]
      if (nrow(cand)) estado_f[cand[runif(nrow(cand)) < beta, 2]] <- 1L

      cand <- pares[f0[pares[, 2]] == 1L & m0[pares[, 1]] == 0L, , drop = FALSE]
      if (nrow(cand)) estado_m[cand[runif(nrow(cand)) < beta, 1]] <- 1L
    }
    ja_infectado_m <- ja_infectado_m | estado_m == 1L
    ja_infectado_f <- ja_infectado_f | estado_f == 1L

    # (4) Recuperação, depois da transmissão: quem se infectou nesta semana
    # ainda não pode se curar nela.
    inf_m <- which(estado_m == 1L); inf_f <- which(estado_f == 1L)
    alvo  <- if (modelo == "SIS") 0L else 2L
    if (length(inf_m)) estado_m[inf_m[runif(length(inf_m)) < gamma_rec]] <- alvo
    if (length(inf_f)) estado_f[inf_f[runif(length(inf_f)) < gamma_rec]] <- alvo

    # (5) Registro. As métricas de rede e a seleção são sobre a rede ACUMULADA,
    # que é a rede da temporada até aqui.
    # Sem k_alvo: na rede acumulada da temporada não há teto de parceiros. O
    # limite que existe é de parcerias SIMULTÂNEAS, e ele é registrado abaixo.
    metrics <- calc_metrics_from_M(M_acum)
    sel     <- diferencial_de_selecao(male_z, copulas)

    out[[r]] <- data.frame(
      semana = r, tipo_selecao = tipo_selecao, modelo = modelo, regra = regra,
      sigma_p = sigma_p, sigma_z = sigma_z,
      encontros = as.integer(encontros),
      concorrencia = as.integer(concorrencia),
      dur_parceria = dur_parceria, cop_semana = cop_semana,
      rodadas = as.integer(rodadas),
      h_I = h_I, beta = beta, gamma_rec = gamma_rec, prev0 = prev0,
      selecao_natural = selecao_natural,

      # --- a epidemia ---
      prev_machos = mean(estado_m == 1L),
      prev_femeas = mean(estado_f == 1L),
      prev_total  = mean(c(estado_m, estado_f) == 1L),
      incid_acum  = mean(c(ja_infectado_m, ja_infectado_f)),
      recuperados = mean(c(estado_m, estado_f) == 2L),

      # --- a rede, e a distinção entre parceiros e cópulas ---
      parceiros_distintos = mean(colSums(M_acum)),
      copulas_acumuladas  = mean(colSums(copulas)),
      copulas_na_semana   = mean(colSums(M_semana)),
      # A razão que justifica a formação explícita de parcerias. Sem elas, cada
      # parceiro rende ~1.4 cópulas e a doença não circula; com elas, a razão
      # sobe para a faixa de 3 a 5, e é ela que dá tempo de transmissão a cada
      # parceria.
      copulas_por_parceria = if (sum(M_acum) > 0) sum(copulas) / sum(M_acum) else NA_real_,
      # As parcerias vigentes no fim desta semana: a concorrência REALIZADA,
      # que é menor do que o teto porque uma parceria só se forma se a fêmea
      # aceitar alguém.
      concorrencia_realizada = mean(colSums(atuais)),
      prop_femeas_na_concorrencia = mean(colSums(atuais) >= as.integer(concorrencia)),
      prop_femeas_sem_parceria    = mean(colSums(atuais) == 0),
      # quantas fêmeas passaram esta semana em branco, sem aceitar ninguém
      prop_semana_em_branco = mean(colSums(M_semana) == 0),
      n_machos_surv = n_m,
      metrics,

      # --- a seleção sobre o traço ---
      # pesada pelas CÓPULAS e não pelos parceiros: é o sucesso reprodutivo que
      # conta, e um macho que copulou dez vezes com a mesma fêmea teve mais
      # sucesso do que um que copulou uma vez.
      S_traco  = sel$S,
      i_traco  = sel$i,
      zbar_pop = mean(male_z),
      zbar_pares = sel$zbar_pares,
      varz_pop = var(male_z),

      # --- o efeito direto de h, medido na ordem causal certa ---
      # Cópulas ganhas NESTA semana, separando os machos pelo estado que tinham
      # no INÍCIO dela. Comparar com o estado do fim da temporada não mede h:
      # os machos de z alto copulam mais e por isso se infectam primeiro, e
      # "estar infectado" viraria consequência do sucesso, e não causa.
      copulas_semana_infectados  = if (any(estado_m_ini == 1L)) mean(rowSums(M_semana)[estado_m_ini == 1L]) else NA_real_,
      copulas_semana_suscetiveis = if (any(estado_m_ini == 0L)) mean(rowSums(M_semana)[estado_m_ini == 0L]) else NA_real_,
      # O confundidor, à vista: se os infectados já tinham z maior, parte da
      # diferença é do traço e não da doença.
      z_infectados  = if (any(estado_m_ini == 1L)) mean(male_z[estado_m_ini == 1L]) else NA_real_,
      z_suscetiveis = if (any(estado_m_ini == 0L)) mean(male_z[estado_m_ini == 0L]) else NA_real_,

      # E o mesmo sobre a rede acumulada, que NÃO isola h e serve para outra
      # coisa: mostrar que quem mais acasala é quem mais se infecta, que é o
      # mecanismo de super-disseminador.
      grau_acum_infectados  = if (any(estado_m == 1L)) mean(rowSums(M_acum)[estado_m == 1L]) else NA_real_,
      grau_acum_suscetiveis = if (any(estado_m == 0L)) mean(rowSums(M_acum)[estado_m == 0L]) else NA_real_
    )
  }

  df <- bind_rows(out)
  # "grande epidemia" pelo critério do plano de trabalho: pelo menos 15% da
  # população infectada em algum momento.
  df$grande_epidemia <- max(df$incid_acum) >= 0.15
  df
}

# ---------------------------------------------------------------------
# O diferencial de seleção sobre o traço do macho
# ---------------------------------------------------------------------
# S = média de z pesada pelo sucesso reprodutivo menos a média de z na
# população. A equação do criador a transforma em resposta esperada: R = h² S.
# Por isso uma temporada já diz alguma coisa sobre evolução, sem gerações.
#
# i = S / sd(z) é o mesmo em unidades de desvio-padrão, o que permite comparar
# entre células com variâncias diferentes.
diferencial_de_selecao <- function(z, sucesso_matriz) {
  sucesso <- rowSums(sucesso_matriz)
  if (sum(sucesso) == 0 || length(z) < 2) {
    return(list(S = NA_real_, i = NA_real_, zbar_pares = NA_real_))
  }
  zbar_pares <- sum(z * sucesso) / sum(sucesso)
  S   <- zbar_pares - mean(z)
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
  cat("Estudo 5: uma IST na rede sexual, ao longo de uma temporada.\n")

  n_replicas <- 100L

  # A transmissão entra como FATOR, com dois níveis, e não como constante. A
  # razão é que o critério de "grande epidemia" do plano de trabalho (15% da
  # população infectada em algum momento) só tem informação numa faixa estreita
  # de beta, e as duas perguntas do estudo vivem em faixas diferentes.
  #
  # Com beta = 0.15 a epidemia acontece em todas as células, e é isso que dá
  # espaço para os contrastes secundários (h_I, SIS contra SIR, sigma_p) serem
  # medidos: a incidência é uma resposta contínua com variação para os dois
  # lados. O critério dos 15%, aí, é passado por 100% das temporadas e não
  # distingue nada.
  #
  # Com beta = 0.06 o critério passa a discriminar, e a curva de preferência
  # deixa de mudar o TAMANHO da epidemia para decidir se ela ACONTECE: na
  # medição, a gaussiana não produz nenhuma grande epidemia e a disruptiva
  # produz em cerca de 80% das temporadas, com os mesmos parâmetros em tudo o
  # mais. É o resultado qualitativo, e ele não seria visível com um beta só.
  #
  # Os dois níveis dobram o custo da rodada, que fica na ordem de algumas
  # horas. Para voltar a um beta só, basta deixar um valor no vetor abaixo.
  cenarios <- expand.grid(
    tipo_selecao = c("uniform", "gaussian", "sigmoid", "u-shaped"),
    sigma_p      = c(0.5, 1.0, 1.5),   # os níveis do plano de trabalho
    h_I          = c(-1, 0, 1),        # em unidades de sigma_z, que é 1.0
    modelo       = c("SIS", "SIR"),
    beta         = c(0.06, 0.15),      # limiar e epidemia estabelecida
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
      modelo       = as.character(cenarios$modelo[i]),
      beta         = cenarios$beta[i]
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
  fim <- df[df$semana == max(df$semana), ]
  cat(sprintf("Parceiros por fêmea: %.1f | cópulas por fêmea: %.1f | cópulas por parceria: %.2f\n",
              mean(fim$parceiros_distintos), mean(fim$copulas_acumuladas),
              mean(fim$copulas_por_parceria, na.rm = TRUE)))
  cat(sprintf("Concorrência realizada: %.2f parcerias simultâneas por fêmea (teto %d)\n",
              mean(fim$concorrencia_realizada), unique(fim$concorrencia)[1]))
  cat(sprintf("Incidência acumulada: %.1f%% | prevalência final: %.1f%%\n",
              100 * mean(fim$incid_acum), 100 * mean(fim$prev_total)))
  # O critério do plano, por nível de transmissão e por curva: é aqui que se vê
  # se o beta baixo está mesmo na faixa em que a curva decide se há epidemia.
  cat("\nGrandes epidemias (pelo menos 15% infectados em algum momento):\n")
  tab <- tapply(fim$grande_epidemia,
                list(fim$tipo_selecao, fim$beta), mean)
  print(round(100 * tab, 1))
}
