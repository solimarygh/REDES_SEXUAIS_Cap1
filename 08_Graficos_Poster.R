# =====================================================================
# SCRIPT 08: Gráficos para Poster
# Três figuras: Assinatura Topológica | Dumbbell | Trajetória Evolutiva
# Foco: k=5 | Modularity + Nestedness | sem seleção natural
# =====================================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)

# ── CARREGAR DADOS ────────────────────────────────────────────────────
arquivo_backup <- "Resultados_Artigo/Fase5_MiudoV2/Dados/backup_lista_fase5_miudov2.rds"
arquivo_final  <- "Resultados_Artigo/Fase5_MiudoV2/Dados/resultados_Fase5_MiudoV2.rds"

if (file.exists(arquivo_backup)) {
  lista <- readRDS(arquivo_backup)
  df    <- bind_rows(lista[!sapply(lista, is.null)])
  cat(sprintf("Backup carregado: %d linhas.\n", nrow(df)))
} else if (file.exists(arquivo_final)) {
  df <- readRDS(arquivo_final)
  cat(sprintf("Arquivo final carregado: %d linhas.\n", nrow(df)))
} else {
  stop("Nenhum arquivo encontrado. Rode Fase4_TodasAsCurvas.R primeiro.")
}

dir_poster <- "Resultados_Artigo/Poster"
dir.create(dir_poster, recursive = TRUE, showWarnings = FALSE)

# ── CONSTANTES ────────────────────────────────────────────────────────
K_POSTER    <- 5L
NS_POSTER   <- FALSE   # sem seleção natural (efeito puro da preferência feminina)
SP_POSTER   <- 2.0     # sigma_p para dumbbell e trajetória
AMAX_POSTER <- 200     # cenário ideal
GEN_FINAL   <- max(df$generation, na.rm = TRUE)
val_reps    <- length(unique(df$replica[!is.na(df$replica)]))

cores_4  <- c("uniform"  = "gray55",
               "gaussian" = "#E6B800",
               "sigmoid"  = "#3BA273",
               "u-shaped" = "#9932CC")

labels_4 <- c("uniform"  = "Random",
               "gaussian" = "Gaussian",
               "sigmoid"  = "Sigmoid",
               "u-shaped" = "Disruptive")

# ── TEMAS POSTER ──────────────────────────────────────────────────────
tema_poster_claro <- theme_light(base_size = 16) +
  theme(
    plot.background   = element_rect(fill = "white",   color = NA),
    panel.background  = element_rect(fill = "#F7F7F7", color = NA),
    panel.grid.major  = element_line(color = "#E0E0E0", linewidth = 0.4),
    panel.grid.minor  = element_blank(),
    strip.background  = element_rect(fill = "#2C3E50"),
    strip.text        = element_text(color = "white",  face = "bold", size = 15),
    plot.title        = element_text(face = "bold", size = 17),
    plot.subtitle     = element_text(color = "gray40", size = 12),
    axis.title        = element_text(face = "bold", size = 14),
    axis.text         = element_text(size = 12),
    legend.position   = "bottom",
    legend.text       = element_text(size = 13),
    legend.key.width  = unit(1.5, "cm"),
    legend.background = element_rect(fill = "white", color = NA)
  )

tema_poster_escuro <- theme_dark(base_size = 16) +
  theme(
    plot.background   = element_rect(fill = "#1A1A2E", color = NA),
    panel.background  = element_rect(fill = "#16213E", color = NA),
    panel.grid.major  = element_line(color = "#2C2C4E", linewidth = 0.4),
    panel.grid.minor  = element_blank(),
    strip.background  = element_rect(fill = "#E6B800"),
    strip.text        = element_text(color = "#1A1A1A", face = "bold", size = 15),
    plot.title        = element_text(color = "white",   face = "bold", size = 17),
    plot.subtitle     = element_text(color = "#AAAAAA", size = 12),
    axis.title        = element_text(color = "white",   face = "bold", size = 14),
    axis.text         = element_text(color = "#CCCCCC", size = 12),
    legend.position   = "bottom",
    legend.text       = element_text(color = "white",  size = 13),
    legend.key.width  = unit(1.5, "cm"),
    legend.background = element_rect(fill = "#1A1A2E", color = NA),
    legend.key        = element_rect(fill = "#1A1A2E", color = NA)
  )

