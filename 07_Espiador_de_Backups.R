# =====================================================================
# SCRIPT 07: O Espião de Backups (Acompanhamento em Tempo Real)
# =====================================================================
library(dplyr)
library(tidyr)
library(ggplot2)

arquivo <- "Resultados_Artigo/Fase4_TodasAsCurvas/Dados/backup_lista_fase4_final.rds"

if(file.exists(arquivo)) {
  lista_parcial <- readRDS(arquivo)
  df_parcial <- bind_rows(lista_parcial[!sapply(lista_parcial, is.null)])

  n_completos <- sum(!sapply(lista_parcial, is.null))
  n_total <- length(lista_parcial)
  cat(sprintf("Espiando! Cenários completos: %d / %d (%.1f%%)\n",
              n_completos, n_total, 100 * n_completos / n_total))
  cat(sprintf("Linhas no df_parcial: %d  |  Réplicas equivalentes: %.1f\n",
              nrow(df_parcial), nrow(df_parcial) / 50))

  df_gen50 <- df_parcial %>% filter(generation == 50) %>% drop_na() %>%
    mutate(Cenario_Ecol = factor(paste0("A_max: ", encounters_n),
                                 levels = c("A_max: 500", "A_max: 100", "A_max: 25")))

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

} else {
  cat("O arquivo de backup ainda não foi criado. Espere a simulação rodar mais um pouco!\n")
}