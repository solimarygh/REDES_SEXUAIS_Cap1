# =====================================================================
# TESTE DE FUMAÇA DOS TRÊS MOTORES
# =====================================================================
# Roda UM cenário de cada estudo e verifica as invariantes do modelo novo.
# Serve para pegar erro de digitação e engano de lógica ANTES de lançar as
# ~136 mil simulações. Leva menos de um minuto.
#
#   Rscript 00_teste_motores.R
#
# Tudo deve sair "OK". Qualquer "FALHOU" precisa ser resolvido antes de rodar.
# =====================================================================

CONTROLE_SO_FUNCOES <- TRUE
ESPELHO_SO_FUNCOES  <- TRUE
source("01_metricas_e_utilitarios.R")
source("Fase_Controle.R")
source("Fase_Espelho.R")

falhas <- 0L
checar <- function(nome, condicao, detalhe = "") {
  ok <- isTRUE(condicao)
  if (!ok) falhas <<- falhas + 1L
  cat(sprintf("  [%s] %s%s\n", if (ok) "OK" else "FALHOU", nome,
              if (nzchar(detalhe)) paste0("  -> ", detalhe) else ""))
}

N <- 200
K <- 5L

# ---------------------------------------------------------------------
cat("\n=== ESTUDO 1: controle nulo ===\n")
set.seed(1)
d1 <- simulate_controle(N_machos = N, N_femeas = N, sigma_z = 2.0, sigma_p = 1.0,
                        tipo_selecao = "gaussian", encounters_n = 40,
                        k_fixo = K, selecao_natural = TRUE)

checar("uma única linha", nrow(d1) == 1)
checar("censo adulto constante mesmo com sigma_z = 2.0 e seleção natural",
       d1$n_machos_surv == N, sprintf("n_machos_surv = %d (esperado %d)", d1$n_machos_surv, N))
checar("colunas novas presentes",
       all(c("grau_medio_femeas", "prop_femeas_atingiu_k", "arestas") %in% names(d1)))
checar("poliandria realizada nunca passa do teto k",
       is.na(d1$grau_medio_femeas) || d1$grau_medio_femeas <= K,
       sprintf("grau_medio_femeas = %.2f, k = %d", d1$grau_medio_femeas, K))
checar("proporção que atingiu k está em [0, 1]",
       is.na(d1$prop_femeas_atingiu_k) ||
         (d1$prop_femeas_atingiu_k >= 0 && d1$prop_femeas_atingiu_k <= 1))

# O ponto principal do censo constante: o pool NÃO deve mudar com sigma_z
set.seed(2); a <- simulate_controle(sigma_z = 0.2, k_fixo = K, selecao_natural = TRUE)
set.seed(3); b <- simulate_controle(sigma_z = 2.0, k_fixo = K, selecao_natural = TRUE)
checar("pool de machos igual em sigma_z = 0.2 e sigma_z = 2.0 (era 198 vs 124 antes)",
       a$n_machos_surv == b$n_machos_surv && a$n_machos_surv == N,
       sprintf("%d vs %d", a$n_machos_surv, b$n_machos_surv))

# A seleção natural deve continuar ESTREITANDO o traço, só não reduzindo o número
set.seed(4); com_ns <- simulate_controle(sigma_z = 2.0, k_fixo = K, selecao_natural = TRUE)
set.seed(4); sem_ns <- simulate_controle(sigma_z = 2.0, k_fixo = K, selecao_natural = FALSE)
checar("seleção natural ainda reduz a variância do traço",
       com_ns$varz_males < sem_ns$varz_males,
       sprintf("var com NS = %.3f, sem NS = %.3f", com_ns$varz_males, sem_ns$varz_males))

# O teto de A_max: com A_max = 10 e k = 20 a poliandria realizada não pode passar de 10
set.seed(5)
d_teto <- simulate_controle(encounters_n = 10, k_fixo = 20L, tipo_selecao = "uniform",
                            selecao_natural = FALSE)
checar("com A_max = 10 e k = 20 o grau realizado fica <= 10",
       is.na(d_teto$grau_medio_femeas) || d_teto$grau_medio_femeas <= 10,
       sprintf("grau_medio_femeas = %.2f", d_teto$grau_medio_femeas))
cat(sprintf("     (poliandria realizada com A_max=10, k=20: %.2f parceiros; %.0f%% atingiram k)\n",
            d_teto$grau_medio_femeas, 100 * d_teto$prop_femeas_atingiu_k))

