# =====================================================================
# SCRIPT FASE 3: O Custo de Amostragem Ecológica (Ruído vs Assortative Mating)
# =====================================================================
# Los modelos de Fisher clásicamente asumen que expresar preferencia tiene un costo (tiempo de búsqueda = 1/encounters_n en tu caso). ¿Esto está modelado explícitamente como costo de fitness femenino, o solo como restricción de muestreo?
# # NOTA E LÓGICA DO EXPERIMENTO:
# Nesta fase, vamos comparar APENAS a preferência Gaussiana frente à Uniforme (Modelo Nulo). 
#
# Por quê? 
# Porque já demonstramos na Fase 2 que a Gaussiana consegue "resgatar" a 
# diversidade genética quando a variação nas fêmeas é alta (sigma_p = 2.0). 
# Agora, na Fase 3, vamos submeter esse resgate a um teste de estresse ecológico: reduziremos a capacidade de amostragem das fêmeas (A_max) 
# de 200 para apenas 20 machos. A hipótese é que o ruído ecológico 
# destruirá a topologia da rede e o resgate da variância colapsará.
#
# O que este script faz estruturalmente:
# 1. Cria a própria pasta (Resultados_Artigo/Fase3_CustosDeAmostragem/).
# 2. Filtra os resultados focando no destino evolutivo (Geração 50).
# 3. Gera subtítulos dinâmicos lendo os parâmetros do dataframe.
# 4. Gera os gráficos com o eixo X invertido (lendo a degradação 
#    de 200 para 20) e salva os PNGs automaticamente na pasta de Gráficos.
#    
#    El costo está modelado explícitamente como un costo de oportunidad ecológica (sampling cost / ecological noise) a través del parámetro Amax. Si Amax es bajo (ej. 20), la hembra gasta su 'tiempo' y se ve forzada a aparearse sub-óptimamente (con el último macho). En la naturaleza, esto equivale a que la búsqueda prolongada aumenta el riesgo de depredación o agota la energía, obligando a las hembras a reducir su exigencia efectiva. Lo medimos ecológicamente, no como una penalidad directa de mortalidad."
# =====================================================================

# 1) CARREGAMOS O MOTOR MESTRE E CONFIGURAMOS AS PASTAS
source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

# Cria as subpastas automaticamente
diretorios <- configurar_diretorios("Fase3_CustosDeAmostragem")

# =====================================================================
# 2) EXECUÇÃO DO EXPERIMENTO FASE 3
# =====================================================================
cat("Iniciando Fase 3: Avaliando a degradação pelo custo de amostragem (A_max)...\n")

# Fixamos a variação da fêmea no máximo (onde a rede da Fase 2 foi mais forte)
sigma_p_fixo <- 2.0 
n_replicas <- 20 # (Soly) Mude para 100 na versão final!

cenarios_fase3 <- expand.grid(
  tipo_selecao = c("uniform", "gaussian"), # Comparamos apenas com o Nulo
  encounters_n = c(200, 100, 50, 20),      # O Gradiente de restrição ecológica
  replica = 1:n_replicas
)

lista_fase3 <- list()
set.seed(2026)

for (i in 1:nrow(cenarios_fase3)) {
  if (i %% 10 == 0 || i == 1) cat("Rodando cenário", i, "de", nrow(cenarios_fase3), "\n")
  
  res <- simulate_evolution(
    generations = 50,
    tipo_selecao = cenarios_fase3$tipo_selecao[i],
    sigma_p = sigma_p_fixo, 
    encounters_n = cenarios_fase3$encounters_n[i], 
    return_details = FALSE 
  )
  res$replica <- cenarios_fase3$replica[i]
  lista_fase3[[i]] <- res
}

df_fase3 <- bind_rows(lista_fase3)

# SALVANDO OS DADOS NA PASTA CORRETA
arquivo_dados <- file.path(diretorios$dados, "resultados_Fase3_Custos.rds")
saveRDS(df_fase3, arquivo_dados)
cat("Simulações da Fase 3 concluídas e salvas em:", arquivo_dados, "\n")

# =====================================================================
# 3) PREPARAÇÃO DOS GRÁFICOS INTELIGENTES (Geração 50)
# =====================================================================
df_gen50_fase3 <- df_fase3 %>% filter(generation == 50) %>% drop_na()

# Extraindo parâmetros reais para o subtítulo dinâmico
val_gens   <- max(df_fase3$generation)
val_sigmap <- unique(df_fase3$sigma_p)
val_reps   <- length(unique(df_fase3$replica))

