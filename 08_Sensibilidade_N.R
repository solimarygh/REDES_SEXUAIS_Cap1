# =====================================================================
# SCRIPT 08: Análise de Sensibilidade ao Tamanho Populacional (N)
# =====================================================================
# Objetivo: Testar se as assinaturas topológicas observadas na Fase 4
# são robustas ao tamanho populacional (N=200 vs N=1000), ou se são
# artefatos demográficos da rede esparsa.
#
# Design minimalista para material suplementar:
#   N            : 200 vs 1000
#   tipo_selecao : uniform, gaussian, u-shaped
#   sigma_p      : 0.5, 2.0
#   encounters_n : 200 (condição ideal, sem ruído ecológico)
#   réplicas     : 30
#   gerações     : 50
#
# Total: 2 x 3 x 2 x 30 = 360 simulações
# =====================================================================
source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

dir08 <- configurar_diretorios("Fase8_SensibilidadeN")

# =====================================================================
# DESENHO EXPERIMENTAL
# =====================================================================
cenarios <- expand.grid(
  N_pop        = c(200, 1000),
  tipo_selecao = c("uniform", "gaussian", "u-shaped"),
  sigma_p      = c(0.5, 2.0),
  encounters_n = 200,
  replica      = 1:30,
  stringsAsFactors = FALSE
)

arquivo_backup <- file.path(dir08$dados, "backup_sensibilidade_N.rds")
arquivo_final  <- file.path(dir08$dados, "resultados_sensibilidade_N.rds")

if (file.exists(arquivo_backup)) {
  lista_res <- readRDS(arquivo_backup)
  cat(sprintf("Backup encontrado! %d cenários já completos.\n", sum(!sapply(lista_res, is.null))))
  if (length(lista_res) != nrow(cenarios)) length(lista_res) <- nrow(cenarios)
} else {
  set.seed(2026)
  lista_res <- vector("list", nrow(cenarios))
  cat("Nenhum backup. Iniciando do zero.\n")
}

# =====================================================================
# LOOP DE SIMULAÇÃO
# =====================================================================
for (i in 1:nrow(cenarios)) {

  if (!is.null(lista_res[[i]])) next

  if (i %% 10 == 0 || i == 1)
    cat(sprintf("Cenário %d / %d (%.1f%%)\n", i, nrow(cenarios), 100*i/nrow(cenarios)))

  N  <- cenarios$N_pop[i]

  res <- tryCatch({
    simulate_evolution(
      generations  = 50,
      N_machos     = N,
      N_femeas     = N,
      tipo_selecao = cenarios$tipo_selecao[i],
      sigma_p      = cenarios$sigma_p[i],
      encounters_n = cenarios$encounters_n[i],
      return_details = FALSE
    )
  }, error = function(e) {
    cat("Erro no cenário", i, ":", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(res)) {
    res$replica <- cenarios$replica[i]
    res$N_pop   <- N
    lista_res[[i]] <- res
  }

  if (i %% 20 == 0) saveRDS(lista_res, arquivo_backup)
}

saveRDS(lista_res, arquivo_backup)
df_sens <- bind_rows(lista_res[!sapply(lista_res, is.null)])
saveRDS(df_sens, arquivo_final)
cat(sprintf("\nConcluído! %d linhas salvas em: %s\n", nrow(df_sens), arquivo_final))

# =====================================================================
# ANÁLISE E GRÁFICOS (Geração 50)
# =====================================================================
df_gen50 <- df_sens %>%
  filter(generation == 50) %>%
  drop_na() %>%
  mutate(
    N_label    = factor(paste0("N = ", N_pop), levels = c("N = 200", "N = 1000")),
    tipo_label = factor(tipo_selecao,
                        levels = c("uniform", "gaussian", "u-shaped"),
                        labels = c("Aleatória", "Gaussiana", "Disruptiva"))
  )

cores_3 <- c("Aleatória" = "gray60", "Gaussiana" = "#E6B800", "Disruptiva" = "#9932CC")

tema <- theme_light(base_size = 13) +
  theme(legend.position  = "bottom",
        strip.background = element_rect(fill = "gray10"),
        strip.text       = element_text(color = "white", face = "bold"))

# ---------------------------------------------------------------------
# PLOT 1: Modularity — sinal topológico persiste com N=1000?
# ---------------------------------------------------------------------
p_mod <- ggplot(df_gen50, aes(x = tipo_label, y = Modularity,
                               color = tipo_label, fill = tipo_label)) +
  geom_boxplot(alpha = 0.3, outlier.size = 0.8) +
  facet_grid(N_label ~ factor(sigma_p, labels = c("σp = 0.5", "σp = 2.0"))) +
  scale_color_manual(values = cores_3) +
  scale_fill_manual(values  = cores_3) +
  labs(title    = "Sensibilidade ao N: Modularidade",
       subtitle = "Cada caixa = 30 réplicas na Geração 50",
       x = "", y = "Modularity (Louvain)", color = "", fill = "") +
  tema

# ---------------------------------------------------------------------
# PLOT 2: Variância genética — rescate persiste com N=1000?
# ---------------------------------------------------------------------
p_varz <- ggplot(df_gen50, aes(x = tipo_label, y = varz_males,
                                color = tipo_label, fill = tipo_label)) +
  geom_boxplot(alpha = 0.3, outlier.size = 0.8) +
  facet_grid(N_label ~ factor(sigma_p, labels = c("σp = 0.5", "σp = 2.0"))) +
  scale_color_manual(values = cores_3) +
  scale_fill_manual(values  = cores_3) +
  labs(title    = "Sensibilidade ao N: Diversidade Genética",
       subtitle = "Cada caixa = 30 réplicas na Geração 50",
       x = "", y = "Var(z) machos", color = "", fill = "") +
  tema

# ---------------------------------------------------------------------
# PLOT 3: Média do traço — exagero persiste com N=1000?
# ---------------------------------------------------------------------
p_zbar <- ggplot(df_gen50, aes(x = tipo_label, y = zbar_males,
                                color = tipo_label, fill = tipo_label)) +
  geom_boxplot(alpha = 0.3, outlier.size = 0.8) +
  geom_hline(yintercept = 5.0, linetype = "dashed", alpha = 0.5) +
  facet_grid(N_label ~ factor(sigma_p, labels = c("σp = 0.5", "σp = 2.0"))) +
  scale_color_manual(values = cores_3) +
  scale_fill_manual(values  = cores_3) +
  labs(title    = "Sensibilidade ao N: Exagero do Traço",
       subtitle = "Linha tracejada = φ = 5.0 (ótimo ecológico)",
       x = "", y = "Média z machos", color = "", fill = "") +
  tema

# Exibir
print(p_mod)
print(p_varz)
print(p_zbar)

# Exportar
ggsave(file.path(dir08$graficos, "Sens_N_Modularity.png"),  plot = p_mod,  width = 9, height = 7, dpi = 300, bg = "white")
ggsave(file.path(dir08$graficos, "Sens_N_VarZ.png"),        plot = p_varz, width = 9, height = 7, dpi = 300, bg = "white")
ggsave(file.path(dir08$graficos, "Sens_N_ZbarMachos.png"),  plot = p_zbar, width = 9, height = 7, dpi = 300, bg = "white")
cat("\nGráficos de sensibilidade salvos em:", dir08$graficos, "\n")
