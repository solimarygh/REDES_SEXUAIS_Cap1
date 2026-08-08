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
cat(sprintf("\n=====================================================\n"))
if (falhas == 0L) {
  cat("TODOS OS TESTES PASSARAM. Pode lançar os três estudos.\n")
} else {
  cat(sprintf("ATENÇÃO: %d teste(s) falharam. NÃO lance ainda.\n", falhas))
}
cat("=====================================================\n")
