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
                           "1. Male Trait Mean (z̅)",
                           "2. Male Trait Variance (Var z)"))

# Linha de referência só para o painel de média (φ=5); Var z escala livre nos dados
df_refs_ruido <- data.frame(
  Variavel   = "1. Male Trait Mean (z̅)",
  yintercept = 5.0,
  label      = "φ = 5 (initial mean)"
)

p_ruido <- ggplot(df_ruido_poster,
                  aes(x = sigma_p, y = Valor,
                      color = tipo_selecao, fill = tipo_selecao)) +
  geom_hline(data = df_refs_ruido,
             aes(yintercept = yintercept),
             linetype = "dashed", color = "gray50", linewidth = 0.8) +
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
# PLOT 3b: TRAJETÓRIA EVOLUTIVA DA VARIÂNCIA DO TRAÇO
# =====================================================================
df_traj_var <- df_k5 %>%
  filter(encounters_n == AMAX_POSTER, sigma_p == SP_POSTER) %>%
  group_by(tipo_selecao, generation) %>%
  summarise(
    media_varz = mean(varz_males, na.rm = TRUE),
    sd_varz    = sd(varz_males,   na.rm = TRUE),
    .groups = "drop"
  )

p_traj_var <- ggplot(df_traj_var,
                     aes(x = generation, y = media_varz,
                         color = tipo_selecao, fill = tipo_selecao)) +
  geom_ribbon(aes(ymin = media_varz - sd_varz, ymax = media_varz + sd_varz),
              alpha = 0.12, color = NA) +
  geom_line(linewidth = 1.4) +
  geom_hline(yintercept = 1, linetype = "dashed",
             color = "gray50", linewidth = 0.8) +
  annotate("text", x = 1, y = 1,
           label = "Var z = 1 (initial)", hjust = 0, vjust = -0.5,
           color = "gray50", size = 3.8, fontface = "italic") +
  scale_color_manual(values = cores_4, labels = labels_4) +
  scale_fill_manual(values  = cores_4, labels = labels_4) +
  labs(
    title    = sprintf("Evolutionary Trajectory of Male Trait Variance (σp = %.1f, k = %d, A_max = %d)",
                       SP_POSTER, K_POSTER, AMAX_POSTER),
    subtitle = sprintf("%d replicates  |  ribbon = ±1 SD across replicates",
                       val_reps),
    x = "Generation", y = "Male Trait Variance (Var z)",
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
  Poster_Plot3_Trajectory           = p_traj,
  Poster_Plot3b_TrajectoryVariance  = p_traj_var
)

dims <- list(
  Poster_Plot1_TopologicalSignature = c(13, 6),
  Poster_Plot2_Dumbbell             = c(13, 5),
  Poster_Plot2b_TraitMeanVariance   = c(13, 6),
  Poster_Plot3_Trajectory           = c(11, 5),
  Poster_Plot3b_TrajectoryVariance  = c(11, 5)
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

cat(sprintf("\n5 plots individuais salvos em: %s\n", dir_poster))
cat("  (_white = fundo branco | _transparent = fundo transparente)\n")
cat("  Para tema escuro: mude 'tema_poster <- tema_poster_escuro' e rode novamente.\n")

# =====================================================================
# POSTER 4×4: Grid Comparativo Completo
# Filas : Modularity | Nestedness | z̄ | Var z
# Colunas: Gen 1 | Gen Final | Traj σp baixo | Traj σp alto
# =====================================================================

SP_LOW  <- 0.5       # σp "baixo" para colunas de trajetória
SP_HIGH <- SP_POSTER  # σp "alto"  (2.0)

# Usar o valor de σp disponível mais próximo
sp_vals_k5  <- sort(unique(df_k5$sigma_p))
SP_LOW_act  <- sp_vals_k5[which.min(abs(sp_vals_k5 - SP_LOW))]
SP_HIGH_act <- sp_vals_k5[which.min(abs(sp_vals_k5 - SP_HIGH))]
cat(sprintf("Grid 4×4: σp baixo = %.2f | σp alto = %.2f\n", SP_LOW_act, SP_HIGH_act))

# ── Dados base ────────────────────────────────────────────────────
df_g1    <- df_k5 %>% filter(generation == 1,         encounters_n == AMAX_POSTER)
df_gFin  <- df_k5 %>% filter(generation == GEN_FINAL,  encounters_n == AMAX_POSTER)
df_tLow  <- df_k5 %>% filter(sigma_p == SP_LOW_act,    encounters_n == AMAX_POSTER)
df_tHigh <- df_k5 %>% filter(sigma_p == SP_HIGH_act,   encounters_n == AMAX_POSTER)

# ── Tema compacto ─────────────────────────────────────────────────
tema_grid <- theme_light(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "#F7F7F7", color = NA),
    panel.grid.major = element_line(color = "#E0E0E0", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold", size = 12, hjust = 0.5,
                                    margin = margin(b = 4)),
    axis.title       = element_text(face = "bold", size = 10),
    axis.text        = element_text(size = 8),
    legend.position  = "bottom",
    legend.text      = element_text(size = 11),
    legend.key.width = unit(1.2, "cm"),
    plot.margin      = margin(3, 5, 3, 5)
  )

