# =====================================================================
# Script 01: Métricas e Utilitários de Rede (01_metricas_e_utilitarios.R)
# =====================================================================
suppressPackageStartupMessages({
  library(igraph)
  library(bipartite)
  library(ggplot2)
  library(dplyr)
  library(tidyr)
})

# Função auxiliar para substituir valores nulos (usada na função de aninhamento)
`%||%` <- function(x, y) if (is.null(x)) y else x

# =====================================================================
# PARTE A: ORGANIZAÇÃO DE PASTAS E EXPORTAÇÃO
# 👉 O objetivo aqui é automatizar a criação de pastas no seu computador 
# para que os milhares de resultados não virem uma bagunça.
# =====================================================================

# 1. Configurar Diretórios
# Cria a estrutura de pastas perfeita para cada fase do seu artigo
configurar_diretorios <- function(nome_fase) {
  pastas <- c(
    paste0("Resultados_Artigo/", nome_fase, "/Dados"),
    paste0("Resultados_Artigo/", nome_fase, "/Graficos"),
    paste0("Resultados_Artigo/", nome_fase, "/Redes_TXT")
  )
  # O loop cria as pastas. 'showWarnings = FALSE' evita erros se a pasta já existir.
  for (p in pastas) dir.create(p, recursive = TRUE, showWarnings = FALSE)
  
  cat("Diretórios prontos para a fase:", nome_fase, "\n")
  return(list(dados = pastas[1], graficos = pastas[2], redes = pastas[3]))
}

# 2. Salvar a Rede em Formato de Texto Leve (Edge List)
# 👉 Salvar matrizes gigantes cheias de zeros (0) gasta muita memória RAM.
# Aqui pegamos apenas os "1s" (quem acasalou com quem) e salvamos em colunas.
salvar_rede_txt <- function(M, replica_id, geracao, tipo_selecao, sigma_p, pasta_redes) {
  # Encontra as coordenadas (linha e coluna) de onde houve cópula (M == 1L)
  arestas <- which(M == 1L, arr.ind = TRUE)
  
  if (nrow(arestas) == 0) return(NULL) # Se ninguém acasalou, não faz nada
  
  # Cria a tabela de quem cruzou com quem
  df_rede <- data.frame(
    Tipo_Selecao = tipo_selecao, 
    Sigma_P = sigma_p,
    Replica = replica_id, 
    Geracao = geracao,
    Macho_ID = arestas[, 1], 
    Femea_ID = arestas[, 2]
  )
  
  # Define o nome do arquivo dinamicamente
  nome_arquivo <- sprintf("%s/Redes_Selecao-%s_SigmaP-%.1f.txt", pasta_redes, tipo_selecao, sigma_p)
  
  # append = TRUE é a mágica: ele apenas adiciona os novos dados no final do 
  # arquivo .txt sem apagar as gerações ou réplicas anteriores!
  write.table(df_rede, file = nome_arquivo, append = TRUE, 
              sep = "\t", row.names = FALSE, col.names = !file.exists(nome_arquivo))
}


# =====================================================================
# INTRODUÇÃO ÀS FUNÇÕES "SAFE_"
# A seguir incluímos uma parte de funções seguras. Estas funções se chamam 
# safe_ porque usam uma técnica de programação chamada tryCatch (tentar e capturar). 
# Si ocurre un error matemático, en lugar de "explotar", la función simplemente 
# devuelve un NA (Not Available / Dato faltante) y permite que la simulación continúe ;) 
#
# Por ejemplo: Si en una Generación, debido a una selección natural fuertísima, 
# solo sobrevive 1 macho. La red será de 1 macho y 200 hembras. ¡No se puede calcular 
# anidamiento ni modularidad ahí! Si las funciones devuelven 0, meteríamos un sesgo 
# estadístico falso (haciendole creer al modelo que la topología fue cero). 
# Al devolver NA, los gráficos de ggplot2 y los modelos glmer simplemente 
# ignorarán ese punto específico sin que el código explote. #Pero lo ideial es ver quantas simulaciones dieron errado.
# =====================================================================

