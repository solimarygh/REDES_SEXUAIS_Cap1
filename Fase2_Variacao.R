# =====================================================================
# SCRIPT FASE 2: O Gradiente de Variação (Uniforme vs Gaussiana)
# =====================================================================

# 1) CARREGAMOS O MOTOR MESTRE E CONFIGURAMOS AS PASTAS
source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

# Cria as subpastas automaticamente
diretorios <- configurar_diretorios("Fase2_TippingPoints")

# =====================================================================
# 2) EXECUÇÃO DO EXPERIMENTO FASE 2
# =====================================================================
cat("Iniciando Fase 2: O Efeito da Variação da Preferência (sigma_p)...\n")

valores_sigma_p <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
n_replicas <- 20 # (Soly) Mude para 100 na versão final!

cenarios_fase2 <- expand.grid(
  tipo_selecao = c("uniform", "gaussian"),
  sigma_p = valores_sigma_p,
  replica = 1:n_replicas
)

lista_fase2 <- list()
set.seed(2026)

for (i in 1:nrow(cenarios_fase2)) {
  if (i %% 10 == 0 || i == 1) cat("Rodando cenário", i, "de", nrow(cenarios_fase2), "\n")
  
  res <- simulate_evolution(
    generations = 50,
    tipo_selecao = cenarios_fase2$tipo_selecao[i],
    sigma_p = cenarios_fase2$sigma_p[i],
    encounters_n = 200,    # A fêmea avalia todos
    return_details = FALSE 
  )
  res$replica <- cenarios_fase2$replica[i]
  lista_fase2[[i]] <- res
}

df_fase2 <- bind_rows(lista_fase2)

# SALVANDO OS DADOS NA PASTA CORRETA
arquivo_dados <- file.path(diretorios$dados, "resultados_Fase2_Variacao.rds")
saveRDS(df_fase2, arquivo_dados)
cat("Simulações da Fase 2 concluídas e salvas em:", arquivo_dados, "\n")

# =====================================================================
# 3) PREPARAÇÃO DOS GRÁFICOS INTELIGENTES
# =====================================================================
df_gen50_fase2 <- df_fase2 %>% filter(generation == 50) %>% drop_na()

# Extraindo parâmetros reais para o subtítulo dinâmico
val_gens <- max(df_fase2$generation)
val_amax <- unique(df_fase2$encounters_n)
val_reps <- length(unique(df_fase2$replica))

subtitulo_dinamico <- sprintf(
  "Parâmetros: %d Gerações | Amostragem (A_max): %d | σp: Gradiente (0.2 a 2.0) | Réplicas: %d", 
  val_gens, val_amax, val_reps
)

tema_sigma <- theme_light(base_size = 14) +
  theme(legend.position = "top",
        strip.background = element_rect(fill = "gray20"),
        strip.text = element_text(color = "white", face = "bold"))

cores_fase2 <- c("uniform" = "gray50", "gaussian" = "#E6B800")
labels_fase2 <- c("uniform" = "Aleatória (Uniforme)", "gaussian" = "Estabilizadora (Gaussiana)")

# ---------------------------------------------------------------------
# PLOT A: O Efeito na Topologia da Rede (Grid 2x2)
# ---------------------------------------------------------------------
p_fase2_rede <- df_gen50_fase2 %>%
  pivot_longer(cols = c(Modularity, Nestedness, I_s, Centralization), 
               names_to = "Metrica", values_to = "Valor") %>%
  mutate(Metrica = case_when(
    Metrica == "Modularity" ~ "1. Modularidade (Assortative)",
    Metrica == "Nestedness" ~ "2. Aninhamento (Hierarquia)",
    Metrica == "I_s" ~ "3. Oportunidade de Seleção (Is)",
    Metrica == "Centralization" ~ "4. Centralização da Rede"
  )) %>%
  ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_smooth(method = "loess", alpha = 0.2, linewidth = 1.2) +
  geom_jitter(alpha = 0.2, width = 0.05, size = 1.5) +
  facet_wrap(~Metrica, scales = "free_y", ncol = 2) +
  scale_color_manual(values = cores_fase2, labels = labels_fase2) +
  scale_fill_manual(values = cores_fase2, labels = labels_fase2) +
  labs(title = "Fase 2: O Impacto da Variação Feminina na Topologia da Rede",
       subtitle = subtitulo_dinamico,
       x = expression(paste("Variação da Preferência das Fêmeas (", sigma[p], ")")),
       y = "Valor da Métrica", color = "Regra:", fill = "Regra:") +
  annotate("text", x = 1.05, y = Inf, label = "sigma[p] == sigma[z]", parse = TRUE, color="red", hjust=0, vjust=2) +
  tema_sigma

# ---------------------------------------------------------------------
# PLOT B: O Efeito na Evolução do Traço Masculino
# ---------------------------------------------------------------------
p_fase2_evo <- df_gen50_fase2 %>%
  pivot_longer(cols = c(zbar_males, varz_males), 
               names_to = "Variavel", values_to = "Valor") %>%
  mutate(Variavel = case_when(
    Variavel == "zbar_males" ~ "1. Exagero do Traço (Média z)",
    Variavel == "varz_males" ~ "2. Resgate da Diversidade Genética (Var z)"
  )) %>%
  ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
  geom_hline(data = filter(data.frame(Variavel = "1. Exagero do Traço (Média z)"), Variavel == "1. Exagero do Traço (Média z)"),
             aes(yintercept = 5), linetype = "dashed", color = "black", alpha = 0.5) +
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_smooth(method = "loess", alpha = 0.2, linewidth = 1.2) +
  geom_jitter(alpha = 0.3, width = 0.05, size = 1.5) +
  facet_wrap(~Variavel, scales = "free_y") +
  scale_color_manual(values = cores_fase2, labels = labels_fase2) +
  scale_fill_manual(values = cores_fase2, labels = labels_fase2) +
  labs(title = "Fase 2: Consequências Evolutivas a Longo Prazo (Ger. 50)",
       subtitle = subtitulo_dinamico,
       x = expression(paste("Variação da Preferência das Fêmeas (", sigma[p], ")")),
       y = "Valor Fenotípico/Genético", color = "Regra:", fill = "Regra:") +
  tema_sigma

print(p_fase2_rede)
print(p_fase2_evo)

# =====================================================================
# 4) SALVANDO OS GRÁFICOS NAS PASTAS
# =====================================================================
arquivo_grafico_A <- file.path(diretorios$graficos, "Fase2_PlotA_Topologia.png")
arquivo_grafico_B <- file.path(diretorios$graficos, "Fase2_PlotB_Evolucao.png")

ggsave(filename = arquivo_grafico_A, plot = p_fase2_rede, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(filename = arquivo_grafico_B, plot = p_fase2_evo, width = 10, height = 5, dpi = 300, bg = "white")

cat("Gráficos salvos com sucesso na pasta:", diretorios$graficos, "\n")

