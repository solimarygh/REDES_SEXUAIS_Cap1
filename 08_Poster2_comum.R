# =====================================================================
# POSTER 2 — motor comum aos dois modelos
# =====================================================================
# Este arquivo não roda sozinho. Ele é carregado por
# 08_Graficos_Poster2_Femeas.R e 08_Graficos_Poster2_Machos.R, que
# definem a lista MODELO e chamam gerar_poster2(MODELO).
#
# Por que um motor comum. Os dois scripts de pôster anteriores
# (08_Graficos_Poster.R e 08_Graficos_Poster_MachoVariando.R) eram cópias
# um do outro, e foi exatamente por isso que os dois envelheceram juntos:
# qualquer correção precisava ser feita duas vezes e nunca era. Aqui o que
# muda entre os modelos são só os campos da lista MODELO.
#
# O que mudou em relação aos scripts antigos, além disso:
#   - lê os dados do censo de adultos constante, juntando os pedaços que
#     cada máquina gravou;
#   - o eixo do experimento vai de 0.2 a 2.0, então as colunas "baixo" e
#     "alto" passam a ser os extremos de verdade e não 0.5 e 2.0;
#   - saiu o corte `coord_cartesian(ylim = c(NA, 0.15))` no painel de
#     variância: ele existia porque a segregação de ruído fixo travava a
#     variância em 0.08, e com o modelo infinitesimal cortaria a figura;
#   - A_max aparece em número absoluto de machos, e não em porcentagem;
#   - entrou uma terceira figura, de poliandria realizada, com as colunas
#     que esta rodada passou a gravar.
# =====================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(patchwork)
})

# =====================================================================
# PARÂMETROS GERAIS — mexa aqui
# =====================================================================

K_vals    <- c(5L, 10L, 20L)    # parceiros buscados por fêmea
NS_vals   <- c(FALSE, TRUE)     # seleção natural desligada / ligada
AMAX_vals <- c(200, 40, 10)     # machos avaliados por fêmea

SIGMA_ALTO  <- 2.0   # extremo heterogêneo — colunas C e F, e as figuras 2 e 3
SIGMA_BAIXO <- 0.2   # extremo homogêneo  — colunas B e E

FUNDO_ESCURO <- FALSE   # TRUE para fundo escuro de pôster
RES_PNG      <- 150     # 150 para olhar na tela; 300 para imprimir o pôster

# =====================================================================
# TEMA E PALETA
# =====================================================================

tema_claro <- theme_light(base_size = 18) +
  theme(
    plot.background  = element_rect(fill = "white",   color = NA),
    panel.background = element_rect(fill = "#FAFAFA", color = NA),
    panel.grid.major = element_line(color = "#E8E8E8", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "#2C3E50"),
    strip.text       = element_text(color = "white", face = "bold", size = 16),
    plot.title       = element_text(face = "bold", size = 18, color = "#1A1A2E",
                                    margin = margin(b = 3)),
    plot.subtitle    = element_text(color = "gray45", size = 13),
    axis.title       = element_text(face = "bold", size = 15),
    axis.text        = element_text(size = 13),
    axis.text.x      = element_text(size = 13, face = "bold"),
    legend.position  = "none",
    plot.margin      = margin(8, 12, 8, 12)
  )

