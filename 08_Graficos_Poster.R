# =====================================================================
# SCRIPT 08: Gráficos para Poster
# Figuras: Grid 2×3 (história principal) + Robustez (custo ecológico)
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

# =====================================================================
# PARÂMETROS — altere aqui para explorar diferentes cenários
# =====================================================================

# Iteração automática — todos os valores serão combinados (expand.grid)
K_vals    <- c(5L, 10L, 20L)   # cópulas por fêmea
NS_vals   <- c(FALSE, TRUE)    # FALSE = sem seleção natural | TRUE = com
AMAX_vals <- c(200, 40, 10)   # max. machos amostrados por fêmea

# Fixos — mudar manualmente conforme necessário
SP_POSTER <- 2.0   # σp "forte" — coluna direita do grid (C/F) e Robustez
SP_LOW    <- 0.5   # σp "fraco" — coluna central do grid (B/E)

# =====================================================================
# TEMA DO POSTER — mude FUNDO_ESCURO para adaptar ao fundo do poster
# =====================================================================

FUNDO_ESCURO <- FALSE  # FALSE = fundo branco/claro | TRUE = fundo escuro/preto

tema_2x3_claro <- theme_light(base_size = 18) +
  theme(
    plot.background  = element_rect(fill = "white",   color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.grid.major = element_line(color = "#E8E8E8", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "#2C3E50"),
    strip.text       = element_text(color = "white", face = "bold", size = 16),
    plot.title       = element_text(face = "bold",  size = 18, color = "#1A1A2E",
                                    margin = margin(b = 3)),
    plot.subtitle    = element_text(color = "gray45", size = 13),
    axis.title       = element_text(face = "bold",  size = 15),
    axis.text        = element_text(size = 13),
    axis.text.x      = element_text(size = 13, face = "bold"),
    legend.position  = "none",
    plot.margin      = margin(8, 12, 8, 12)
  )

tema_2x3_escuro <- theme_dark(base_size = 18) +
  theme(
    plot.background  = element_rect(fill = "#1A1A2E", color = NA),
    panel.background = element_rect(fill = "#16213E", color = NA),
    panel.grid.major = element_line(color = "#2A3A5E", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "#2C3E50"),
    strip.text       = element_text(color = "white", face = "bold", size = 16),
    plot.title       = element_text(face = "bold",  size = 18, color = "#E8E8FF",
                                    margin = margin(b = 3)),
    plot.subtitle    = element_text(color = "#AAAAAA", size = 13),
    axis.title       = element_text(face = "bold",  size = 15, color = "white"),
    axis.text        = element_text(size = 13, color = "#CCCCCC"),
    axis.text.x      = element_text(size = 13, face = "bold", color = "#CCCCCC"),
    legend.position  = "none",
    plot.margin      = margin(8, 12, 8, 12)
  )

tema_2x3  <- if (FUNDO_ESCURO) tema_2x3_escuro else tema_2x3_claro
bg_poster  <- if (FUNDO_ESCURO) "#1A1A2E"       else "white"
cor_ref    <- if (FUNDO_ESCURO) "gray70"         else "gray50"
cor_titulo <- if (FUNDO_ESCURO) "#E8E8FF"        else "#1A1A2E"

tema_rob <- tema_2x3 +
  theme(
    plot.title    = element_text(size = 24, face = "bold"),
    plot.subtitle = element_text(size = 17),
    axis.title    = element_text(size = 20, face = "bold"),
    axis.text     = element_text(size = 17),
    axis.text.x   = element_text(size = 17, face = "bold")
  )

# =====================================================================
# PALETA DE CORES
# =====================================================================

cores_4  <- c("uniform"  = "gray55",
               "gaussian" = "#E6B800",
               "sigmoid"  = "#3BA273",
               "u-shaped" = "#9932CC")

labels_4 <- c("uniform"  = "Random",
               "gaussian" = "Gaussian",
               "sigmoid"  = "Sigmoid",
               "u-shaped" = "Disruptive")

GEN_FINAL <- max(df$generation, na.rm = TRUE)

# =====================================================================
# FUNÇÕES AUXILIARES (independentes dos parâmetros de iteração)
# =====================================================================

make_row_label <- function(txt, bg_color) {
  ggplot() +
    annotate("text", x = 0.5, y = 0.5, label = txt,
             angle = 90, size = 6.0, fontface = "bold",
             color = "white", lineheight = 0.9) +
    xlim(0, 1) + ylim(0, 1) +
    theme_void() +
    theme(plot.background = element_rect(fill = bg_color, color = NA),
          plot.margin = margin(0, 4, 0, 4))
}

lbl_rede  <- make_row_label("NETWORK ARCHITECTURE", "#2C3E50")
lbl_traco <- make_row_label("MALE TRAIT EVOLUTION",  "#6B3A8C")

guias_cor <- guides(
  color = guide_legend(override.aes = list(size = 4, shape = 19,
                                           linetype = 1, linewidth = 1.2, alpha = 1)),
  fill  = "none"
)

make_dumbbell <- function(df_in, titulo, subtitulo,
                           ylim_mod = NULL, ylim_nest = NULL) {
  plot_metric <- function(df_m, y_label, ylim_m) {
    p <- ggplot(df_m) +
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
                hjust = -0.2, vjust = 0.5, size = 4.5, fontface = "bold") +
      scale_color_manual(values = cores_4, labels = labels_4) +
      labs(x = "", y = y_label, color = "") +
      guias_cor +
      tema_2x3
    if (!is.null(ylim_m)) p <- p + coord_cartesian(ylim = ylim_m)
    p
  }
  p_mod <- plot_metric(
    df_in %>% filter(Metrica == "1. Modularity"),
    "Modularity", ylim_mod
  ) + labs(title = titulo, subtitle = subtitulo)
  p_nest <- plot_metric(
    df_in %>% filter(Metrica == "2. Nestedness (NODF)"),
    "Nestedness (NODF)", ylim_nest
  )
  p_mod / p_nest
}

