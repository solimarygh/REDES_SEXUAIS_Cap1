# =====================================================================
# SCRIPT 06: A Rede Representativa (a partir dos dados REAIS da Fase 5)
# Atualizado para Fase5_MiudoV2 — inclui k_fixo e selecao_natural
# =====================================================================
# Critério: réplica × geração (fase estável, gen >= 20) cuja MODULARIDADE
# é a mais próxima da MÉDIA estável do cenário dado.
# Replay RNG-fiel: replay_capturar() espelha simulate_evolution() exatamente.
# =====================================================================

source("01_metricas_e_utilitarios.R")
library(ggplot2)
library(dplyr)
library(tidyr)
library(igraph)
library(patchwork)

diretorios <- configurar_diretorios("Redes_Representativas")

# =====================================================================
# PARÂMETROS (devem coincidir EXATAMENTE com Fase4_TodasAsCurvas.R)
# =====================================================================
SEED_BASE       <- 2026
N_POP           <- 200
GEN_MAX         <- 100
GEN_BURNIN      <- 20
N_REPLICAS      <- 30
VALORES_SIGMA_P <- c(0.2, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0)
VALORES_AMAX    <- c(200, 40, 10)
TIPOS_SELECAO   <- c("uniform", "gaussian", "sigmoid", "u-shaped")
VALORES_K       <- c(5L, 10L, 20L)

# Grade idêntica à de Fase4_TodasAsCurvas.R — índice i == seed SEED_BASE+i
cenarios_fase4 <- expand.grid(
  tipo_selecao    = TIPOS_SELECAO,
  sigma_p         = VALORES_SIGMA_P,
  encounters_n    = VALORES_AMAX,
  k_fixo          = VALORES_K,
  selecao_natural = c(TRUE, FALSE),
  replica         = 1:N_REPLICAS,
  stringsAsFactors = FALSE
)

# =====================================================================
# CARREGAR DADOS DA FASE 5 (MiudoV2)
# =====================================================================
arquivo_final  <- "Resultados_Artigo/Fase5_MiudoV2/Dados/resultados_Fase5_MiudoV2.rds"
arquivo_backup <- "Resultados_Artigo/Fase5_MiudoV2/Dados/backup_lista_fase5_miudov2.rds"

if (file.exists(arquivo_final)) {
  df_fase4 <- readRDS(arquivo_final)
  cat(sprintf("Dados FINAIS carregados (%d linhas).\n", nrow(df_fase4)))
} else if (file.exists(arquivo_backup)) {
  lista_backup <- readRDS(arquivo_backup)
  df_fase4 <- bind_rows(lista_backup[!sapply(lista_backup, is.null)])
  cat(sprintf("Dados PARCIAIS (backup) carregados (%d linhas).\n", nrow(df_fase4)))
} else {
  stop("Nenhum arquivo de dados da Fase 5 encontrado. Rode Fase4_TodasAsCurvas.R primeiro.")
}

# =====================================================================
# FUNÇÃO 1: encontrar_representativa
# =====================================================================
encontrar_representativa <- function(tipo_sel, sp, am, kf, sel_nat,
                                     gen_burnin = GEN_BURNIN) {
  fase_estavel <- df_fase4 %>%
    filter(tipo_selecao    == tipo_sel,
           sigma_p         == sp,
           encounters_n    == am,
           k_fixo          == kf,
           selecao_natural == sel_nat,
           generation      >= gen_burnin) %>%
    tidyr::drop_na(Modularity)

  if (nrow(fase_estavel) == 0) return(NULL)

  mod_media <- mean(fase_estavel$Modularity, na.rm = TRUE)
  idx       <- which.min(abs(fase_estavel$Modularity - mod_media))
  escolhido <- fase_estavel[idx, ]

  i_cenario <- which(
    cenarios_fase4$tipo_selecao    == tipo_sel &
    cenarios_fase4$sigma_p         == sp &
    cenarios_fase4$encounters_n    == am &
    cenarios_fase4$k_fixo          == kf &
    cenarios_fase4$selecao_natural == sel_nat &
    cenarios_fase4$replica         == escolhido$replica
  )

  list(
    tipo_selecao     = tipo_sel,
    sigma_p          = sp,
    encounters_n     = am,
    k_fixo           = kf,
    selecao_natural  = sel_nat,
    replica          = escolhido$replica,
    geracao_alvo     = escolhido$generation,
    i_cenario        = i_cenario,
    seed             = SEED_BASE + i_cenario,
    modularity_alvo  = escolhido$Modularity,
    modularity_media = mod_media
  )
}

