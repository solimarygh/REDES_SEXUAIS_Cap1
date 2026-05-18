# =====================================================================
# SCRIPT FASE 1: BASELINE (Modelo Nulo vs Seleção Estabilizadora)
# =====================================================================

# 1) CARREGAMOS O MOTOR MESTRE E CONFIGURAMOS AS PASTAS
source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

# Cria as subpastas: Dados, Graficos e Redes_TXT automaticamente
diretorios <- configurar_diretorios("Fase1_Baseline")

# =====================================================================
# 2) EXECUÇÃO DO EXPERIMENTO FASE 1 (BASELINE)
# =====================================================================
cat("Iniciando Fase 1: Uniform (Aleatório) vs Gaussian (Estabilizadora)...\n")

n_replicas <- 20 # (Soly) Mude para 100 para a versão final do artigo.

cenarios_fase1 <- expand.grid(
  tipo_selecao = c("uniform", "gaussian"),
  replica = 1:n_replicas
)

lista_fase1 <- list()
set.seed(2026)

for (i in 1:nrow(cenarios_fase1)) {
  if (i %% 10 == 0 || i == 1) cat("Rodando cenário", i, "de", nrow(cenarios_fase1), "\n")
  
  res <- simulate_evolution(
    generations = 50,
    tipo_selecao = cenarios_fase1$tipo_selecao[i],
    sigma_p = 1.0,         # Variação igual ao macho (Baseline)
    encounters_n = 200,    # Amostragem total!
    return_details = FALSE 
  )
  res$replica <- cenarios_fase1$replica[i]
  lista_fase1[[i]] <- res
}

df_fase1 <- bind_rows(lista_fase1)

# SALVANDO OS DADOS NA PASTA CORRETA
arquivo_dados <- file.path(diretorios$dados, "resultados_Fase1_Baseline.rds")
saveRDS(df_fase1, arquivo_dados)
cat("Simulações da Fase 1 concluídas e salvas em:", arquivo_dados, "\n")

# =====================================================================
# 3) PREPARAÇÃO DOS GRÁFICOS INTELIGENTES (Auto-etiquetados)
# =====================================================================
# Extraindo parâmetros reais dos dados para o subtítulo dinâmico
val_gens   <- max(df_fase1$generation)
val_amax   <- unique(df_fase1$encounters_n)
val_sigmap <- unique(df_fase1$sigma_p)
val_reps   <- length(unique(df_fase1$replica))

subtitulo_dinamico <- sprintf(
  "Parâmetros: %d Gerações | Amostragem (A_max): %d | Variação (σp): %.1f | Réplicas: %d", 
  val_gens, val_amax, val_sigmap, val_reps
)

tema_fase1 <- theme_light(base_size = 14) +
  theme(legend.position = "top", 
        strip.background = element_rect(fill = "gray30"),
        strip.text = element_text(color = "white", face = "bold"))

# Resumo para os plots
df_fase1_sum <- df_fase1 %>%
  group_by(generation, tipo_selecao) %>%
  summarise(
    mean_z = mean(zbar_males, na.rm=T), sd_z = sd(zbar_males, na.rm=T),
    mean_var = mean(varz_males, na.rm=T), sd_var = sd(varz_males, na.rm=T),
    mean_mod = mean(Modularity, na.rm=T), sd_mod = sd(Modularity, na.rm=T),
    mean_nest = mean(Nestedness, na.rm=T), sd_nest = sd(Nestedness, na.rm=T),
    mean_Is = mean(I_s, na.rm=T), sd_Is = sd(I_s, na.rm=T),
    mean_cent = mean(Centralization, na.rm=T), sd_cent = sd(Centralization, na.rm=T),
    .groups = "drop"
  )