make_traj <- function(df_in, titulo, subtitulo, ylim_z = NULL) {
  p <- ggplot(df_in, aes(x = generation, y = media_z,
                    color = tipo_selecao, fill = tipo_selecao)) +
    geom_ribbon(aes(ymin = media_z - sd_z, ymax = media_z + sd_z),
                alpha = 0.12, color = NA) +
    geom_line(linewidth = 1.5) +
    geom_hline(yintercept = 5, linetype = "dashed",
               color = cor_ref, linewidth = 0.8) +
    annotate("text", x = 1, y = 5, label = "φ = 5  (initial)",
             hjust = 0, vjust = -0.55, color = cor_ref,
             size = 4.5, fontface = "italic") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values  = cores_4, labels = labels_4) +
    labs(title = titulo, subtitle = subtitulo,
         x = "Generation",
         y = expression(bold(paste("Male Trait Mean (", bar(z), ")"))),
         color = "", fill = "") +
    guias_cor +
    tema_2x3
  if (!is.null(ylim_z)) p <- p + coord_cartesian(ylim = ylim_z)
  p
}

# ── Aranha mascote — descomente para ativar ───────────────────────────
# lbl_aranha <- ggplot() +
#   # Patas esquerdas — 2 por cor, de cima para baixo
#   annotate("segment", x=0.42, xend=0.08, y=0.64, yend=0.82, linewidth=2.2, color="gray55") +
#   annotate("segment", x=0.42, xend=0.10, y=0.59, yend=0.44, linewidth=2.2, color="gray55") +
#   annotate("segment", x=0.42, xend=0.10, y=0.64, yend=0.82, linewidth=2.2, color="#E6B800") +
#   annotate("segment", x=0.42, xend=0.12, y=0.59, yend=0.44, linewidth=2.2, color="#E6B800") +
#   annotate("segment", x=0.42, xend=0.14, y=0.64, yend=0.82, linewidth=2.2, color="#3BA273") +
#   annotate("segment", x=0.42, xend=0.16, y=0.59, yend=0.44, linewidth=2.2, color="#3BA273") +
#   annotate("segment", x=0.42, xend=0.18, y=0.64, yend=0.82, linewidth=2.2, color="#9932CC") +
#   annotate("segment", x=0.42, xend=0.20, y=0.59, yend=0.44, linewidth=2.2, color="#9932CC") +
#   # Patas direitas — espelhadas
#   annotate("segment", x=0.58, xend=0.92, y=0.64, yend=0.82, linewidth=2.2, color="gray55") +
#   annotate("segment", x=0.58, xend=0.90, y=0.59, yend=0.44, linewidth=2.2, color="gray55") +
#   annotate("segment", x=0.58, xend=0.90, y=0.64, yend=0.82, linewidth=2.2, color="#E6B800") +
#   annotate("segment", x=0.58, xend=0.88, y=0.59, yend=0.44, linewidth=2.2, color="#E6B800") +
#   annotate("segment", x=0.58, xend=0.86, y=0.64, yend=0.82, linewidth=2.2, color="#3BA273") +
#   annotate("segment", x=0.58, xend=0.84, y=0.59, yend=0.44, linewidth=2.2, color="#3BA273") +
#   annotate("segment", x=0.58, xend=0.82, y=0.64, yend=0.82, linewidth=2.2, color="#9932CC") +
#   annotate("segment", x=0.58, xend=0.80, y=0.59, yend=0.44, linewidth=2.2, color="#9932CC") +
#   # Abdômen
#   annotate("point", x=0.50, y=0.32, size=22, color="#4A1570") +
#   annotate("point", x=0.50, y=0.32, size=17, color="#9932CC") +
#   annotate("point", x=0.50, y=0.32, size=7,  color="#CC66FF", alpha=0.6) +
#   # Cefalotórax
#   annotate("point", x=0.50, y=0.58, size=13, color="#4A1570") +
#   annotate("point", x=0.50, y=0.58, size=10, color="#9932CC") +
#   # Olhos
#   annotate("point", x=c(0.46, 0.54), y=c(0.63, 0.63), size=3.0, color="white") +
#   annotate("point", x=c(0.46, 0.54), y=c(0.63, 0.63), size=1.2, color="#1A1A2E") +
#   xlim(0, 1) + ylim(0, 1) + theme_void() +
#   theme(plot.background = element_rect(fill = bg_poster, color = NA),
#         plot.margin = margin(4, 4, 4, 4))