# ── Função: painel de snapshot (X = σp, gen fixo) ─────────────────
f_snap <- function(df_in, metrica_col, titulo = NULL,
                   y_label = NULL, x_label = NULL, ref_y = NULL) {
  df_p <- df_in %>%
    mutate(Valor = .data[[metrica_col]]) %>%
    drop_na(Valor)
  p <- ggplot(df_p, aes(x = sigma_p, y = Valor,
                         color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red",
               linewidth = 0.5, alpha = 0.6) +
    geom_smooth(method = "loess", formula = y ~ x, alpha = 0.15,
                linewidth = 1.0, show.legend = FALSE) +
    geom_jitter(alpha = 0.2, width = 0.05, size = 0.9) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values  = cores_4, labels = labels_4) +
    labs(title = titulo, x = x_label, y = y_label, color = "", fill = "") +
    guides(color = guide_legend(override.aes = list(size = 3, alpha = 1, shape = 19)),
           fill = "none") +
    tema_grid
  if (!is.null(ref_y))
    p <- p + geom_hline(yintercept = ref_y, linetype = "dashed",
                        color = "gray50", linewidth = 0.6)
  p
}

# ── Função: painel de trajetória (X = geração, σp fixo) ───────────
f_traj <- function(df_in, metrica_col, titulo = NULL,
                   y_label = NULL, x_label = NULL, ref_y = NULL) {
  df_t <- df_in %>%
    drop_na(all_of(metrica_col)) %>%
    group_by(tipo_selecao, generation) %>%
    summarise(media  = mean(.data[[metrica_col]], na.rm = TRUE),
              sd_val = sd(.data[[metrica_col]],   na.rm = TRUE),
              .groups = "drop")
  p <- ggplot(df_t, aes(x = generation, y = media,
                         color = tipo_selecao, fill = tipo_selecao)) +
    geom_ribbon(aes(ymin = media - sd_val, ymax = media + sd_val),
                alpha = 0.12, color = NA) +
    geom_line(linewidth = 1.0) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values  = cores_4, labels = labels_4) +
    labs(title = titulo, x = x_label, y = y_label, color = "", fill = "") +
    guides(color = guide_legend(override.aes = list(size = 3, alpha = 1, shape = 19)),
           fill = "none") +
    tema_grid
  if (!is.null(ref_y))
    p <- p + geom_hline(yintercept = ref_y, linetype = "dashed",
                        color = "gray50", linewidth = 0.6)
  p
}

# ── Rótulos ───────────────────────────────────────────────────────
hdr1 <- "Gen 1"
hdr2 <- sprintf("Gen %d", GEN_FINAL)
hdr3 <- sprintf("Traj  σp = %.1f", SP_LOW_act)
hdr4 <- sprintf("Traj  σp = %.1f", SP_HIGH_act)

ylb_M <- "Modularity"
ylb_N <- "Nestedness\n(NODF)"
ylb_Z <- "z̄  (Trait Mean)"
ylb_V <- "Var z\n(Trait Var)"

xlb_sp  <- expression(sigma[p])
xlb_gen <- "Generation"

# ── 16 painéis ────────────────────────────────────────────────────

# Fila 1: Modularity
p_M1 <- f_snap(df_g1,    "Modularity", titulo = hdr1, y_label = ylb_M)
p_M2 <- f_snap(df_gFin,  "Modularity", titulo = hdr2)
p_M3 <- f_traj(df_tLow,  "Modularity", titulo = hdr3)
p_M4 <- f_traj(df_tHigh, "Modularity", titulo = hdr4)

