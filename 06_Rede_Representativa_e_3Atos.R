# =====================================================================
# SCRIPT 06: A Rede Representativa e a Evolução em 3 Atos
# =====================================================================
source("01_metricas_e_utilitarios.R")
library(ggplot2)
library(dplyr)
library(tidyr)
library(igraph)
library(patchwork)

diretorios <- configurar_diretorios("Redes_Representativas")

# =====================================================================
# MODO DE USO:
#
# 1) EXPLORAÇÃO INDIVIDUAL — ajuste os parâmetros abaixo e chame:
#       rodar_cenario(TIPO_SELECAO, SIGMA_P, ENCOUNTERS_N)
#
# 2) LOTE COMPLETO — rode o bloco "LOTE" no final do script
#
# tipo_selecao: "uniform", "gaussian", "sigmoid", "u-shaped"
# sigma_p:      variação da preferência feminina (ex: 0.5, 1.0, 2.0)
# encounters_n: capacidade de amostragem (ex: 20, 100, 200)
# =====================================================================
TIPO_SELECAO <- "gaussian"
SIGMA_P      <- 2.0
ENCOUNTERS_N <- 200
# =====================================================================


# ---------------------------------------------------------------------
# FUNÇÃO PRINCIPAL: roda um cenário completo e salva os gráficos
# ---------------------------------------------------------------------
rodar_cenario <- function(tipo_selecao, sigma_p, encounters_n) {

  cat(sprintf("\n>>> Rodando: %s | sigmap=%.1f | Amax=%d\n", tipo_selecao, sigma_p, encounters_n))

  # 1) Simulação: busca rede representativa na fase estável
  simulate_stable_phase <- function(generations=100, N_machos=200, N_femeas=200, gen_inicio=40) {
    male_z_gen1   <- pmax(0, rnorm(N_machos, 5, 1.0))
    female_p_gen1 <- pmax(0, rnorm(N_femeas, 5, sigma_p))
    female_z_gen1 <- pmax(0, rnorm(N_femeas, 5, 1.0))
    male_z_gen <- male_z_gen1; female_z_gen <- female_z_gen1; redes_estaveis <- list()

    for (t in seq_len(generations)) {
      female_p <- if(t==1) female_p_gen1 else pmax(0, rnorm(N_femeas, 5, sigma_p))
      female_s <- pmax(0, rnorm(N_femeas, 2, 0.2))
      V        <- exp(-0.2 * (male_z_gen - 5)^2)
      survive  <- ensure_min_survivors(runif(N_machos) <= V, V, 2)
      male_z_surv <- male_z_gen[survive]
      M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao, encounters_n=encounters_n)

      if (t >= gen_inicio) {
        n_m <- nrow(M); n_f <- ncol(M)
        adj <- matrix(0L, n_m+n_f, n_m+n_f)
        adj[1:n_m, (n_m+1):(n_m+n_f)] <- M; adj[(n_m+1):(n_m+n_f), 1:n_m] <- t(M)
        redes_estaveis[[as.character(t)]] <- list(
          geracao=t, Matriz_M=M, male_z_surv=male_z_surv, female_p=female_p,
          modularity=safe_modularity(igraph::graph_from_adjacency_matrix(adj, mode="undirected")))
      }
      if (t == generations) Gen50_dados <- list(Z_Machos=male_z_surv, P_Femeas=female_p)
      offspring   <- produce_offspring(M, male_z_surv, female_z_gen, N_machos, N_femeas, eps_sd=0.2)
      male_z_gen  <- offspring$male_z_next; female_z_gen <- offspring$female_z_next
    }
    list(Gen1=list(Z_Machos=male_z_gen1, P_Femeas=female_p_gen1), Redes=redes_estaveis, Gen50=Gen50_dados)
  }

  # 2) Busca da rede com modularity mais próxima da média estável
  set.seed(2026)
  n_reps <- 20; todas_redes <- list(); todos_mods <- numeric(); pop_completas <- list(); cont <- 1
  for(i in 1:n_reps) {
    res <- simulate_stable_phase(); pop_completas[[i]] <- res
    for(t_str in names(res$Redes)) {
      r <- res$Redes[[t_str]]; r$replica <- i
      todas_redes[[cont]] <- r; todos_mods[cont] <- r$modularity; cont <- cont + 1
    }
  }
  media_estavel <- mean(todos_mods, na.rm=TRUE)
  idx_escolhido <- which.min(abs(todos_mods - media_estavel))
  rede_escolhida <- todas_redes[[idx_escolhido]]
  pop_escolhida  <- pop_completas[[rede_escolhida$replica]]

  # 3) Laplaciano, comunidades Louvain e plot da rede
  M    <- rede_escolhida$Matriz_M; n_m <- nrow(M); n_f <- ncol(M)
  adj  <- matrix(0L, n_m+n_f, n_m+n_f)
  adj[1:n_m, (n_m+1):(n_m+n_f)] <- M; adj[(n_m+1):(n_m+n_f), 1:n_m] <- t(M)
  g_final <- igraph::graph_from_adjacency_matrix(adj, mode="undirected")
  V(g_final)$type <- c(rep(TRUE, n_m), rep(FALSE, n_f))

  num_grupos   <- sum(round(eigen(igraph::laplacian_matrix(g_final, sparse=FALSE))$values, 5) <= 1e-7)
  comunidades  <- igraph::cluster_louvain(g_final)
  n_comunidades <- length(unique(igraph::membership(comunidades)))
  paleta        <- colorRampPalette(c("#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00","#A65628","#F781BF","#999999"))(n_comunidades)
  cores_comunidade <- paleta[igraph::membership(comunidades)]

  cat(sprintf("    Tribos: %d | Comunidades: %d | Mod média: %.3f\n", num_grupos, n_comunidades, media_estavel))

  set.seed(2026)
  layout_fr <- igraph::layout_with_fr(g_final)
  formas    <- ifelse(V(g_final)$type, "square", "circle")

  nome_rede <- sprintf("%s/Rede_%s_sigmap%.1f_Amax%d.png", diretorios$graficos, tipo_selecao, sigma_p, encounters_n)
  png(nome_rede, width=3000, height=2800, res=300); par(mar=c(5,2,5,2))
  plot(g_final, layout=layout_fr, vertex.color=cores_comunidade, vertex.shape=formas,
       vertex.size=4, vertex.label=NA, vertex.frame.color=rgb(0,0,0,0.2),
       edge.color=rgb(0.4,0.4,0.4,0.12), edge.width=0.8,
       main=sprintf("Rede Representativa — %s | σp = %.1f | A_max = %d\nMod: %.3f | Tribos: %d | Comunidades: %d",
                    tipo_selecao, sigma_p, encounters_n, rede_escolhida$modularity, num_grupos, n_comunidades))
  legend("bottomleft", legend=c("Macho","Fêmea"), pch=c(15,16), col="gray40", pt.cex=2, bty="n", title="Tipo")
  legend("bottomright", legend=paste("Comunidade", 1:n_comunidades), fill=paleta, bty="n", title="Louvain")
  dev.off()
  cat(sprintf("    Rede salva: %s\n", nome_rede))

  # 4) Histogramas — Evolução em 3 Atos
  df_hist <- bind_rows(
    data.frame(Valor=c(pop_escolhida$Gen1$Z_Machos, pop_escolhida$Gen1$P_Femeas),
               Nome=c(rep("Macho (z)",200), rep("Fêmea (p)",200)), Geracao="1. Início (Gen 1)"),
    data.frame(Valor=c(rede_escolhida$male_z_surv, rede_escolhida$female_p),
               Nome=c(rep("Macho (z)", length(rede_escolhida$male_z_surv)), rep("Fêmea (p)",200)),
               Geracao=sprintf("2. A Rede (Gen %d)", rede_escolhida$geracao)),
    data.frame(Valor=c(pop_escolhida$Gen50$Z_Machos, pop_escolhida$Gen50$P_Femeas),
               Nome=c(rep("Macho (z)", length(pop_escolhida$Gen50$Z_Machos)), rep("Fêmea (p)",200)),
               Geracao="3. O Destino (Gen 100)")
  )
  p_hist <- ggplot(df_hist, aes(x=Valor, fill=Nome, color=Nome)) +
    geom_density(alpha=0.4, linewidth=1) + facet_wrap(~Geracao, ncol=1) +
    scale_fill_manual(values=c("Macho (z)"="#4682B4","Fêmea (p)"="#E6B800")) +
    scale_color_manual(values=c("Macho (z)"="#4682B4","Fêmea (p)"="#E6B800")) +
    geom_vline(xintercept=5, linetype="dashed") +
    labs(title=sprintf("Evolução em 3 Atos — %s | σp = %.1f | A_max = %d", tipo_selecao, sigma_p, encounters_n)) +
    theme_minimal(base_size=14) + theme(legend.position="top")

  nome_hist <- sprintf("%s/Histogramas_%s_sigmap%.1f_Amax%d.png", diretorios$graficos, tipo_selecao, sigma_p, encounters_n)
  ggsave(nome_hist, plot=p_hist, width=6, height=8, dpi=300, bg="white")
  cat(sprintf("    Histogramas salvos: %s\n", nome_hist))

  # Retorna objetos para painéis comparativos + resumo numérico
  invisible(list(
    resumo  = data.frame(tipo_selecao=tipo_selecao, sigma_p=sigma_p, encounters_n=encounters_n,
                         modularity=round(media_estavel,3), tribos=num_grupos, comunidades=n_comunidades),
    g_final        = g_final,
    layout_fr      = layout_fr,
    cores_comunidade = cores_comunidade,
    formas         = formas,
    rede_escolhida = rede_escolhida,
    n_comunidades  = n_comunidades,
    num_grupos     = num_grupos,
    p_hist         = p_hist
  ))
}