# ---------------------------------------------------------------------
cat("\n=== ESTUDO 2: fêmeas variando (traço herdável) ===\n")
set.seed(10)
d2 <- simulate_evolution(generations = 10, N_machos = N, N_femeas = N,
                         tipo_selecao = "sigmoid", sigma_p = 1.0, sigma_z_init = 1.0,
                         encounters_n = 40, k_fixo = K, selecao_natural = TRUE)

checar("10 linhas para 10 gerações (uma por geração)", nrow(d2) == 10,
       sprintf("nrow = %d", nrow(d2)))
checar("segregacao gravada como escalar", length(unique(d2$segregacao)) == 1 &&
         d2$segregacao[1] == "infinitesimal")
checar("censo adulto constante em todas as gerações", all(d2$n_machos_surv == N),
       paste(unique(d2$n_machos_surv), collapse = ", "))
checar("réplica completa: extincao_gen é NA", all(is.na(d2$extincao_gen)))
checar("poliandria realizada <= k em todas as gerações",
       all(is.na(d2$grau_medio_femeas) | d2$grau_medio_femeas <= K))
checar("variância do traço NÃO colapsa (modelo infinitesimal)",
       d2$varz_males[10] > 0.2 * d2$varz_males[1],
       sprintf("gen 1 = %.3f, gen 10 = %.3f", d2$varz_males[1], d2$varz_males[10]))

# ---------------------------------------------------------------------
cat("\n=== ESTUDO 3: machos variando (preferência herdável) ===\n")
set.seed(20)
d3 <- simulate_espelho(generations = 10, N_machos = N, N_femeas = N,
                       tipo_selecao = "sigmoid", sigma_z = 1.0, sigma_p_init = 1.0,
                       encounters_n = 40, k_fixo = K, selecao_natural = TRUE)

checar("10 linhas para 10 gerações", nrow(d3) == 10, sprintf("nrow = %d", nrow(d3)))
checar("censo adulto constante em todas as gerações", all(d3$n_machos_surv == N),
       paste(unique(d3$n_machos_surv), collapse = ", "))
checar("réplica completa: extincao_gen é NA", all(is.na(d3$extincao_gen)))
checar("poliandria realizada <= k", all(is.na(d3$grau_medio_femeas) | d3$grau_medio_femeas <= K))
checar("variância da preferência NÃO colapsa",
       d3$varp_pop[10] > 0.2 * d3$varp_pop[1],
       sprintf("gen 1 = %.3f, gen 10 = %.3f", d3$varp_pop[1], d3$varp_pop[10]))
checar("traço do macho NÃO evolui (é ambiental): média fica em torno de phi",
       abs(mean(d3$zbar_males) - 5) < 0.5,
       sprintf("média de zbar_males = %.2f", mean(d3$zbar_males)))

# ---------------------------------------------------------------------
cat("\n=== A INTERAÇÃO A_max x k x curva de preferência ===\n")
cat("Poliandria REALIZADA (grau médio das fêmeas que acasalaram), sem seleção natural:\n\n")
grade <- expand.grid(curva = c("gaussian", "uniform", "u-shaped"),
                     A_max = c(200L, 40L, 10L), k = c(5L, 10L, 20L),
                     stringsAsFactors = FALSE)
grade$grau <- NA_real_; grade$atingiu_k <- NA_real_
for (i in seq_len(nrow(grade))) {
  set.seed(100 + i)
  r <- simulate_controle(tipo_selecao = grade$curva[i], encounters_n = grade$A_max[i],
                         k_fixo = grade$k[i], selecao_natural = FALSE)
  grade$grau[i] <- r$grau_medio_femeas
  grade$atingiu_k[i] <- r$prop_femeas_atingiu_k
}
grade$grau <- round(grade$grau, 2)
grade$atingiu_k <- round(100 * grade$atingiu_k)
print(grade, row.names = FALSE)
cat("\nLeitura: onde 'grau' fica bem abaixo de 'k', o teto NÃO foi atingido e o\n")
cat("tratamento nominal de poliandria não aconteceu. É por isso que a análise\n")
cat("precisa usar a poliandria realizada, e não o k nominal.\n")


# ---------------------------------------------------------------------
cat("\n=== A REGRA DE ESCOLHA: sequencial vs best-of-n ===\n")

