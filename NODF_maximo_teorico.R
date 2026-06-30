# =====================================================================
# Cálculo do NODF máximo teórico dadas as restrições do modelo
# =====================================================================

library(bipartite)

N_f <- 200   # fêmeas (linhas)
N_m <- 200   # machos (colunas)
k   <- 5     # acasalamentos por fêmea (fixo)

# ── 1. Matriz maximamente nested (k fixo) ────────────────────────────
# Estratégia: concentrar todas as conexões nos mesmos machos.
# Se todas as 200 fêmeas acasalam com os MESMOS 5 machos,
# a sobreposição entre pares de linhas é máxima (100%).
M_max_nested <- matrix(0L, nrow = N_f, ncol = N_m)
M_max_nested[, 1:k] <- 1L
cat("Soma por linha:", unique(rowSums(M_max_nested)), "\n")
cat("Soma das colunas ocupadas:", colSums(M_max_nested)[1:k], "\n")
cat("Connectance:", sum(M_max_nested) / (N_f * N_m), "\n\n")

nodf_max <- networklevel(M_max_nested, index = "NODF")
cat("NODF máximo teórico (todas as fêmeas, mesmos 5 machos):", nodf_max, "\n\n")

# ── 2. Matriz maximamente nested COM variação de grau ────────────────
# Para comparação: se as fêmeas pudessem ter graus DIFERENTES
# (ex: fêmea 1 acasala com 10, fêmea 200 acasala com 1),
# qual seria o NODF máximo?
M_var <- matrix(0L, nrow = N_f, ncol = N_m)
graus <- ceiling(seq(N_m, 1, length.out = N_f))
for (i in seq_len(N_f)) {
  M_var[i, 1:graus[i]] <- 1L
}
nodf_var <- networklevel(M_var, index = "NODF")
cat("NODF máximo teórico (graus variáveis, perfeitamente nested):", nodf_var, "\n\n")

# ── 3. Matriz aleatória (baseline) ──────────────────────────────────
set.seed(42)
M_rand <- matrix(0L, nrow = N_f, ncol = N_m)
for (i in seq_len(N_f)) {
  M_rand[i, sample(N_m, k)] <- 1L
}
nodf_rand <- networklevel(M_rand, index = "NODF")
cat("NODF aleatório (k=5, escolha uniforme):", nodf_rand, "\n\n")

# ── 4. Testar com A_max restrito ─────────────────────────────────────
cat("=== Efeito de A_max no NODF máximo teórico ===\n")
for (amax in c(200, 40, 10)) {
  M_amax <- matrix(0L, nrow = N_f, ncol = N_m)
  # Cada fêmea amostra A_max machos, e escolhe k=5 deles
  # Máxima nestedness: todas amostram os mesmos A_max machos,
  # e escolhem os mesmos k deles
  cols <- 1:min(amax, N_m)
  chosen <- cols[1:k]
  M_amax[, chosen] <- 1L
  nodf_amax <- networklevel(M_amax, index = "NODF")
  cat(sprintf("  A_max = %3d (%3d%%): NODF max = %.4f\n",
              amax, round(100 * amax / N_m), nodf_amax))
}

cat("\n=== Resumo ===\n")
cat(sprintf("NODF max (k fixo = %d, todas iguais):  %.4f\n", k, nodf_max))
cat(sprintf("NODF max (graus variáveis, nested):     %.4f\n", nodf_var))
cat(sprintf("NODF aleatório (baseline):              %.4f\n", nodf_rand))
cat("\nConclusão: com k fixo, o teto de NODF é estruturalmente limitado.\n")
cat("A nestedness 'baixa' observada nos dados pode ser em grande parte\n")
cat("uma consequência da restrição paramétrica, não da ausência de preferência.\n")
