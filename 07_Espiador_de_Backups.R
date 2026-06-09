# =====================================================================
# SCRIPT 07: O Espião de Backups (Acompanhamento em Tempo Real)
# =====================================================================
library(dplyr)
library(tidyr)
library(ggplot2)
library(patchwork)
library(segmented)

arquivo <- "Resultados_Artigo/Fase5_MiudoV2/Dados/resultados_Fase5_MiudoV2.rds"

# Pastas de saída
dir_espiadinhas <- "Resultados_Artigo/Fase5_MiudoV2/Graficos/Espiadinhas"
dir_graficos    <- "Resultados_Artigo/Fase5_MiudoV2/Graficos"
dir_dados_out   <- "Resultados_Artigo/Fase5_MiudoV2/Dados"
dir.create(dir_graficos,    recursive = TRUE, showWarnings = FALSE)
dir.create(dir_espiadinhas, recursive = TRUE, showWarnings = FALSE)
dir.create(dir_dados_out,   recursive = TRUE, showWarnings = FALSE)

cat(sprintf("Procurando backup em: %s\n", normalizePath(arquivo, mustWork = FALSE)))
cat(sprintf("Arquivo existe? %s\n", ifelse(file.exists(arquivo), "SIM", "NAO - verifique o caminho")))

if(file.exists(arquivo)) {
  df_parcial <- readRDS(arquivo)

  # GEN_FINAL: detecta automaticamente a última geração
  GEN_FINAL <- max(df_parcial$generation, na.rm = TRUE)

  cat(sprintf("Dados carregados: %d linhas | Geração final: %d\n",
              nrow(df_parcial), GEN_FINAL))
  cat(sprintf("k_fixo: %s | sel.nat: %s\n",
              paste(sort(unique(df_parcial$k_fixo)), collapse=", "),
              paste(unique(df_parcial$selecao_natural), collapse=", ")))

  # Baseline para Espiadinhas 1-8: k=10, sel.nat=TRUE (cenário principal)
  K_BASE  <- 10L
  NS_BASE <- TRUE
  df_base <- df_parcial %>%
    filter(k_fixo == K_BASE, selecao_natural == NS_BASE)
  cat(sprintf("Baseline (k=%d, sel.nat=%s): %d linhas\n", K_BASE, NS_BASE, nrow(df_base)))

  n_completos <- length(unique(paste(df_base$tipo_selecao, df_base$sigma_p,
                                     df_base$encounters_n, df_base$replica)))
  n_total <- 4 * 7 * 3 * 30  # total esperado no baseline

  df_gen50 <- df_base %>% filter(generation == GEN_FINAL) %>% drop_na() %>%
    mutate(Cenario_Ecol = factor(paste0("A_max: ", encounters_n),
                                 levels = c("A_max: 200", "A_max: 40", "A_max: 10")))

  cores_4  <- c("uniform"="gray60", "gaussian"="#E6B800", "sigmoid"="#3BA273", "u-shaped"="#9932CC")
  labels_4 <- c("uniform"="Aleatória", "gaussian"="Gaussiana", "sigmoid"="Sigmoide", "u-shaped"="Disruptiva")

  # ---- ESPIADINHA 1: Diversidade Genética ----
  p_varz <- ggplot(df_gen50, aes(x = sigma_p, y = varz_males,
                                  color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_wrap(~Cenario_Ecol) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 1: Diversidade Genética (Var z) em Tempo Real",
         x = expression(sigma[p]), y = "Var(z) machos", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  # ---- ESPIADINHA 2: Modularidade ----
  p_mod <- ggplot(df_gen50, aes(x = sigma_p, y = Modularity,
                                 color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_wrap(~Cenario_Ecol) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 2: Modularidade em Tempo Real",
         x = expression(sigma[p]), y = "Modularity (Louvain)", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  # ---- ESPIADINHA 3: Média do Traço Masculino ----
  p_zbar <- ggplot(df_gen50, aes(x = sigma_p, y = zbar_males,
                                  color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_hline(yintercept = 5.0, linetype = "dashed", alpha = 0.4) +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_wrap(~Cenario_Ecol) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 3: Média do Traço Masculino em Tempo Real",
         subtitle = "Linha tracejada cinza = φ = 5.0 (ótimo ecológico)",
         x = expression(sigma[p]), y = "Média z machos", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  # ---- ESPIADINHA 4: Aninhamento (NODF) ----
  p_nest <- ggplot(df_gen50, aes(x = sigma_p, y = Nestedness,
                                  color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_wrap(~Cenario_Ecol) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 4: Aninhamento (NODF) em Tempo Real",
         x = expression(sigma[p]), y = "Nestedness (NODF)", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  # ---- ESPIADINHA 5: Centralização ----
  p_cent <- ggplot(df_gen50, aes(x = sigma_p, y = Centralization,
                                  color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_wrap(~Cenario_Ecol) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 5: Centralização em Tempo Real",
         x = expression(sigma[p]), y = "Degree Centralization", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  # ---- ESPIADINHA 6: Oportunidade de Seleção Sexual (Is) ----
  p_is <- ggplot(df_gen50, aes(x = sigma_p, y = I_s,
                                color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_wrap(~Cenario_Ecol) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 6: Oportunidade de Seleção Sexual (Is) em Tempo Real",
         x = expression(sigma[p]), y = expression(I[s]), color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  print(p_varz)
  print(p_mod)
  print(p_zbar)
  print(p_nest)
  print(p_cent)
  print(p_is)

  # Salvar espiadinhas 1-6 como PNG
  ggsave(file.path(dir_espiadinhas, "Espiadinha1_VarZ.png"),        p_varz, width=10, height=5, dpi=200, bg="white")
  ggsave(file.path(dir_espiadinhas, "Espiadinha2_Modularidade.png"), p_mod,  width=10, height=5, dpi=200, bg="white")
  ggsave(file.path(dir_espiadinhas, "Espiadinha3_MediaTraco.png"),  p_zbar, width=10, height=5, dpi=200, bg="white")
  ggsave(file.path(dir_espiadinhas, "Espiadinha4_Aninhamento.png"), p_nest, width=10, height=5, dpi=200, bg="white")
  ggsave(file.path(dir_espiadinhas, "Espiadinha5_Centralizacao.png"), p_cent, width=10, height=5, dpi=200, bg="white")
  ggsave(file.path(dir_espiadinhas, "Espiadinha6_Is.png"),         p_is,   width=10, height=5, dpi=200, bg="white")

  cat("\n>>> CHECKPOINT 1: Espiadinhas 1-6 OK\n")

  # =====================================================================
  # LIMITES GLOBAIS POR MÉTRICA (para eixo Y consistente entre cenários)
  # =====================================================================
  df_global <- df_parcial %>%
    drop_na() %>%
    group_by(generation, tipo_selecao, sigma_p, encounters_n) %>%
    summarise(across(c(Modularity, Nestedness, I_s, Centralization),
                     \(x) mean(x, na.rm = TRUE)),
              .groups = "drop") %>%
    pivot_longer(cols = c(Modularity, Nestedness, I_s, Centralization),
                 names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = case_when(
      Metrica == "Modularity"     ~ "1. Modularidade",
      Metrica == "Nestedness"     ~ "2. Aninhamento",
      Metrica == "I_s"            ~ "3. Oportunidade de Seleção (Is)",
      Metrica == "Centralization" ~ "4. Centralidade"
    ))

  limites_metrica <- df_global %>%
    group_by(Metrica) %>%
    summarise(ymin = min(Valor, na.rm = TRUE),
              ymax = max(Valor, na.rm = TRUE),
              .groups = "drop")

  df_limites <- bind_rows(
    limites_metrica %>% mutate(Valor = ymin),
    limites_metrica %>% mutate(Valor = ymax)
  ) %>%
    mutate(generation = 1, tipo_selecao = "uniform")

  # =====================================================================
  # LIMITES GLOBAIS para métricas EVOLUTIVAS (MeanZ e VarZ)
  # =====================================================================
  df_global_evo <- df_parcial %>%
    drop_na() %>%
    group_by(generation, tipo_selecao, sigma_p, encounters_n) %>%
    summarise(zbar_males = mean(zbar_males, na.rm = TRUE),
              varz_males = mean(varz_males, na.rm = TRUE),
              .groups = "drop") %>%
    pivot_longer(cols = c(zbar_males, varz_males),
                 names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = case_when(
      Metrica == "zbar_males" ~ "1. Média do traço (z̄)",
      Metrica == "varz_males" ~ "2. Variância do traço (Var z)"
    ))

  limites_evo <- df_global_evo %>%
    group_by(Metrica) %>%
    summarise(ymin = min(Valor, na.rm = TRUE),
              ymax = max(Valor, na.rm = TRUE),
              .groups = "drop")

  df_limites_evo <- bind_rows(
    limites_evo %>% mutate(Valor = ymin),
    limites_evo %>% mutate(Valor = ymax)
  ) %>%
    mutate(generation = 1, tipo_selecao = "uniform")

  cat(">>> CHECKPOINT 2: Limites globais OK\n")

  # =====================================================================
  # FUNÇÃO HELPER: Trajetórias evolutivas (MeanZ + VarZ)
  # Recebe A_max como parâmetro
  # =====================================================================
  trajetoria_evolutiva <- function(amax, num_espiadinha) {
    df_traj <- df_parcial %>%
      filter(encounters_n == amax, sigma_p %in% c(0.5, 2.0)) %>%
      drop_na() %>%
      group_by(generation, tipo_selecao, sigma_p) %>%
      summarise(zbar_males = mean(zbar_males, na.rm = TRUE),
                varz_males = mean(varz_males, na.rm = TRUE),
                .groups = "drop") %>%
      pivot_longer(cols = c(zbar_males, varz_males),
                   names_to = "Metrica", values_to = "Valor") %>%
      mutate(Metrica = case_when(
        Metrica == "zbar_males" ~ "1. Média do traço (z̄)",
        Metrica == "varz_males" ~ "2. Variância do traço (Var z)"
      ),
      sigma_label = factor(sprintf("σp = %.1f", sigma_p),
                           levels = c("σp = 0.5", "σp = 2.0")))

    if (nrow(df_traj) == 0) {
      cat(sprintf("ESPIADINHA %d: ainda não há dados para A_max=%d\n",
                  num_espiadinha, amax))
      return(invisible(NULL))
    }

    # Linha horizontal em φ=5 só para a métrica de média
    df_phi <- data.frame(Metrica = "1. Média do traço (z̄)", yintercept = 5.0)

    ggplot(df_traj, aes(x = generation, y = Valor, color = tipo_selecao)) +
      geom_blank(data = df_limites_evo) +
      geom_hline(data = df_phi, aes(yintercept = yintercept),
                 linetype = "dashed", alpha = 0.5, color = "gray30") +
      geom_line(linewidth = 0.8, alpha = 0.9) +
      facet_grid(Metrica ~ sigma_label, scales = "free_y") +
      scale_color_manual(values = cores_4, labels = labels_4) +
      labs(title = sprintf("Trajetórias evolutivas (A_max = %d)", amax),
           x = "Geração", y = "Valor", color = "Funcao") +
      theme_light(base_size = 12) +
      theme(legend.position = "bottom",
            strip.background = element_rect(fill = "gray20"),
            strip.text = element_text(color = "white", face = "bold"))
  }

  # =====================================================================
  # FUNÇÃO HELPER: Trajetórias estilo Espiadinha 7 (σp=0.5 vs σp=2.0)
  # Recebe A_max como parâmetro
  # =====================================================================
  trajetoria_dois_sigmas <- function(amax, num_espiadinha) {
    df_traj <- df_parcial %>%
      filter(encounters_n == amax, sigma_p %in% c(0.5, 2.0)) %>%
      drop_na() %>%
      group_by(generation, tipo_selecao, sigma_p) %>%
      summarise(across(c(Modularity, Nestedness, I_s, Centralization),
                       \(x) mean(x, na.rm = TRUE)),
                .groups = "drop") %>%
      pivot_longer(cols = c(Modularity, Nestedness, I_s, Centralization),
                   names_to = "Metrica", values_to = "Valor") %>%
      mutate(Metrica = case_when(
        Metrica == "Modularity"     ~ "1. Modularidade",
        Metrica == "Nestedness"     ~ "2. Aninhamento",
        Metrica == "I_s"            ~ "3. Oportunidade de Seleção (Is)",
        Metrica == "Centralization" ~ "4. Centralidade"
      ),
      sigma_label = factor(sprintf("σp = %.1f", sigma_p),
                           levels = c("σp = 0.5", "σp = 2.0")))

    if (nrow(df_traj) == 0) {
      cat(sprintf("ESPIADINHA %d: ainda não há dados para A_max=%d\n",
                  num_espiadinha, amax))
      return(invisible(NULL))
    }

    ggplot(df_traj, aes(x = generation, y = Valor, color = tipo_selecao)) +
      geom_blank(data = df_limites) +  # força limites globais por métrica
      geom_line(linewidth = 0.8, alpha = 0.9) +
      facet_grid(Metrica ~ sigma_label, scales = "free_y") +
      scale_color_manual(values = cores_4, labels = labels_4) +
      labs(title = sprintf("ESPIADINHA %d: Trajetórias por geração (A_max = %d)",
                           num_espiadinha, amax),
           subtitle = "Médias por geração | Eixo Y consistente entre cenários",
           x = "Geração", y = "Valor da Métrica", color = "Funcao") +
      theme_light(base_size = 12) +
      theme(legend.position = "top",
            strip.background = element_rect(fill = "gray20"),
            strip.text = element_text(color = "white", face = "bold"))
  }

  cat(">>> CHECKPOINT 3: Funções trajetória definidas OK\n")

  # =====================================================================
  # ESPIADINHA 7: Trajetórias σp=0.5 vs 2.0 em DOIS níveis de A_max
  # Painel duplo lado a lado:
  #   Esquerda: A_max = 200 (sem restrição ecológica)
  #   Direita:  A_max = 10  (restrição severa)
  # =====================================================================
  p_left  <- trajetoria_dois_sigmas(amax = 200, num_espiadinha = 7)
  p_right <- trajetoria_dois_sigmas(amax = 10,  num_espiadinha = 7)

  if (!is.null(p_left) && !is.null(p_right)) {
    # Títulos curtos + subtítulos com a descrição
    p_left_clean  <- p_left  +
      labs(title = "A_max = 200",
           subtitle = "200 machos amostrados por fêmea") +
      theme(plot.title    = element_text(size = 14, face = "bold", hjust = 0.5),
            plot.subtitle = element_text(size = 10, hjust = 0.5),
            plot.title.position = "plot",
            legend.position = "bottom")

    p_right_clean <- p_right +
      labs(title = "A_max = 10",
           subtitle = "10 machos amostrados por fêmea",
           y = NULL) +
      theme(plot.title    = element_text(size = 14, face = "bold", hjust = 0.5),
            plot.subtitle = element_text(size = 10, hjust = 0.5),
            plot.title.position = "plot",
            legend.position = "none",
            axis.text.y = element_blank())

    p_combinado <- (p_left_clean | p_right_clean) +
      plot_annotation(
        title    = "ESPIADINHA 7: Trajetórias topológicas sob níveis contrastantes de A_max",
        subtitle = "Linhas = médias por geração entre todas as réplicas | Eixo Y consistente entre painéis"
      )

    print(p_combinado)
    ggsave(file.path(dir_espiadinhas, "Espiadinha7_Topologia_Amax.png"),
           p_combinado, width=14, height=10, dpi=200, bg="white")
  } else {
    if (!is.null(p_left))  print(p_left)
    if (!is.null(p_right)) print(p_right)
  }

  # =====================================================================
  # ESPIADINHA 8: Trajetórias EVOLUTIVAS (MeanZ + VarZ)
  # Painel duplo lado a lado, mesmo formato da Espiadinha 7
  #   Esquerda: A_max = 200 (sem restrição ecológica)
  #   Direita:  A_max = 10  (restrição severa)
  # =====================================================================
  p_evo_left  <- trajetoria_evolutiva(amax = 200, num_espiadinha = 8)
  p_evo_right <- trajetoria_evolutiva(amax = 10,  num_espiadinha = 8)

  if (!is.null(p_evo_left) && !is.null(p_evo_right)) {
    p_evo_left_clean  <- p_evo_left  +
      labs(title = "A_max = 200",
           subtitle = "200 machos amostrados por fêmea") +
      theme(plot.title    = element_text(size = 14, face = "bold", hjust = 0.5),
            plot.subtitle = element_text(size = 10, hjust = 0.5),
            plot.title.position = "plot",
            legend.position = "bottom")

    p_evo_right_clean <- p_evo_right +
      labs(title = "A_max = 10",
           subtitle = "10 machos amostrados por fêmea",
           y = NULL) +
      theme(plot.title    = element_text(size = 14, face = "bold", hjust = 0.5),
            plot.subtitle = element_text(size = 10, hjust = 0.5),
            plot.title.position = "plot",
            legend.position = "none",
            axis.text.y = element_blank())

    p_evo_combinado <- (p_evo_left_clean | p_evo_right_clean) +
      plot_annotation(
        title    = "ESPIADINHA 8: Trajetórias evolutivas (média e variância do traço masculino)",
        subtitle = "Linha tracejada cinza = φ = 5.0 (ótimo ecológico) | Eixo Y consistente entre painéis"
      )

    print(p_evo_combinado)
    ggsave(file.path(dir_espiadinhas, "Espiadinha8_Trajetorias_Evolutivas.png"),
           p_evo_combinado, width = 14, height = 10, dpi = 200, bg = "white")
  } else {
    if (!is.null(p_evo_left))  print(p_evo_left)
    if (!is.null(p_evo_right)) print(p_evo_right)
  }

  cat(">>> CHECKPOINT 4: Espiadinhas 7 e 8 OK\n")

  # =====================================================================
  # TABELA: Comparação Geração 1 vs Geração Final para todas as métricas
  # =====================================================================
  cat(sprintf("\n\n========== TABELA: Gen 1 vs Gen %d ==========\n", GEN_FINAL))

  df_tabela <- df_base %>%
    filter(generation %in% c(1, GEN_FINAL)) %>%
    drop_na() %>%
    group_by(generation, tipo_selecao, sigma_p, encounters_n) %>%
    summarise(
      Modularity     = mean(Modularity,     na.rm = TRUE),
      Nestedness     = mean(Nestedness,     na.rm = TRUE),
      I_s            = mean(I_s,            na.rm = TRUE),
      Centralization = mean(Centralization, na.rm = TRUE),
      varz_males     = mean(varz_males,     na.rm = TRUE),
      zbar_males     = mean(zbar_males,     na.rm = TRUE),
      n_reps         = n(),
      .groups = "drop"
    ) %>%
    pivot_longer(cols = c(Modularity, Nestedness, I_s, Centralization,
                          varz_males, zbar_males),
                 names_to = "Metrica", values_to = "Valor") %>%
    mutate(gen_label = ifelse(generation == 1, "Gen_inicial", "Gen_final")) %>%
    dplyr::select(-generation, -n_reps) %>%
    pivot_wider(names_from = gen_label, values_from = Valor) %>%
    mutate(Delta     = Gen_final - Gen_inicial,
           Delta_pct = 100 * (Gen_final - Gen_inicial) / Gen_inicial) %>%
    arrange(encounters_n, sigma_p, tipo_selecao, Metrica)

  # Imprime no console em formato legível
  print(df_tabela, n = Inf, width = Inf)

  out_csv <- file.path(dir_dados_out, sprintf("Tabela_Gen1_vs_Gen%d_k%d_NS%s.csv",
                                              GEN_FINAL, K_BASE, NS_BASE))
  write.csv(df_tabela, out_csv, row.names = FALSE)
  cat(sprintf("\nTabela salva em: %s\n", out_csv))

  # =====================================================================
  # TABELA FOCAL: Modularity + Nestedness | A_max=200 | sigma_p=2.0
  # =====================================================================
  cat(sprintf("\n\n========== TABELA FOCAL: Mod + Nest | A_max=200 | σp=2.0 ==========\n"))

  df_focal <- df_tabela %>%
    filter(Metrica %in% c("Modularity", "Nestedness"),
           encounters_n == 200,
           sigma_p == 2.0) %>%
    dplyr::select(tipo_selecao, Metrica, Gen_inicial, Gen_final, Delta, Delta_pct) %>%
    arrange(Metrica, tipo_selecao) %>%
    mutate(across(c(Gen_inicial, Gen_final, Delta), \(x) round(x, 3)),
           Delta_pct = round(Delta_pct, 1))

  print(df_focal, n = Inf)

  cat(">>> CHECKPOINT 5: Tabela OK\n")

  # =====================================================================
  # ESPIADINHA 9: Efeito da Poliandria (k_fixo) na Topologia e Evolução
  # A_max=200, sel.nat=TRUE, geração final — comparando k=5, 10, 20
  # =====================================================================
  df_k <- df_parcial %>%
    filter(encounters_n == 200, selecao_natural == TRUE, generation == GEN_FINAL) %>%
    drop_na() %>%
    mutate(k_label = factor(paste0("k = ", k_fixo),
                            levels = paste0("k = ", c(5, 10, 20))))

  p_k_topo <- df_k %>%
    pivot_longer(cols = c(Nestedness, Modularity), names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = ifelse(Metrica == "Modularity", "1. Modularidade", "2. Aninhamento (NODF)")) %>%
    ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_grid(Metrica ~ k_label, scales = "free_y") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 9: Efeito da Poliandria (k) na Topologia",
         subtitle = "A_max=200 | sel.nat=TRUE | cada coluna = nível de poliandria",
         x = expression(sigma[p]), y = "Valor da Métrica", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  p_k_evo <- df_k %>%
    pivot_longer(cols = c(zbar_males, varz_males), names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = ifelse(Metrica == "zbar_males",
                            "1. Média do traço (z̄)", "2. Variância do traço (Var z)")) %>%
    ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_grid(Metrica ~ k_label, scales = "free_y") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 9b: Efeito da Poliandria (k) na Evolução do Traço",
         subtitle = "A_max=200 | sel.nat=TRUE",
         x = expression(sigma[p]), y = "Valor Evolutivo", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  print(p_k_topo)
  print(p_k_evo)
  ggsave(file.path(dir_espiadinhas, "Espiadinha9a_Poliandria_Topologia.png"),
         p_k_topo, width = 12, height = 7, dpi = 200, bg = "white")
  ggsave(file.path(dir_espiadinhas, "Espiadinha9b_Poliandria_Evolucao.png"),
         p_k_evo,  width = 12, height = 7, dpi = 200, bg = "white")
  cat(">>> CHECKPOINT 6: Espiadinha 9 OK\n")

  # =====================================================================
  # ESPIADINHA 10: Efeito de selecao_natural (com vs sem)
  # A_max=200, k=10, geração final
  # =====================================================================
  df_ns <- df_parcial %>%
    filter(encounters_n == 200, k_fixo == 10, generation == GEN_FINAL) %>%
    drop_na() %>%
    mutate(ns_label = factor(ifelse(selecao_natural, "Com sel. natural", "Sem sel. natural"),
                             levels = c("Com sel. natural", "Sem sel. natural")))

  p_ns_topo <- df_ns %>%
    pivot_longer(cols = c(Nestedness, Modularity), names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = ifelse(Metrica == "Modularity", "1. Modularidade", "2. Aninhamento (NODF)")) %>%
    ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_grid(Metrica ~ ns_label, scales = "free_y") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 10: Efeito da Seleção Natural na Topologia da Rede",
         subtitle = "A_max=200 | k=10 | esquerda=com viabilidade, direita=sem viabilidade (V_j=1)",
         x = expression(sigma[p]), y = "Valor da Métrica", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  p_ns_evo <- df_ns %>%
    pivot_longer(cols = c(zbar_males, varz_males), names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = ifelse(Metrica == "zbar_males",
                            "1. Média do traço (z̄)", "2. Variância do traço (Var z)")) %>%
    ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    geom_jitter(alpha = 0.15, width = 0.05, size = 0.8) +
    facet_grid(Metrica ~ ns_label, scales = "free_y") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title = "ESPIADINHA 10b: Efeito da Seleção Natural na Evolução do Traço",
         subtitle = "A_max=200 | k=10",
         x = expression(sigma[p]), y = "Valor Evolutivo", color = "", fill = "") +
    theme_light() + theme(legend.position = "bottom")

  print(p_ns_topo)
  print(p_ns_evo)
  ggsave(file.path(dir_espiadinhas, "Espiadinha10a_SelNat_Topologia.png"),
         p_ns_topo, width = 10, height = 7, dpi = 200, bg = "white")
  ggsave(file.path(dir_espiadinhas, "Espiadinha10b_SelNat_Evolucao.png"),
         p_ns_evo,  width = 10, height = 7, dpi = 200, bg = "white")
  cat(">>> CHECKPOINT 7: Espiadinha 10 OK\n")

  # =====================================================================
  # GRÁFICOS FINAIS (Fase 5)
  # =====================================================================
  val_reps       <- length(unique(df_parcial$replica[!is.na(df_parcial$replica)]))
  subtitulo_base <- sprintf("Parâmetros: %d Gerações | N=200 | Réplicas: %d de 30 (%.0f%%)",
                             GEN_FINAL, val_reps, 100 * n_completos / n_total)

  tema_master <- theme_light(base_size = 14) +
    theme(legend.position = "bottom",
          strip.background = element_rect(fill = "gray10"),
          strip.text = element_text(color = "white", face = "bold"))

  # ---------------------------------------------------------------------
  # PLOT A: ASSINATURA TOPOLÓGICA (A_max = 200)
  # ---------------------------------------------------------------------
  p_fase4_topo <- df_gen50 %>% filter(encounters_n == 200) %>%
    pivot_longer(cols = c(Modularity, Nestedness, I_s, Centralization),
                 names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = case_when(
      Metrica == "Modularity"     ~ "1. Modularidade",
      Metrica == "Nestedness"     ~ "2. Aninhamento",
      Metrica == "I_s"            ~ "3. Is",
      Metrica == "Centralization" ~ "4. Centralidade")) %>%
    ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red", linewidth = 1) +
    annotate("text", x = 1.0, y = Inf, label = "σp = σz", hjust = -0.15, vjust = 1.8,
             color = "red", size = 3.2, fontface = "italic") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15, linewidth = 1.2,
                show.legend = FALSE) +
    geom_jitter(alpha = 0.2, width = 0.05, size = 1.2) +
    facet_wrap(~Metrica, scales = "free_y", ncol = 2) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title    = sprintf("Fase 4: A Assinatura Topológica Suprema (A_max = 200, Gen %d)", GEN_FINAL),
         subtitle = subtitulo_base,
         x = expression(paste("Variação da Preferência (", sigma[p], ")")),
         y = "Valor da Métrica", color = "", fill = "") +
    guides(color = guide_legend(override.aes = list(size = 3, alpha = 1))) +
    tema_master

  # ---------------------------------------------------------------------
  # PLOT B: RUÍDO ECOLÓGICO (A_max: 200, 40, 10)
  # ---------------------------------------------------------------------
  df_ruido <- df_gen50 %>%
    mutate(Cenario_Ecol = factor(paste0("A_max: ", encounters_n),
                                 levels = c("A_max: 200", "A_max: 40", "A_max: 10"))) %>%
    pivot_longer(cols = c(zbar_males, varz_males),
                 names_to = "Variavel", values_to = "Valor") %>%
    mutate(Variavel = ifelse(Variavel == "zbar_males",
                             "1. Média (Exagero)", "2. Diversidade Genética (Var z)"))

  p_fase4_ruido <- ggplot(df_ruido, aes(x = sigma_p, y = Valor,
                                         color = tipo_selecao, fill = tipo_selecao)) +
    geom_hline(data = filter(df_ruido, Variavel == "1. Média (Exagero)"),
               aes(yintercept = 5.0), linetype = "dashed", alpha = 0.6) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red", linewidth = 1) +
    annotate("text", x = 1.0, y = Inf, label = "σp = σz", hjust = -0.15, vjust = 1.8,
             color = "red", size = 3.0, fontface = "italic") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15, linewidth = 1.2,
                show.legend = FALSE) +
    geom_jitter(alpha = 0.2, width = 0.05, size = 1) +
    facet_grid(Variavel ~ Cenario_Ecol, scales = "free_y") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title    = sprintf("Fase 4: Efeito do Custo de Busca sobre a Média e a Variância do Traço (Gen %d)", GEN_FINAL),
         subtitle = "Lendo da esq. para a dir.: A restrição de amostragem (A_max) atenua a seleção sexual",
         x = expression(paste("Variação da Preferência (", sigma[p], ")")),
         y = "Valor Fenotípico / Genético", color = "", fill = "") +
    guides(color = guide_legend(override.aes = list(size = 3, alpha = 1))) +
    tema_master

  # ---------------------------------------------------------------------
  # PLOT C: PROVA CAUSAL (A_max = 200, sigma_p = 2.0)
  # ---------------------------------------------------------------------
  df_causal <- df_gen50 %>%
    filter(encounters_n == 200, sigma_p == 2.0) %>%
    pivot_longer(cols = c(Modularity, Nestedness),
                 names_to = "Topologia", values_to = "EixoX") %>%
    mutate(Topologia = ifelse(Topologia == "Modularity",
                              "1. Modularidade (vs Var z)",
                              "2. Aninhamento (vs Média z)"),
           EixoY = ifelse(Topologia == "1. Modularidade (vs Var z)",
                          varz_males, zbar_males))

  p_fase4_causal <- ggplot(df_causal, aes(x = EixoX, y = EixoY,
                                           color = tipo_selecao, fill = tipo_selecao)) +
    geom_point(alpha = 0.5, size = 2) +
    geom_smooth(method = "lm", formula = y~x, se = TRUE, linewidth = 1.2,
                alpha = 0.15, show.legend = FALSE) +
    facet_wrap(~Topologia, scales = "free", ncol = 2) +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title    = sprintf("Fase 4: Evidência Correlacional Topologia–Evolução (σp=2.0, Gen %d)", GEN_FINAL),
         subtitle = "Regressões lineares indicam associação entre estrutura da rede e fenótipo",
         x = "Valor Topológico da Rede",
         y = "Valor Evolutivo (Média ou Variância)", color = "", fill = "") +
    guides(color = guide_legend(override.aes = list(size = 3, alpha = 1))) +
    tema_master

  # ---------------------------------------------------------------------
  # PLOT D: TOPOLOGIA × σp × A_max
  # Mostra como A_max (ruído ecológico) modifica a assinatura topológica
  # de cada curva ao longo do gradiente de σp
  # ---------------------------------------------------------------------
  p_fase4_topo_amax <- df_gen50 %>%
    mutate(Cenario_Ecol = factor(paste0("A_max: ", encounters_n),
                                 levels = c("A_max: 200", "A_max: 40", "A_max: 10"))) %>%
    pivot_longer(cols = c(Modularity, Nestedness),
                 names_to = "Metrica", values_to = "Valor") %>%
    mutate(Metrica = case_when(
      Metrica == "Modularity"  ~ "1. Modularidade",
      Metrica == "Nestedness"  ~ "2. Aninhamento")) %>%
    ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red", linewidth = 1) +
    annotate("text", x = 1.0, y = Inf, label = "σp = σz", hjust = -0.15, vjust = 1.8,
             color = "red", size = 3.0, fontface = "italic") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15, linewidth = 1.2,
                show.legend = FALSE) +
    geom_jitter(alpha = 0.2, width = 0.05, size = 1) +
    facet_grid(Metrica ~ Cenario_Ecol, scales = "free_y") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    scale_fill_manual(values = cores_4, labels = labels_4) +
    labs(title    = sprintf("Fase 4: A Restrição de Amostragem Dissolve a Assinatura Topológica? (Gen %d)", GEN_FINAL),
         subtitle = "Lendo da esq. para a dir.: A_max reduz o acesso feminino e perturba a estrutura da rede",
         x = expression(paste("Variação da Preferência das Fêmeas (", sigma[p], ")")),
         y = "Valor da Métrica Topológica", color = "", fill = "") +
    guides(color = guide_legend(override.aes = list(size = 3, alpha = 1))) +
    tema_master

  # ---------------------------------------------------------------------
  # PLOT E: DUMBBELL — Mudança Gen 1 → Gen Final (Modularity + Nestedness)
  # σp = 2.0, todos os A_max, todas as curvas
  # ---------------------------------------------------------------------
  df_dumbell <- df_tabela %>%
    filter(Metrica %in% c("Modularity", "Nestedness"),
           sigma_p == 2.0) %>%
    mutate(
      Amax_label = factor(paste0("A_max: ", encounters_n),
                          levels = c("A_max: 200", "A_max: 40", "A_max: 10")),
      Metrica_label = case_when(
        Metrica == "Modularity" ~ "1. Modularidade",
        Metrica == "Nestedness" ~ "2. Aninhamento"
      ),
      tipo_label = factor(tipo_selecao,
                          levels = c("u-shaped", "sigmoid", "gaussian", "uniform"),
                          labels = c("U-shaped", "Sigmoide", "Gaussiana", "Uniforme"))
    )

  p_fase4_dumbell <- ggplot(df_dumbell) +
    geom_segment(aes(x = Gen_inicial, xend = Gen_final,
                     y = tipo_label,  yend = tipo_label,
                     color = tipo_selecao),
                 linewidth = 1.8, alpha = 0.7) +
    geom_point(aes(x = Gen_inicial, y = tipo_label, color = tipo_selecao),
               size = 4, shape = 21, fill = "white", stroke = 2) +
    geom_point(aes(x = Gen_final, y = tipo_label, color = tipo_selecao),
               size = 4) +
    geom_text(aes(x = (Gen_inicial + Gen_final) / 2, y = tipo_label,
                  label = sprintf("%+.3f", Delta),
                  color = tipo_selecao),
              hjust = 0.5, vjust = -0.6, size = 3.0, fontface = "bold") +
    facet_grid(Metrica_label ~ Amax_label, scales = "free_x") +
    scale_color_manual(values = cores_4, labels = labels_4) +
    labs(
      title    = sprintf("Plot E: Mudança nas Métricas Topológicas: Gen 1 → Gen %d (σp = 2.0)", GEN_FINAL),
      subtitle = "Círculo aberto = Geração 1  |  Círculo fechado = Geração final  |  Rótulos = Δ absoluto",
      x        = "Valor Médio da Métrica",
      y        = NULL,
      color    = ""
    ) +
    guides(color = guide_legend(override.aes = list(size = 3, alpha = 1))) +
    tema_master +
    theme(panel.spacing.x = unit(1.5, "lines"))

  print(p_fase4_topo)
  print(p_fase4_topo_amax)
  print(p_fase4_ruido)
  print(p_fase4_causal)
  print(p_fase4_dumbell)

  ggsave(file.path(dir_graficos, "Fase4_PlotA_AssinaturaTopologica.png"),
         plot = p_fase4_topo,       width = 10, height = 8,  dpi = 300, bg = "white")
  ggsave(file.path(dir_graficos, "Fase4_PlotD_TopologiaAmax.png"),
         plot = p_fase4_topo_amax,  width = 12, height = 7,  dpi = 300, bg = "white")
  ggsave(file.path(dir_graficos, "Fase4_PlotB_RuidoEcologico.png"),
         plot = p_fase4_ruido,      width = 12, height = 7,  dpi = 300, bg = "white")
  ggsave(file.path(dir_graficos, "Fase4_PlotC_ProvaCausal.png"),
         plot = p_fase4_causal,     width = 10, height = 5,  dpi = 300, bg = "white")
  ggsave(file.path(dir_graficos, "Fase4_PlotE_Dumbell_Gen1vsGenFinal.png"),
         plot = p_fase4_dumbell,    width = 12, height = 6,  dpi = 300, bg = "white")
  cat(sprintf("\nGráficos A, B, C, D, E salvos em: %s\n", dir_graficos))

  # =====================================================================
  # BLOCO E: MODELOS LINEARES (LMs) — ESTATÍSTICA OFICIAL
  # =====================================================================
  cat("\nPreparando dados para os Modelos Lineares...\n")

  # Modelos lineares: baseline k=10, sel.nat=TRUE
  df_stats_low <- df_gen50 %>%
    filter(sigma_p <= 1.0) %>%
    drop_na(Modularity, Nestedness, Centralization, I_s, varz_males, zbar_males) %>%
    mutate(
      z_Modularity     = as.numeric(scale(Modularity)),
      z_Nestedness     = as.numeric(scale(Nestedness)),
      z_Centralization = as.numeric(scale(Centralization)),
      z_SigmaP         = as.numeric(scale(sigma_p)),
      f_encounters     = factor(encounters_n)
    )

  df_stats_high <- df_gen50 %>%
    filter(sigma_p >= 1.0) %>%
    drop_na(Modularity, Nestedness, Centralization, I_s, varz_males, zbar_males) %>%
    mutate(
      z_Modularity     = as.numeric(scale(Modularity)),
      z_Nestedness     = as.numeric(scale(Nestedness)),
      z_Centralization = as.numeric(scale(Centralization)),
      z_SigmaP         = as.numeric(scale(sigma_p)),
      f_encounters     = factor(encounters_n)
    )

  cat("\n--- MODELO 1a (sigma_p <= 1.0): Modularidade e Diversidade Genética ---\n")
  mod1a <- lm(varz_males ~ z_Modularity * tipo_selecao + z_SigmaP + f_encounters,
              data = df_stats_low)
  print(summary(mod1a))

  cat("\n--- MODELO 1b (sigma_p >= 1.0): Modularidade e Diversidade Genética ---\n")
  mod1b <- lm(varz_males ~ z_Modularity * tipo_selecao + z_SigmaP + f_encounters,
              data = df_stats_high)
  print(summary(mod1b))

  cat("\n--- MODELO 2a (sigma_p <= 1.0): Aninhamento e Exagero do Traço ---\n")
  mod2a <- lm(zbar_males ~ z_Nestedness * tipo_selecao + z_SigmaP + f_encounters,
              data = df_stats_low)
  print(summary(mod2a))

  cat("\n--- MODELO 2b (sigma_p >= 1.0): Aninhamento e Exagero do Traço ---\n")
  mod2b <- lm(zbar_males ~ z_Nestedness * tipo_selecao + z_SigmaP + f_encounters,
              data = df_stats_high)
  print(summary(mod2b))

  cat("\n--- MODELO 3a (sigma_p <= 1.0): Is ~ Centralização + Modularidade ---\n")
  mod3a <- lm(I_s ~ z_Centralization + z_Modularity + z_SigmaP + tipo_selecao + f_encounters,
              data = df_stats_low)
  print(summary(mod3a))

  cat("\n--- MODELO 3b (sigma_p >= 1.0): Is ~ Centralização + Modularidade ---\n")
  mod3b <- lm(I_s ~ z_Centralization + z_Modularity + z_SigmaP + tipo_selecao + f_encounters,
              data = df_stats_high)
  print(summary(mod3b))

  # =====================================================================
  # MODELO SEGMENTADO: Tipping Point em sigma_p = 1.0
  # =====================================================================
  cat("\n--- MODELO SEGMENTADO: Var(z) ~ sigma_p com breakpoint em 1.0 ---\n")
  modelo_geral      <- lm(varz_males ~ sigma_p, data = df_gen50)  # baseline k=10, NS=TRUE
  modelo_segmentado <- segmented(modelo_geral, seg.Z = ~sigma_p, psi = 1.0)
  print(summary(modelo_segmentado))

} else {
  cat("O arquivo de backup ainda não foi criado. Espere a simulação rodar mais um pouco!\n")
}