# =====================================================================
# LOOP 1 — Grid 2×3: um gráfico por combinação K × NS × AMAX
# =====================================================================

comb_2x3 <- expand.grid(
  K    = K_vals,
  NS   = NS_vals,
  AMAX = AMAX_vals,
  stringsAsFactors = FALSE
)
cat(sprintf("\nGrid 2×3 — total de combinações: %d\n\n", nrow(comb_2x3)))

for (i in seq_len(nrow(comb_2x3))) {

  K_POSTER    <- as.integer(comb_2x3$K[i])
  NS_POSTER   <- comb_2x3$NS[i]
  AMAX_POSTER <- comb_2x3$AMAX[i]

  cat(sprintf("[%d/%d]  k = %d  |  NS = %-5s  |  Amax = %d\n",
              i, nrow(comb_2x3), K_POSTER, NS_POSTER, AMAX_POSTER))

  # ── Filtrar dados ──────────────────────────────────────────────────
  df_k5    <- df %>% filter(k_fixo == K_POSTER, selecao_natural == NS_POSTER)
  val_reps <- length(unique(df_k5$replica[!is.na(df_k5$replica)]))

  if (nrow(df_k5) == 0) {
    cat("  → Sem dados para esta combinação, pulando.\n")
    next
  }

  # ── σp disponíveis ─────────────────────────────────────────────────
  sp_vals     <- sort(unique(df_k5$sigma_p))
  SP_LOW_act  <- sp_vals[which.min(abs(sp_vals - SP_LOW))]
  SP_HIGH_act <- sp_vals[which.min(abs(sp_vals - SP_POSTER))]

  # ── Sufixo do arquivo ──────────────────────────────────────────────
  sufixo <- sprintf("k%d_amax%d_spL%s_spH%s_%s_%s",
                    K_POSTER, AMAX_POSTER,
                    sub("\\.", "", sprintf("%.1f", SP_LOW_act)),
                    sub("\\.", "", sprintf("%.1f", SP_POSTER)),
                    if (NS_POSTER) "comNS" else "semNS",
                    if (FUNDO_ESCURO) "escuro" else "claro")

  # ── Dados para os painéis ──────────────────────────────────────────
  prep_dumb <- function(df_in, sp_val) {
    df_in %>%
      filter(generation %in% c(1, GEN_FINAL),
             encounters_n == AMAX_POSTER, sigma_p == sp_val) %>%
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
          dplyr::recode(tipo_selecao, "uniform" = "Random", "gaussian" = "Gaussian",
                                      "sigmoid" = "Sigmoid", "u-shaped" = "U-shaped"),
          levels = c("U-shaped", "Sigmoid", "Gaussian", "Random")),
        Metrica = ifelse(Metrica == "Modularity", "1. Modularity", "2. Nestedness (NODF)")
      )
  }

  df_topo <- df_k5 %>%
    filter(generation == GEN_FINAL, encounters_n == AMAX_POSTER) %>%
    drop_na(Modularity, Nestedness) %>%
    pivot_longer(cols = c(Modularity, Nestedness),
                 names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = ifelse(Metrica == "Modularity",
                            "1. Modularity", "2. Nestedness (NODF)"))

  df_dumb_low    <- prep_dumb(df_k5, SP_LOW_act)
  df_tabela_dumb <- prep_dumb(df_k5, SP_POSTER)

  df_zbar_D <- df_k5 %>%
    filter(generation == GEN_FINAL, encounters_n == AMAX_POSTER) %>%
    drop_na(zbar_males) %>%
    mutate(metric_label = "bold(paste('Male Trait Mean (', bar(z), ')'))")

  prep_traj <- function(df_in, sp_val) {
    df_in %>%
      filter(sigma_p == sp_val, encounters_n == AMAX_POSTER) %>%
      group_by(tipo_selecao, generation) %>%
      summarise(media_z = mean(zbar_males, na.rm = TRUE),
                sd_z    = sd(zbar_males,   na.rm = TRUE),
                .groups = "drop")
  }
  df_traj_low <- prep_traj(df_k5, SP_LOW_act)
  df_traj     <- prep_traj(df_k5, SP_POSTER)

  ylim_mod_A  <- range(df_topo$Valor[df_topo$Metrica == "1. Modularity"],        na.rm = TRUE)
  ylim_nest_A <- range(df_topo$Valor[df_topo$Metrica == "2. Nestedness (NODF)"], na.rm = TRUE)
  ylim_z_D    <- range(df_zbar_D$zbar_males, na.rm = TRUE)

  # ── Painéis A-F ────────────────────────────────────────────────────
  p_A <- ggplot(df_topo, aes(x = sigma_p, y = Valor,
                              color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red",
               linewidth = 0.8, alpha = 0.5) +
    annotate("text", x = 1.05, y = Inf,
             label = "sigma[p] == sigma[z]", parse = TRUE,
             hjust = 0, vjust = 1.5, color = "red", size = 4.2, fontface = "italic") +
    geom_smooth(method = "loess", formula = y ~ x, alpha = 0.15,
                linewidth = 1.4, show.legend = FALSE) +
    geom_jitter(alpha = 0.22, width = 0.05, size = 1.8) +
    facet_wrap(~Metrica, scales = "free_y", ncol = 1,
               strip.position = "left",
               labeller = as_labeller(c(
                 "1. Modularity"        = "Modularity",
                 "2. Nestedness (NODF)" = "Nestedness (NODF)"
               ))) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values  = cores_4, labels = labels_4) +
    labs(title    = "A  ·  Network Topology at Generation 100",
         subtitle = sprintf("k = %d  |  A_max = %d",
                            K_POSTER, AMAX_POSTER),
         x = expression(bold(paste("Preference Variation (", sigma[p], ")"))),
         y = NULL, color = "", fill = "") +
    guias_cor + tema_2x3 +
    theme(strip.placement = "outside",
          strip.text.y.left = element_text(color = "white", face = "bold",
                                           size = 15, angle = 90))

  p_B <- make_dumbbell(df_dumb_low,
    titulo    = sprintf("B  ·  Network Change: Gen 1 → %d  (σp = %.1f)", GEN_FINAL, SP_LOW_act),
    subtitulo = "○ = Gen 1    ● = Gen 100    |    Label = Δ",
    ylim_mod = ylim_mod_A, ylim_nest = ylim_nest_A)

  p_C <- make_dumbbell(df_tabela_dumb,
    titulo    = sprintf("C  ·  Network Change: Gen 1 → %d  (σp = %.1f)", GEN_FINAL, SP_POSTER),
    subtitulo = "○ = Gen 1    ● = Gen 100    |    Label = Δ",
    ylim_mod = ylim_mod_A, ylim_nest = ylim_nest_A)

  p_D <- ggplot(df_zbar_D, aes(x = sigma_p, y = zbar_males,
                                color = tipo_selecao, fill = tipo_selecao)) +
    geom_hline(yintercept = 5.0, linetype = "dashed",
               color = cor_ref, linewidth = 0.8) +
    annotate("text", x = 0.25, y = 5.0, label = "φ = 5  (initial mean)",
             hjust = 0, vjust = -0.55, color = cor_ref,
             size = 4.5, fontface = "italic") +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red",
               linewidth = 0.8, alpha = 0.5) +
    annotate("text", x = 1.05, y = Inf,
             label = "sigma[p] == sigma[z]", parse = TRUE,
             hjust = 0, vjust = 1.5, color = "red", size = 4.2, fontface = "italic") +
    geom_smooth(method = "loess", formula = y ~ x, alpha = 0.15,
                linewidth = 1.4, show.legend = FALSE) +
    geom_jitter(alpha = 0.22, width = 0.05, size = 1.8) +
    facet_wrap(~metric_label, strip.position = "left", labeller = label_parsed) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values  = cores_4, labels = labels_4) +
    labs(title    = "D  ·  Male Trait Mean at Generation 100",
         subtitle = sprintf("k = %d  |  A_max = %d",
                            K_POSTER, AMAX_POSTER),
         x = expression(bold(paste("Preference Variation (", sigma[p], ")"))),
         y = NULL, color = "", fill = "") +
    guias_cor + tema_2x3 +
    theme(strip.placement   = "outside",
          strip.background  = element_rect(fill = "#6B3A8C"),
          strip.text.y.left = element_text(color = "white", face = "bold",
                                           size = 15, angle = 90))

  p_E <- make_traj(df_traj_low,
    titulo    = sprintf("E  ·  Trait Trajectory  (σp = %.1f)", SP_LOW_act),
    subtitulo = "Ribbon = ±1 SD",
    ylim_z    = ylim_z_D)

  p_F <- make_traj(df_traj,
    titulo    = sprintf("F  ·  Trait Trajectory  (σp = %.1f)", SP_POSTER),
    subtitulo = "Ribbon = ±1 SD",
    ylim_z    = ylim_z_D)

  # ── Grid 2×3 ───────────────────────────────────────────────────────
  larg_faixa   <- 0.08
  layout_linha <- plot_layout(widths = c(larg_faixa, 1.3, 0.65, 0.65))
  row_rede  <- (lbl_rede  | p_A | p_B | p_C) + layout_linha
  row_traco <- (lbl_traco | p_D | p_E | p_F) + layout_linha

  lbl_titulo <- ggplot() +
    annotate("text", x = 0.5, y = 0.68,
             label = "How female preference shapes network architecture and trait evolution?",
             size = 9.0, fontface = "bold", hjust = 0.5, vjust = 1,
             color = cor_titulo) +
    annotate("text", x = 0.5, y = 0.32,
             label = sprintf("Matings per female (k) = %d  |  Max. males sampled per female (A_max) = %d  |  %s",
                             K_POSTER, AMAX_POSTER,
                             if (NS_POSTER) "With natural selection" else "Without natural selection"),
             size = 5.5, hjust = 0.5, vjust = 1,
             color = if (FUNDO_ESCURO) "#AAAAAA" else "gray45") +
    xlim(0, 1) + ylim(0, 1) + theme_void() +
    theme(plot.background = element_rect(fill = bg_poster, color = NA))

  # lbl_header_2x3 <- (lbl_aranha | lbl_titulo) + plot_layout(widths = c(0.12, 1))

  grid_2x3 <- lbl_titulo / (row_rede / row_traco + plot_layout(heights = c(2, 1))) +
    plot_layout(heights = c(0.14, 1))

  path_2x3 <- file.path(dir_poster, sprintf("Poster_Grid2x3_%s.png", sufixo))
  png(path_2x3, width = 19.5, height = 14.5, units = "in", res = 300, bg = bg_poster)
  print(grid_2x3)
  dev.off()
  cat(sprintf("  → Grid 2×3  : %s\n", basename(path_2x3)))

} # fim do loop Grid 2×3
cat(sprintf("\nGrid 2×3 concluído. %d figuras salvas em %s\n",
            nrow(comb_2x3), dir_poster))