# =====================================================================
# FUNÇÃO 2: replay_capturar
# CRÍTICO: deve espelhar simulate_evolution() exatamente para que o
# estado do RNG coincida e a rede capturada seja a mesma dos dados.
# =====================================================================
replay_capturar <- function(seed, tipo_sel, sp, am, gen_alvo,
                            k_fixo = NULL, sel_nat = TRUE,
                            N = N_POP, generations = GEN_MAX,
                            phi = 5, gamma = 0.2, sigma_z_init = 1.0,
                            sigma_s = 0.2, eps_sd = 0.2) {
  set.seed(seed)

  male_z_gen1   <- pmax(0, rnorm(N, mean = phi, sd = sigma_z_init))
  female_p_gen1 <- pmax(0, rnorm(N, mean = phi, sd = sp))
  female_z_gen1 <- pmax(0, rnorm(N, mean = phi, sd = sigma_z_init))

  male_z_gen   <- male_z_gen1
  female_z_gen <- female_z_gen1

  captura_alvo    <- NULL
  Gen_final_dados <- NULL

  for (t in seq_len(generations)) {
    if (t == 1) {
      female_p <- female_p_gen1
    } else {
      female_p <- pmax(0, rnorm(N, mean = phi, sd = sp))
    }
    female_s <- pmax(0, rnorm(N, mean = 2, sd = sigma_s))

    # Bloco de viabilidade: idêntico ao de simulate_evolution()
    if (sel_nat) {
      V <- exp(-gamma * (male_z_gen - phi)^2)
      survive <- runif(N) <= V
      survive <- ensure_min_survivors(survive, V, min_surv = 2)
    } else {
      survive <- rep(TRUE, N)   # V_j = 1: sem consumo de RNG
    }
    male_z_surv <- male_z_gen[survive]

    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_sel,
                              encounters_n = am, k_fixo = k_fixo)

    # OBRIGATÓRIO: calc_metrics consome RNs (cluster_louvain usa RNG)
    metrics <- calc_metrics_from_M(M)

    if (t == gen_alvo) {
      captura_alvo <- list(
        Matriz_M       = M,
        male_z_surv    = male_z_surv,
        female_p       = female_p,
        geracao        = t,
        modularity     = metrics$Modularity,
        nestedness     = metrics$Nestedness,
        Is             = metrics$I_s,
        centralization = metrics$Centralization
      )
    }

    if (t == generations) {
      Gen_final_dados <- list(Z_Machos = male_z_surv, P_Femeas = female_p)
    }

    offspring    <- produce_offspring(M, male_z_surv, female_z_gen, N, N, eps_sd = eps_sd)
    male_z_gen   <- offspring$male_z_next
    female_z_gen <- offspring$female_z_next
  }

  list(
    Gen1     = list(Z_Machos = male_z_gen1, P_Femeas = female_p_gen1),
    GenAlvo  = captura_alvo,
    GenFinal = Gen_final_dados
  )
}

