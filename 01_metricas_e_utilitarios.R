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
calc_metrics_from_M <- function(M, k_alvo = NULL) {
  grau_femeas <- colSums(M)

  # Proporção de fêmeas que NÃO acasalaram. Sem a regra de escape, esta é a
  # medida direta da força de seleção agindo sobre a preferência feminina.
  prop_sem_acasalar <- if (ncol(M) > 0) mean(grau_femeas == 0) else NA_real_

  # ------------------------------------------------------------------
  # POLIANDRIA REALIZADA (variável resposta, não parâmetro)
  # ------------------------------------------------------------------
  # k é um TETO ("até quantos parceiros ela busca"), não uma cota garantida: a
  # fêmea para em k OU quando esgota os A_max machos avaliados. Quantos parceiros
  # ela de fato consegue depende da disponibilidade (A_max) e da própria curva de
  # preferência, que fixa a taxa de aceite. Por isso a poliandria precisa ser
  # MEDIDA e nunca lida do parâmetro nominal: com A_max = 10 e k = 20 o teto é
  # inalcançável por construção, e mesmo com A_max = 10 e k = 5 só uma parte das
  # fêmeas chega lá, em proporção que varia com a curva.
  grau_medio_femeas <- if (any(grau_femeas > 0)) mean(grau_femeas[grau_femeas > 0]) else NA_real_
  prop_atingiu_k <- if (!is.null(k_alvo) && !is.na(k_alvo) && ncol(M) > 0) {
    mean(grau_femeas >= as.numeric(k_alvo))
  } else NA_real_
  arestas <- sum(M)

  # As métricas de rede EXCLUEM as fêmeas sem acasalamento (colunas de zeros):
  # elas entrariam como nós isolados e inflariam artificialmente tribos/modularidade.
  # Machos com grau 0 são MANTIDOS — são justamente o sinal da seleção sexual (Is).
  Mm <- M[, grau_femeas > 0, drop = FALSE]

  if (ncol(Mm) == 0) {
    return(data.frame(I_s = NA_real_, Modularity = NA_real_, Nestedness = NA_real_,
                      Centralization = NA_real_,
                      prop_femeas_sem_acasalar = prop_sem_acasalar,
                      grau_medio_femeas = grau_medio_femeas,
                      prop_femeas_atingiu_k = prop_atingiu_k,
                      arestas = arestas))
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
    prop_femeas_sem_acasalar = prop_sem_acasalar,
    grau_medio_femeas = grau_medio_femeas,       # poliandria REALIZADA
    prop_femeas_atingiu_k = prop_atingiu_k,      # quantas chegaram ao teto k
    arestas = arestas                            # densidade da rede
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

# =====================================================================
# CENSO DE ADULTOS CONSTANTE
# =====================================================================
# A seleção natural de viabilidade age sobre JUVENIS, antes do censo de adultos.
# O pool adulto tem sempre N_adultos machos, com ou sem seleção natural.
#
# POR QUE ISTO IMPORTA
# Na versão anterior a viabilidade agia sobre os 200 machos adultos, então o
# número de machos disponíveis para acasalar CAÍA com sigma_z: cerca de 198 com
# sigma_z = 0.2 e cerca de 124 com sigma_z = 2.0, porque a fração que sobrevive é
# 1/sqrt(1 + 2*gamma*sigma_z^2). Como o número de fêmeas e o k não mudavam, o
# mesmo número de arestas se repartia entre menos machos e o grau médio dos machos
# subia de ~5.1 para ~8.1 ao longo do gradiente. Isso mexia sozinho em Is,
# centralização e aninhamento, sem nenhuma relação com a escolha feminina, e
# confundia justamente o eixo dos Estudos 1 e 3.
# Agora a seleção natural muda QUAIS machos estão disponíveis (a distribuição do
# traço, que é o que queremos) sem mudar QUANTOS (que era o confundimento).
#
# Devolve ÍNDICES e não valores, para que características pareadas (o p que o
# macho carrega no Estudo 3, e o par (z, p) no Estudo 4) acompanhem o mesmo macho.
# =====================================================================
selecionar_machos_adultos <- function(z_juv, N_adultos, phi = 5, gamma = 0.2,
                                      selecao_natural = TRUE) {
  n <- length(z_juv)

  if (!selecao_natural) {
    # V_j = 1: nenhuma mortalidade seletiva, o censo é uma amostra aleatória
    return(if (n <= N_adultos) seq_len(n) else sample.int(n, N_adultos))
  }

  V   <- exp(-gamma * (z_juv - phi)^2)
  idx <- which(runif(n) <= V)

  if (length(idx) > N_adultos) {
    # sobraram mais do que as vagas: censo aleatório entre os sobreviventes
    idx <- idx[sample.int(length(idx), N_adultos)]
  } else if (length(idx) < 2) {
    # trava de segurança (equivalente ao antigo ensure_min_survivors): a rede
    # precisa de ao menos 2 machos para as métricas fazerem sentido
    idx <- order(V, decreasing = TRUE)[seq_len(min(2, n))]
  }
  idx
}

# =====================================================================
# A REGRA DE ESCOLHA (decisão da reunião com o Miudo, 2026-08)
# =====================================================================
# São duas famílias clássicas na literatura de escolha de parceiro, e a
# diferença entre elas é biológica e não técnica: elas supõem coisas
# diferentes sobre o que a fêmea consegue fazer.
#
# "sequencial" — regra de umbral fixo (Janetos 1980; Real 1990). A fêmea
#   avalia um macho de cada vez, decide na hora, nunca compara nem volta
#   atrás, e PARA assim que junta k parceiros. É o que o modelo fazia até
#   agora. Barata cognitivamente, e realista quando os machos aparecem
#   espalhados no tempo ou no espaço.
#
#   O problema que isso trouxe: com a parada antecipada, A_max deixava de
#   ser o número de machos avaliados e virava um teto que quase nunca era
#   alcançado. Com a curva aleatória e k = 5, a fêmea junta 5 aceites em
#   umas 10 avaliações, então o cenário A_max = 200 e o cenário A_max = 40
#   eram na prática o mesmo: o custo de busca que dizíamos modelar não
#   chegava a ser pago.
#
# "best_of_n" — comparação em pool. A fêmea avalia os A_max machos, todos,
#   e só depois escolhe. É o default agora. Supõe que ela consegue amostrar
#   antes de decidir, que é o típico de leks e agregações.
#
#   Aqui a escolha tem dois passos, e os dois importam. Primeiro cada macho
#   avaliado é aceitável ou não, com probabilidade P_ij, que é o filtro da
#   curva de preferência. Depois, entre os aceitáveis, ela fica com os k de
#   maior P_ij. Manter o primeiro passo é o que preserva duas coisas que o
#   modelo precisa: a exigência s continua importando (ela governa quantos
#   passam o filtro), e uma fêmea que não aceita ninguém continua ficando
#   sem acasalar, que é a variância de fitness de que o estudo dos machos
#   depende.
#
# "best_of_n_estrito" — a versão sem filtro: ela avalia os A_max e fica
#   direto com os k de maior P_ij. É a leitura literal de "os k mais bem
#   ajustados", e dá a interpretação limpa de seleção por truncamento, com
#   k/A_max como proporção selecionada.
#
#   ATENÇÃO ao usá-la. Como o ranking só depende da ORDEM que a curva
#   induz, e exp(-s d^2) é monótona em d para qualquer s > 0, a exigência s
#   vira um parâmetro inerte. E toda fêmea consegue exatamente k parceiros,
#   então NENHUMA fica sem acasalar: sem variância de sucesso reprodutivo
#   entre fêmeas, não há seleção sobre a preferência e o estudo dos machos
#   variando deixa de funcionar. Fica disponível para comparação, não para
#   rodar o desenho inteiro.
#
# Nas três regras o ranking por P_ij faz a coisa certa em cada curva:
# gaussiana ordena do mais parecido ao mais diferente, u-shaped o inverso,
# sigmoide do maior z ao menor, e a aleatória empata tudo — e como a ordem
# de avaliação já é um sorteio, o empate se resolve ao acaso, que é
# exatamente o que "não discriminar" quer dizer.
# =====================================================================
mate_with_survivors <- function(male_z_surv, female_p, female_s, tipo_selecao,
                                min_cop = 1, max_cop = 5, encounters_n = 200,
                                k_fixo = NULL,
                                regra = c("best_of_n", "best_of_n_estrito", "sequencial")) {
  regra <- match.arg(regra)
  n_m <- length(male_z_surv); n_f <- length(female_p)
  matings_per_female <- if (!is.null(k_fixo)) rep(as.integer(k_fixo), n_f) else sample(min_cop:max_cop, n_f, replace = TRUE)
  M <- matrix(0L, nrow = n_m, ncol = n_f)

  prob_aceite <- function(z, p_i, s_i) {
    if (tipo_selecao == "uniform")       rep(0.5, length(z))
    else if (tipo_selecao == "gaussian") exp(-s_i * (z - p_i)^2)
    else if (tipo_selecao == "sigmoid")  1 / (1 + exp(-s_i * (z - p_i)))
    else if (tipo_selecao == "u-shaped") 1 - exp(-s_i * (z - p_i)^2)
    else stop("tipo_selecao desconhecido: ", tipo_selecao)
  }

  for (i in seq_len(n_f)) {
    p_i <- female_p[i]; s_i <- female_s[i]; k_i <- matings_per_female[i]

    # SEM reposição: A_max é o número de machos DISTINTOS avaliados
    # (decisão da reunião com Erika e Miudo). A ordem é um sorteio novo
    # para cada fêmea, então não existe viés de posição.
    n_aval    <- min(encounters_n, n_m)
    avaliados <- sample(seq_len(n_m), size = n_aval, replace = FALSE)
    P         <- prob_aceite(male_z_surv[avaliados], p_i, s_i)

    escolhidos <-
      if (regra == "sequencial") {
        aceitos <- integer(0)
        for (j in seq_len(n_aval)) {
          if (length(aceitos) >= k_i) break          # PARA ao atingir k
          if (runif(1) <= P[j]) aceitos <- c(aceitos, avaliados[j])
        }
        aceitos

      } else if (regra == "best_of_n") {
        aceitos <- which(runif(n_aval) <= P)         # avalia TODOS, sem parar
        if (length(aceitos) > k_i)                    # e só então compara
          aceitos <- aceitos[order(P[aceitos], decreasing = TRUE)][seq_len(k_i)]
        avaliados[aceitos]

      } else {                                       # best_of_n_estrito
        if (n_aval <= k_i) avaliados
        else avaliados[order(P, decreasing = TRUE)[seq_len(k_i)]]
      }

    if (length(escolhidos)) M[escolhidos, i] <- 1L
  }

  # SEM regra de escape (decisão Erika/Miudo, 2026-07): uma fêmea que não
  # aceita nenhum macho fica SEM acasalar e deixa 0 filhotes. Isso cria
  # variância de fitness entre fêmeas, que é condição necessária para a
  # preferência poder estar sob seleção no estudo dos machos variando.
  # Em "best_of_n_estrito" isso deixa de valer, como avisado acima.
  M
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
  # O mínimo é o necessário para que, depois do sexo 1:1 e da viabilidade, ainda
  # sobrem N adultos de cada sexo no pior caso do gradiente (sobrevivência ~0.62
  # com sigma_z = 2.0): 800 filhotes dão 400 juvenis de cada sexo, e 400 * 0.62 =
  # 248 machos sobreviventes para as 200 vagas.
  if (total_filhotes < 2 * (N_males_next + N_females_next)) return(NULL)

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
  # TODOS os filhotes são juvenis: o sexo é atribuído ao acaso, 1:1. Não há
  # capacidade de carga aqui. Ela é imposta no início da geração seguinte, no
  # censo dos N adultos de cada sexo, depois da viabilidade.
  # O sorteio é por ÍNDICE e não por valor. Com uma característica só os dois são
  # equivalentes, mas o Estudo 4 exige a forma por índice, porque lá z e p do
  # mesmo filhote precisam viajar juntos. Padronizado nos três motores.
  idx  <- sample.int(total_filhotes)
  meio <- total_filhotes %/% 2

  list(male_z_juv   = z_filhotes[idx[seq_len(meio)]],
       female_z_juv = z_filhotes[idx[(meio + 1):(2 * meio)]])
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
    segregacao = c("infinitesimal", "fixa"), mut_sd = 0.05, fecundidade_base = 50,
    return_details = FALSE, salvar_redes = FALSE, pasta_redes = NULL, replica_id = 1,
    selecao_natural = TRUE, k_fixo = NULL,
    regra = c("best_of_n", "best_of_n_estrito", "sequencial")
) {
  regra <- match.arg(regra)
  segregacao <- match.arg(segregacao)   # sem isto o vetor de 2 elementos duplicaria cada linha do output

  # Os dois sexos entram na geração como JUVENIS, em número igual (razão sexual
  # primária 1:1). A viabilidade age sobre os juvenis machos e o censo fixa a
  # população adulta em N_machos e N_femeas (ver selecionar_machos_adultos).
  # O tamanho do pool de juvenis não é um parâmetro livre: é o que a fecundidade
  # produz, N_femeas * F filhotes repartidos entre os dois sexos.
  N_juvenis     <- N_femeas * fecundidade_base %/% 2

  male_z_gen1   <- pmax(0, rnorm(N_juvenis, mean = phi, sd = sigma_z_init))
  female_p_gen1 <- pmax(0, rnorm(N_femeas, mean = phi, sd = sigma_p))
  female_z_gen1 <- pmax(0, rnorm(N_juvenis, mean = phi, sd = sigma_z_init))

  male_z_juv   <- male_z_gen1
  female_z_juv <- female_z_gen1

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
    
    # CENSO DE ADULTOS: a viabilidade age sobre os juvenis machos e sobram sempre
    # N_machos adultos, com ou sem seleção natural. Assim a seleção muda a
    # distribuição do traço sem mudar a densidade da rede. As fêmeas não passam
    # por viabilidade, então o censo delas é um sorteio aleatório entre as juvenis.
    idx_adultos  <- selecionar_machos_adultos(male_z_juv, N_machos, phi, gamma, selecao_natural)
    male_z_surv  <- male_z_juv[idx_adultos]
    female_z_gen <- female_z_juv[sample.int(length(female_z_juv), N_femeas)]

    M <- mate_with_survivors(male_z_surv, female_p, female_s, tipo_selecao,
                             encounters_n = encounters_n, k_fixo = k_fixo, regra = regra)
    metrics <- calc_metrics_from_M(M, k_alvo = k_fixo)
    
    if (t == generations && salvar_redes && !is.null(pasta_redes)) {
      salvar_rede_txt(M, replica_id, t, tipo_selecao, sigma_p, pasta_redes)
    }
    
    # CORREÇÃO: Salvamos a Média e a Variância apenas dos machos que SOBREVIVERAM (male_z_surv)!!!
    out[[t]] <- data.frame(
      generation = t, tipo_selecao = tipo_selecao, segregacao = segregacao,
      regra = regra,
      sigma_p = sigma_p, sigma_z_init = sigma_z_init, encounters_n = encounters_n,
      k_fixo = ifelse(is.null(k_fixo), NA_integer_, as.integer(k_fixo)),
      selecao_natural = selecao_natural,
      zbar_males = mean(male_z_surv), varz_males = var(male_z_surv),
      # Tamanho do censo adulto de machos. Com o censo constante deve ser sempre
      # igual a N_machos; fica registrado como verificação, para flagrar na hora
      # qualquer cenário em que a trava de segurança dos 2 machos tenha entrado.
      n_machos_surv = length(male_z_surv),
      metrics
    )
    
    if (t == generations && return_details == TRUE) {
      M_final <- M
      male_z_final <- male_z_surv
      female_p_final <- female_p
    }
    
    offspring <- produce_offspring(M, male_z_surv, female_z_gen, N_machos, N_femeas,
                                   fecundidade_base = fecundidade_base, eps_sd = eps_sd,
                                   segregacao = segregacao, mut_sd = mut_sd)
    # Réplica encerrada: não há filhotes suficientes para a geração seguinte.
    # Guardamos as gerações já rodadas e registramos ONDE parou, para que a perda
    # seja contável na análise em vez de virar uma réplica que some no filtro
    # generation == 100.
    if (is.null(offspring)) { extincao_gen <- t; break }
    male_z_juv   <- offspring$male_z_juv
    female_z_juv <- offspring$female_z_juv
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
