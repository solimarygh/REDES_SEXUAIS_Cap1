# =====================================================================
# Cálculo do NODF máximo teórico dadas as restrições do modelo
# =====================================================================

library(bipartite)

N_f <- 200   # fêmeas (linhas)
N_m <- 200   # machos (colunas)
k   <- 5     # acasalamentos por fêmea (fixo)

# ── 1. Matriz maximamente nested com k fixo ──────────────────────────
# Estratégia: construir um gradiente de popularidade nos machos.
# Macho 1 é escolhido por TODAS as fêmeas → grau máximo
# Machos seguintes por cada vez menos fêmeas → grau decrescente
# Isso maximiza variação nos graus dos machos (colunas),
# mantendo k=5 fixo por fêmea (linhas).
#
# Construção: fêmea i conecta às colunas {1, 2, ..., 4, 4 + ceil(i * (N_m-4)/N_f)}
# → colunas 1-4 fixas (grau = N_f) + coluna 5 vai "deslizando"
# → maximiza overlap entre pares de colunas com graus decrescentes

M_nested_kfixo <- matrix(0L, nrow = N_f, ncol = N_m)
for (i in seq_len(N_f)) {
  fixas <- 1:4
  movel <- 4 + ceiling(i * (N_m - 4) / N_f)
  M_nested_kfixo[i, c(fixas, movel)] <- 1L
}
cat("=== Matriz nested com k fixo ===\n")
cat("Soma por linha (deve ser 5):", unique(rowSums(M_nested_kfixo)), "\n")
cat("Range graus colunas:", range(colSums(M_nested_kfixo)), "\n")
cat("Colunas com grau > 0:", sum(colSums(M_nested_kfixo) > 0), "\n\n")

nodf_nested_kfixo <- networklevel(M_nested_kfixo, index = "NODF")
cat("NODF (k fixo, gradiente nested):", nodf_nested_kfixo, "\n\n")

# ── 2. Variação: mais colunas "deslizantes" ──────────────────────────
# Agora 3 fixas + 2 deslizantes → mais variação nos graus das colunas
M_nested_v2 <- matrix(0L, nrow = N_f, ncol = N_m)
for (i in seq_len(N_f)) {
  fixas <- 1:3
  movel1 <- 3 + ceiling(i * (N_m - 3) / N_f)
  movel2 <- 3 + ceiling(((i + N_f/2 - 1) %% N_f + 1) * (N_m - 3) / N_f)
  cols <- unique(c(fixas, movel1, movel2))
  if (length(cols) < k) {
    extras <- setdiff(seq_len(N_m), cols)
    cols <- c(cols, extras[1:(k - length(cols))])
  }
  M_nested_v2[i, cols[1:k]] <- 1L
}
cat("=== Variação 2: 3 fixas + 2 deslizantes ===\n")
cat("Soma por linha:", unique(rowSums(M_nested_v2)), "\n")
nodf_v2 <- networklevel(M_nested_v2, index = "NODF")
cat("NODF v2:", nodf_v2, "\n\n")

# ── 3. Matriz perfeitamente nested (graus variáveis, sem restrição k) ─
M_var <- matrix(0L, nrow = N_f, ncol = N_m)
graus <- ceiling(seq(N_m, 1, length.out = N_f))
for (i in seq_len(N_f)) {
  M_var[i, 1:graus[i]] <- 1L
}
nodf_var <- networklevel(M_var, index = "NODF")
cat("=== Sem restrição de k (graus variáveis) ===\n")
cat("NODF máximo teórico absoluto:", nodf_var, "\n\n")

# ── 4. Baseline: matriz aleatória com k fixo ─────────────────────────
set.seed(42)
M_rand <- matrix(0L, nrow = N_f, ncol = N_m)
for (i in seq_len(N_f)) {
  M_rand[i, sample(N_m, k)] <- 1L
}
nodf_rand <- networklevel(M_rand, index = "NODF")
cat("=== Random baseline (k=5) ===\n")
cat("NODF aleatório:", nodf_rand, "\n\n")

# ── 5. Efeito de A_max ───────────────────────────────────────────────
cat("=== Efeito de A_max no NODF (random, k=5) ===\n")
set.seed(42)
for (amax in c(200, 40, 10)) {
  M_amax <- matrix(0L, nrow = N_f, ncol = N_m)
  for (i in seq_len(N_f)) {
    pool <- sample(N_m, amax)
    escolhidos <- sample(pool, min(k, amax))
    M_amax[i, escolhidos] <- 1L
  }
  nodf_amax <- networklevel(M_amax, index = "NODF")
  cat(sprintf("  A_max = %3d (%3d%%): NODF = %.4f\n",
              amax, round(100 * amax / N_m), nodf_amax))
}

cat("\n=== RESUMO ===\n")
cat(sprintf("NODF max absoluto (graus variáveis):     %.1f\n", nodf_var))
cat(sprintf("NODF max com k fixo (gradiente nested):  %.4f\n", nodf_nested_kfixo))
cat(sprintf("NODF v2 (3 fixas + 2 deslizantes):       %.4f\n", nodf_v2))
cat(sprintf("NODF random baseline (k=5):              %.4f\n", nodf_rand))
cat("\nNota: com k fixo, NODFlinhas = 0 sempre (todas as fêmeas têm grau = k).\n")
cat("O NODF observado vem inteiramente da variação nos graus dos MACHOS.\n")
cat("Teto teórico com k fixo ≈ 50 (metade da métrica está morta).\n")
