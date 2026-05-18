# =====================================================================
# SCRIPT FASE 4: O Grand Finale (Os 4 Titãs, Ruído Ecológico e Correlações)
# =====================================================================
# 📌 NOTA ECOLÓGICA E LÓGICA DO EXPERIMENTO:
# Nesta fase final, vamos comparar SIMULTANEAMENTE as 4 curvas de preferência:
# Uniforme (Nula), Gaussiana (Estabilizadora), Sigmoide (Direcional) e 
# U-shaped (Disruptiva).
#
# Por quê? 
# 1. Para mapear a "Assinatura Topológica" de cada regime: Provaremos que a 
#    Sigmoide maximiza o Aninhamento (gerando o Fisherian Runaway) e a U-shaped 
#    maximiza a Modularidade por desassortatividade, resgatando a variância.
# 2. Para testar o "Ruído Ecológico": Avaliaremos essas 4 curvas sob 3 
#    restrições de amostragem (A_max = 200, 100 e 20) para demonstrar que o 
#    ruído destrói as assinaturas topológicas e neutraliza a evolução.
# 3. Para fazer a "Prova Causal": Congelaremos a genética (fixando sigma_p = 2.0)
#    e faremos regressões lineares diretas (Topologia vs Evolução) para provar 
#    que a arquitetura da rede é o verdadeiro motor da mudança fenotípica.
#
# ⚙️ O que este script faz estruturalmente:
# 1. Cria a pasta Resultados_Artigo/Fase4_TodasAsCurvas/.
# 2. Roda um LOOP GIGANTE com sistema de BACKUP AUTOMÁTICO (salva a cada 20 
#    réplicas para evitar perda de dados por quedas de energia).
# 3. Gera e exporta os gráficos finais com subtítulos dinâmicos.
# =====================================================================

# 1) CARREGAMOS O MOTOR MESTRE E CONFIGURAMOS AS PASTAS
source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

diretorios <- configurar_diretorios("Fase4_TodasAsCurvas")

# =====================================================================
# 2) DESENHO EXPERIMENTAL E SISTEMA DE BACKUP A PROVA DE BALAS
# =====================================================================
cat("Iniciando Fase 4: O Confronto dos 4 Titãs Evolutivos...\n")

valores_sigma_p <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
n_replicas <- 100

cenarios_fase4 <- expand.grid(
  tipo_selecao = c("uniform", "gaussian", "sigmoid", "u-shaped"),
  sigma_p = valores_sigma_p,
  encounters_n = c(200, 100, 20), 
  replica = 1:n_replicas
)

# ---------------------------------------------------------------------
# A CORREÇÃO DAS PASTAS ESTÁ AQUI:
# Forçamos os arquivos a morarem na subpasta "Dados" da Fase 4
# ---------------------------------------------------------------------
arquivo_backup <- file.path(diretorios$dados, "backup_lista_fase4_final.rds")
arquivo_final  <- file.path(diretorios$dados, "resultados_Fase4_Final.rds")

if (file.exists(arquivo_backup)) {
  lista_fase4 <- readRDS(arquivo_backup)
  cat("Backup encontrado! Retomando as simulações...\n")
  
  # Bug 4 Corrigido: Só ajusta o tamanho se houver divergência.
  # (Se por algum motivo o backup ficou maior, truncava silenciosamente. Adicionei a verificação).
  if (length(lista_fase4) != nrow(cenarios_fase4)) {
    length(lista_fase4) <- nrow(cenarios_fase4) 
  }
} else {
  # Bug 3 Corrigido: O set.seed só roda se começarmos do zero! 
  # En el contexto de un IBM esto probablemente no es crítico (cada simulación es independente), 
  # pero afecta la reproducibilidad exacta de las simulaciones reanudadas. 
  # Movi o set.seed(2026) para que solo se ejecute cuando no hay backup.
  set.seed(2026) 
  
  lista_fase4 <- vector("list", nrow(cenarios_fase4))
  cat("Nenhum backup encontrado. Iniciando do zero.\n")
}
# =====================================================================
# 3) LOOP DE SIMULAÇÃO (Pode pausar e retomar quando quiser)
# =====================================================================
for (i in 1:nrow(cenarios_fase4)) {
  
  if (!is.null(lista_fase4[[i]])) next # Resume mágico: Pula o que já está pronto
  
  if (i %% 20 == 0 || i == 1) cat(sprintf("Rodando cenário %d de %d (%.1f%%)\n", i, nrow(cenarios_fase4), (i/nrow(cenarios_fase4))*100))
  
  res <- tryCatch({
    simulate_evolution(
      generations = 50,
      tipo_selecao = cenarios_fase4$tipo_selecao[i],
      sigma_p = cenarios_fase4$sigma_p[i],
      encounters_n = cenarios_fase4$encounters_n[i],
      return_details = FALSE
    )
  }, error = function(e) {
    cat("Erro no cenário", i, ":", conditionMessage(e), "\n")
    return(NULL) 
  })
  
  if (!is.null(res)) {
    res$replica <- cenarios_fase4$replica[i]
    lista_fase4[[i]] <- res
  }
  
  # Salva o backup no HD a cada 20 cenários
  if (i %% 20 == 0) saveRDS(lista_fase4, arquivo_backup)
}

