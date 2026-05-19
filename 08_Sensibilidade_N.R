# =====================================================================
# SCRIPT 08: Análise de Sensibilidade ao Tamanho Populacional (N)
# =====================================================================
# Objetivo: Testar se as assinaturas topológicas observadas na Fase 4
# são robustas ao tamanho populacional (N=200 vs N=1000), ou se são
# artefatos demográficos da rede esparsa.
#
# Design para material suplementar:
#   N            : 200 vs 1000
#   tipo_selecao : uniform, gaussian, sigmoid, u-shaped (4 funções completas)
#   sigma_p      : 0.5, 2.0
#   encounters_n : 200 (condição ideal, sem ruído ecológico)
#   réplicas     : 30
#   gerações     : 50
#
# Total: 2 x 4 x 2 x 30 = 480 simulações
# =====================================================================
source("01_metricas_e_utilitarios.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

dir08 <- configurar_diretorios("Fase8_SensibilidadeN")

# =====================================================================
# DESENHO EXPERIMENTAL
# =====================================================================
cenarios <- expand.grid(
  N_pop        = c(200, 1000),
  tipo_selecao = c("uniform", "gaussian", "sigmoid", "u-shaped"),
  sigma_p      = c(0.5, 2.0),
  encounters_n = 200,
  replica      = 1:30,
  stringsAsFactors = FALSE
)

arquivo_backup <- file.path(dir08$dados, "backup_sensibilidade_N.rds")
arquivo_final  <- file.path(dir08$dados, "resultados_sensibilidade_N.rds")

if (file.exists(arquivo_backup)) {
  lista_res <- readRDS(arquivo_backup)
  cat(sprintf("Backup encontrado! %d cenários já completos.\n", sum(!sapply(lista_res, is.null))))
  if (length(lista_res) != nrow(cenarios)) length(lista_res) <- nrow(cenarios)
} else {
  set.seed(2026)
  lista_res <- vector("list", nrow(cenarios))
  cat("Nenhum backup. Iniciando do zero.\n")
}

# =====================================================================
# LOOP DE SIMULAÇÃO
# =====================================================================
for (i in 1:nrow(cenarios)) {

  if (!is.null(lista_res[[i]])) next

  if (i %% 10 == 0 || i == 1)
    cat(sprintf("Cenário %d / %d (%.1f%%)\n", i, nrow(cenarios), 100*i/nrow(cenarios)))

  N  <- cenarios$N_pop[i]

  res <- tryCatch({
    simulate_evolution(
      generations  = 50,
      N_machos     = N,
      N_femeas     = N,
      tipo_selecao = cenarios$tipo_selecao[i],
      sigma_p      = cenarios$sigma_p[i],
      encounters_n = cenarios$encounters_n[i],
      return_details = FALSE
    )
  }, error = function(e) {
    cat("Erro no cenário", i, ":", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(res)) {
    res$replica <- cenarios$replica[i]
    res$N_pop   <- N
    lista_res[[i]] <- res
  }

  if (i %% 20 == 0) saveRDS(lista_res, arquivo_backup)
}

saveRDS(lista_res, arquivo_backup)
df_sens <- bind_rows(lista_res[!sapply(lista_res, is.null)])
saveRDS(df_sens, arquivo_final)
cat(sprintf("\nConcluído! %d linhas salvas em: %s\n", nrow(df_sens), arquivo_final))

# =====================================================================
# ANÁLISE E GRÁFICOS (Geração 50)
# =====================================================================

backup <- readRDS("Resultados_Artigo/Fase8_SensibilidadeN/Dados/backup_sensibilidade_N.rds")
df_sens <- bind_rows(backup[!sapply(backup, is.null)])

table(df_sens$tipo_selecao) ### no inclui la sigmoinal....:/

# Preparar para gráficos
df_gen50 <- df_sens %>%
  filter(generation == 50) %>% drop_na() %>%
  mutate(
    N_label    = factor(paste0("N = ", N_pop), levels = c("N = 200", "N = 1000")),
    tipo_label = factor(tipo_selecao,
                        levels = c("uniform", "gaussian", "sigmoid", "u-shaped"),
                        labels = c("Aleatória", "Gaussiana", "Sigmoide", "Disruptiva"))
  )

cores_4 <- c("Aleatória"="gray60", "Gaussiana"="#E6B800",
             "Sigmoide"="#3BA273", "Disruptiva"="#9932CC")
tema <- theme_light(base_size=13) +
  theme(legend.position="bottom",
        strip.background=element_rect(fill="gray10"),
        strip.text=element_text(color="white", face="bold"))

# Plot 1 — Modularity
p_mod <- ggplot(df_gen50, aes(x=tipo_label, y=Modularity, color=tipo_label, fill=tipo_label)) +
  geom_boxplot(alpha=0.3, outlier.size=0.8) +
  facet_grid(N_label ~ factor(sigma_p, labels=c("σp = 0.5","σp = 2.0"))) +
  scale_color_manual(values=cores_4) + scale_fill_manual(values=cores_4) +
  labs(title="Sensibilidade ao N: Modularidade", x="", y="Modularity (Louvain)", color="", fill="") + tema

# Plot 2 — Varz
p_varz <- ggplot(df_gen50, aes(x=tipo_label, y=varz_males, color=tipo_label, fill=tipo_label)) +
  geom_boxplot(alpha=0.3, outlier.size=0.8) +
  facet_grid(N_label ~ factor(sigma_p, labels=c("σp = 0.5","σp = 2.0"))) +
  scale_color_manual(values=cores_4) + scale_fill_manual(values=cores_4) +
  labs(title="Sensibilidade ao N: Diversidade Genética", x="", y="Var(z) machos", color="", fill="") + tema

# Plot 3 — zbar
p_zbar <- ggplot(df_gen50, aes(x=tipo_label, y=zbar_males, color=tipo_label, fill=tipo_label)) +
  geom_boxplot(alpha=0.3, outlier.size=0.8) +
  geom_hline(yintercept=5.0, linetype="dashed", alpha=0.5) +
  facet_grid(N_label ~ factor(sigma_p, labels=c("σp = 0.5","σp = 2.0"))) +
  scale_color_manual(values=cores_4) + scale_fill_manual(values=cores_4) +
  labs(title="Sensibilidade ao N: Exagero do Traço", x="", y="Média z machos", color="", fill="") + tema

# Salvar
out <- "Resultados_Artigo/Fase8_SensibilidadeN/Graficos/"
ggsave(paste0(out,"Sens_N_Modularity.png"), p_mod, width=9, height=7, dpi=300, bg="white")
ggsave(paste0(out,"Sens_N_VarZ.png"), p_varz, width=9, height=7, dpi=300, bg="white")
ggsave(paste0(out,"Sens_N_ZbarMachos.png"), p_zbar, width=9, height=7, dpi=300, bg="white")
cat("Listo!\n")

# ---- MÉTRICAS DE REDE ADICIONAIS ----

# Plot 4 — Nestedness (NODF)
p_nest <- ggplot(df_gen50, aes(x=tipo_label, y=Nestedness, color=tipo_label, fill=tipo_label)) +
  geom_boxplot(alpha=0.3, outlier.size=0.8) +
  facet_grid(N_label ~ factor(sigma_p, labels=c("σp = 0.5","σp = 2.0"))) +
  scale_color_manual(values=cores_4) + scale_fill_manual(values=cores_4) +
  labs(title="Sensibilidade ao N: Aninhamento (NODF)",
       x="", y="Nestedness", color="", fill="") + tema

# Plot 5 — Centralization
p_cent <- ggplot(df_gen50, aes(x=tipo_label, y=Centralization, color=tipo_label, fill=tipo_label)) +
  geom_boxplot(alpha=0.3, outlier.size=0.8) +
  facet_grid(N_label ~ factor(sigma_p, labels=c("σp = 0.5","σp = 2.0"))) +
  scale_color_manual(values=cores_4) + scale_fill_manual(values=cores_4) +
  labs(title="Sensibilidade ao N: Centralização",
       x="", y="Degree Centralization", color="", fill="") + tema

# Plot 6 — Is (Opportunity for Sexual Selection)
p_is <- ggplot(df_gen50, aes(x=tipo_label, y=I_s, color=tipo_label, fill=tipo_label)) +
  geom_boxplot(alpha=0.3, outlier.size=0.8) +
  facet_grid(N_label ~ factor(sigma_p, labels=c("σp = 0.5","σp = 2.0"))) +
  scale_color_manual(values=cores_4) + scale_fill_manual(values=cores_4) +
  labs(title="Sensibilidade ao N: Oportunidade de Seleção Sexual",
       x="", y=expression(I[s]), color="", fill="") + tema

# Mostrar e salvar
print(p_nest); print(p_cent); print(p_is)
ggsave(paste0(out,"Sens_N_Nestedness.png"), p_nest, width=9, height=7, dpi=300, bg="white")
ggsave(paste0(out,"Sens_N_Centralization.png"), p_cent, width=9, height=7, dpi=300, bg="white")
ggsave(paste0(out,"Sens_N_Is.png"), p_is, width=9, height=7, dpi=300, bg="white")
