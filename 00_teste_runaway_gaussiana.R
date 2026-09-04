# =====================================================================
# O RUNAWAY DA GAUSSIANA: CONFIRMAÇÃO COM RÉPLICAS
# =====================================================================
#     Rscript 00_teste_runaway_gaussiana.R
#
# No primeiro teste, uma única réplica da curva gaussiana sem seleção natural
# terminou com zbar = 9.1 e pbar = 9.2, partindo de 5, e cov(z,p) = 14.5. Isso
# tem cara de runaway de Fisher, mas com n = 1 não dá para afirmar nada.
#
# Este teste responde três perguntas que separam um runaway de uma deriva:
#
#   1. As duas médias andam JUNTAS dentro de cada réplica? Num runaway sim,
#      porque a covariância genética as amarra. Na deriva, não.
#   2. A DIREÇÃO é aleatória entre réplicas? A linha de equilíbrios de Lande
#      não tem direção preferida, então metade deveria subir e metade descer.
#      Se todas forem para o mesmo lado, não é runaway, é alguma assimetria
#      do modelo (o truncamento em zero, por exemplo).
#   3. O deslocamento é MAIOR do que o da curva aleatória? A aleatória não tem
#      seleção sexual nenhuma, então serve de régua para a deriva pura.
# =====================================================================

COEVO_SO_FUNCOES <- TRUE
source("Fase_Coevolucao.R")
suppressPackageStartupMessages({ library(dplyr) })

G <- 100L   # gerações
R <- 10L    # réplicas por curva

cat(sprintf("\nRodando %d réplicas de 2 curvas, %d gerações, sem seleção natural...\n", R, G))

res <- bind_rows(lapply(c("gaussian", "uniform"), function(cv) {
  bind_rows(lapply(seq_len(R), function(r) {
    set.seed(9000 + r)   # a MESMA semente nas duas curvas, para o contraste ser limpo
    x <- simulate_coevolucao(generations = G, tipo_selecao = cv,
                             encounters_n = 200, k_fixo = 5L,
                             selecao_natural = FALSE)
    x$replica <- r
    x
  }))
}))

fim <- res %>% filter(generation == G)

# ---------------------------------------------------------------------
cat("\n=== Onde cada réplica terminou (partindo de phi = 5) ===\n\n")
tab <- fim %>%
  transmute(curva = tipo_selecao, replica,
            zbar = round(zbar_pop, 2), pbar = round(pbar_pop, 2),
            desloc_z = round(zbar_pop - 5, 2),
            cov_zp = round(cov_zp, 2), cor_zp = round(cor_zp, 2),
            varz = round(varz_pop, 2)) %>%
  arrange(curva, replica)
print(as.data.frame(tab), row.names = FALSE)

# ---------------------------------------------------------------------
cat("\n=== 1. As duas médias andam juntas? ===\n")
for (cv in c("gaussian", "uniform")) {
  f <- fim %>% filter(tipo_selecao == cv)
  r_zp <- suppressWarnings(cor(f$zbar_pop, f$pbar_pop))
  cat(sprintf("  %-9s correlação entre zbar e pbar entre réplicas: %+.2f\n", cv, r_zp))
}
cat("  Perto de +1 na gaussiana significa que onde o traço foi, a preferência foi junto.\n")

# ---------------------------------------------------------------------
cat("\n=== 2. A direção é aleatória? ===\n")
for (cv in c("gaussian", "uniform")) {
  f <- fim %>% filter(tipo_selecao == cv)
  sobem <- sum(f$zbar_pop > 5)
  cat(sprintf("  %-9s subiram %d de %d réplicas\n", cv, sobem, nrow(f)))
}
cat("  Num runaway sobre a linha de equilíbrios, o esperado é metade para cada lado.\n")
cat("  Todas para o mesmo lado seria sinal de assimetria do modelo, não de Fisher.\n")

# ---------------------------------------------------------------------
cat("\n=== 3. O deslocamento passa da deriva pura? ===\n")
comp <- fim %>%
  group_by(tipo_selecao) %>%
  summarise(desloc_medio = round(mean(abs(zbar_pop - 5)), 2),
            desloc_max   = round(max(abs(zbar_pop - 5)), 2),
            cov_media    = round(mean(cov_zp), 2),
            varz_media   = round(mean(varz_pop), 2),
            .groups = "drop")
print(as.data.frame(comp), row.names = FALSE)

dg <- comp$desloc_medio[comp$tipo_selecao == "gaussian"]
du <- comp$desloc_medio[comp$tipo_selecao == "uniform"]
cat(sprintf("\n  A gaussiana se afastou %.1f vezes mais que a aleatória.\n", dg / max(du, 0.01)))

# ---------------------------------------------------------------------
cat("\n=== A trajetória da gaussiana, a cada 20 gerações ===\n\n")
print(as.data.frame(
  res %>%
    filter(tipo_selecao == "gaussian", generation %% 20 == 0) %>%
    group_by(generation) %>%
    summarise(zbar = round(mean(zbar_pop), 2),
              pbar = round(mean(pbar_pop), 2),
              cov_zp = round(mean(cov_zp), 2),
              varz = round(mean(varz_pop), 2),
              .groups = "drop")
), row.names = FALSE)
cat("\n  Se cov_zp cresce antes de as médias se moverem, a ordem causal é a que\n")
cat("  Fisher prevê: primeiro a covariância se acumula, depois ela arrasta.\n")

dir.create("Resultados_Artigo/Fase_Coevolucao/Dados", recursive = TRUE, showWarnings = FALSE)
saveRDS(res, "Resultados_Artigo/Fase_Coevolucao/Dados/teste_runaway_gaussiana.rds")
cat("\nDados em Resultados_Artigo/Fase_Coevolucao/Dados/teste_runaway_gaussiana.rds\n")