# Exportação Final
saveRDS(lista_fase4, arquivo_backup)
df_fase4 <- bind_rows(lista_fase4[!sapply(lista_fase4, is.null)])
saveRDS(df_fase4, arquivo_final)
cat("\nFase 4 concluída com sucesso! Dados salvos em:", arquivo_final, "\n")

# =====================================================================
# 4) PREPARAÇÃO DOS GRÁFICOS (Geração 50)
# =====================================================================
df_gen50 <- df_fase4 %>% filter(generation == 50) %>% drop_na()

val_gens <- max(df_fase4$generation)
val_reps <- length(unique(df_fase4$replica))
subtitulo_base <- sprintf("Parâmetros: %d Gerações | Réplicas: %d", val_gens, val_reps)

tema_master <- theme_light(base_size = 14) +
  theme(legend.position = "bottom",
        strip.background = element_rect(fill = "gray10"),
        strip.text = element_text(color = "white", face = "bold"))

cores_4 <- c("uniform" = "gray60", "gaussian" = "#E6B800", "sigmoid" = "#3BA273", "u-shaped" = "#9932CC")
labels_4 <- c("uniform" = "Aleatória", "gaussian" = "Gaussiana", "sigmoid" = "Sigmoide", "u-shaped" = "Disruptiva")

# ---------------------------------------------------------------------
# PLOT A: ASSINATURA TOPOLÓGICA (Apenas cenário ideal: A_max = 200)
# ---------------------------------------------------------------------
p_fase4_topo <- df_gen50 %>% filter(encounters_n == 200) %>%
  pivot_longer(cols = c(Modularity, Nestedness, I_s, Centralization), names_to = "Metrica", values_to = "Valor") %>%
  mutate(Metrica = case_when(Metrica == "Modularity" ~ "1. Modularidade", Metrica == "Nestedness" ~ "2. Aninhamento",
                             Metrica == "I_s" ~ "3. Is", Metrica == "Centralization" ~ "4. Centralidade")) %>%
  ggplot(aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_smooth(method = "loess", formula = y~x, alpha = 0.15, linewidth = 1.2, show.legend = FALSE) +
  geom_jitter(alpha = 0.2, width = 0.05, size = 1.2) +
  facet_wrap(~Metrica, scales = "free_y", ncol=2) +
  scale_color_manual(values = cores_4, labels = labels_4) + scale_fill_manual(values = cores_4, labels = labels_4) +
  labs(title = "Fase 4: A Assinatura Topológica Suprema (A_max = 200)", subtitle = subtitulo_base,
       x = expression(paste("Variação da Preferência (", sigma[p], ")")), y = "Valor da Métrica", color = "", fill="") +
  guides(color = guide_legend(override.aes = list(size = 3, alpha = 1))) + tema_master

# ---------------------------------------------------------------------
# PLOT B: RUÍDO ECOLÓGICO - A Queda da Evolução (A_max: 200, 100, 20)
# ---------------------------------------------------------------------
df_ruido <- df_gen50 %>% mutate(Cenario_Ecol = factor(paste0("A_max: ", encounters_n), 
                                                      levels = c("A_max: 200", "A_max: 100", "A_max: 20"))) %>%
  pivot_longer(cols = c(zbar_males, varz_males), names_to = "Variavel", values_to = "Valor") %>%
  mutate(Variavel = ifelse(Variavel == "zbar_males", "1. Média (Exagero)", "2. Diversidade Genética (Var z)"))

p_fase4_ruido <- ggplot(df_ruido, aes(x = sigma_p, y = Valor, color = tipo_selecao, fill = tipo_selecao)) +
  geom_hline(data = filter(df_ruido, Variavel == "1. Média (Exagero)"), aes(yintercept = 5.0), linetype = "dashed", alpha = 0.6) + #5.0 ES la variable \phi de nuestro modelo ecológico! 
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "red", linewidth = 1) +
  geom_smooth(method = "loess", formula = y~x, alpha = 0.15, linewidth = 1.2, show.legend = FALSE) +
  geom_jitter(alpha = 0.2, width = 0.05, size = 1) +
  facet_grid(Variavel ~ Cenario_Ecol, scales = "free_y") +
  scale_color_manual(values = cores_4, labels = labels_4) + scale_fill_manual(values = cores_4, labels = labels_4) +
  labs(title = "Fase 4: O Colapso Ecológico das Forças Evolutivas", subtitle = "Lendo da esq. para a dir.: O custo de busca neutraliza a seleção sexual",
       x = expression(paste("Variação da Preferência (", sigma[p], ")")), y = "Valor Fenotípico / Genético", color = "", fill="") +
  guides(color = guide_legend(override.aes = list(size = 3, alpha = 1))) + tema_master