# ---------------------------------------------------------------------
# 1. Cálculo de Aninhamento (Nestedness / NODF) seguro
# Con Nestedness (NODF) evaluaremos si la red tiene una estructura jerárquica 
# (machos alfa monopolizando a hembras exigentes y generalistas, mientras machos 
# subóptimos solo se aparean con generalistas).
# ---------------------------------------------------------------------
safe_nested_nodf <- function(M) {
  # REGLA DE SEGURIDAD 1: Dimensiones mínimas
  # Si la matriz M no existe, o si tiene menos de 2 filas o 2 columnas, 
  # o si hubo menos de 2 cópulas en total (sum(M) < 2), es matemáticamente
  # imposible calcular el anidamiento. Devolvemos NA.
  if (is.null(M) || any(dim(M) < 2) || sum(M) < 2) return(NA_real_)
  
  # REGLA DE SEGURIDAD 2: Filas o columnas fantasma
  # Si absolutamente TODOS los machos tienen 0 cópulas (rowSums) o 
  # TODAS las hembras tienen 0 cópulas (colSums), devolvemos NA.
  if (all(rowSums(M) == 0) || all(colSums(M) == 0)) return(NA_real_)
  
  # EL ESCUDO (tryCatch): "Intenta hacer esto, si fallas, haz lo otro"
  out <- tryCatch({
    res <- bipartite::nested(M, method = "NODF")
    if (is.list(res)) {
      res$statistic %||% res$NODF %||% as.numeric(res)
    } else {
      as.numeric(res)
    }
  }, error = function(e) NA_real_)
  return(out)
}

# ---------------------------------------------------------------------
# 2. Cálculo da Modularidade (Louvain)
# Aquí evaluamos si la red se fractura en sub-redes aisladas (Assortative Mating / 
# Selección Disruptiva). Para esto usaremos la librería igraph y el algoritmo de 
# "Louvain" (bom para detectar comunidades, será que é mesmo o melhor neste caso?).
#  Louvain sobre esta proyección detecta comunidades que mezclan machos y hembras. Para mating networks bipartidas lo más apropiado sería modularidad bipartida. El paquete bipartite tiene computeModules():
# r# Alternativa:
# library(bipartite)
# mod_result <- tryCatch(
#   computeModules(M)@likelihood,
#   error = function(e) NA_real_
# )
# Aunque computeModules es más lento — vale la pena discutir con el Miúdo cuál es más defendible para el paper. El algoritmo de Louvain en la proyección no-dirigida toma 0.01 segundos. El algoritmo computeModules toma a veces hasta 10 segundos por red. Como tú simulas 70,000 redes,el código tardaría semanas en correr! Louvain es una heurística ampliamente aceptada y súper correlacionada con la modularidad bipartita real. Por ahora, sigo con esa! :)
# ---------------------------------------------------------------------
safe_modularity <- function(g) {
  tryCatch({
    # REGLA DE SEGURIDAD: 
    # ecount(g) cuenta el número de 'edges' (aristas / cópulas).
    # Si nadie se apareó en esta generación (0 aristas), no hay módulos que detectar.
    # Pero eso tecnicamente es imposible, pois cada hembra se deve aparear con al 
    # menos un macho...pero si cambio esa regla melhor manter isto.
    if (igraph::ecount(g) == 0) return(NA_real_)
    
    # 1. Agrupar (Clustering): Algoritmo de Louvain
    cl <- igraph::cluster_louvain(g)
    
    # 2. Medir a pontuação (de 0 a 1)
    igraph::modularity(cl)
  }, error = function(e) NA_real_) 
}

# ---------------------------------------------------------------------
# 3. Cálculo da Centralização da Rede (Degree Centralization)
# Usamos o pacote igraph de novo. mede o grau em que as interações da rede estão 
# concentradas em poucos indivíduos (aqui podem ser machos o femeas!-- considerar 
# fazer só para machos #Discutir Miudo- ver abaixo a versao comentada) 
# Mantida aqui para comparar com o Is durante as discussões com o Miudo
# ---------------------------------------------------------------------
safe_centralization <- function(g) {
  tryCatch({
    if (igraph::ecount(g) == 0) return(NA_real_)
    
    # mode = "all" = cuenta todas las conexiones del nodo, com la red de copulas 
    # es no dirigida, o sea, una celda 1 solo indica que hubo al menos una cópula 
    # entre macho y hembra, ese modo parece ok. #checar con Miudo
    res <- igraph::centr_degree(g, mode = "all")
    res$centralization
  }, error = function(e) NA_real_)
}