tema_escuro <- theme_dark(base_size = 18) +
  theme(
    plot.background  = element_rect(fill = "#1A1A2E", color = NA),
    panel.background = element_rect(fill = "#16213E", color = NA),
    panel.grid.major = element_line(color = "#2A3A5E", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    strip.background = element_rect(fill = "#2C3E50"),
    strip.text       = element_text(color = "white", face = "bold", size = 16),
    plot.title       = element_text(face = "bold", size = 18, color = "#E8E8FF",
                                    margin = margin(b = 3)),
    plot.subtitle    = element_text(color = "#AAAAAA", size = 13),
    axis.title       = element_text(face = "bold", size = 15, color = "white"),
    axis.text        = element_text(size = 13, color = "#CCCCCC"),
    axis.text.x      = element_text(size = 13, face = "bold", color = "#CCCCCC"),
    legend.position  = "none",
    plot.margin      = margin(8, 12, 8, 12)
  )

tema_poster <- if (FUNDO_ESCURO) tema_escuro else tema_claro
bg_poster   <- if (FUNDO_ESCURO) "#1A1A2E"   else "white"
cor_ref     <- if (FUNDO_ESCURO) "gray70"    else "gray50"
cor_titulo  <- if (FUNDO_ESCURO) "#E8E8FF"   else "#1A1A2E"
cor_sub     <- if (FUNDO_ESCURO) "#AAAAAA"   else "gray45"

tema_grande <- tema_poster +
  theme(plot.title    = element_text(size = 26, face = "bold"),
        plot.subtitle = element_blank(),
        axis.title    = element_text(size = 22, face = "bold"),
        axis.text     = element_text(size = 19),
        axis.text.x   = element_text(size = 19, face = "bold"),
        plot.margin   = margin(8, 12, 22, 12))

cores_4  <- c("uniform" = "gray55", "gaussian" = "#E6B800",
              "sigmoid" = "#3BA273", "u-shaped" = "#9932CC")
labels_4 <- c("uniform" = "Random", "gaussian" = "Gaussian",
              "sigmoid" = "Sigmoid", "u-shaped" = "Disruptive")

guias_cor <- guides(
  color = guide_legend(override.aes = list(size = 4, shape = 19, linetype = 1,
                                           linewidth = 1.2, alpha = 1)),
  fill  = "none")

faixa_lateral <- function(txt, bg_color) {
  ggplot() +
    annotate("text", x = 0.5, y = 0.5, label = txt, angle = 90,
             size = 6.0, fontface = "bold", color = "white", lineheight = 0.9) +
    xlim(0, 1) + ylim(0, 1) + theme_void() +
    theme(plot.background = element_rect(fill = bg_color, color = NA),
          plot.margin = margin(0, 4, 0, 4))
}

banner <- function(titulo, subtitulo, tam = 9.0) {
  ggplot() +
    annotate("text", x = 0.5, y = 0.72, label = titulo, size = tam,
             fontface = "bold", hjust = 0.5, vjust = 1, lineheight = 0.9,
             color = cor_titulo) +
    annotate("text", x = 0.5, y = 0.30, label = subtitulo, size = 5.5,
             hjust = 0.5, vjust = 1, color = cor_sub) +
    xlim(0, 1) + ylim(0, 1) + theme_void() +
    theme(plot.background = element_rect(fill = bg_poster, color = NA))
}

# =====================================================================
# LEITURA DOS DADOS
# =====================================================================
# Aceita tanto o backup (lista com NULLs onde faltou) quanto o arquivo
# final, e junta os pedaços que cada máquina gravou. É a mesma lógica do
# 99_juntar_resultados.R; as linhas repetidas são idênticas porque a
# semente é set.seed(seed_base + idx_global), então distinct() basta.
#
# `rodadas` vai da mais nova para a mais antiga, e a leitura PARA na primeira
# que existir. Isso é de propósito: cada rodada é um modelo diferente, e juntar
# duas daria um conjunto sem sentido. Um regex que casasse com as duas de uma
# vez misturaria tudo em silêncio, que é justamente o que não pode acontecer.
RODADAS <- c("bestOfN", "censoConst")

carregar_modelo <- function(pasta, estudo) {
  for (r in RODADAS) {
    padrao <- sprintf("^(backup|resultados)_%s_%s.*\\.rds$", estudo, r)
    arqs   <- list.files(pasta, pattern = padrao, full.names = TRUE)
    if (!length(arqs)) next
    pedacos <- lapply(arqs, function(a) {
      obj <- readRDS(a)
      if (is.data.frame(obj)) obj else bind_rows(obj[!vapply(obj, is.null, logical(1))])
    })
    df <- distinct(bind_rows(pedacos))
    cat(sprintf("  rodada '%s': %d arquivo(s), %s linhas, %d réplicas\n",
                r, length(arqs), format(nrow(df), big.mark = "."),
                dplyr::n_distinct(df$replica)))
    return(df)
  }
  NULL
}

# =====================================================================
# PAINÉIS
# =====================================================================

# ── Painel A / D: a resposta ao longo do eixo do experimento, na geração
#    final. Nuvem de réplicas + loess.
painel_gradiente <- function(dados, eixo, eixo_lab, titulo, subtitulo,
                             cor_faixa, parse_strip = FALSE,
                             linha_ref = NULL, texto_ref = NULL) {
  p <- ggplot(dados, aes(x = .data[[eixo]], y = valor,
                         color = tipo_selecao, fill = tipo_selecao))
  if (!is.null(linha_ref)) {
    p <- p +
      geom_hline(yintercept = linha_ref, linetype = "dashed",
                 color = cor_ref, linewidth = 0.8) +
      annotate("text", x = -Inf, y = linha_ref, label = texto_ref,
               hjust = -0.08, vjust = -0.55, color = cor_ref,
               size = 4.5, fontface = "italic")
  }
  p +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red",
               linewidth = 0.8, alpha = 0.5) +
    annotate("text", x = 1.05, y = Inf, label = "sigma[p] == sigma[z]",
             parse = TRUE, hjust = 0, vjust = 1.5, color = "red",
             size = 4.2, fontface = "italic") +
    geom_smooth(method = "loess", formula = y ~ x, alpha = 0.15,
                linewidth = 1.4, show.legend = FALSE) +
    geom_jitter(alpha = 0.22, width = 0.05, size = 1.8) +
    facet_wrap(~ rotulo, scales = "free_y", ncol = 1, strip.position = "left",
               labeller = if (parse_strip) label_parsed else "label_value") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values  = cores_4, labels = labels_4) +
    labs(title = titulo, subtitle = subtitulo, x = eixo_lab,
         y = NULL, color = "", fill = "") +
    guias_cor + tema_poster +
    theme(strip.placement   = "outside",
          strip.background  = element_rect(fill = cor_faixa),
          strip.text.y.left = element_text(color = "white", face = "bold",
                                           size = 15, angle = 90))
}