# =====================================================================
# FUNÇÃO 3: rodar_cenario
# =====================================================================
rodar_cenario <- function(tipo_sel, sp, am, kf, sel_nat) {

  sel_label <- ifelse(sel_nat, "NS", "noNS")
  cat(sprintf("\n>>> %s | σp=%.1f | A_max=%d | k=%d | %s\n",
              tipo_sel, sp, am, kf, sel_label))

  rep_info <- encontrar_representativa(tipo_sel, sp, am, kf, sel_nat)
  if (is.null(rep_info)) {
    cat("    Sem dados disponíveis para este cenário ainda.\n")
    return(invisible(NULL))
  }

  cat(sprintf("    Réplica %d | Geração %d | Mod=%.3f (média estável=%.3f) | seed=%d\n",
              rep_info$replica, rep_info$geracao_alvo,
              rep_info$modularity_alvo, rep_info$modularity_media, rep_info$seed))

  dados <- replay_capturar(rep_info$seed, tipo_sel, sp, am, rep_info$geracao_alvo,
                           k_fixo = kf, sel_nat = sel_nat)

  # -----------------------------------------------------------------
  # PLOT DA REDE
  # -----------------------------------------------------------------
  M   <- dados$GenAlvo$Matriz_M
  n_m <- nrow(M); n_f <- ncol(M)
  adj <- matrix(0L, n_m + n_f, n_m + n_f)
  adj[1:n_m, (n_m+1):(n_m+n_f)] <- M
  adj[(n_m+1):(n_m+n_f), 1:n_m] <- t(M)
  g_final <- igraph::graph_from_adjacency_matrix(adj, mode = "undirected")
  V(g_final)$type <- c(rep(TRUE, n_m), rep(FALSE, n_f))

  num_grupos    <- sum(round(eigen(igraph::laplacian_matrix(g_final, sparse = FALSE))$values, 5) <= 1e-7)
  comunidades   <- igraph::cluster_louvain(g_final)
  n_comunidades <- length(unique(igraph::membership(comunidades)))
  paleta        <- colorRampPalette(c("#E41A1C","#377EB8","#4DAF4A","#984EA3",
                                      "#FF7F00","#A65628","#F781BF","#999999"))(n_comunidades)
  cores_comunidade <- paleta[igraph::membership(comunidades)]

  set.seed(2026)
  layout_fr <- igraph::layout_with_fr(g_final)
  formas    <- ifelse(V(g_final)$type, "square", "circle")

  nome_rede <- sprintf("%s/Rede_%s_sigmap%.1f_Amax%d_k%d_%s.png",
                       diretorios$graficos, tipo_sel, sp, am, kf, sel_label)
  png(nome_rede, width = 3000, height = 2800, res = 300); par(mar = c(5, 2, 5, 2))
  plot(g_final, layout = layout_fr, vertex.color = cores_comunidade,
       vertex.shape = formas, vertex.size = 4, vertex.label = NA,
       vertex.frame.color = rgb(0,0,0,0.2), edge.color = rgb(0.4,0.4,0.4,0.12),
       edge.width = 0.8,
       main = sprintf("Rede Representativa — %s | σp=%.1f | A_max=%d | k=%d | %s\nRép %d | Gen %d | Mod: %.3f | Tribos: %d | Comunidades: %d",
                      tipo_sel, sp, am, kf, sel_label,
                      rep_info$replica, rep_info$geracao_alvo,
                      dados$GenAlvo$modularity, num_grupos, n_comunidades))
  legend("bottomleft", legend = c("Macho","Fêmea"), pch = c(15, 16),
         col = "gray40", pt.cex = 2, bty = "n", title = "Tipo")
  dev.off()
  cat(sprintf("    Rede salva: %s\n", nome_rede))

  # -----------------------------------------------------------------
  # HISTOGRAMAS — Evolução em 3 Atos
  # -----------------------------------------------------------------
  n_m_gen1 <- length(dados$Gen1$Z_Machos)
  n_f_gen1 <- length(dados$Gen1$P_Femeas)
  n_m_alvo <- length(dados$GenAlvo$male_z_surv)
  n_f_alvo <- length(dados$GenAlvo$female_p)
  n_m_fim  <- length(dados$GenFinal$Z_Machos)
  n_f_fim  <- length(dados$GenFinal$P_Femeas)

  df_hist <- bind_rows(
    data.frame(Valor = c(dados$Gen1$Z_Machos, dados$Gen1$P_Femeas),
               Nome  = c(rep("Macho (z)", n_m_gen1), rep("Fêmea (p)", n_f_gen1)),
               Geracao = "1. Início (Gen 1)"),
    data.frame(Valor = c(dados$GenAlvo$male_z_surv, dados$GenAlvo$female_p),
               Nome  = c(rep("Macho (z)", n_m_alvo), rep("Fêmea (p)", n_f_alvo)),
               Geracao = sprintf("2. A Rede (Gen %d)", rep_info$geracao_alvo)),
    data.frame(Valor = c(dados$GenFinal$Z_Machos, dados$GenFinal$P_Femeas),
               Nome  = c(rep("Macho (z)", n_m_fim), rep("Fêmea (p)", n_f_fim)),
               Geracao = sprintf("3. O Destino (Gen %d)", GEN_MAX))
  )

  p_hist <- ggplot(df_hist, aes(x = Valor, fill = Nome, color = Nome)) +
    geom_density(alpha = 0.4, linewidth = 1) +
    facet_wrap(~Geracao, ncol = 1) +
    scale_fill_manual(values  = c("Macho (z)"="#4682B4", "Fêmea (p)"="#E6B800")) +
    scale_color_manual(values = c("Macho (z)"="#4682B4", "Fêmea (p)"="#E6B800")) +
    geom_vline(xintercept = 5, linetype = "dashed") +
    labs(title = sprintf("Evolução em 3 Atos — %s | σp=%.1f | k=%d | %s",
                          tipo_sel, sp, kf, sel_label)) +
    theme_minimal(base_size = 14) + theme(legend.position = "top")

  nome_hist <- sprintf("%s/Histogramas_%s_sigmap%.1f_Amax%d_k%d_%s.png",
                       diretorios$graficos, tipo_sel, sp, am, kf, sel_label)
  ggsave(nome_hist, plot = p_hist, width = 6, height = 8, dpi = 300, bg = "white")
  cat(sprintf("    Histogramas salvos: %s\n", nome_hist))

  invisible(list(
    resumo = data.frame(
      tipo_selecao             = tipo_sel,
      sigma_p                  = sp,
      encounters_n             = am,
      k_fixo                   = kf,
      selecao_natural          = sel_nat,
      replica                  = rep_info$replica,
      geracao_alvo             = rep_info$geracao_alvo,
      modularity               = round(dados$GenAlvo$modularity, 3),
      modularity_media_estavel = round(rep_info$modularity_media, 3),
      tribos                   = num_grupos,
      comunidades              = n_comunidades,
      nestedness               = round(dados$GenAlvo$nestedness, 3),
      Is                       = round(dados$GenAlvo$Is, 3),
      centralization           = round(dados$GenAlvo$centralization, 4)
    ),
    g_final          = g_final,
    layout_fr        = layout_fr,
    cores_comunidade = cores_comunidade,
    formas           = formas,
    rep_info         = rep_info,
    dados            = dados,
    n_comunidades    = n_comunidades,
    num_grupos       = num_grupos,
    p_hist           = p_hist
  ))
}