# ---------------------------------------------------------------------
# 4. Cálculo da Oportunidade de Seleção Sexual (Is)
# El "Is" (Índice de Crow) mide el potencial de selección sexual generado por la 
# desigualdad reproductiva. Si un macho acapara a casi todas las hembras y el resto 
# tiene cero cópulas, el Is se dispara, indicando alta oportunidad de selección sexual.
# ---------------------------------------------------------------------
safe_opportunity_sexual_selection <- function(M) {
  if (is.null(M) || nrow(M) == 0 || sum(M) == 0) return(NA_real_)
  
  tryCatch({
    # k_males es el grado (número de hembras con las que copuló cada macho)
    k_males <- rowSums(M)
    mean_k <- mean(k_males)
    
    # Regla de seguridad matemática: No se puede dividir por cero
    if (mean_k <= 1e-9) return(NA_real_)
    
    # Is = Varianza del éxito reproductivo / (Media del éxito reproductivo)^2
    Is <- var(k_males) / (mean_k^2)
    return(Is)
  }, error = function(e) NA_real_)
}

# =====================================================================
# PARTE C: A FUNÇÃO COMPILADORA (O "Gerente" das Métricas)
# 👉 Esta função pega a Matriz M e o Grafo e roda todas as suas funções 
# "safe_" de uma vez só, devolvendo uma linha limpa de dados.
# =====================================================================
calc_metrics_from_M <- function(M) {
  n_m <- nrow(M); n_f <- ncol(M)
  
  # Cria o grafo bipartido para o igraph
  adj_matrix <- matrix(0L, nrow = n_m + n_f, ncol = n_m + n_f)
  adj_matrix[1:n_m, (n_m + 1):(n_m + n_f)] <- M
  adj_matrix[(n_m + 1):(n_m + n_f), 1:n_m] <- t(M)
  g <- igraph::graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
  
  # Retorna um Data Frame com 1 linha contendo todas as métricas
  data.frame(
    I_s = safe_opportunity_sexual_selection(M),
    Modularity = safe_modularity(g), 
    Nestedness = safe_nested_nodf(M), 
    Centralization = safe_centralization(g)
  )
}

# =====================================================================
# NOTAS E ALTERNATIVAS PARA DISCUTIR COM MIUDO
# =====================================================================
# safe_male_centralization <- function(g) {
#   tryCatch({
#     if (igraph::ecount(g) == 0) return(NA_real_)
#     # 
#     # Como a rede é bipartida, se usarmos 'centr_degree(g, mode="all")', 
#     # o igraph mistura machos e fêmeas. Para centralização APENAS de machos,
#     # precisaríamos extrair apenas os nós TRUE (Machos) e calcular o Gini
#     # ou a centralização isolada deles. O I_s já faz isso de forma perfeita, 
#     # por isso a Centralização geral pode ser redundante com o I_s, mas é útil
#     # para ver a topologia global!
#   })
# }


# =====================================================================
# PARTE D: DINÂMICA BIOLÓGICA E EVOLUTIVA (O MOTOR DO MODELO)
# =====================================================================

ensure_min_survivors <- function(survive_vec, viability, min_surv = 2) {
  if (sum(survive_vec) >= min_surv) return(survive_vec)
  ord <- order(viability, decreasing = TRUE)
  survive_vec[ord[seq_len(min_surv)]] <- TRUE
  return(survive_vec)
}

