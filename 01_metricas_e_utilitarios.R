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
  # Proporção de fêmeas que NÃO acasalaram. Sem a regra de escape, esta é a
  # medida direta da força de seleção agindo sobre a preferência feminina.
  prop_sem_acasalar <- if (ncol(M) > 0) mean(colSums(M) == 0) else NA_real_

  # As métricas de rede EXCLUEM as fêmeas sem acasalamento (colunas de zeros):
  # elas entrariam como nós isolados e inflariam artificialmente tribos/modularidade.
  # Machos com grau 0 são MANTIDOS — são justamente o sinal da seleção sexual (Is).
  Mm <- M[, colSums(M) > 0, drop = FALSE]

  if (ncol(Mm) == 0) {
    return(data.frame(I_s = NA_real_, Modularity = NA_real_, Nestedness = NA_real_,
                      Centralization = NA_real_,
                      prop_femeas_sem_acasalar = prop_sem_acasalar))
  }

  n_m <- nrow(Mm); n_f <- ncol(Mm)

  # Cria o grafo bipartido para o igraph
  adj_matrix <- matrix(0L, nrow = n_m + n_f, ncol = n_m + n_f)
  adj_matrix[1:n_m, (n_m + 1):(n_m + n_f)] <- Mm
  adj_matrix[(n_m + 1):(n_m + n_f), 1:n_m] <- t(Mm)
  g <- igraph::graph_from_adjacency_matrix(adj_matrix, mode = "undirected")

  # Retorna um Data Frame com 1 linha contendo todas as métricas
  data.frame(
    I_s = safe_opportunity_sexual_selection(Mm),
    Modularity = safe_modularity(g),
    Nestedness = safe_nested_nodf(Mm),
    Centralization = safe_centralization(g),
    prop_femeas_sem_acasalar = prop_sem_acasalar
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
                                min_cop = 1, max_cop = 5, encounters_n = 200,
                                k_fixo = NULL) {
  n_m <- length(male_z_surv); n_f <- length(female_p)
  matings_per_female <- if (!is.null(k_fixo)) rep(as.integer(k_fixo), n_f) else sample(min_cop:max_cop, n_f, replace = TRUE)
  M <- matrix(0L, nrow = n_m, ncol = n_f)
  
  for (i in seq_len(n_f)) {
    p_i <- female_p[i]; s_i <- female_s[i]
    evaluacoes_reais <- min(encounters_n, n_m)
    encounters <- sample(seq_len(n_m), size = evaluacoes_reais, replace = FALSE)  # SEM reposição: A_max = nº de machos DISTINTOS avaliados (decisão reunião Erika/Miudo)
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
    # SEM regra de escape (decisão Erika/Miudo, 2026-07):
    # uma fêmea que não aceita nenhum macho fica SEM acasalar (0 filhotes).
    # Isso cria variância de fitness entre fêmeas — condição necessária para
    # que a preferência possa estar sob seleção (modelo espelho).
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

produce_offspring <- function(M, male_z_surv, female_z_gen, N_males_next = 200, N_females_next = 200,
                              fecundidade_base = 50, eps_sd = 0.2,
                              segregacao = c("infinitesimal", "fixa"), mut_sd = 0.05) {
  segregacao <- match.arg(segregacao)
  n_femeas <- ncol(M)
  # POLIANDRIA NEUTRA: fecundidade fixa por fêmea, independente do número de parceiros.
  # A poliandria continua importando para a competência espermática (paternidade
  # ainda é distribuída entre as parceiras via "fair raffle"), mas NÃO para o
  # número total de filhotes. Decisão tomada em reunião com supervisor (2026-05-21).
  # Hembras que não acasalaram com ninguém recebem 0 filhotes.
  acasalaram <- colSums(M) > 0
  num_filhotes_por_femea <- ifelse(acasalaram, fecundidade_base, 0)
  total_filhotes <- sum(num_filhotes_por_femea)

  # CASO DEGENERADO — regra única nos três motores (Estudos 2, 3 e 4).
  # Duas situações impedem formar a geração seguinte:
  #   (a) ninguém acasalou, então não há filhotes;
  #   (b) há filhotes, mas menos do que as vagas, e o desenho exige N constante.
  # Nos dois casos devolvemos NULL: quem chama ENCERRA a réplica e registra em
  # que geração isso aconteceu (coluna extincao_gen). A versão antiga devolvia a
  # geração anterior, o que fabricava uma geração de pais imortais e, pior,
  # devolvia só os SOBREVIVENTES, encolhendo a população em silêncio: dali em
  # diante runif(N_machos) reciclava um V mais curto e male_z_gen[survive]
  # passava a produzir NA sem nenhum aviso.
  if (total_filhotes < N_males_next + N_females_next) return(NULL)

  moms <- rep(1:n_femeas, times = num_filhotes_por_femea)

  dads <- sapply(moms, function(mom_id) {
    parceiros <- which(M[, mom_id] == 1L)
    if(length(parceiros) > 1) { sample(parceiros, 1) } else { parceiros[1] }
  })

  z_dads <- male_z_surv[dads]
  z_moms <- female_z_gen[moms]

  # Genética quantitativa
  midparent <- (z_dads + z_moms) / 2
  if (segregacao == "fixa") {
    # Ruído FIXO (comportamento histórico). O blending corta a variância pela
    # metade a cada geração, então V converge para 2*eps_sd^2 (~0.08 com 0.2),
    # independentemente da variância inicial e da seleção.
    desvio <- rnorm(total_filhotes, 0, eps_sd)
  } else {
    # MODELO INFINITESIMAL (Falconer & Mackay): variância de segregação = V_A/2,
    # proporcional à variância parental. Assim V' = V/2 + V/2 = V: a variância
    # não erode sozinha e passa a ser determinada pela seleção e pela deriva.
    var_pais <- var(c(male_z_surv, female_z_gen))
    if (!is.finite(var_pais) || var_pais < 0) var_pais <- 0
    desvio <- rnorm(total_filhotes, 0, sqrt(var_pais / 2)) + rnorm(total_filhotes, 0, mut_sd)
  }
  z_filhotes <- pmax(0, midparent + desvio)

  # Capacidade de carga: mortalidade aleatória até as vagas.
  # O sorteio é por ÍNDICE e não por valor. Com uma característica só os dois são
  # equivalentes (sample sobre um vetor é sample.int seguido de indexação), mas o
  # Estudo 4 exige a forma por índice, porque lá z e p do mesmo filhote precisam
  # viajar juntos. Padronizado aqui para que os três motores tenham a mesma forma.
  vagas <- N_males_next + N_females_next
  idx   <- sample(seq_len(total_filhotes), size = vagas, replace = FALSE)
  meio  <- floor(vagas / 2)

  list(male_z_next   = z_filhotes[idx[1:meio]],
       female_z_next = z_filhotes[idx[(meio + 1):(2 * meio)]])
}


# =====================================================================
# EXECUÇÃO PARALELA DE CENÁRIOS (com backup e retomada)
# =====================================================================
# Roda os cenários PENDENTES em blocos, repartindo cada bloco entre vários
# núcleos com parallel::mclapply. O backup é salvo ao fim de cada bloco, então
# a retomada ("resume mágico") continua funcionando igual à versão serial.
#
# IMPORTANTE — os números não mudam: a semente é definida DENTRO de cada tarefa
# (set.seed(seed_base + i)), exatamente como na versão em série. Portanto o
# resultado do cenário i é idêntico ao que a execução sequencial produziria.
# A paralelização só muda a ORDEM em que os cenários são calculados.
#
#   cenarios       data.frame do desenho experimental (uma linha por cenário)
#   lista          lista de resultados (NULL onde ainda falta)
#   arquivo_backup caminho do .rds de backup
#   simular_i      função(i) que roda o cenário i e devolve o data.frame
#   n_cores        núcleos a usar
# =====================================================================
rodar_cenarios <- function(cenarios, lista, arquivo_backup, simular_i,
                           n_cores = 5, seed_base = 2026, tamanho_bloco = NULL,
                           idx_global = NULL) {
  # idx_global: índice ORIGINAL de cada cenário no desenho completo. Serve para que
  # a semente seja set.seed(seed_base + idx_global[i]) mesmo quando rodamos só um
  # subconjunto de réplicas em cada máquina — assim o cenário produz EXATAMENTE o
  # mesmo resultado que produziria numa corrida única e inteira.
  if (is.null(idx_global)) idx_global <- seq_len(nrow(cenarios))

  if (.Platform$OS.type == "windows" && n_cores > 1) {
    warning("mclapply não paraleliza no Windows; rodando com 1 núcleo.")
    n_cores <- 1
  }
  if (is.null(tamanho_bloco)) tamanho_bloco <- max(1, n_cores * 20)

  pendentes <- which(vapply(lista, is.null, logical(1)))
  if (length(pendentes) == 0) { cat("Nada pendente: todos os cenários já estão prontos.\n"); return(lista) }

  cat(sprintf("Pendentes: %d de %d cenários | %d núcleos | blocos de %d\n",
              length(pendentes), nrow(cenarios), n_cores, tamanho_bloco))
  flush.console()

  blocos <- split(pendentes, ceiling(seq_along(pendentes) / tamanho_bloco))
  t0 <- Sys.time(); feitos <- 0L; falhas <- 0L

  for (b in seq_along(blocos)) {
    idx <- blocos[[b]]

    res <- parallel::mclapply(idx, function(i) {
      set.seed(seed_base + idx_global[i])   # semente pelo índice GLOBAL
      tryCatch(simular_i(i), error = function(e) NULL)
    }, mc.cores = n_cores)

    for (j in seq_along(idx)) {
      r <- res[[j]]
      if (!is.null(r) && !inherits(r, "try-error") && is.data.frame(r) && nrow(r) > 0) {
        lista[[idx[j]]] <- r
      } else {
        falhas <- falhas + 1L
      }
    }

    saveRDS(lista, arquivo_backup)   # backup ao fim de cada bloco
    feitos <- feitos + length(idx)
    dt     <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
    resta  <- (length(pendentes) - feitos) * dt / feitos
    cat(sprintf("Bloco %d/%d | %d/%d cenários | %.1f min decorridos | ~%.0f min restantes | falhas: %d\n",
                b, length(blocos), feitos, length(pendentes), dt, resta, falhas))
    flush.console()
  }

  if (falhas > 0) cat(sprintf("ATENÇÃO: %d cenários falharam e ficaram NULL.\n", falhas))
  lista
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
    segregacao = c("infinitesimal", "fixa"), mut_sd = 0.05,
    return_details = FALSE, salvar_redes = FALSE, pasta_redes = NULL, replica_id = 1,
    selecao_natural = TRUE, k_fixo = NULL
) {
  segregacao <- match.arg(segregacao)   # sem isto o vetor de 2 elementos duplicaria cada linha do output
  
  male_z_gen1   <- pmax(0, rnorm(N_machos, mean = phi, sd = sigma_z_init))
  female_p_gen1 <- pmax(0, rnorm(N_femeas, mean = phi, sd = sigma_p))
  female_z_gen1 <- pmax(0, rnorm(N_femeas, mean = phi, sd = sigma_z_init)) 
  
  male_z_gen   <- male_z_gen1
  female_z_gen <- female_z_gen1
  
  out <- vector("list", generations)
  extincao_gen <- NA_integer_   # geração em que a réplica foi encerrada; NA = chegou ao fim
  M_final <- NULL; male_z_final <- NULL; female_p_final <- NULL

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
    
    # length(male_z_gen) em vez de N_machos: são sempre iguais no desenho atual,
    # mas escrito assim o passo nunca recicla um V mais curto se a população
    # encolher por algum motivo (o que gerava NA silenciosos).
    n_machos_atual <- length(male_z_gen)
    if (selecao_natural) {
      V <- exp(-gamma * (male_z_gen - phi)^2)
      survive <- runif(n_machos_atual) <= V
      survive <- ensure_min_survivors(survive, V, min_surv = 2)
    } else {
      survive <- rep(TRUE, n_machos_atual)  # V_j = 1: todos os machos sobrevivem
    }
    male_z_surv <- male_z_gen[survive]
    
    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao, encounters_n = encounters_n, k_fixo = k_fixo)
    metrics <- calc_metrics_from_M(M)
    
    if (t == generations && salvar_redes && !is.null(pasta_redes)) {
      salvar_rede_txt(M, replica_id, t, tipo_selecao, sigma_p, pasta_redes)
    }
    
    # CORREÇÃO: Salvamos a Média e a Variância apenas dos machos que SOBREVIVERAM (male_z_surv)!!!
    out[[t]] <- data.frame(
      generation = t, tipo_selecao = tipo_selecao, segregacao = segregacao,
      sigma_p = sigma_p, sigma_z_init = sigma_z_init, encounters_n = encounters_n,
      k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
      selecao_natural = selecao_natural,
      zbar_males = mean(male_z_surv), varz_males = var(male_z_surv),
      # Tamanho do pool de machos disponíveis. Não é constante: cai com sigma_z
      # quando a seleção natural está ligada, e isso muda a densidade da rede
      # independentemente de qualquer efeito da escolha feminina. Registrado para
      # poder entrar como covariável na análise.
      n_machos_surv = length(male_z_surv),
      metrics
    )
    
    if (t == generations && return_details == TRUE) {
      M_final <- M
      male_z_final <- male_z_surv
      female_p_final <- female_p
    }
    
    offspring <- produce_offspring(M, male_z_surv, female_z_gen, N_machos, N_femeas, eps_sd = eps_sd,
                                   segregacao = segregacao, mut_sd = mut_sd)
    # Réplica encerrada: não há filhotes suficientes para a geração seguinte.
    # Guardamos as gerações já rodadas e registramos ONDE parou, para que a perda
    # seja contável na análise em vez de virar uma réplica que some no filtro
    # generation == 100.
    if (is.null(offspring)) { extincao_gen <- t; break }
    male_z_gen   <- offspring$male_z_next
    female_z_gen <- offspring$female_z_next
  }

  df_out <- dplyr::bind_rows(out)
  df_out$extincao_gen <- extincao_gen

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