# Fila 2: Nestedness
p_N1 <- f_snap(df_g1,    "Nestedness", y_label = ylb_N)
p_N2 <- f_snap(df_gFin,  "Nestedness")
p_N3 <- f_traj(df_tLow,  "Nestedness")
p_N4 <- f_traj(df_tHigh, "Nestedness")

# Fila 3: z̄
p_Z1 <- f_snap(df_g1,    "zbar_males", y_label = ylb_Z, ref_y = 5.0)
p_Z2 <- f_snap(df_gFin,  "zbar_males",                  ref_y = 5.0)
p_Z3 <- f_traj(df_tLow,  "zbar_males",                  ref_y = 5.0)
p_Z4 <- f_traj(df_tHigh, "zbar_males",                  ref_y = 5.0)

# Fila 4: Var z — única fila com rótulos X
p_V1 <- f_snap(df_g1,    "varz_males", y_label = ylb_V, x_label = xlb_sp,  ref_y = 1.0)
p_V2 <- f_snap(df_gFin,  "varz_males",                  x_label = xlb_sp,  ref_y = 1.0)
p_V3 <- f_traj(df_tLow,  "varz_males",                  x_label = xlb_gen, ref_y = 1.0)
p_V4 <- f_traj(df_tHigh, "varz_males",                  x_label = xlb_gen, ref_y = 1.0)

# ── Montagem patchwork ────────────────────────────────────────────
grid_4x4 <- wrap_plots(
  p_M1, p_M2, p_M3, p_M4,
  p_N1, p_N2, p_N3, p_N4,
  p_Z1, p_Z2, p_Z3, p_Z4,
  p_V1, p_V2, p_V3, p_V4,
  ncol = 4
) +
  plot_layout(guides = "collect") +
  plot_annotation(
    title    = "Sexual Selection on Interaction Networks: Overview",
    subtitle = sprintf("k = %d  |  A_max = %d  |  %d replicates  |  without natural selection",
                       K_POSTER, AMAX_POSTER, val_reps)
  )

path_grid <- file.path(dir_poster, "Poster_Grid4x4_white.png")
png(path_grid, width = 26, height = 22, units = "in", res = 300, bg = "white")
print(grid_4x4)
dev.off()

cat(sprintf("Grid 4×4 salvo em: %s\n", path_grid))

# =====================================================================
# POSTER 2×3: Grid Principal — História Clara
# Col A/D : Padrão geral vs σp  (visão completa)
# Col B/E : σp = 0.5  (preferência estreita — efeitos fracos)
# Col C/F : σp = 2.0  (preferência ampla  — efeitos fortes)
# Fila 1 (azul escuro): NETWORK ARCHITECTURE
# Fila 2 (roxo):        MALE TRAIT EVOLUTION
# =====================================================================

tema_2x3 <- theme_light(base_size = 14) +
  theme(
    plot.background  = element_rect(fill = "white",   color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.grid.major = element_line(color = "#E8E8E8", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "#2C3E50"),
    strip.text       = element_text(color = "white", face = "bold", size = 13),
    plot.title       = element_text(face = "bold",  size = 14, color = "#1A1A2E",
                                    margin = margin(b = 3)),
    plot.subtitle    = element_text(color = "gray45", size = 10),
    axis.title       = element_text(face = "bold",  size = 12),
    axis.text        = element_text(size = 10),
    legend.position  = "none",
    plot.margin      = margin(8, 12, 8, 12)
  )

make_row_label <- function(txt, bg_color) {
  ggplot() +
    annotate("text", x = 0.5, y = 0.5, label = txt,
             angle = 90, size = 4.5, fontface = "bold",
             color = "white", lineheight = 0.9) +
    xlim(0, 1) + ylim(0, 1) +
    theme_void() +
    theme(plot.background = element_rect(fill = bg_color, color = NA),
          plot.margin = margin(0, 4, 0, 4))
}

lbl_rede  <- make_row_label("NETWORK\nARCHITECTURE", "#2C3E50")
lbl_traco <- make_row_label("MALE TRAIT\nEVOLUTION",  "#6B3A8C")

# Legenda unificada: mesma chave visual para todos os tipos de painel
guias_cor <- guides(
  color = guide_legend(override.aes = list(size = 4, shape = 19,
                                           linetype = 1, linewidth = 1.2, alpha = 1)),
  fill  = "none"
)

# ── Dados novos: dumbbell e trajetória para SP_LOW_act ────────────
# SP_LOW_act definido na seção Grid 4×4 acima

df_dumb_low <- df_k5 %>%
  filter(generation %in% c(1, GEN_FINAL),
         encounters_n == AMAX_POSTER,
         sigma_p == SP_LOW_act) %>%
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
    Delta      = Gen_final - Gen_inicial,
    tipo_label = factor(
      dplyr::recode(tipo_selecao, "uniform" = "Random",  "gaussian" = "Gaussian",
                                  "sigmoid" = "Sigmoid", "u-shaped" = "U-shaped"),
      levels = c("U-shaped", "Sigmoid", "Gaussian", "Random")),
    Metrica    = ifelse(Metrica == "Modularity", "1. Modularity", "2. Nestedness (NODF)")
  )