# Troca aqui para o tema escuro: tema_poster <- tema_poster_escuro
tema_poster <- tema_poster_claro

# ── DADOS FILTRADOS ────────────────────────────────────────────────────
df_k5 <- df %>% filter(k_fixo == K_POSTER, selecao_natural == NS_POSTER)

# =====================================================================
# PLOT 1: ASSINATURA TOPOLÓGICA
# =====================================================================
df_topo <- df_k5 %>%
  filter(generation == GEN_FINAL, encounters_n == AMAX_POSTER) %>%
  drop_na(Modularity, Nestedness) %>%
  pivot_longer(cols = c(Modularity, Nestedness),
               names_to = "Metrica", values_to = "Valor") %>%
  mutate(Metrica = ifelse(Metrica == "Modularity",
                          "1. Modularity",
                          "2. Nestedness (NODF)"))

p_topo <- ggplot(df_topo,
                 aes(x = sigma_p, y = Valor,
                     color = tipo_selecao, fill = tipo_selecao)) +
  geom_vline(xintercept = 1.0, linetype = "dashed",
             color = "red", linewidth = 1) +
  annotate("text", x = 1.0, y = Inf,
           label = "σp = σz", hjust = -0.15, vjust = 2,
           color = "red", size = 4.5, fontface = "italic") +
  geom_smooth(method = "loess", formula = y ~ x,
              alpha = 0.15, linewidth = 1.5, show.legend = FALSE) +
  geom_jitter(alpha = 0.25, width = 0.05, size = 1.8) +
  facet_wrap(~Metrica, scales = "free_y", ncol = 2) +
  scale_color_manual(values = cores_4, labels = labels_4) +
  scale_fill_manual(values  = cores_4, labels = labels_4) +
  labs(
    title    = "Topological Signature of Female Preference Curves",
    subtitle = sprintf("k = %d  |  A_max = %d  |  %d replicates  |  Generation %d",
                       K_POSTER, AMAX_POSTER, val_reps, GEN_FINAL),
    x        = expression(paste("Female Preference Variation (", sigma[p], ")")),
    y        = "Metric Value",
    color    = "", fill = ""
  ) +
  guides(color = guide_legend(override.aes = list(size = 4, alpha = 1, shape = 19)),
         fill  = "none") +
  tema_poster

# =====================================================================
# PLOT 2: DUMBBELL — Gen 1 → Gen Final
# =====================================================================
resumir_gen <- function(df_in, gen_label) {
  df_in %>%
    filter(encounters_n == AMAX_POSTER, sigma_p == SP_POSTER) %>%
    drop_na(Modularity, Nestedness) %>%
    group_by(tipo_selecao) %>%
    summarise(Modularity = mean(Modularity, na.rm = TRUE),
              Nestedness = mean(Nestedness, na.rm = TRUE),
              .groups = "drop") %>%
    mutate(Geracao = gen_label)
}

# Tabela wide: Gen_inicial e Gen_final como colunas separadas (igual Script 07)
df_tabela_dumb <- df_k5 %>%
  filter(generation %in% c(1, GEN_FINAL),
         encounters_n == AMAX_POSTER,
         sigma_p == SP_POSTER) %>%
  drop_na(Modularity, Nestedness) %>%
  group_by(generation, tipo_selecao) %>%
  summarise(Modularity = mean(Modularity, na.rm = TRUE),
            Nestedness = mean(Nestedness, na.rm = TRUE),
            .groups = "drop") %>%
  pivot_longer(cols = c(Modularity, Nestedness),
               names_to = "Metrica", values_to = "Valor") %>%
  mutate(gen_label = ifelse(generation == 1, "Gen_inicial", "Gen_final")) %>%
  dplyr::select(-generation) %>%
  pivot_wider(names_from = gen_label, values_from = Valor) %>%
  mutate(
    Delta = Gen_final - Gen_inicial,
    tipo_label = factor(
      recode(tipo_selecao, "uniform"="Random", "gaussian"="Gaussian",
             "sigmoid"="Sigmoid", "u-shaped"="U-shaped"),
      levels = c("U-shaped","Sigmoid","Gaussian","Random")),
    Metrica = ifelse(Metrica == "Modularity", "1. Modularity", "2. Nestedness (NODF)")
  )