# =====================================================================
# EXPLORAÇÃO INDIVIDUAL — corre só o cenário definido acima
# =====================================================================
rodar_cenario(TIPO_SELECAO, SIGMA_P, ENCOUNTERS_N)


# =====================================================================
# LOTE COMPLETO — descomente para rodar todas as combinações
# =====================================================================
cenarios <- expand.grid(
  tipo_selecao = c("uniform", "gaussian", "sigmoid", "u-shaped"),
  sigma_p      = c(0.5, 2.0),
  encounters_n = c(200, 40, 10),
  stringsAsFactors = FALSE
)

labels_tipo <- c("uniform"="Aleatória", "gaussian"="Gaussiana",
                 "sigmoid"="Sigmoide", "u-shaped"="Disruptiva")

# Roda todos os cenários e guarda os resultados
resultados <- lapply(1:nrow(cenarios), function(i) {
  rodar_cenario(cenarios$tipo_selecao[i], cenarios$sigma_p[i], cenarios$encounters_n[i])
})

# Tabela resumo numérica
tabela_resumo <- bind_rows(lapply(resultados, function(r) r$resumo))
print(tabela_resumo)
write.csv(tabela_resumo, file.path(diretorios$dados, "resumo_redes_representativas.csv"), row.names=FALSE)
cat("\nTabela resumo salva!\n")