# =====================================================================
# MODO DE USO:
# (A) EXPLORAÇÃO INDIVIDUAL:
#       res <- rodar_cenario("gaussian", 2.0, 200, kf = 10, sel_nat = FALSE)
# (B) LOTE — rode o bloco abaixo
# =====================================================================

# =====================================================================
# LOTE COMPLETO
# Foco: encounters_n=200, selecao_natural=FALSE (isolando efeito da
# preferência feminina sem viabilidade), k ∈ {5, 10, 20}
# =====================================================================
cenarios <- expand.grid(
  tipo_selecao    = TIPOS_SELECAO,
  sigma_p         = c(0.5, 2.0),
  encounters_n    = 200,
  k_fixo          = c(5L, 10L, 20L),
  selecao_natural = FALSE,
  stringsAsFactors = FALSE
)

labels_tipo <- c("uniform"  = "Aleatória",
                 "gaussian" = "Gaussiana",
                 "sigmoid"  = "Sigmoide",
                 "u-shaped" = "Disruptiva")

resultados <- lapply(1:nrow(cenarios), function(i) {
  rodar_cenario(cenarios$tipo_selecao[i], cenarios$sigma_p[i],
                cenarios$encounters_n[i], cenarios$k_fixo[i],
                cenarios$selecao_natural[i])
})