mate_with_survivors <- function(male_z_surv, female_p, female_s, tipo_selecao,
                                min_cop = 1, max_cop = 5, encounters_n = 200) {
  n_m <- length(male_z_surv); n_f <- length(female_p)
  matings_per_female <- sample(min_cop:max_cop, n_f, replace = TRUE)
  M <- matrix(0L, nrow = n_m, ncol = n_f)
  
  for (i in seq_len(n_f)) {
    p_i <- female_p[i]; s_i <- female_s[i]
    evaluacoes_reais <- min(encounters_n, n_m)
    encounters <- sample(seq_len(n_m), size = evaluacoes_reais, replace = TRUE)
    matings_done <- 0L
    
    for (idx in encounters) {
      if (matings_done >= matings_per_female[i]) break
      z_j <- male_z_surv[idx]
      
      if (tipo_selecao == "uniform") { P_ij <- 0.5 
      } else if (tipo_selecao == "gaussian") { P_ij <- exp(-s_i * (z_j - p_i)^2)
      } else if (tipo_selecao == "sigmoid") { P_ij <- 1 / (1 + exp(-s_i * (z_j - p_i)))
      } else if (tipo_selecao == "u-shaped") { P_ij <- 1 - exp(-s_i * (z_j - p_i)^2) }
      
      # CORREÇÃO DO REVISOR: Só conta o acasalamento se ELES AINDA NÃO CRUZARAM ANTES!
      if (runif(1) <= P_ij && M[idx, i] == 0L) { 
        M[idx, i] <- 1L
        matings_done <- matings_done + 1L 
      }
    }
    # Regra de escape: se não cruzou com ninguém, cruza com o último
    if (matings_done == 0L) M[encounters[evaluacoes_reais], i] <- 1L
  }
  return(M)
}

# =====================================================================
# NOTAS SOBRE A FECUNDIDADE BASEADA EM REDE (DISCUTIR COM O REVISOR/MIUDO)
# =====================================================================
# Como M es binaria, colSums(M) = número de machos distintos con los que copuló la hembra (entre 1 y 3). 
# Entonces una hembra que copuló con 3 machos tiene 30 crías y una con 1 macho tiene 10. 
# Pode ser que alguem diga que Biológicamente, la fecundidad no debería depender del número de parejas 
# sino ser fija (o depender de la calidad del macho).
#
# Alternativa biológicamente nesse caso: 
# Seria cambiar la linha "num_filhotes_por_femea <- colSums(M) * fecundidade_base" 
# por "num_filhotes_por_femea <- rep(fecundidade_base, n_femeas)". 
# 
# Mas me gosto do próprio artigo do Tarantino & Garcia-Gonzalez. Em muitos insetos, copular múltiplas 
# vezes otorga beneficios directos (direct fitness benefits) a través de regalos nupciales o proteínas 
# en el espermatóforo, aumentando la cantidad de huevos que pone la hembra.-- Aclaré mejor en el texto.
# =====================================================================

produce_offspring <- function(M, male_z_surv, female_z_gen, N_males_next = 200, N_females_next = 200, fecundidade_base = 50, eps_sd = 0.2) {
  n_femeas <- ncol(M)
  # POLIANDRIA NEUTRA: fecundidade fixa por fêmea, independente do número de parceiros.
  # A poliandria continua importando para a competência espermática (paternidade
  # ainda é distribuída entre as parceiras via "fair raffle"), mas NÃO para o
  # número total de filhotes. Decisão tomada em reunião com supervisor (2026-05-21).
  # Hembras que não acasalaram com ninguém recebem 0 filhotes.
  acasalaram <- colSums(M) > 0
  num_filhotes_por_femea <- ifelse(acasalaram, fecundidade_base, 0)
  total_juveniles <- sum(num_filhotes_por_femea)
  
  # Segurança: se ninguém acasalou, devolve a geração anterior
  if(total_juveniles == 0) return(list(male_z_next=male_z_surv, female_z_next=female_z_gen))
  
  moms_of_juveniles <- rep(1:n_femeas, times = num_filhotes_por_femea)
  
  dads_of_juveniles <- sapply(moms_of_juveniles, function(mom_id) {
    parceiros <- which(M[, mom_id] == 1L) 
    if(length(parceiros) > 1) { sample(parceiros, 1) } else { parceiros[1] }
  })
  
  # AQUI ESTAVA O PROBLEMA! Esta linha deve ter sumido no seu script:
  z_dads <- male_z_surv[dads_of_juveniles] 
  z_moms <- female_z_gen[moms_of_juveniles]
  
  # Genética quantitativa
  z_todos_filhotes <- pmax(0, (z_dads + z_moms) / 2 + rnorm(total_juveniles, 0, eps_sd))
  
  # Capacidade de carga
  vagas_reais  <- min(N_males_next + N_females_next, total_juveniles) 
  sobreviventes_z <- sample(z_todos_filhotes, size = vagas_reais, replace = FALSE)
  meio <- floor(vagas_reais / 2)
  
  list(male_z_next = sobreviventes_z[1:meio], female_z_next = sobreviventes_z[(meio + 1):(meio * 2)])
}