df_traj_low <- df_tLow %>%          # df_tLow = sigma_p == SP_LOW_act, AMAX_POSTER
  group_by(tipo_selecao, generation) %>%
  summarise(media_z = mean(zbar_males, na.rm = TRUE),
            sd_z    = sd(zbar_males,   na.rm = TRUE),
            .groups = "drop")

df_zbar_D <- df_k5 %>%
  filter(generation == GEN_FINAL, encounters_n == AMAX_POSTER) %>%
  drop_na(zbar_males)

# ── Função auxiliar: dumbbell (eixos trocados, Mod acima, Nest abaixo) ──
make_dumbbell <- function(df_in, titulo, subtitulo) {
  ggplot(df_in) +
    geom_segment(aes(x = tipo_label, xend = tipo_label,
                     y = Gen_inicial,  yend = Gen_final,
                     color = tipo_selecao),
                 linewidth = 2.2, alpha = 0.75) +
    geom_point(aes(x = tipo_label, y = Gen_inicial, color = tipo_selecao),
               size = 5.5, shape = 21, fill = "white", stroke = 2.2) +
    geom_point(aes(x = tipo_label, y = Gen_final, color = tipo_selecao),
               size = 5.5) +
    geom_text(aes(x = tipo_label, y = (Gen_inicial + Gen_final) / 2,
                  label = sprintf("%+.3f", Delta), color = tipo_selecao),
              hjust = -0.8, vjust = 0.5, size = 4.0, fontface = "bold") +
    facet_wrap(~Metrica, scales = "free_y", ncol = 1) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    labs(title = titulo, subtitle = subtitulo,
         x = "", y = "Mean Metric Value", color = "") +
    guias_cor +
    tema_2x3
}

# ── Função auxiliar: trajetória de z̄ ──────────────────────────────
make_traj <- function(df_in, titulo, subtitulo) {
  ggplot(df_in, aes(x = generation, y = media_z,
                    color = tipo_selecao, fill = tipo_selecao)) +
    geom_ribbon(aes(ymin = media_z - sd_z, ymax = media_z + sd_z),
                alpha = 0.12, color = NA) +
    geom_line(linewidth = 1.5) +
    geom_hline(yintercept = 5, linetype = "dashed",
               color = "gray50", linewidth = 0.8) +
    annotate("text", x = 1, y = 5, label = "φ = 5  (initial)",
             hjust = 0, vjust = -0.55, color = "gray50",
             size = 3.5, fontface = "italic") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values  = cores_4, labels = labels_4) +
    labs(title = titulo, subtitle = subtitulo,
         x = "Generation",
         y = expression(paste("Mean Male Trait (", bar(z), ")")),
         color = "", fill = "") +
    guias_cor +
    tema_2x3
}

# ── Painéis ───────────────────────────────────────────────────────

# A: Topologia final (Mod + Nestedness vs σp)
p_A <- ggplot(df_topo, aes(x = sigma_p, y = Valor,
                            color = tipo_selecao, fill = tipo_selecao)) +
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "red",
             linewidth = 0.8, alpha = 0.5) +
  geom_smooth(method = "loess", formula = y ~ x, alpha = 0.15,
              linewidth = 1.4, show.legend = FALSE) +
  geom_jitter(alpha = 0.22, width = 0.05, size = 1.8) +
  facet_wrap(~Metrica, scales = "free_y", ncol = 1) +
  scale_color_manual(values = cores_4, labels = labels_4) +
  scale_fill_manual(values  = cores_4, labels = labels_4) +
  labs(title    = "A  ·  Network Topology at Generation 100",
       subtitle = sprintf("k = %d  |  A_max = %d  |  %d replicates",
                          K_POSTER, AMAX_POSTER, val_reps),
       x = expression(paste("Preference Variation (", sigma[p], ")")),
       y = "Metric Value", color = "", fill = "") +
  guias_cor +
  tema_2x3