# ── Painel B / C: dumbbell da geração 1 até a última, por curva.
painel_dumbbell <- function(dados, titulo, subtitulo, limites = NULL) {
  uma <- function(dd, y_lab, lim) {
    p <- ggplot(dd) +
      geom_segment(aes(x = curva, xend = curva, y = valor_ini, yend = valor_fim,
                       color = tipo_selecao), linewidth = 2.2, alpha = 0.75) +
      geom_point(aes(x = curva, y = valor_ini, color = tipo_selecao),
                 size = 5.5, shape = 21, fill = "white", stroke = 2.2) +
      geom_point(aes(x = curva, y = valor_fim, color = tipo_selecao), size = 5.5) +
      geom_text(aes(x = curva, y = (valor_ini + valor_fim) / 2,
                    label = sprintf("%+.3f", delta), color = tipo_selecao),
                hjust = -0.2, vjust = 0.5, size = 4.5, fontface = "bold") +
      scale_color_manual(values = cores_4, labels = labels_4) +
      labs(x = "", y = y_lab, color = "") +
      guias_cor + tema_poster
    if (!is.null(lim)) p <- p + coord_cartesian(ylim = lim)
    p
  }
  if (is.null(limites)) limites <- list(NULL, NULL)
  metricas <- levels(droplevels(dados$rotulo))
  p1 <- uma(filter(dados, rotulo == metricas[1]), metricas[1], limites[[1]]) +
    labs(title = titulo, subtitle = subtitulo)
  p2 <- uma(filter(dados, rotulo == metricas[2]), metricas[2], limites[[2]])
  p1 / p2
}

# ── Painel E / F: trajetória ao longo das gerações, média ± 1 SD.
painel_trajetoria <- function(dados, titulo, subtitulo, y_lab,
                              linha_ref = NULL, texto_ref = NULL, lim = NULL) {
  p <- ggplot(dados, aes(x = generation, y = media,
                         color = tipo_selecao, fill = tipo_selecao)) +
    geom_ribbon(aes(ymin = media - desvio, ymax = media + desvio),
                alpha = 0.12, color = NA) +
    geom_line(linewidth = 1.5)
  if (!is.null(linha_ref)) {
    p <- p +
      geom_hline(yintercept = linha_ref, linetype = "dashed",
                 color = cor_ref, linewidth = 0.8) +
      annotate("text", x = 1, y = linha_ref, label = texto_ref, hjust = 0,
               vjust = -0.55, color = cor_ref, size = 4.5, fontface = "italic")
  }
  p <- p +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values  = cores_4, labels = labels_4) +
    labs(title = titulo, subtitle = subtitulo, x = "Generation", y = y_lab,
         color = "", fill = "") +
    guias_cor + tema_poster
  if (!is.null(lim)) p <- p + coord_cartesian(ylim = lim)
  p
}