# =====================================================================
# LOOP 2 — Robustez: um gráfico por combinação K × NS (sem AMAX)
# =====================================================================

comb_rob <- expand.grid(
  K  = K_vals,
  NS = NS_vals,
  stringsAsFactors = FALSE
)
cat(sprintf("\nRobustez — total de combinações: %d\n\n", nrow(comb_rob)))

for (i in seq_len(nrow(comb_rob))) {

  K_POSTER  <- as.integer(comb_rob$K[i])
  NS_POSTER <- comb_rob$NS[i]

  cat(sprintf("[%d/%d]  k = %d  |  NS = %-5s\n",
              i, nrow(comb_rob), K_POSTER, NS_POSTER))

  df_k5    <- df %>% filter(k_fixo == K_POSTER, selecao_natural == NS_POSTER)
  val_reps <- length(unique(df_k5$replica[!is.na(df_k5$replica)]))

  if (nrow(df_k5) == 0) {
    cat("  → Sem dados para esta combinação, pulando.\n")
    next
  }

  sufixo_rob <- sprintf("k%d_spH%s_%s_%s",
                        K_POSTER,
                        sub("\\.", "", sprintf("%.1f", SP_POSTER)),
                        if (NS_POSTER) "comNS" else "semNS",
                        if (FUNDO_ESCURO) "escuro" else "claro")

  df_robusto <- df_k5 %>%
    filter(generation == GEN_FINAL, sigma_p == SP_POSTER) %>%
    drop_na(Modularity, Nestedness, zbar_males, varz_males) %>%
    mutate(Amax_f = factor(encounters_n,
                           levels = c(200, 40, 10),
                           labels = c("200 (100%)", "40 (20%)", "10 (5%)")))

  df_rob_med <- df_robusto %>%
    group_by(tipo_selecao, Amax_f) %>%
    summarise(mod_mean  = mean(Modularity,  na.rm = TRUE),
              nest_mean = mean(Nestedness,  na.rm = TRUE),
              z_mean    = mean(zbar_males,  na.rm = TRUE),
              varz_mean = mean(varz_males,  na.rm = TRUE),
              .groups   = "drop")

  p_rob_mod <- ggplot(df_robusto, aes(x = Amax_f, color = tipo_selecao)) +
    geom_jitter(aes(y = Modularity), alpha = 0.2, width = 0.15, size = 1.8) +
    geom_line(data = df_rob_med, aes(y = mod_mean, group = tipo_selecao), linewidth = 1.6) +
    geom_point(data = df_rob_med, aes(y = mod_mean), size = 5, shape = 19) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    labs(title    = "A  ·  Network Modularity vs Sampling Effort",
         subtitle = sprintf("σp = %.1f  |  Gen %d  |  k = %d",
                            SP_POSTER, GEN_FINAL, K_POSTER),
         x = NULL,
         y = "Modularity", color = "") +
    guias_cor + tema_rob

  p_rob_nest <- ggplot(df_robusto, aes(x = Amax_f, color = tipo_selecao)) +
    geom_jitter(aes(y = Nestedness), alpha = 0.2, width = 0.15, size = 1.8) +
    geom_line(data = df_rob_med, aes(y = nest_mean, group = tipo_selecao), linewidth = 1.6) +
    geom_point(data = df_rob_med, aes(y = nest_mean), size = 5, shape = 19) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    labs(title    = "B  ·  Network Nestedness vs Sampling Effort",
         subtitle = sprintf("σp = %.1f  |  Gen %d  |  k = %d",
                            SP_POSTER, GEN_FINAL, K_POSTER),
         x = NULL,
         y = "Nestedness (NODF)", color = "") +
    guias_cor + tema_rob

  p_rob_z <- ggplot(df_robusto, aes(x = Amax_f, color = tipo_selecao)) +
    geom_hline(yintercept = 5.0, linetype = "dashed", color = cor_ref, linewidth = 0.8) +
    annotate("text", x = -Inf, y = 5.0, label = "φ = 5  (initial)",
             hjust = -0.1, vjust = -0.55, color = cor_ref, size = 4.5, fontface = "italic") +
    geom_jitter(aes(y = zbar_males), alpha = 0.2, width = 0.15, size = 1.8) +
    geom_line(data = df_rob_med, aes(y = z_mean, group = tipo_selecao), linewidth = 1.6) +
    geom_point(data = df_rob_med, aes(y = z_mean), size = 5, shape = 19) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    labs(title    = "C  ·  Male Trait Mean vs Sampling Effort",
         subtitle = sprintf("σp = %.1f  |  Gen %d  |  k = %d",
                            SP_POSTER, GEN_FINAL, K_POSTER),
         x = NULL,
         y = expression(bold(paste("Male Trait Mean (", bar(z), ")"))),
         color = "") +
    guias_cor + tema_rob

  p_rob_varz <- ggplot(df_robusto, aes(x = Amax_f, color = tipo_selecao)) +
    geom_hline(yintercept = 1.0, linetype = "dashed", color = cor_ref, linewidth = 0.8) +
    annotate("text", x = -Inf, y = 1.0, label = "Var z = 1  (initial)",
             hjust = -0.1, vjust = -0.55, color = cor_ref, size = 4.5, fontface = "italic") +
    geom_jitter(aes(y = varz_males), alpha = 0.2, width = 0.15, size = 1.8) +
    geom_line(data = df_rob_med, aes(y = varz_mean, group = tipo_selecao), linewidth = 1.6) +
    geom_point(data = df_rob_med, aes(y = varz_mean), size = 5, shape = 19) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    coord_cartesian(ylim = c(NA, 0.15)) +
    labs(title    = "D  ·  Male Trait Variance vs Sampling Effort",
         subtitle = sprintf("σp = %.1f  |  Gen %d  |  k = %d",
                            SP_POSTER, GEN_FINAL, K_POSTER),
         x = "Maximum number of males sampled per female (A_max)",
         y = "Male Trait Variance (Var z)", color = "") +
    guias_cor + tema_rob

  p_robusto <- p_rob_mod / p_rob_nest / p_rob_z / p_rob_varz

  lbl_titulo_rob <- ggplot() +
    annotate("text", x = 0.5, y = 1.0,
             label = "What happens when females can only assess\na fraction of available males?",
             size = 9.0, fontface = "bold", hjust = 0.5, vjust = 1,
             lineheight = 0.9, color = cor_titulo) +
    annotate("text", x = 0.5, y = 0.18,
             label = sprintf("Matings per female (k) = %d  |  %s",
                             K_POSTER,
                             if (NS_POSTER) "With natural selection" else "Without natural selection"),
             size = 5.5, hjust = 0.5, vjust = 1,
             color = if (FUNDO_ESCURO) "#AAAAAA" else "gray45") +
    xlim(0, 1) + ylim(0, 1) + theme_void() +
    theme(plot.background = element_rect(fill = bg_poster, color = NA),
          plot.margin = margin(0, 0, 0, 0))

  # lbl_header_rob <- (lbl_aranha | lbl_titulo_rob) + plot_layout(widths = c(0.12, 1))

  fig_robusto <- lbl_titulo_rob / p_robusto +
    plot_layout(heights = c(0.07, 1))

  path_rob <- file.path(dir_poster, sprintf("Poster_Robustez_%s.png", sufixo_rob))
  png(path_rob, width = 10, height = 28, units = "in", res = 300, bg = bg_poster)
  print(fig_robusto)
  dev.off()
  cat(sprintf("  → Robustez  : %s\n", basename(path_rob)))

} # fim do loop Robustez
cat(sprintf("\nRobustez concluído. %d figuras salvas em %s\n",
            nrow(comb_rob), dir_poster))