# ---------------------------------------------------------------------
# PLOT C: A PROVA CAUSAL (A_max = 200, sigma_p fixo em 2.0)
# ---------------------------------------------------------------------
df_causal <- df_gen50 %>% filter(encounters_n == 200, sigma_p == 2.0) %>%
  pivot_longer(cols = c(Modularity, Nestedness), names_to = "Topologia", values_to = "EixoX") %>%
  mutate(Topologia = ifelse(Topologia == "Modularity", "1. Modularidade (vs Var z)", "2. Aninhamento (vs Média z)"),
         EixoY = ifelse(Topologia == "1. Modularidade (vs Var z)", varz_males, zbar_males))

p_fase4_causal <- ggplot(df_causal, aes(x = EixoX, y = EixoY, color = tipo_selecao, fill = tipo_selecao)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", formula = y~x, se = TRUE, linewidth = 1.2, alpha = 0.15, show.legend = FALSE) +
  facet_wrap(~Topologia, scales = "free", ncol=2) +
  scale_color_manual(values = cores_4, labels = labels_4) + scale_fill_manual(values = cores_4, labels = labels_4) +
  labs(title = "Fase 4: Evidência Correlacional entre Topologia e Evolução (σp = 2.0)", subtitle = "Regressões lineares indicam forte associação entre a estrutura da rede e o fenótipo",
       x = "Valor Topológico da Rede", y = "Valor Evolutivo (Média ou Variância)", color="", fill="") +
  guides(color = guide_legend(override.aes = list(size = 3, alpha = 1))) + tema_master

# Exibir
print(p_fase4_topo)
print(p_fase4_ruido)
print(p_fase4_causal)

# ---------------------------------------------------------------------
# 5) EXPORTANDO GRÁFICOS
# ---------------------------------------------------------------------
ggsave(file.path(diretorios$graficos, "Fase4_PlotA_AssinaturaTopologica.png"), plot = p_fase4_topo, width = 10, height = 8, dpi = 300, bg = "white")
ggsave(file.path(diretorios$graficos, "Fase4_PlotB_RuidoEcologico.png"), plot = p_fase4_ruido, width = 12, height = 7, dpi = 300, bg = "white")
ggsave(file.path(diretorios$graficos, "Fase4_PlotC_ProvaCausal.png"), plot = p_fase4_causal, width = 10, height = 5, dpi = 300, bg = "white")
cat("\nGráficos salvos com sucesso na pasta:", diretorios$graficos, "\n")


# =====================================================================
# BLOCO E: MODELOS lineares (LMs) - Antes eram mixtos, mas nao preciso
# =====================================================================
# 
# había un error gravísimo que cometimos en la estadística: al usar (1 | replica), le estábamos diciendo a R que la "réplica 1" de la selección Sigmoide era la misma población que la "réplica 1" de la selección Gaussiana. ¡Eso es falso, son poblaciones distintas!
# Carregamos os pacotes mistos 
# suppressPackageStartupMessages({
#   library(lme4)
#   library(lmerTest) 
# })  Como estamos analizando solo la Generación 50, cada red es un punto de datos 100% independiente. Por lo tanto, no necesitamos un modelo mixto (lmer)! Un modelo lineal normal (lm) es la herramienta estadísticamente correcta y perfecta aquí. 

cat("\nPreparando dados para os Modelos..\n")

# 1. Preparamos os dados (Focamos na Geração 50, que é o destino evolutivo)
# Escalamos as variáveis contínuas (Z-score) para que os coeficientes sejam comparáveis
# Nota: o Z-score é calculado dentro de cada subconjunto para que seja comparável internamente.

df_stats_low <- df_gen50 %>%  # Subconjunto: sigma_p <= 1.0 (regime abaixo do limiar ecológico)
  filter(sigma_p <= 1.0) %>%
  drop_na(Modularity, Nestedness, Centralization, I_s, varz_males, zbar_males) %>%
  mutate(
    z_Modularity     = scale(Modularity),
    z_Nestedness     = scale(Nestedness),
    z_Centralization = scale(Centralization),
    z_SigmaP         = scale(sigma_p),
    f_encounters     = factor(encounters_n)
  )

df_stats_high <- df_gen50 %>%  # Subconjunto: sigma_p >= 1.0 (regime acima do limiar ecológico)
  filter(sigma_p >= 1.0) %>%
  drop_na(Modularity, Nestedness, Centralization, I_s, varz_males, zbar_males) %>%
  mutate(
    z_Modularity     = scale(Modularity),
    z_Nestedness     = scale(Nestedness),
    z_Centralization = scale(Centralization),
    z_SigmaP         = scale(sigma_p),
    f_encounters     = factor(encounters_n)
  )

# -----------------------------------------------------------------------
# MODELO 1: A Topologia resgatando a Diversidade Genética
# Interação z_Modularity * tipo_selecao: captura que Gaussiana e Disruptiva
# respondem de forma distinta à modularidade
# -----------------------------------------------------------------------
cat("\n--- MODELO 1a (sigma_p <= 1.0): Modularidade e Diversidade Genética ---\n")
mod1a <- lm(varz_males ~ z_Modularity * tipo_selecao + z_SigmaP + f_encounters, data = df_stats_low)
print(summary(mod1a))

cat("\n--- MODELO 1b (sigma_p >= 1.0): Modularidade e Diversidade Genética ---\n")
mod1b <- lm(varz_males ~ z_Modularity * tipo_selecao + z_SigmaP + f_encounters, data = df_stats_high)
print(summary(mod1b))

# -----------------------------------------------------------------------
# MODELO 2: A Topologia gerando o Exagero do Traço
# -----------------------------------------------------------------------
cat("\n--- MODELO 2a (sigma_p <= 1.0): Aninhamento e Exagero do Traço ---\n")
mod2a <- lm(zbar_males ~ z_Nestedness * tipo_selecao + z_SigmaP + f_encounters, data = df_stats_low)
print(summary(mod2a))

cat("\n--- MODELO 2b (sigma_p >= 1.0): Aninhamento e Exagero do Traço ---\n")
mod2b <- lm(zbar_males ~ z_Nestedness * tipo_selecao + z_SigmaP + f_encounters, data = df_stats_high)
print(summary(mod2b))

# -----------------------------------------------------------------------
# MODELO 3: A Origem da Oportunidade de Seleção (Is)
# -----------------------------------------------------------------------
cat("\n--- MODELO 3a (sigma_p <= 1.0): Is ~ Centralização + Modularidade ---\n")
mod3a <- lm(I_s ~ z_Centralization + z_Modularity + z_SigmaP + tipo_selecao + f_encounters, data = df_stats_low)
print(summary(mod3a))

cat("\n--- MODELO 3b (sigma_p >= 1.0): Is ~ Centralização + Modularidade ---\n")
mod3b <- lm(I_s ~ z_Centralization + z_Modularity + z_SigmaP + tipo_selecao + f_encounters, data = df_stats_high)
print(summary(mod3b))