# =====================================================================
# PARTE E: O LOOP EVOLUTIVO (O Maestro da Simulação)
# =====================================================================
# NOTAS SOBRE A COVARIÂNCIA GENÉTICA (FISHERIAN RUNAWAY):
# En nuestro modelo bloqueamos intencionalmente la coevolución de la preferencia 
# (las hembras heredan p de una distribución fija, no evoluciona). Hicimos esto, al 
# igual que Millan et al. (2020), para aislar matemáticamente el efecto de la topología 
# de la red. Si hubiéramos permitido que p y z co-evolucionaran, no sabríamos si la 
# exageración del rasgo fue causada por la estructura de la red (Anidamiento) o por 
# un simple bucle de retroalimentación genética. Al congelar la preferencia, demostramos 
# que la red anidada por sí sola genera suficiente asimetría reproductiva para vencer 
# a la selección natural...
# =====================================================================

simulate_evolution <- function(
    generations = 50, N_machos = 200, N_femeas = 200,
    sigma_z_init = 1.0, sigma_p = 1.0, sigma_s = 0.2,
    tipo_selecao = "gaussian", encounters_n = 200, phi = 5, gamma = 0.2, eps_sd = 0.2,
    return_details = FALSE, salvar_redes = FALSE, pasta_redes = NULL, replica_id = 1
) {
  
  male_z_gen1   <- pmax(0, rnorm(N_machos, mean = phi, sd = sigma_z_init))
  female_p_gen1 <- pmax(0, rnorm(N_femeas, mean = phi, sd = sigma_p))
  female_z_gen1 <- pmax(0, rnorm(N_femeas, mean = phi, sd = sigma_z_init)) 
  
  male_z_gen   <- male_z_gen1
  female_z_gen <- female_z_gen1
  
  out <- vector("list", generations)
  
  for (t in seq_len(generations)) {
    
    # RE-MUESTREO (Congelando a Evolução da Preferência)
    # En cada generación, las preferencias femeninas son tiradas de nuevo desde cero 
    # de una distribución fija N(φ=5, σ_p). No se heredan de las madres.
    if (t == 1) { 
      female_p <- female_p_gen1 
    } else { 
      female_p <- pmax(0, rnorm(N_femeas, mean = phi, sd = sigma_p)) 
    } 
    
    female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))
    
    V <- exp(-gamma * (male_z_gen - phi)^2)
    survive <- runif(N_machos) <= V
    survive <- ensure_min_survivors(survive, V, min_surv = 2)
    male_z_surv <- male_z_gen[survive]
    
    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao, encounters_n = encounters_n)
    metrics <- calc_metrics_from_M(M)
    
    if (t == generations && salvar_redes && !is.null(pasta_redes)) {
      salvar_rede_txt(M, replica_id, t, tipo_selecao, sigma_p, pasta_redes)
    }
    
    # CORREÇÃO: Salvamos a Média e a Variância apenas dos machos que SOBREVIVERAM (male_z_surv)!!!
    out[[t]] <- data.frame(
      generation = t, tipo_selecao = tipo_selecao, sigma_p = sigma_p, encounters_n = encounters_n,
      zbar_males = mean(male_z_surv), varz_males = var(male_z_surv), metrics
    )
    
    if (t == generations && return_details == TRUE) {
      M_final <- M
      male_z_final <- male_z_surv
      female_p_final <- female_p
    }
    
    offspring <- produce_offspring(M, male_z_surv, female_z_gen, N_machos, N_femeas, eps_sd = eps_sd)
    male_z_gen   <- offspring$male_z_next
    female_z_gen <- offspring$female_z_next
  }
  
  df_out <- dplyr::bind_rows(out)
  
  if (return_details) {
    return(list(
      dados_tabela = df_out,
      Gen1  = data.frame(Z_Machos = male_z_gen1, P_Femeas = female_p_gen1),
      Gen50 = data.frame(Z_Machos = male_z_final, P_Femeas = female_p_final[1:length(male_z_final)]),
      Matriz_M_Gen50 = M_final
    ))
  }
  
  return(df_out)
}