# Tabela resumo
tabela_resumo <- bind_rows(lapply(resultados, function(r) if (!is.null(r)) r$resumo))
print(tabela_resumo)
write.csv(tabela_resumo,
          file.path(diretorios$dados, "resumo_redes_representativas_MiudoV2.csv"),
          row.names = FALSE)

# =====================================================================
# TABELA COMPARATIVA (para o poster): Mod/NODF/Tribos/Comunidades
# por curva de preferência × sigma_p × k_fixo (sem sel. natural)
# =====================================================================
tabela_comparativa <- tabela_resumo %>%
  mutate(Curva = labels_tipo[tipo_selecao]) %>%
  select(Curva, sigma_p, k_fixo, modularity, nestedness, tribos, comunidades) %>%
  rename(Sigma_p             = sigma_p,
         k                   = k_fixo,
         Modularidade        = modularity,
         NODF                = nestedness,
         Tribos              = tribos,
         Comunidades         = comunidades) %>%
  arrange(Curva, Sigma_p, k)

cat("\n=== Tabela comparativa (Mod/NODF/Tribos/Comunidades) ===\n")
print(tabela_comparativa)

write.csv(tabela_comparativa,
          file.path(diretorios$dados, "Tabela_Comparativa_MiudoV2.csv"),
          row.names = FALSE)
cat(sprintf("Tabela comparativa salva: %s\n",
            file.path(diretorios$dados, "Tabela_Comparativa_MiudoV2.csv")))

# Versão "larga" — uma linha por (Curva, sigma_p), colunas separadas por k
tabela_comparativa_larga <- tabela_resumo %>%
  mutate(Curva = labels_tipo[tipo_selecao]) %>%
  select(Curva, sigma_p, k_fixo, modularity, nestedness, tribos, comunidades) %>%
  pivot_wider(
    names_from  = k_fixo,
    values_from = c(modularity, nestedness, tribos, comunidades),
    names_glue  = "{.value}_k{k_fixo}"
  ) %>%
  select(Curva, sigma_p,
         starts_with("modularity"), starts_with("nestedness"),
         starts_with("tribos"), starts_with("comunidades")) %>%
  arrange(Curva, sigma_p)

write.csv(tabela_comparativa_larga,
          file.path(diretorios$dados, "Tabela_Comparativa_MiudoV2_larga.csv"),
          row.names = FALSE)
cat(sprintf("Tabela comparativa (larga) salva: %s\n",
            file.path(diretorios$dados, "Tabela_Comparativa_MiudoV2_larga.csv")))

# =====================================================================
# PAINÉIS TIPO A: por (sigma_p × k_fixo) — 4 curvas cada
# Para cada combinação de sigma_p e k, mostra as 4 curvas de preferência
# =====================================================================
params_painel <- unique(cenarios[, c("sigma_p", "k_fixo")])

