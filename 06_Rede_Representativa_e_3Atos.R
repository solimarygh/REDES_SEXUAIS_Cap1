# =====================================================================
# SCRIPT 06: A Rede Representativa e a Evolução em 3 Atos
# =====================================================================
# 
# #Este es el código para  MIUDO hehe. Extrae la matriz Laplaciana, dibuja la red hermosa con los nodos celestes y salmón, y muestra los histogramas de la "Evolución en 3 Actos/generaciones/momentos".
# 
source("01_metricas_e_utilitarios.R")
library(ggplot2)
library(dplyr)
library(tidyr)
library(igraph)

cat("Buscando a Rede Representativa (Gaussiana, σp = 2.0)...\n")

# 1) FUNÇÃO MODIFICADA (Salva dados da G1, Geração Estável e G50)
simulate_stable_phase <- function(generations=50, N_machos=200, N_femeas=200, sigma_p=2.0, tipo_selecao="gaussian", encounters_n=100, gen_inicio=20) {
  male_z_gen1 <- pmax(0, rnorm(N_machos, 5, 1.0)); female_p_gen1 <- pmax(0, rnorm(N_femeas, 5, sigma_p)); female_z_gen1 <- pmax(0, rnorm(N_femeas, 5, 1.0)) 
  male_z_gen <- male_z_gen1; female_z_gen <- female_z_gen1; redes_estaveis <- list() 
  
  for (t in seq_len(generations)) {
    female_p <- if(t==1) female_p_gen1 else pmax(0, rnorm(N_femeas, 5, sigma_p))
    female_s <- pmax(0, rnorm(N_femeas, 2, 0.2))
    
    V <- exp(-0.2 * (male_z_gen - 5)^2)
    survive <- ensure_min_survivors(runif(N_machos) <= V, V, 2)
    male_z_surv <- male_z_gen[survive]
    
    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao, encounters_n=encounters_n)
    
    if (t >= gen_inicio) {
      n_m <- nrow(M); n_f <- ncol(M)
      adj <- matrix(0L, n_m+n_f, n_m+n_f); adj[1:n_m, (n_m+1):(n_m+n_f)] <- M; adj[(n_m+1):(n_m+n_f), 1:n_m] <- t(M)
      redes_estaveis[[as.character(t)]] <- list(geracao = t, Matriz_M = M, male_z_surv = male_z_surv, female_p = female_p, modularity = safe_modularity(igraph::graph_from_adjacency_matrix(adj, mode="undirected")))
    }
    if (t == generations) Gen50_dados <- list(Z_Machos = male_z_surv, P_Femeas = female_p)
    
    offspring <- produce_offspring(M, male_z_surv, female_z_gen, N_machos, N_femeas, eps_sd=0.2)
    male_z_gen <- offspring$male_z_next; female_z_gen <- offspring$female_z_next
  }
  list(Gen1 = list(Z_Machos=male_z_gen1, P_Femeas=female_p_gen1), Redes = redes_estaveis, Gen50 = Gen50_dados)
}

# 2) BUSCA DA REDE
set.seed(2026); n_reps <- 20; todas_redes <- list(); todos_mods <- numeric(); pop_completas <- list(); cont <- 1
for(i in 1:n_reps) {
  res <- simulate_stable_phase(); pop_completas[[i]] <- res
  for(t_str in names(res$Redes)) { r <- res$Redes[[t_str]]; r$replica <- i; todas_redes[[cont]] <- r; todos_mods[cont] <- r$modularity; cont <- cont + 1 }
}

media_estavel <- mean(todos_mods, na.rm=TRUE)
idx_escolhido <- which.min(abs(todos_mods - media_estavel))
rede_escolhida <- todas_redes[[idx_escolhido]]
pop_escolhida <- pop_completas[[rede_escolhida$replica]]

# 3) O LAPLACIANO E O PLOT DA REDE
M <- rede_escolhida$Matriz_M; n_m <- nrow(M); n_f <- ncol(M)
adj <- matrix(0L, n_m+n_f, n_m+n_f); adj[1:n_m, (n_m+1):(n_m+n_f)] <- M; adj[(n_m+1):(n_m+n_f), 1:n_m] <- t(M)
g_final <- igraph::graph_from_adjacency_matrix(adj, mode="undirected"); V(g_final)$type <- c(rep(TRUE, n_m), rep(FALSE, n_f))
num_grupos <- sum(round(eigen(igraph::laplacian_matrix(g_final, sparse=FALSE))$values, 5) <= 1e-7) 

cat(sprintf("A rede quebrou-se em %d tribos (Média Mod: %.3f)\n", num_grupos, media_estavel))

png("Rede_Representativa_Estavel.png", width=3000, height=1200, res=300); par(mar=c(4,1,4,1)) 
V(g_final)$color <- ifelse(V(g_final)$type, "lightblue", "salmon"); V(g_final)$shape <- ifelse(V(g_final)$type, "square", "circle")
plot(g_final, layout=layout_as_bipartite(g_final), vertex.label=NA, vertex.size=4, vertex.frame.color=NA, edge.color=rgb(0.5,0.5,0.5,0.15), main=sprintf("Rede Representativa (Mod: %.3f | Tribos: %d)", rede_escolhida$modularity, num_grupos), asp=0)
legend("bottom", inset=-0.15, xpd=TRUE, legend=c("Fêmeas (Top)", "Machos (Bottom)"), col=c("salmon", "lightblue"), pch=c(16, 15), pt.cex=2.5, bty="n", horiz=TRUE)
dev.off()

# 4) OS HISTOGRAMAS (OS 3 ATOS)
df_hist <- bind_rows(
  data.frame(Valor=c(pop_escolhida$Gen1$Z_Machos, pop_escolhida$Gen1$P_Femeas), Nome=c(rep("Macho (z)", 200), rep("Fêmea (p)", 200)), Geracao="1. Início (Gen 1)"),
  data.frame(Valor=c(rede_escolhida$male_z_surv, rede_escolhida$female_p), Nome=c(rep("Macho (z)", length(rede_escolhida$male_z_surv)), rep("Fêmea (p)", 200)), Geracao=sprintf("2. A Rede (Gen %d)", rede_escolhida$geracao)),
  data.frame(Valor=c(pop_escolhida$Gen50$Z_Machos, pop_escolhida$Gen50$P_Femeas), Nome=c(rep("Macho (z)", length(pop_escolhida$Gen50$Z_Machos)), rep("Fêmea (p)", 200)), Geracao="3. O Destino (Gen 50)")
)
p_hist <- ggplot(df_hist, aes(x=Valor, fill=Nome, color=Nome)) + geom_density(alpha=0.4, linewidth=1) + facet_wrap(~Geracao, ncol=1) +
  scale_fill_manual(values=c("Macho (z)"="#4682B4", "Fêmea (p)"="#E6B800")) + scale_color_manual(values=c("Macho (z)"="#4682B4", "Fêmea (p)"="#E6B800")) +
  geom_vline(xintercept=5, linetype="dashed") + theme_minimal(base_size=14) + theme(legend.position="top")
print(p_hist)