# ── Figura 2: uma resposta contra A_max, nuvem + média por curva.
painel_custo_busca <- function(bruto, medias, col, rotulo, letra, cor_faixa,
                               parse_strip = FALSE, x_lab = NULL,
                               linha_ref = NULL, texto_ref = NULL) {
  b <- bruto  %>% mutate(rot = rotulo)
  m <- medias %>% mutate(rot = rotulo)
  p <- ggplot(b, aes(x = amax_f, color = tipo_selecao))
  if (!is.null(linha_ref)) {
    p <- p +
      geom_hline(yintercept = linha_ref, linetype = "dashed",
                 color = cor_ref, linewidth = 0.8) +
      annotate("text", x = -Inf, y = linha_ref, label = texto_ref, hjust = -0.1,
               vjust = -0.55, color = cor_ref, size = 4.5, fontface = "italic")
  }
  p +
    geom_jitter(aes(y = .data[[col]]), alpha = 0.2, width = 0.15, size = 1.8) +
    geom_line(data = m, aes(y = .data[[col]], group = tipo_selecao), linewidth = 1.6) +
    geom_point(data = m, aes(y = .data[[col]]), size = 5, shape = 19) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    facet_wrap(~ rot, strip.position = "left",
               labeller = if (parse_strip) label_parsed else "label_value") +
    labs(title = letra, x = x_lab, y = NULL, color = "") +
    guias_cor + tema_grande +
    theme(strip.placement   = "outside",
          strip.background  = element_rect(fill = cor_faixa),
          strip.text.y.left = element_text(color = "white", face = "bold",
                                           size = 17, angle = 90))
}