p_dumb <- ggplot(df_tabela_dumb) +
  geom_segment(aes(x = Gen_inicial, xend = Gen_final,
                   y = tipo_label,  yend = tipo_label,
                   color = tipo_selecao),
               linewidth = 1.8, alpha = 0.7) +
  # Gen 1 — círculo ABERTO (fill branco)
  geom_point(aes(x = Gen_inicial, y = tipo_label, color = tipo_selecao),
             size = 5, shape = 21, fill = "white", stroke = 2) +
  # Gen Final — círculo FECHADO (fill colorido)
  geom_point(aes(x = Gen_final, y = tipo_label, color = tipo_selecao),
             size = 5) +
  geom_text(aes(x = (Gen_inicial + Gen_final) / 2, y = tipo_label,
                label = sprintf("%+.3f", Delta), color = tipo_selecao),
            hjust = 0.5, vjust = -0.7, size = 4, fontface = "bold") +
  facet_wrap(~Metrica, scales = "free_x", ncol = 2) +
  scale_color_manual(values = cores_4, labels = labels_4) +
  labs(
    title    = sprintf("Evolutionary Change in Network Structure (σp = %.1f, k = %d, A_max = %d)",
                       SP_POSTER, K_POSTER, AMAX_POSTER),
    subtitle = sprintf("Open circle = Gen 1  |  Filled circle = Gen %d  |  Label = Δ",
                       GEN_FINAL),
    x = "Mean Metric Value", y = "", color = ""
  ) +
  guides(color = guide_legend(override.aes = list(size = 4, shape = 19)),
         fill  = "none") +
  tema_poster

# =====================================================================
# PLOT 2b: EFEITO DO CUSTO DE BUSCA — Média e Variância do Traço (A_max=200)
# =====================================================================
df_ruido_poster <- df_k5 %>%
  filter(generation == GEN_FINAL, encounters_n == AMAX_POSTER) %>%
  drop_na(zbar_males, varz_males) %>%
  pivot_longer(cols = c(zbar_males, varz_males),
               names_to = "Variavel", values_to = "Valor") %>%
  mutate(Variavel = ifelse(Variavel == "zbar_males",
                           "1. Mean Ornament (z̅)",
                           "2. Genetic Diversity (Var z)"))

# Linhas de referência por painel: φ=5 para média, Var z=1 para variância
df_refs_ruido <- data.frame(
  Variavel   = c("1. Mean Ornament (z̅)", "2. Genetic Diversity (Var z)"),
  yintercept = c(5.0, 1.0),
  label      = c("φ = 5 (initial mean)", "Var z = 1 (initial)")
)

p_ruido <- ggplot(df_ruido_poster,
                  aes(x = sigma_p, y = Valor,
                      color = tipo_selecao, fill = tipo_selecao)) +
  geom_hline(data = df_refs_ruido,
             aes(yintercept = yintercept),
             linetype = "dashed", color = "gray50", linewidth = 0.8,
             inherit.aes = FALSE) +
  geom_text(data = df_refs_ruido,
            aes(x = 0.3, y = yintercept, label = label),
            hjust = 0, vjust = -0.5, color = "gray50", size = 3.5,
            fontface = "italic", inherit.aes = FALSE) +
  geom_vline(xintercept = 1.0, linetype = "dashed",
             color = "red", linewidth = 1) +
  annotate("text", x = 1.0, y = Inf,
           label = "σp = σz", hjust = -0.15, vjust = 2,
           color = "red", size = 4.5, fontface = "italic") +
  geom_smooth(method = "loess", formula = y ~ x,
              alpha = 0.15, linewidth = 1.5, show.legend = FALSE) +
  geom_jitter(alpha = 0.25, width = 0.05, size = 1.8) +
  facet_wrap(~Variavel, scales = "free_y", ncol = 2) +
  scale_color_manual(values = cores_4, labels = labels_4) +
  scale_fill_manual(values  = cores_4, labels = labels_4) +
  labs(
    title    = sprintf("Female Preference Shapes Trait Mean and Variance (A_max = %d, k = %d, Gen %d)",
                       AMAX_POSTER, K_POSTER, GEN_FINAL),
    subtitle = sprintf("%d replicates", val_reps),
    x        = expression(paste("Female Preference Variation (", sigma[p], ")")),
    y        = NULL,
    color    = "", fill = ""
  ) +
  guides(color = guide_legend(override.aes = list(size = 4, alpha = 1, shape = 19)),
         fill  = "none") +
  tema_poster