# ------------------------------------------------------------
# PLOT A: Topologia e Desigualdade da Rede (Grid 2x2)
# ------------------------------------------------------------
p_fase1_topo <- df_fase1_sum %>%
  pivot_longer(cols = c(mean_mod, mean_nest, mean_Is, mean_cent), 
               names_to = "Metrica", values_to = "Valor") %>%
  mutate(Metrica = case_when(
    Metrica == "mean_mod" ~ "1. Modularidade",
    Metrica == "mean_nest" ~ "2. Aninhamento",
    Metrica == "mean_Is" ~ "3. Oportunidade de Seleção (Is)",
    Metrica == "mean_cent" ~ "4. Centralidade"
  )) %>%
  ggplot(aes(x = generation, y = Valor, color = tipo_selecao)) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~Metrica, scales = "free_y", ncol = 2) +
  scale_color_manual(
    values = c("uniform" = "gray50", "gaussian" = "#E6B800"),
    labels = c("uniform" = "Aleatória (Uniforme)", "gaussian" = "Estabilizadora (Gaussiana)")
  ) +
  labs(title = "Fase 1: Evolução Topológica da Rede Sexual", 
       subtitle = subtitulo_dinamico, # <--- A MÁGICA AQUI
       x = "Geração", y = "Valor da Métrica", color = "Regra de Acasalamento:") +
  tema_fase1

# ------------------------------------------------------------
# PLOT B: Consequências Evolutivas (Média e Variância do Traço z)
# ------------------------------------------------------------
df_fase1_evo <- df_fase1_sum %>%
  select(generation, tipo_selecao, mean_z, sd_z, mean_var, sd_var) %>%
  pivot_longer(cols = c(mean_z, mean_var), names_to = "Metrica", values_to = "Media") %>%
  mutate(Desvio = ifelse(Metrica == "mean_z", sd_z, sd_var)) %>%
  mutate(Metrica = case_when(
    Metrica == "mean_z" ~ "1. Exagero do Traço (Média z)",
    Metrica == "mean_var" ~ "2. Variância Genética (Var z)"
  ))

p_fase1_evo <- ggplot(df_fase1_evo, aes(x = generation, y = Media, color = tipo_selecao)) +
  geom_hline(data = filter(df_fase1_evo, Metrica == "1. Exagero do Traço (Média z)"),
             aes(yintercept = 5), linetype = "dashed", color = "black", alpha = 0.5) +
  geom_ribbon(aes(ymin = pmax(0, Media - Desvio), ymax = Media + Desvio, fill = tipo_selecao), alpha=0.2, color=NA) +
  geom_line(linewidth = 1.2) +
  facet_wrap(~Metrica, scales = "free_y") +
  scale_color_manual(
    values = c("uniform" = "gray50", "gaussian" = "#E6B800"),
    labels = c("uniform" = "Aleatória (Uniforme)", "gaussian" = "Estabilizadora (Gaussiana)")
  ) +
  scale_fill_manual(
    values = c("uniform" = "gray50", "gaussian" = "#E6B800"),
    labels = c("uniform" = "Aleatória (Uniforme)", "gaussian" = "Estabilizadora (Gaussiana)")
  ) +
  labs(title = "Fase 1: Evolução Fenotípica e Diversidade Genética",
       subtitle = subtitulo_dinamico, # <--- A MÁGICA AQUI
       x = "Geração", y = "Valor Evolutivo", color = "Regra de Acasalamento:", fill="Regra de Acasalamento:") +
  tema_fase1

# Exibimos os gráficos no RStudio
print(p_fase1_topo)
print(p_fase1_evo)

# =====================================================================
# 4) SALVANDO OS GRÁFICOS NAS PASTAS
# =====================================================================
arquivo_grafico_A <- file.path(diretorios$graficos, "Fase1_PlotA_Topologia.png")
arquivo_grafico_B <- file.path(diretorios$graficos, "Fase1_PlotB_Evolucao.png")

# Salvamos com fundo branco e alta resolução (DPI = 300)
ggsave(filename = arquivo_grafico_A, plot = p_fase1_topo, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(filename = arquivo_grafico_B, plot = p_fase1_evo, width = 10, height = 5, dpi = 300, bg = "white")

cat("Gráficos salvos com sucesso na pasta:", diretorios$graficos, "\n")

