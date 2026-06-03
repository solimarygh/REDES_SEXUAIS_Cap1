# =====================================================================
# SCRIPT 09: Distribuição do Traço Masculino — U-shaped (Bimodalidade)
# =====================================================================
# Roda simulate_evolution com return_details=TRUE para extrair os z
# individuais de cada macho na geração final e visualizar a bimodalidade.
# =====================================================================
source("01_metricas_e_utilitarios.R")
library(ggplot2)
library(dplyr)
library(patchwork)

set.seed(2026)

GENERATIONS  <- 100
N            <- 200
N_REPS       <- 30
SIGMAS       <- c(0.5, 1.0, 1.5, 2.0)
AMAXES       <- c(200, 40, 10)
CURVAS_COMP  <- c("u-shaped", "sigmoid", "gaussian", "uniform")

dir_out <- "Resultados_Artigo/UShape_Bimodalidade/Graficos"
dir.create(dir_out, recursive = TRUE, showWarnings = FALSE)

# ---- 1. COLETA DE DISTRIBUIÇÕES (u-shaped, todos sigma_p × A_max) ----
cat("Rodando simulações para u-shaped...\n")
df_ushaped <- list()
cont <- 1

for (sp in SIGMAS) {
  for (am in AMAXES) {
    cat(sprintf("  σp = %.1f | A_max = %d\n", sp, am))
    for (r in seq_len(N_REPS)) {
      set.seed(2026 + r * 100 + am)
      res <- simulate_evolution(
        tipo_selecao = "u-shaped", sigma_p = sp,
        encounters_n = am, generations = GENERATIONS,
        N_machos = N, N_femeas = N, return_details = TRUE
      )
      df_ushaped[[cont]] <- data.frame(
        z = res$Gen50$Z_Machos,
        sigma_p = sp, encounters_n = am, replica = r
      )
      cont <- cont + 1
    }
  }
}

df_u <- bind_rows(df_ushaped) %>%
  mutate(
    Amax_label  = factor(paste0("A_max = ", encounters_n),
                         levels = c("A_max = 200", "A_max = 40", "A_max = 10")),
    sigma_label = factor(paste0("σp = ", sigma_p),
                         levels = paste0("σp = ", SIGMAS))
  )