# =====================================================================
# GERADOR
# =====================================================================
gerar_poster2 <- function(MODELO) {

  eixo <- MODELO$eixo
  dir_saida <- file.path("Resultados_Artigo", "Poster2")
  dir.create(dir_saida, recursive = TRUE, showWarnings = FALSE)

  cat(sprintf("\n=== POSTER 2 — %s ===\n", MODELO$nome))
  df <- carregar_modelo(MODELO$pasta, MODELO$estudo)
  if (is.null(df)) {
    cat(sprintf("  Nenhum arquivo em %s. Rode %s primeiro.\n",
                MODELO$pasta, MODELO$script))
    return(invisible(NULL))
  }
  if (!eixo %in% names(df)) {
    cat(sprintf("  A coluna '%s' não existe nestes dados. Confira o arquivo lido.\n", eixo))
    return(invisible(NULL))
  }

  GEN_FIM <- max(df$generation, na.rm = TRUE)
  vals    <- sort(unique(df[[eixo]]))
  s_baixo <- vals[which.min(abs(vals - SIGMA_BAIXO))]
  s_alto  <- vals[which.min(abs(vals - SIGMA_ALTO))]
  cat(sprintf("  geração final %d · eixo %s de %.1f a %.1f\n",
              GEN_FIM, MODELO$eixo_txt, min(vals), max(vals)))

  rot_mod  <- "Modularity"
  rot_nest <- "Nestedness (NODF)"

  # -------------------------------------------------------------------
  # FIGURA 1 — grade 2x3, uma por (k, seleção natural, A_max)
  # -------------------------------------------------------------------
  faixa_rede <- faixa_lateral("NETWORK ARCHITECTURE", "#2C3E50")
  faixa_evo  <- faixa_lateral(MODELO$faixa_evo, MODELO$cor_evo)

  combos <- expand.grid(k = K_vals, ns = NS_vals, amax = AMAX_vals,
                        stringsAsFactors = FALSE)
  cat(sprintf("\n  Figura 1 (grade 2x3): %d combinações\n", nrow(combos)))

  for (i in seq_len(nrow(combos))) {
    kk <- as.integer(combos$k[i]); ns <- combos$ns[i]; amax <- combos$amax[i]

    base <- df %>% filter(k_fixo == kk, selecao_natural == ns, encounters_n == amax)
    if (nrow(base) == 0) { cat(sprintf("  [%d] sem dados\n", i)); next }

    sufixo <- sprintf("%s_k%d_amax%d_%s_%s", MODELO$prefixo, kk, amax,
                      if (ns) "comNS" else "semNS",
                      if (FUNDO_ESCURO) "escuro" else "claro")

    # Painel A: as duas métricas de rede ao longo do eixo
    dd_rede <- base %>%
      filter(generation == GEN_FIM) %>%
      drop_na(Modularity, Nestedness) %>%
      pivot_longer(c(Modularity, Nestedness), names_to = "rotulo", values_to = "valor") %>%
      mutate(rotulo = factor(ifelse(rotulo == "Modularity", rot_mod, rot_nest),
                             levels = c(rot_mod, rot_nest)))

    lim_mod  <- range(dd_rede$valor[dd_rede$rotulo == rot_mod],  na.rm = TRUE)
    lim_nest <- range(dd_rede$valor[dd_rede$rotulo == rot_nest], na.rm = TRUE)

    # Painéis B e C: dumbbell da geração 1 até a final
    prep_dumb <- function(sval) {
      base %>%
        filter(generation %in% c(1, GEN_FIM), .data[[eixo]] == sval) %>%
        drop_na(Modularity, Nestedness) %>%
        group_by(generation, tipo_selecao) %>%
        summarise(Modularity = mean(Modularity, na.rm = TRUE),
                  Nestedness = mean(Nestedness, na.rm = TRUE), .groups = "drop") %>%
        pivot_longer(c(Modularity, Nestedness), names_to = "rotulo", values_to = "valor") %>%
        mutate(quando = ifelse(generation == 1, "valor_ini", "valor_fim")) %>%
        dplyr::select(-generation) %>%
        pivot_wider(names_from = quando, values_from = valor) %>%
        mutate(delta  = valor_fim - valor_ini,
               rotulo = factor(ifelse(rotulo == "Modularity", rot_mod, rot_nest),
                               levels = c(rot_mod, rot_nest)),
               # as.character() de propósito: se tipo_selecao vier como fator,
               # labels_4[fator] indexaria pelos códigos inteiros e trocaria
               # silenciosamente os nomes das curvas.
               curva  = factor(labels_4[as.character(tipo_selecao)],
                               levels = c("Disruptive", "Sigmoid", "Gaussian", "Random")))
    }

    # Painel D: a característica que evolui, ao longo do eixo
    dd_evo <- base %>%
      filter(generation == GEN_FIM) %>%
      drop_na(all_of(MODELO$col_media)) %>%
      mutate(valor = .data[[MODELO$col_media]], rotulo = MODELO$lab_media)
    lim_evo <- range(dd_evo$valor, na.rm = TRUE)

    # Painéis E e F: trajetórias
    prep_traj <- function(sval) {
      base %>%
        filter(.data[[eixo]] == sval) %>%
        group_by(tipo_selecao, generation) %>%
        summarise(media  = mean(.data[[MODELO$col_media]], na.rm = TRUE),
                  desvio = sd(.data[[MODELO$col_media]],   na.rm = TRUE),
                  .groups = "drop")
    }

    sub_cen <- sprintf("k = %d  |  A_max = %d", kk, amax)

    p_A <- painel_gradiente(dd_rede, eixo, MODELO$eixo_lab,
                            sprintf("A  ·  Network Topology at Generation %d", GEN_FIM),
                            sub_cen, "#2C3E50")
    p_B <- painel_dumbbell(prep_dumb(s_baixo),
                           sprintf("B  ·  Network Change: Gen 1 → %d  (%s = %.1f)",
                                   GEN_FIM, MODELO$eixo_txt, s_baixo),
                           sprintf("○ = Gen 1    ● = Gen %d    |    Label = Δ", GEN_FIM),
                           list(lim_mod, lim_nest))
    p_C <- painel_dumbbell(prep_dumb(s_alto),
                           sprintf("C  ·  Network Change: Gen 1 → %d  (%s = %.1f)",
                                   GEN_FIM, MODELO$eixo_txt, s_alto),
                           sprintf("○ = Gen 1    ● = Gen %d    |    Label = Δ", GEN_FIM),
                           list(lim_mod, lim_nest))
    p_D <- painel_gradiente(dd_evo, eixo, MODELO$eixo_lab,
                            sprintf("D  ·  %s at Generation %d", MODELO$titulo_evo, GEN_FIM),
                            sub_cen, MODELO$cor_evo, parse_strip = TRUE,
                            linha_ref = MODELO$ref_media, texto_ref = MODELO$ref_media_txt)
    p_E <- painel_trajetoria(prep_traj(s_baixo),
                             sprintf("E  ·  Trajectory  (%s = %.1f)", MODELO$eixo_txt, s_baixo),
                             "Ribbon = ±1 SD", MODELO$y_media,
                             MODELO$ref_media, MODELO$ref_media_txt, lim_evo)
    p_F <- painel_trajetoria(prep_traj(s_alto),
                             sprintf("F  ·  Trajectory  (%s = %.1f)", MODELO$eixo_txt, s_alto),
                             "Ribbon = ±1 SD", MODELO$y_media,
                             MODELO$ref_media, MODELO$ref_media_txt, lim_evo)

    linha  <- plot_layout(widths = c(0.08, 1.3, 0.65, 0.65))
    grade  <- banner(MODELO$titulo,
                     sprintf("Matings sought per female (k) = %d  |  Males assessed per female (A_max) = %d  |  %s",
                             kk, amax,
                             if (ns) "With natural selection" else "Without natural selection")) /
      (((faixa_rede | p_A | p_B | p_C) + linha) /
       ((faixa_evo  | p_D | p_E | p_F) + linha) + plot_layout(heights = c(2, 1))) +
      plot_layout(heights = c(0.14, 1))

    arq <- file.path(dir_saida, sprintf("Poster2_Grid2x3_%s.png", sufixo))
    png(arq, width = 20, height = 14, units = "in", res = RES_PNG, bg = bg_poster)
    print(grade); dev.off()
    cat(sprintf("  [%2d/%d] %s\n", i, nrow(combos), basename(arq)))
  }

  # -------------------------------------------------------------------
  # FIGURA 2 — custo de busca: tudo contra A_max, uma por (k, NS)
  # -------------------------------------------------------------------
  combos_rob <- expand.grid(k = K_vals, ns = NS_vals, stringsAsFactors = FALSE)
  cat(sprintf("\n  Figura 2 (custo de busca): %d combinações\n", nrow(combos_rob)))

  for (i in seq_len(nrow(combos_rob))) {
    kk <- as.integer(combos_rob$k[i]); ns <- combos_rob$ns[i]

    bruto <- df %>%
      filter(k_fixo == kk, selecao_natural == ns,
             generation == GEN_FIM, .data[[eixo]] == s_alto) %>%
      drop_na(Modularity, Nestedness) %>%
      mutate(amax_f = factor(encounters_n, levels = c(200, 40, 10),
                             labels = c("200", "40", "10")))
    if (nrow(bruto) == 0) { cat(sprintf("  [%d] sem dados\n", i)); next }

    medias <- bruto %>%
      group_by(tipo_selecao, amax_f) %>%
      summarise(across(any_of(c("Modularity", "Nestedness",
                                MODELO$col_media, MODELO$col_var)),
                       ~ mean(.x, na.rm = TRUE)), .groups = "drop")

    p1 <- painel_custo_busca(bruto, medias, "Modularity", rot_mod,  "A", "#2C3E50")
    p2 <- painel_custo_busca(bruto, medias, "Nestedness", rot_nest, "B", "#2C3E50")
    p3 <- painel_custo_busca(bruto, medias, MODELO$col_media, MODELO$lab_media, "C",
                             MODELO$cor_evo, parse_strip = TRUE,
                             linha_ref = MODELO$ref_media, texto_ref = MODELO$ref_media_txt)
    p4 <- painel_custo_busca(bruto, medias, MODELO$col_var, MODELO$lab_var, "D",
                             MODELO$cor_evo,
                             x_lab = "Males assessed per female (A_max)",
                             linha_ref = MODELO$ref_var, texto_ref = MODELO$ref_var_txt)

    fig <- banner("What happens when females can only assess\na fraction of the available males?",
                  sprintf("%s = %.1f  |  Gen %d  |  k = %d  |  %s",
                          MODELO$eixo_txt, s_alto, GEN_FIM, kk,
                          if (ns) "With natural selection" else "Without natural selection")) /
      (p1 / p2 / p3 / p4) + plot_layout(heights = c(0.07, 1))

    arq <- file.path(dir_saida,
                     sprintf("Poster2_CustoBusca_%s_k%d_%s_%s.png", MODELO$prefixo, kk,
                             if (ns) "comNS" else "semNS",
                             if (FUNDO_ESCURO) "escuro" else "claro"))
    png(arq, width = 10, height = 28, units = "in", res = RES_PNG, bg = bg_poster)
    print(fig); dev.off()
    cat(sprintf("  [%d/%d] %s\n", i, nrow(combos_rob), basename(arq)))
  }

  # -------------------------------------------------------------------
  # FIGURA 3 — poliandria realizada, uma por regime de seleção natural
  # -------------------------------------------------------------------
  # Figura nova. k é um teto e não uma cota: quantos parceiros a fêmea de
  # fato consegue depende da curva de preferência e de A_max, e é isso que
  # esta figura mostra. A linha tracejada em cada painel é o k buscado.
  cols_poli <- c("grau_medio_femeas", "prop_femeas_atingiu_k", "prop_femeas_sem_acasalar")
  if (!all(cols_poli %in% names(df))) {
    cat("\n  Figura 3 pulada: estes dados são anteriores às colunas de poliandria realizada.\n")
  } else {
    cat(sprintf("\n  Figura 3 (poliandria realizada): %d combinações\n", length(NS_vals)))
    for (ns in NS_vals) {
      bruto <- df %>%
        filter(selecao_natural == ns, generation == GEN_FIM, .data[[eixo]] == s_alto) %>%
        mutate(amax_f = factor(encounters_n, levels = c(200, 40, 10),
                               labels = c("200", "40", "10")),
               k_lab  = factor(sprintf("k = %d", k_fixo),
                               levels = sprintf("k = %d", sort(K_vals))))
      if (nrow(bruto) == 0) next

      medias <- bruto %>%
        group_by(tipo_selecao, amax_f, k_lab, k_fixo) %>%
        summarise(across(all_of(cols_poli), ~ mean(.x, na.rm = TRUE)), .groups = "drop")

      uma <- function(col, letra, teto = FALSE) {
        p <- ggplot(bruto, aes(x = amax_f, color = tipo_selecao))
        if (teto) p <- p + geom_hline(data = distinct(medias, k_lab, k_fixo),
                                      aes(yintercept = k_fixo), linetype = "dashed",
                                      color = cor_ref, linewidth = 0.8)
        p +
          geom_jitter(aes(y = .data[[col]]), alpha = 0.18, width = 0.15, size = 1.6) +
          geom_line(data = medias, aes(y = .data[[col]], group = tipo_selecao),
                    linewidth = 1.5) +
          geom_point(data = medias, aes(y = .data[[col]]), size = 4.2) +
          scale_color_manual(values = cores_4, labels = labels_4) +
          facet_grid(rotulo ~ k_lab, switch = "y") +
          labs(title = letra, x = NULL, y = NULL, color = "") +
          guias_cor + tema_grande +
          theme(strip.placement   = "outside",
                strip.background  = element_rect(fill = "#1F6F8B"),
                strip.text.y.left = element_text(color = "white", face = "bold",
                                                 size = 15, angle = 90),
                strip.text.x      = element_text(color = "white", face = "bold", size = 17))
      }

      # A cada painel o rótulo da faixa lateral muda; como `uma` lê `bruto` e
      # `medias` do ambiente do laço, basta trocar a coluna antes de chamar.
      bruto$rotulo  <- "Realized polyandry"
      medias$rotulo <- "Realized polyandry"
      q1 <- uma("grau_medio_femeas", "A", teto = TRUE)
      bruto$rotulo  <- "Proportion reaching k"
      medias$rotulo <- "Proportion reaching k"
      q2 <- uma("prop_femeas_atingiu_k", "B")
      bruto$rotulo  <- "Unmated females"
      medias$rotulo <- "Unmated females"
      q3 <- uma("prop_femeas_sem_acasalar", "C") +
        labs(x = "Males assessed per female (A_max)")

      fig <- banner("k is a ceiling, not a quota:\nhow many partners does a female actually get?",
                    sprintf("%s = %.1f  |  Gen %d  |  %s", MODELO$eixo_txt, s_alto, GEN_FIM,
                            if (ns) "With natural selection" else "Without natural selection")) /
        (q1 / q2 / q3) + plot_layout(heights = c(0.10, 1))

      arq <- file.path(dir_saida,
                       sprintf("Poster2_Poliandria_%s_%s_%s.png", MODELO$prefixo,
                               if (ns) "comNS" else "semNS",
                               if (FUNDO_ESCURO) "escuro" else "claro"))
      png(arq, width = 16, height = 20, units = "in", res = RES_PNG, bg = bg_poster)
      print(fig); dev.off()
      cat(sprintf("  %s\n", basename(arq)))
    }
  }

  cat(sprintf("\n=== %s concluído. Figuras em %s ===\n\n", MODELO$nome, dir_saida))
  invisible(TRUE)
}