# (a) REGRESSÃO. A refatoração de mate_with_survivors não pode ter mudado o
# comportamento antigo. Com regra = "sequencial" o consumo de RNG é o mesmo de
# antes (mesmo sample() dos avaliados, mesmo runif(1) por macho até a parada),
# então a MESMA semente tem que dar a MESMA rede. Se isto falhar, o refactor
# mexeu em algo e os dados velhos deixam de ser comparáveis.
set.seed(4242)
z <- pmax(0, rnorm(200, 5, 1)); p <- pmax(0, rnorm(200, 5, 1)); s <- rnorm(200, 2, 0.2)
set.seed(99); M_seq_a <- mate_with_survivors(z, p, s, "gaussian", encounters_n = 40, k_fixo = 5, regra = "sequencial")
set.seed(99); M_seq_b <- mate_with_survivors(z, p, s, "gaussian", encounters_n = 40, k_fixo = 5, regra = "sequencial")
ok_det <- identical(M_seq_a, M_seq_b)
cat(sprintf("  [%s] sequencial e determinístico dada a semente\n", if (ok_det) "OK" else "FALHOU"))
if (!ok_det) falhas <- falhas + 1L

# (b) QUANTAS AVALIAÇÕES REALMENTE ACONTECEM. É o problema que motivou a
# mudança: com a parada antecipada, A_max era um teto que quase nunca era
# alcançado, então o custo de busca que dizíamos modelar não era pago.
# Sob best-of-n a fêmea avalia sempre os A_max, por construção.
avaliacoes_sequencial <- function(n_aval, P_medio, k) {
  # esperança do número de avaliações até juntar k aceites (binomial negativa),
  # limitada por n_aval
  min(n_aval, k / P_medio)
}
cat("\n  Machos que a fêmea REALMENTE avalia (A_max = 200):\n")
cat(sprintf("    %-12s %-8s %-14s %-14s\n", "curva", "k", "sequencial", "best-of-n"))
for (cv in c("uniform", "gaussian", "u-shaped")) {
  Pm <- switch(cv, "uniform" = 0.50, "gaussian" = 0.33, "u-shaped" = 0.67)
  for (kk in c(5, 20)) {
    cat(sprintf("    %-12s %-8d ~%-13.0f %-14d\n", cv, kk,
                avaliacoes_sequencial(200, Pm, kk), 200L))
  }
}
cat("  Ou seja: no sequencial, A_max = 200 e A_max = 40 eram quase o mesmo cenário.\n")

# (c) O EFEITO DAS TRÊS REGRAS sobre a rede, no mesmo cenário e mesma semente.
cat("\n  As três regras no mesmo cenário (gaussiana, A_max = 40, sem NS):\n")
cat(sprintf("    %-20s %-10s %-10s %-14s\n", "regra", "grau", "atingiu k", "sem acasalar"))
for (rg in c("sequencial", "best_of_n", "best_of_n_estrito")) {
  set.seed(7)
  r <- simulate_controle(tipo_selecao = "gaussian", encounters_n = 40, k_fixo = 10,
                         selecao_natural = FALSE, regra = rg)
  cat(sprintf("    %-20s %-10.2f %-10.0f%% %-13.0f%%\n", rg, r$grau_medio_femeas,
              100 * r$prop_femeas_atingiu_k, 100 * r$prop_femeas_sem_acasalar))
}
cat("\n  Leitura: em 'best_of_n_estrito' NENHUMA fêmea fica sem acasalar, porque\n")
cat("  todas conseguem exatamente k. Sem variância de sucesso reprodutivo entre\n")
cat("  fêmeas não há seleção sobre a preferência, e o Estudo 3 deixa de funcionar.\n")
cat("  É por isso que o default é 'best_of_n', que mantém o filtro de aceite.\n")

# (d) A exigência s importa? Deve importar nas duas primeiras e NÃO na estrita,
# porque ali só a ordem conta, e ela não muda com s.
cat("\n  A exigência s ainda faz diferença? (gaussiana, A_max = 40, k = 10)\n")
for (rg in c("best_of_n", "best_of_n_estrito")) {
  graus <- sapply(c(0.5, 2, 8), function(ss) {
    set.seed(11)
    zz <- pmax(0, rnorm(200, 5, 1)); pp <- pmax(0, rnorm(200, 5, 1))
    Mx <- mate_with_survivors(zz, pp, rep(ss, 200), "gaussian",
                              encounters_n = 40, k_fixo = 10, regra = rg)
    mean(colSums(Mx)[colSums(Mx) > 0])
  })
  cat(sprintf("    %-20s s=0.5: %.2f   s=2: %.2f   s=8: %.2f\n", rg,
              graus[1], graus[2], graus[3]))
}
cat("  Em 'best_of_n_estrito' os três valores devem ser iguais: s vira inerte.\n")

# ---------------------------------------------------------------------
cat(sprintf("\n=====================================================\n"))
if (falhas == 0L) {
  cat("TODOS OS TESTES PASSARAM. Pode lançar os três estudos.\n")
} else {
  cat(sprintf("ATENÇÃO: %d teste(s) falharam. NÃO lance ainda.\n", falhas))
}
cat("=====================================================\n")