# ---- 2. PLOT A: Distribuições por σp (A_max = 200) ----
p_sigmas <- ggplot(df_u %>% filter(encounters_n == 200),
                   aes(x = z, fill = sigma_label, color = sigma_label)) +
  geom_density(alpha = 0.35, linewidth = 0.9) +
  geom_vline(xintercept = 5, linetype = "dashed", color = "black", alpha = 0.5) +
  facet_wrap(~sigma_label, ncol = 1, scales = "free_y") +
  scale_fill_viridis_d(option = "plasma", begin = 0.1, end = 0.85) +
  scale_color_viridis_d(option = "plasma", begin = 0.1, end = 0.85) +
  labs(
    title    = "Distribuição de z (machos) — U-shaped",
    subtitle = sprintf("A_max = 200 | N = %d | Gen = %d | %d réplicas pooled", N, GENERATIONS, N_REPS),
    x = "Traço masculino z", y = "Densidade"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", strip.text = element_text(face = "bold"))

# ---- 3. PLOT B: Efeito de A_max na bimodalidade (σp = 2.0) ----
p_amax <- ggplot(df_u %>% filter(sigma_p == 2.0),
                 aes(x = z, fill = Amax_label, color = Amax_label)) +
  geom_density(alpha = 0.35, linewidth = 0.9) +
  geom_vline(xintercept = 5, linetype = "dashed", color = "black", alpha = 0.5) +
  facet_wrap(~Amax_label, ncol = 1, scales = "free_y") +
  scale_fill_manual(values  = c("A_max = 200" = "#2E86AB",
                                 "A_max = 40"  = "#A23B72",
                                 "A_max = 10"  = "#F18F01")) +
  scale_color_manual(values = c("A_max = 200" = "#2E86AB",
                                 "A_max = 40"  = "#A23B72",
                                 "A_max = 10"  = "#F18F01")) +
  labs(
    title    = "Efeito do custo de busca (σp = 2.0)",
    subtitle = sprintf("σp = 2.0 | N = %d | Gen = %d | %d réplicas pooled", N, GENERATIONS, N_REPS),
    x = "Traço masculino z", y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", strip.text = element_text(face = "bold"))

# ---- 4. PLOT C: Comparação entre as 4 curvas (σp = 2.0, A_max = 200) ----
cat("Rodando simulações comparativas para as 4 curvas...\n")
df_comp <- list()
cont <- 1

for (curva in CURVAS_COMP) {
  cat(sprintf("  %s\n", curva))
  for (r in seq_len(N_REPS)) {
    set.seed(2026 + r * 100)
    res <- simulate_evolution(
      tipo_selecao = curva, sigma_p = 2.0,
      encounters_n = 200, generations = GENERATIONS,
      N_machos = N, N_femeas = N, return_details = TRUE
    )
    df_comp[[cont]] <- data.frame(
      z = res$Gen50$Z_Machos,
      curva = curva, replica = r
    )
    cont <- cont + 1
  }
}

df_c <- bind_rows(df_comp) %>%
  mutate(curva = factor(curva,
                        levels = c("uniform", "gaussian", "sigmoid", "u-shaped"),
                        labels = c("Uniforme", "Gaussiana", "Sigmoide", "U-shaped")))

cores_4 <- c("Uniforme" = "gray60", "Gaussiana" = "#E6B800",
             "Sigmoide" = "#3BA273", "U-shaped"  = "#9932CC")

p_comp <- ggplot(df_c, aes(x = z, fill = curva, color = curva)) +
  geom_density(alpha = 0.35, linewidth = 0.9) +
  geom_vline(xintercept = 5, linetype = "dashed", color = "black", alpha = 0.5) +
  facet_wrap(~curva, ncol = 2) +
  scale_fill_manual(values  = cores_4) +
  scale_color_manual(values = cores_4) +
  labs(
    title    = "Distribuição de z na Gen 100 — Comparação das 4 curvas",
    subtitle = sprintf("σp = 2.0 | A_max = 200 | N = %d | Gen = %d | %d réplicas pooled",
                       N, GENERATIONS, N_REPS),
    x = "Traço masculino z", y = "Densidade",
    caption = "Linha tracejada = ótimo ecológico φ = 5.0"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", strip.text = element_text(face = "bold", size = 11))

# ---- 5. PAINEL FINAL ----
painel_esquerda <- p_sigmas | p_amax

painel_final <- painel_esquerda / p_comp +
  plot_annotation(
    title = "U-shaped: Evidência de Dois Morfos Masculinos",
    subtitle = sprintf(
      "Seleção sexual disruptiva em conflito com seleção viabilidade (φ = 5.0)\nN = %d | Gen = %d | %d réplicas por cenário",
      N, GENERATIONS, N_REPS
    ),
    theme = theme(
      plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 11, hjust = 0.5)
    )
  ) +
  plot_layout(heights = c(1, 0.8))

nome_saida <- file.path(dir_out, "Bimodalidade_Ushaped.png")
ggsave(nome_saida, painel_final, width = 14, height = 18, dpi = 300, bg = "white")
cat(sprintf("\nGráfico salvo em: %s\n", nome_saida))

# ---- 6. TESTE DE HARTIGAN'S DIP (bimodalidade formal) ----
if (requireNamespace("diptest", quietly = TRUE)) {
  library(diptest)
  cat("\n===== TESTE DE HARTIGAN'S DIP =====\n")

  dir_dados <- "Resultados_Artigo/UShape_Bimodalidade/Dados"
  dir.create(dir_dados, recursive = TRUE, showWarnings = FALSE)

  resultados_dip <- list()
  cont_dip <- 1

  for (am in AMAXES) {
    for (sp in SIGMAS) {
      z_vals <- df_u %>% filter(encounters_n == am, sigma_p == sp) %>% pull(z)
      d <- dip.test(z_vals)
      cat(sprintf("  σp = %.1f | A_max = %3d  |  D = %.4f  |  p = %.4f  %s\n",
                  sp, am, d$statistic, d$p.value,
                  ifelse(d$p.value < 0.05, "*** BIMODAL", "")))
      resultados_dip[[cont_dip]] <- data.frame(
        sigma_p     = sp,
        encounters_n = am,
        D           = round(as.numeric(d$statistic), 4),
        p_valor     = round(d$p.value, 4)
      )
      cont_dip <- cont_dip + 1
    }
  }

  df_dip <- bind_rows(resultados_dip)
  write.csv(df_dip, file.path(dir_dados, "dip_test_resultados.csv"), row.names = FALSE)
  cat(sprintf("\nTabela dip test salva em: %s/dip_test_resultados.csv\n", dir_dados))

} else {
  cat("\nPara testar bimodalidade formalmente: install.packages('diptest')\n")
}