for (j in 1:nrow(params_painel)) {
  sp <- params_painel$sigma_p[j]
  kf <- params_painel$k_fixo[j]

  idx <- which(cenarios$sigma_p == sp & cenarios$k_fixo == kf)
  if (any(sapply(resultados[idx], is.null))) next

  # Painel de redes
  nome_painel <- sprintf("%s/Painel_Redes_sigmap%.1f_Amax200_k%d_noNS.png",
                         diretorios$graficos, sp, kf)
  png(nome_painel, width = 5600, height = 5600, res = 300)
  par(mfrow = c(2, 2), mar = c(3, 2, 5, 2))
  for (i in idx) {
    r  <- resultados[[i]]
    tl <- labels_tipo[cenarios$tipo_selecao[i]]
    plot(r$g_final, layout = r$layout_fr, vertex.color = r$cores_comunidade,
         vertex.shape = r$formas, vertex.size = 4, vertex.label = NA,
         vertex.frame.color = rgb(0,0,0,0.2), edge.color = rgb(0.4,0.4,0.4,0.12),
         edge.width = 0.8,
         main = sprintf("%s\nMod: %.3f | NODF: %.3f | Tribos: %d",
                        tl, r$resumo$modularity, r$resumo$nestedness, r$num_grupos))
    legend("bottomleft", legend = c("Macho","Fêmea"), pch = c(15,16),
           col = "gray40", pt.cex = 1.5, bty = "n")
  }
  dev.off()
  cat(sprintf("Painel salvo: %s\n", nome_painel))

  # Painel de histogramas
  plots_hist <- lapply(idx, function(i) {
    tl <- labels_tipo[cenarios$tipo_selecao[i]]
    resultados[[i]]$p_hist + ggtitle(tl) +
      theme(plot.title = element_text(size = 12, face = "bold"))
  })
  painel_hist <- (plots_hist[[1]] | plots_hist[[2]]) /
                 (plots_hist[[3]] | plots_hist[[4]]) +
    plot_annotation(title = sprintf("Evolução em 3 Atos | σp=%.1f | k=%d | sem sel.natural",
                                    sp, kf))
  nome_hist_painel <- sprintf("%s/Painel_Histogramas_sigmap%.1f_Amax200_k%d_noNS.png",
                               diretorios$graficos, sp, kf)
  ggsave(nome_hist_painel, plot = painel_hist, width = 16, height = 20,
         dpi = 300, bg = "white")
  cat(sprintf("Painel histogramas salvo: %s\n", nome_hist_painel))
}

# =====================================================================
# PAINÉIS TIPO B: comparação de k (5/10/20) × sigma_p (2.0/0.5)
# Para cada tipo_selecao, grade 2x3: linha de cima sigma_p=2.0,
# linha de baixo sigma_p=0.5; colunas k=5, k=10, k=20
# =====================================================================
for (tc in TIPOS_SELECAO) {
  idx <- which(cenarios$tipo_selecao == tc)
  if (length(idx) != 6 || any(sapply(resultados[idx], is.null))) next

  nome_kcomp <- sprintf("%s/Comparacao_k_sigmap_%s_noNS.png",
                        diretorios$graficos, tc)
  png(nome_kcomp, width = 7200, height = 5000, res = 300)
  par(mfrow = c(2, 3), mar = c(3, 2, 6, 2))
  for (sp in c(2.0, 0.5)) {
    for (kf in c(5L, 10L, 20L)) {
      i <- idx[which(cenarios$sigma_p[idx] == sp & cenarios$k_fixo[idx] == kf)]
      r <- resultados[[i]]
      plot(r$g_final, layout = r$layout_fr, vertex.color = r$cores_comunidade,
           vertex.shape = r$formas, vertex.size = 5, vertex.label = NA,
           vertex.frame.color = rgb(0,0,0,0.2), edge.color = rgb(0.4,0.4,0.4,0.15),
           edge.width = 0.9,
           main = sprintf("k = %d | σp = %.1f\nMod: %.3f | NODF: %.3f | Tribos: %d | Com: %d",
                          kf, sp, r$resumo$modularity, r$resumo$nestedness,
                          r$num_grupos, r$n_comunidades))
      legend("bottomleft", legend = c("Macho","Fêmea"), pch = c(15,16),
             col = "gray40", pt.cex = 1.5, bty = "n")
    }
  }
  title(main = sprintf("%s | sem sel.natural — comparação de k e σp",
                       labels_tipo[tc]),
        outer = TRUE, line = -1.5, cex.main = 1.6)
  dev.off()
  cat(sprintf("Comparação k×σp salva: %s\n", nome_kcomp))
}