# =====================================================================
# PLOT 3: TRAJETÓRIA EVOLUTIVA DO TRAÇO MASCULINO
# =====================================================================
df_traj <- df_k5 %>%
  filter(encounters_n == AMAX_POSTER, sigma_p == SP_POSTER) %>%
  group_by(tipo_selecao, generation) %>%
  summarise(
    media_z = mean(zbar_males, na.rm = TRUE),
    sd_z    = sd(zbar_males,   na.rm = TRUE),
    .groups = "drop"
  )

p_traj <- ggplot(df_traj,
                 aes(x = generation, y = media_z,
                     color = tipo_selecao, fill = tipo_selecao)) +
  geom_ribbon(aes(ymin = media_z - sd_z, ymax = media_z + sd_z),
              alpha = 0.12, color = NA) +
  geom_line(linewidth = 1.4) +
  geom_hline(yintercept = 5, linetype = "dashed",
             color = "gray50", linewidth = 0.8) +
  annotate("text", x = 1, y = 5,
           label = "φ = 5 (initial optimum)", hjust = 0, vjust = -0.5,
           color = "gray50", size = 3.8, fontface = "italic") +
  scale_color_manual(values = cores_4, labels = labels_4) +
  scale_fill_manual(values  = cores_4, labels = labels_4) +
  labs(
    title    = sprintf("Evolutionary Trajectory of Male Ornament (σp = %.1f, k = %d, A_max = %d)",
                       SP_POSTER, K_POSTER, AMAX_POSTER),
    subtitle = sprintf("%d replicates  |  ribbon = ±1 SD across replicates",
                       val_reps),
    x = "Generation", y = expression(paste("Mean Male Trait (", bar(z), ")")),
    color = "", fill = ""
  ) +
  guides(
    color = guide_legend(override.aes = list(size = 3, alpha = 1, shape = 19)),
    fill  = "none"
  ) +
  tema_poster

# =====================================================================
# EXPORTAR — claro e transparente
# =====================================================================
plots <- list(
  Poster_Plot1_TopologicalSignature = p_topo,
  Poster_Plot2_Dumbbell             = p_dumb,
  Poster_Plot2b_TraitMeanVariance   = p_ruido,
  Poster_Plot3_Trajectory           = p_traj
)

dims <- list(
  Poster_Plot1_TopologicalSignature = c(13, 6),
  Poster_Plot2_Dumbbell             = c(13, 5),
  Poster_Plot2b_TraitMeanVariance   = c(13, 6),
  Poster_Plot3_Trajectory           = c(11, 5)
)

for (nome in names(plots)) {
  w <- dims[[nome]][1]; h <- dims[[nome]][2]
  # Fundo branco
  ggsave(file.path(dir_poster, paste0(nome, "_white.png")),
         plot = plots[[nome]], width = w, height = h, dpi = 300, bg = "white")
  # Fundo transparente (para posters com fundo colorido)
  ggsave(file.path(dir_poster, paste0(nome, "_transparent.png")),
         plot = plots[[nome]], width = w, height = h, dpi = 300, bg = "transparent")
}

cat(sprintf("\n6 arquivos PNG salvos em: %s\n", dir_poster))
cat("  (_white = fundo branco | _transparent = fundo transparente)\n")
cat("  Para tema escuro: mude 'tema_poster <- tema_poster_escuro' e rode novamente.\n")

print(p_topo)
print(p_dumb)
print(p_traj)