subtitulo_dinamico <- sprintf(
  "Parâmetros: %d Gerações | σp Fixo: %.1f | Amostragem: 200 a 20 | Réplicas: %d", 
  val_gens, val_sigmap, val_reps
)

tema_custos <- theme_light(base_size = 14) +
  theme(legend.position = "top",
        strip.background = element_rect(fill = "gray20"),
        strip.text = element_text(color = "white", face = "bold"))

cores_fase3 <- c("uniform" = "gray50", "gaussian" = "#E6B800")
labels_fase3 <- c("uniform" = "Aleatória (Uniforme)", "gaussian" = "Estabilizadora (Gaussiana)")

# ---------------------------------------------------------------------
# PLOT A: A Queda da Topologia da Rede (Grid 2x2)
# ---------------------------------------------------------------------
p_fase3_rede <- df_gen50_fase3 %>%
  pivot_longer(cols = c(Modularity, Nestedness, I_s, Centralization), 
               names_to = "Metrica", values_to = "Valor") %>%
  mutate(Metrica = case_when(
    Metrica == "Modularity" ~ "1. Modularidade (Assortative)",
    Metrica == "Nestedness" ~ "2. Aninhamento",
    Metrica == "I_s" ~ "3. Oportunidade de Seleção (Is)",
    Metrica == "Centralization" ~ "4. Centralização"
  )) %>%
  ggplot(aes(x = encounters_n, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
  geom_smooth(method = "loess", formula = y ~ x, alpha = 0.2, linewidth = 1.2) +
  geom_jitter(alpha = 0.3, width = 2, size = 1.5) +
  facet_wrap(~Metrica, scales = "free_y", ncol = 2) +
  scale_color_manual(values = cores_fase3, labels = labels_fase3) +
  scale_fill_manual(values = cores_fase3, labels = labels_fase3) +
  labs(title = "Fase 3: A Degradação da Topologia pelo Custo de Busca",
       subtitle = subtitulo_dinamico,
       x = "Máximo de Machos Avaliados (A_max)",
       y = "Valor da Métrica", color = "Regra:", fill = "Regra:") +
  scale_x_reverse(breaks = c(200, 100, 50, 20)) + # Invertemos o Eixo X
  tema_custos

# ---------------------------------------------------------------------
# PLOT B: A Perda da Variância Genética (Efeito Ecológico vs Evolutivo)
# ---------------------------------------------------------------------
p_fase3_evo <- df_gen50_fase3 %>%
  pivot_longer(cols = c(zbar_males, varz_males), 
               names_to = "Variavel", values_to = "Valor") %>%
  mutate(Variavel = case_when(
    Variavel == "zbar_males" ~ "1. Exagero do Traço (Média z)",
    Variavel == "varz_males" ~ "2. Diversidade Genética (Var z)"
  )) %>%
  ggplot(aes(x = encounters_n, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
  geom_hline(data = filter(data.frame(Variavel = "1. Exagero do Traço (Média z)"), Variavel == "1. Exagero do Traço (Média z)"),
             aes(yintercept = 5), linetype = "dashed", color = "black", alpha = 0.5) +
  geom_smooth(method = "loess", formula = y ~ x, alpha = 0.2, linewidth = 1.2) +
  geom_jitter(alpha = 0.3, width = 2, size = 1.5) +
  facet_wrap(~Variavel, scales = "free_y") +
  scale_color_manual(values = cores_fase3, labels = labels_fase3) +
  scale_fill_manual(values = cores_fase3, labels = labels_fase3) +
  labs(title = "Fase 3: O Colapso das Consequências Evolutivas",
       subtitle = "Sem amostragem adequada, a seleção estabilizadora falha em manter a variação",
       x = "Máximo de Machos Avaliados (A_max)",
       y = "Valor Fenotípico / Genético", color = "Regra:", fill = "Regra:") +
  scale_x_reverse(breaks = c(200, 100, 50, 20)) +
  tema_custos

# Exibe os Gráficos
print(p_fase3_rede)
print(p_fase3_evo)

# =====================================================================
# 4) SALVANDO OS GRÁFICOS NAS PASTAS
# =====================================================================
arquivo_grafico_A <- file.path(diretorios$graficos, "Fase3_PlotA_Topologia.png")
arquivo_grafico_B <- file.path(diretorios$graficos, "Fase3_PlotB_Evolucao.png")

ggsave(filename = arquivo_grafico_A, plot = p_fase3_rede, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(filename = arquivo_grafico_B, plot = p_fase3_evo, width = 10, height = 5, dpi = 300, bg = "white")

cat("Gráficos salvos com sucesso na pasta:", diretorios$graficos, "\n")