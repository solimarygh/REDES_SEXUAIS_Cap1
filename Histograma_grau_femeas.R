# =====================================================================
# Histograma: número real de machos com os que cada fêmea se acasalou
# =====================================================================

source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})

# ── Parâmetros a explorar ─────────────────────────────────────────────
sigma_p_val  <- 2.0
encounters_n_val <- 200
k_val        <- 5L
ns_val       <- FALSE

cores_4  <- c("uniform"  = "gray55",
              "gaussian" = "#E6B800",
              "sigmoid"  = "#3BA273",
              "u-shaped" = "#9932CC")

labels_4 <- c("uniform"  = "Random",
              "gaussian" = "Gaussian",
              "sigmoid"  = "Sigmoid",
              "u-shaped" = "Disruptive")

# ── Rodar 1 réplica por tipo de preferência e extrair M ──────────────
set.seed(2026)

graus_todas <- data.frame()

for (tipo in names(cores_4)) {
  res <- simulate_evolution(
    generations     = 100,
    N_machos        = 200,
    N_femeas        = 200,
    tipo_selecao    = tipo,
    sigma_p         = sigma_p_val,
    encounters_n    = encounters_n_val,
    k_fixo          = k_val,
    selecao_natural = ns_val,
    return_details  = TRUE
  )

  M <- res$Matriz_M_Gen50
  # colSums(M) = grau de cada fêmea (quantos machos distintos ela acasalou)
  grau_femeas <- colSums(M)

  graus_todas <- rbind(graus_todas, data.frame(
    tipo_selecao = tipo,
    grau = grau_femeas
  ))
}

# ── Histograma ────────────────────────────────────────────────────────
p <- ggplot(graus_todas, aes(x = grau, fill = tipo_selecao)) +
  geom_histogram(binwidth = 1, color = "white", alpha = 0.85,
                 position = "identity") +
  facet_wrap(~tipo_selecao,
             labeller = as_labeller(labels_4)) +
  scale_fill_manual(values = cores_4) +
  scale_x_continuous(breaks = 0:10) +
  labs(title = "How many males did each female actually mate with?",
       subtitle = sprintf("Gen 100  |  σp = %.1f  |  A_max = %d  |  k = %d  |  %s",
                          sigma_p_val, encounters_n_val, k_val,
                          if (ns_val) "With NS" else "Without NS"),
       x = "Number of mates per female",
       y = "Number of females") +
  theme_light(base_size = 14) +
  theme(legend.position = "none",
        strip.background = element_rect(fill = "#2C3E50"),
        strip.text = element_text(color = "white", face = "bold", size = 13),
        plot.title = element_text(face = "bold", size = 16),
        plot.subtitle = element_text(color = "gray45", size = 11))

# ── Estatísticas ──────────────────────────────────────────────────────
cat("\n=== Grau das fêmeas (Gen 100) ===\n")
graus_todas %>%
  group_by(tipo_selecao) %>%
  summarise(
    min = min(grau),
    media = round(mean(grau), 2),
    max = max(grau),
    prop_menor_k = round(mean(grau < k_val) * 100, 1),
    .groups = "drop"
  ) %>%
  print()

# ── Salvar ────────────────────────────────────────────────────────────
dir.create("Resultados_Artigo/Poster", recursive = TRUE, showWarnings = FALSE)
ggsave("Resultados_Artigo/Poster/Histograma_grau_femeas.png",
       p, width = 10, height = 7, dpi = 300)
cat("\nGráfico salvo em: Resultados_Artigo/Poster/Histograma_grau_femeas.png\n")