# B: Dumbbell σp = 0.5  (weak preference)
p_B <- make_dumbbell(
  df_dumb_low,
  titulo    = sprintf("B  ·  Network Change: Gen 1 → %d  (σp = %.1f)", GEN_FINAL, SP_LOW_act),
  subtitulo = "○ = Gen 1    ● = Gen 100    |    Label = Δ"
)

# C: Dumbbell σp = 2.0  (strong preference)
p_C <- make_dumbbell(
  df_tabela_dumb,
  titulo    = sprintf("C  ·  Network Change: Gen 1 → %d  (σp = %.1f)", GEN_FINAL, SP_POSTER),
  subtitulo = "○ = Gen 1    ● = Gen 100    |    Label = Δ"
)

# D: z̄ vs σp (Gen final)
p_D <- ggplot(df_zbar_D, aes(x = sigma_p, y = zbar_males,
                              color = tipo_selecao, fill = tipo_selecao)) +
  geom_hline(yintercept = 5.0, linetype = "dashed",
             color = "gray50", linewidth = 0.8) +
  annotate("text", x = 0.25, y = 5.0, label = "φ = 5  (initial mean)",
           hjust = 0, vjust = -0.55, color = "gray50",
           size = 3.5, fontface = "italic") +
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "red",
             linewidth = 0.8, alpha = 0.5) +
  geom_smooth(method = "loess", formula = y ~ x, alpha = 0.15,
              linewidth = 1.4, show.legend = FALSE) +
  geom_jitter(alpha = 0.22, width = 0.05, size = 1.8) +
  scale_color_manual(values = cores_4, labels = labels_4) +
  scale_fill_manual(values  = cores_4, labels = labels_4) +
  labs(title    = "D  ·  Male Trait Mean at Generation 100",
       subtitle = sprintf("k = %d  |  A_max = %d  |  %d replicates",
                          K_POSTER, AMAX_POSTER, val_reps),
       x = expression(paste("Preference Variation (", sigma[p], ")")),
       y = expression(paste("Mean Male Trait (", bar(z), ")")),
       color = "", fill = "") +
  guias_cor +
  tema_2x3

# E: Trajetória de z̄ — σp = 0.5
p_E <- make_traj(
  df_traj_low,
  titulo    = sprintf("E  ·  Trait Trajectory  (σp = %.1f)", SP_LOW_act),
  subtitulo = sprintf("%d replicates  |  Ribbon = ±1 SD", val_reps)
)

# F: Trajetória de z̄ — σp = 2.0
p_F <- make_traj(
  df_traj,
  titulo    = sprintf("F  ·  Trait Trajectory  (σp = %.1f)", SP_POSTER),
  subtitulo = sprintf("%d replicates  |  Ribbon = ±1 SD", val_reps)
)

# ── Montagem ──────────────────────────────────────────────────────
# widths aplicados por fila (não no grid externo) para garantir propagação correta
larg_faixa <- 0.08    # faixa colorida com texto legível
layout_linha <- plot_layout(widths = c(larg_faixa, 1.3, 1, 1))

row_rede  <- (lbl_rede  | p_A | p_B | p_C) + layout_linha
row_traco <- (lbl_traco | p_D | p_E | p_F) + layout_linha

grid_2x3 <- row_rede / row_traco +
  plot_annotation(
    title    = "How Female Preference Shapes Network Architecture and Trait Evolution",
    subtitle = sprintf("k = %d  |  A_max = %d  |  without natural selection  |  %d replicates",
                       K_POSTER, AMAX_POSTER, val_reps)
  )

path_2x3 <- file.path(dir_poster, "Poster_Grid2x3_white.png")
png(path_2x3, width = 26, height = 14, units = "in", res = 300, bg = "white")
print(grid_2x3)
dev.off()

cat(sprintf("Grid 2×3 salvo em: %s\n", path_2x3))

print(p_topo)
print(p_dumb)
print(p_traj)
print(grid_2x3)
