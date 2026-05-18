# =====================================================================
# SCRIPT 07: O Espião de Backups (Acompanhamento em Tempo Real)
# =====================================================================
library(dplyr)
library(tidyr)
library(ggplot2)

# Ajuste o caminho se necessário (ex: "Resultados_Artigo/Fase4_TodasAsCurvas/Dados/backup_lista_fase4.rds")
arquivo <- "Resultados_Artigo/Fase4_TodasAsCurvas/Dados/backup_lista_fase4.rds"

if(file.exists(arquivo)) {
  lista_parcial <- readRDS(arquivo)
  df_parcial <- bind_rows(lista_parcial[!sapply(lista_parcial, is.null)])
  cat("Espiando! Réplicas completas até o momento:", nrow(df_parcial) / 50, "\n")
  
  df_gen50 <- df_parcial %>% filter(generation == 50) %>% drop_na() %>%
    mutate(Cenario_Ecol = factor(paste0("A_max: ", encounters_n), levels = c("A_max: 200", "A_max: 100", "A_max: 20")))
  
  cores_4 <- c("uniform"="gray60", "gaussian"="#E6B800", "sigmoid"="#3BA273", "u-shaped"="#9932CC")
  
  # Gráfico Rápido de Variância Genética
  p_espiao <- ggplot(df_gen50, aes(x = sigma_p, y = varz_males, color = tipo_selecao, fill = tipo_selecao)) +
    geom_vline(xintercept = 1.0, linetype = "dashed", color = "red") +
    geom_smooth(method = "loess", formula = y~x, alpha = 0.15) +
    facet_wrap(~Cenario_Ecol) +
    scale_color_manual(values = cores_4) + scale_fill_manual(values = cores_4) +
    labs(title = "ESPIADINHA: Diversidade Genética (Var z) em Tempo Real", x = expression(sigma[p]), y = "Var(z)") +
    theme_light() + theme(legend.position = "bottom")
  
  print(p_espiao)
} else {
  cat("O arquivo de backup ainda não foi criado. Espere a simulação rodar mais um pouco!\n")
}