# -----------------------------------------------------------------
# PAINÉIS COMPARATIVOS: um painel de redes por (sigma_p × A_max)
# -----------------------------------------------------------------
sigmas_painel <- unique(cenarios$sigma_p)
amaxes_painel <- unique(cenarios$encounters_n)

for (sp in sigmas_painel) {
  for (am in amaxes_painel) {
    idx <- which(cenarios$sigma_p == sp & cenarios$encounters_n == am)
    nome_painel <- sprintf("%s/Painel_Redes_sigmap%.1f_Amax%d.png",
                           diretorios$graficos, sp, am)
    png(nome_painel, width=5600, height=5600, res=300); par(mfrow=c(2,2), mar=c(3,2,5,2))

    for (i in idx) {
      r  <- resultados[[i]]
      tl <- labels_tipo[cenarios$tipo_selecao[i]]
      plot(r$g_final, layout=r$layout_fr, vertex.color=r$cores_comunidade,
           vertex.shape=r$formas, vertex.size=4, vertex.label=NA,
           vertex.frame.color=rgb(0,0,0,0.2), edge.color=rgb(0.4,0.4,0.4,0.12),
           edge.width=0.8,
           main=sprintf("%s\nMod: %.3f | Tribos: %d | Comunidades: %d",
                        tl, r$rede_escolhida$modularity, r$num_grupos, r$n_comunidades))
    }
    dev.off()
    cat(sprintf("Painel de redes salvo: %s\n", nome_painel))
  }
}

# -----------------------------------------------------------------
# PAINÉIS COMPARATIVOS: um painel de histogramas por (sigma_p × A_max)
# -----------------------------------------------------------------
for (sp in sigmas_painel) {
  for (am in amaxes_painel) {
    idx <- which(cenarios$sigma_p == sp & cenarios$encounters_n == am)
    plots_hist <- lapply(idx, function(i) {
      tl <- labels_tipo[cenarios$tipo_selecao[i]]
      resultados[[i]]$p_hist + ggtitle(tl) + theme(plot.title=element_text(size=12, face="bold"))
    })
    painel_hist <- (plots_hist[[1]] | plots_hist[[2]]) / (plots_hist[[3]] | plots_hist[[4]]) +
      plot_annotation(title=sprintf("Evolução em 3 Atos — σp = %.1f | A_max = %d", sp, am),
                      theme=theme(plot.title=element_text(size=16, face="bold", hjust=0.5)))

    nome_hist_painel <- sprintf("%s/Painel_Histogramas_sigmap%.1f_Amax%d.png",
                                 diretorios$graficos, sp, am)
    ggsave(nome_hist_painel, plot=painel_hist, width=16, height=20, dpi=300, bg="white")
    cat(sprintf("Painel de histogramas salvo: %s\n", nome_hist_painel))
  }
}
