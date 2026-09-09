# =====================================================================
# FIGURA CONCEITUAL: O QUE sigma_p FAZ
# =====================================================================
#     Rscript 10_Figuras_conceituais.R
#
# O tratamento central dos Estudos 1 e 2 é sigma_p, a variação entre fêmeas nos
# picos de preferência. É fácil de dizer e difícil de ver, então esta figura
# mostra o que ele significa em três níveis, com as duas pontas do gradiente
# lado a lado.
#
# Não é um desenho esquemático: as duas colunas saem do motor de verdade, com a
# MESMA população de machos e o mesmo mate_with_survivors dos estudos. As
# métricas que aparecem nos subtítulos são as métricas de rede calculadas ali.
#
# Fica como função, para poder ser chamada de dentro da apresentação e dos
# documentos sem duplicar código:
#
#     source("10_Figuras_conceituais.R")
#     figura_sigma_p()
# =====================================================================

source("01_metricas_e_utilitarios.R")
# O motor do espelho, só as funções: sem a guarda ele roda o experimento inteiro
# ao ser lido.
ESPELHO_SO_FUNCOES <- TRUE
source("Fase_Espelho.R")
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(patchwork)
})

# ---------------------------------------------------------------------
# O MECANISMO, PARA QUALQUER DOS DOIS EIXOS
# ---------------------------------------------------------------------
# Uma função só para os Estudos 2 e 3, porque eles são espelhos e a figura
# também deve ser. O que muda entre os dois:
#
#   eixo = "sigma_p" (Estudo 2). Os machos são sempre os mesmos e o que varia
#     entre as colunas é o quanto as fêmeas discordam entre si. A linha de
#     baixo mostra o sucesso dos MACHOS, porque é sobre eles que a seleção
#     sexual está agindo.
#
#   eixo = "sigma_z" (Estudo 3). As fêmeas são sempre as mesmas, com as mesmas
#     curvas de aceite, e o que varia é a variedade de machos disponíveis. A
#     linha de baixo mostra o sucesso das FÊMEAS, porque agora quem fica de
#     fora é a fêmea cujo pico não encontra ninguém, e é essa a seleção que
#     age sobre a preferência.
#
# As duas primeiras linhas são idênticas nos dois casos, de propósito: é o
# mesmo mecanismo visto do mesmo ângulo, com a variação trocada de lado.
figura_eixo <- function(eixo = c("sigma_p", "sigma_z"),
                        baixo = 0.2, alto = 2.0, fixo = 1.0,
                        N = 200, phi = 5, s_media = 2, sigma_s = 0.2,
                        k = 5L, A_max = 200L, tipo = "gaussian",
                        n_curvas = 14, seed = 42) {

  eixo <- match.arg(eixo)
  varia_femeas <- eixo == "sigma_p"

  set.seed(seed)
  # O lado que NÃO varia é sorteado uma vez só e reaproveitado nas duas
  # colunas: assim a única diferença entre elas é o eixo do experimento.
  s_all <- pmax(0, rnorm(N, s_media, sigma_s))
  if (varia_femeas) male_z_fixo   <- pmax(0, rnorm(N, phi, fixo))
  else              female_p_fixo <- pmax(0, rnorm(N, phi, fixo))

  um_lado <- function(sigma) {
    set.seed(seed + round(sigma * 1000))
    if (varia_femeas) {
      male_z   <- male_z_fixo
      female_p <- pmax(0, rnorm(N, phi, sigma))
    } else {
      male_z   <- pmax(0, rnorm(N, phi, sigma))
      female_p <- female_p_fixo
    }
    M   <- mate_with_survivors(male_z, female_p, s_all, tipo,
                               encounters_n = A_max, k_fixo = k)
    met <- calc_metrics_from_M(M, k_alvo = k)
    ar  <- which(M == 1L, arr.ind = TRUE)
    list(z = male_z, p = female_p, s = s_all, M = M, met = met, sigma = sigma,
         pares = tibble(z_macho = male_z[ar[, 1]], p_femea = female_p[ar[, 2]]))
  }

  lado_baixo <- um_lado(baixo)
  lado_alto  <- um_lado(alto)

  amplitude <- max(alto, fixo, 1)
  grade_z <- seq(max(0, phi - 4 * amplitude), phi + 4 * amplitude, length.out = 400)

  letra <- if (varia_femeas) "σp" else "σz"
  titulo <- function(lado, texto) {
    sprintf("%s  (%s = %.1f)\nmodularidade %.2f | centralização %.2f | Is %.2f",
            texto, letra, lado$sigma,
            lado$met$Modularity, lado$met$Centralization, lado$met$I_s)
  }

  # ---- linha 1: cada fêmea é uma curva de aceite -----------------------
  # No Estudo 2 é aqui que a diferença salta: com sigma_p pequeno as curvas se
  # empilham umas sobre as outras, e com sigma_p grande se espalham. No Estudo 3
  # as curvas são as MESMAS nas duas colunas, e o que muda são os machos
  # marcados no eixo de baixo. Ver as curvas paradas enquanto o material muda é
  # justamente o que o Estudo 3 quer dizer.
  curvas <- function(lado) {
    idx <- sample(seq_len(N), n_curvas)
    df <- bind_rows(lapply(idx, function(i) {
      tibble(femea = i, z = grade_z, P = prob_de_aceite(grade_z, lado$p[i], lado$s[i], tipo))
    }))
    ggplot(df, aes(z, P, group = femea)) +
      geom_line(color = "#E6B800", alpha = 0.75, linewidth = 0.7) +
      geom_rug(data = tibble(z = lado$z), aes(x = z), inherit.aes = FALSE,
               sides = "b", alpha = 0.25, length = unit(0.05, "npc")) +
      coord_cartesian(xlim = range(grade_z), ylim = c(0, 1)) +
      labs(x = NULL, y = "P(aceitar)") +
      theme_light(base_size = 12)
  }

  # ---- linha 2: quem acasalou com quem ---------------------------------
  # Cada ponto é um casal, com o traço do macho no x e o pico da fêmea no y. A
  # diagonal marca onde os dois coincidem, então pontos ao longo dela são
  # acasalamento assortativo.
  #
  # O traço do macho fica no x nas TRÊS linhas de propósito, para que o eixo de
  # baixo, que o patchwork compartilha, queira dizer a mesma coisa em todas.
  casais <- function(lado) {
    ggplot(lado$pares, aes(z_macho, p_femea)) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray55") +
      geom_point(alpha = 0.25, size = 1.5, color = "#3BA273") +
      coord_cartesian(xlim = range(grade_z), ylim = range(grade_z)) +
      labs(x = NULL, y = "pico da fêmea (p)") +
      theme_light(base_size = 12)
  }

  # ---- linha 3: de que lado cai o sucesso ------------------------------
  # O eixo vertical é o MESMO nas duas colunas, senão a coluna em que poucos
  # levam tudo pareceria igual à outra, que é justo a diferença a mostrar.
  grau_de <- function(lado) if (varia_femeas) rowSums(lado$M) else colSums(lado$M)
  grau_max <- max(grau_de(lado_baixo), grau_de(lado_alto))
  sucesso <- function(lado) {
    g <- if (varia_femeas) tibble(x = lado$z, grau = rowSums(lado$M))
         else              tibble(x = lado$p, grau = colSums(lado$M))
    ggplot(g, aes(x, grau)) +
      geom_point(alpha = 0.45, size = 1.6, color = "#9932CC") +
      coord_cartesian(xlim = range(grade_z), ylim = c(0, grau_max)) +
      labs(x = if (varia_femeas) "traço do macho (z)" else "pico da fêmea (p)",
           y = if (varia_femeas) "parceiras do macho" else "parceiros da fêmea") +
      theme_light(base_size = 12)
  }

  col <- function(lado, texto) {
    (curvas(lado) + ggtitle(titulo(lado, texto))) / casais(lado) / sucesso(lado)
  }

  rotulos <- if (varia_femeas)
    c("Fêmeas concordam: todas querem o mesmo",
      "Fêmeas discordam: cada uma quer uma coisa")
  else
    c("Machos parecidos: pouca coisa para escolher",
      "Machos variados: há de tudo para escolher")

  (col(lado_baixo, rotulos[1]) | col(lado_alto, rotulos[2])) +
    plot_annotation(
      title = if (varia_femeas)
        "Estudo 2: o que sigma_p faz" else "Estudo 3: o que sigma_z faz",
      subtitle = sprintf(
        "Preferência %s | %s nas duas colunas | %d machos e %d fêmeas | A_max = %d | k = %d | uma geração",
        tipo,
        if (varia_femeas) sprintf("os MESMOS machos, z ~ N(%g, %g)", phi, fixo)
        else sprintf("as MESMAS fêmeas, p ~ N(%g, %g)", phi, fixo),
        N, N, A_max, k),
      caption = paste0(
        "O eixo de baixo é o traço do macho nas duas primeiras linhas.\n",
        "Linha 1: a curva de aceite de ", n_curvas, " fêmeas sorteadas, e os machos disponíveis marcados no eixo.\n",
        "Linha 2: cada ponto é um casal, e a diagonal marca onde o macho é igual ao pico da fêmea.\n",
        if (varia_femeas) "Linha 3: quantas parceiras cada macho teve."
        else "Linha 3: quantos parceiros cada fêmea teve, contra o seu próprio pico."),
      theme = theme(plot.title = element_text(face = "bold", size = 15)))
}

# A curva de aceite, na mesma forma que mate_with_survivors usa. Fica aqui
# porque lá dentro ela é local à função e não dá para chamar de fora.
prob_de_aceite <- function(z, p, s, tipo) {
  switch(tipo,
         "uniform"  = rep(0.5, length(z)),
         "gaussian" = exp(-s * (z - p)^2),
         "sigmoid"  = 1 / (1 + exp(-s * (z - p))),
         "u-shaped" = 1 - exp(-s * (z - p)^2),
         stop("tipo desconhecido: ", tipo))
}

# Os dois nomes antigos continuam funcionando, agora como atalhos.
figura_sigma_p <- function(...) figura_eixo("sigma_p", ...)
figura_sigma_z <- function(...) figura_eixo("sigma_z", ...)

# =====================================================================
# AS MESMAS QUATRO SITUAÇÕES, DESENHADAS COMO REDE
# =====================================================================
# A matriz ordenada mostra a estrutura, mas quem trabalha com redes lê melhor
# uma rede. Aqui são os mesmos quatro cantos, pequenos o bastante para que os
# nós se distingam, com as cores vindo do Louvain, que é exatamente o algoritmo
# que a métrica de modularidade usa. Assim os módulos que aparecem na figura
# são os módulos que o número conta, e não uma impressão visual paralela.
#
# É base R e não ggplot porque a função de desenho de rede do igraph é a que os
# outros scripts do projeto já usam.
# De uma matriz de acasalamentos para uma rede desenhável. As cores saem do
# cluster_louvain, que é o próprio algoritmo da métrica de modularidade, então
# os módulos que se veem são os que o número conta, e não uma impressão visual
# paralela. Quem não acasalou fica cinza: é informação, não sujeira.
preparar_rede <- function(M, seed_layout = 2026) {
  n_m <- nrow(M); n_f <- ncol(M)
  adj <- matrix(0L, n_m + n_f, n_m + n_f)
  adj[1:n_m, (n_m + 1):(n_m + n_f)] <- M
  adj[(n_m + 1):(n_m + n_f), 1:n_m] <- t(M)
  g <- igraph::graph_from_adjacency_matrix(adj, mode = "undirected")
  igraph::V(g)$type <- c(rep(TRUE, n_m), rep(FALSE, n_f))

  memb  <- igraph::membership(igraph::cluster_louvain(g))
  n_com <- length(unique(memb))
  paleta <- grDevices::colorRampPalette(
    c("#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00","#A65628","#F781BF","#999999"))(n_com)
  cores <- paleta[memb]
  cores[igraph::degree(g) == 0] <- "gray85"

  set.seed(seed_layout)
  list(g = g, cores = cores, layout = igraph::layout_with_fr(g),
       formas = ifelse(igraph::V(g)$type, "square", "circle"),
       n_com = n_com,
       sem = sum(igraph::degree(g)[(n_m + 1):(n_m + n_f)] == 0))
}

desenhar_rede <- function(r, titulo, tamanho = 7) {
  plot(r$g, layout = r$layout, vertex.color = r$cores,
       vertex.shape = r$formas, vertex.size = tamanho, vertex.label = NA,
       vertex.frame.color = grDevices::rgb(0, 0, 0, 0.25),
       edge.color = grDevices::rgb(0.4, 0.4, 0.4, 0.35), edge.width = 1)
  title(main = titulo, cex.main = 1.05, font.main = 1)
}

figura_redes <- function(sigma_baixo = 0.2, sigma_alto = 2.0,
                         N = 40, phi = 5, s_media = 2, sigma_s = 0.2,
                         k = 3L, tipo = "gaussian", seed = 11) {

  um_canto <- function(sz, sp) {
    set.seed(seed + round(100 * sz) + round(10000 * sp))
    male_z   <- pmax(0, rnorm(N, phi, sz))
    female_p <- pmax(0, rnorm(N, phi, sp))
    s_all    <- pmax(0, rnorm(N, s_media, sigma_s))
    M   <- mate_with_survivors(male_z, female_p, s_all, tipo,
                               encounters_n = N, k_fixo = k)
    met <- calc_metrics_from_M(M, k_alvo = k)

    c(preparar_rede(M), list(met = met))
  }

  cantos <- list(
    list(sz = sigma_baixo, sp = sigma_baixo, tit = "machos parecidos, fêmeas concordam"),
    list(sz = sigma_alto,  sp = sigma_baixo, tit = "machos variados, fêmeas concordam"),
    list(sz = sigma_baixo, sp = sigma_alto,  tit = "machos parecidos, fêmeas discordam"),
    list(sz = sigma_alto,  sp = sigma_alto,  tit = "machos variados, fêmeas discordam")
  )

  op <- par(mfrow = c(2, 2), mar = c(1.5, 1.5, 4.5, 1.5), oma = c(3, 0, 3, 0))
  on.exit(par(op), add = TRUE)
  for (cc in cantos) {
    r <- um_canto(cc$sz, cc$sp)
    desenhar_rede(r, sprintf("%s  (σz = %.1f, σp = %.1f)\nmodularidade %.2f | %d módulos | %d fêmeas sem acasalar",
                             cc$tit, cc$sz, cc$sp, r$met$Modularity, r$n_com, r$sem))
  }
  mtext("A mesma regra de escolha, quatro composições da população",
        outer = TRUE, side = 3, line = 0.5, cex = 1.3, font = 2)
  mtext("Quadrados: machos.  Círculos: fêmeas.  Cores: comunidades do Louvain, que é o algoritmo da métrica de modularidade.  Cinza: sem acasalar.",
        outer = TRUE, side = 1, line = 1, cex = 0.8, col = "gray30")
  invisible(NULL)
}

# =====================================================================
# A REDE ANTES E DEPOIS DE CEM GERAÇÕES
# =====================================================================
# figura_redes() mostra o Estudo 1, que é uma geração só. Para os Estudos 2 e 3
# a pergunta é outra: o que a evolução FEZ com a rede. Então são quatro painéis,
# a dispersão baixa e a alta nas linhas, e a geração 1 contra a 100 nas colunas.
#
# Roda o motor de verdade, com N = 200 como nos estudos, e não uma versão
# encolhida: numa população pequena a deriva domina e a figura mostraria outra
# coisa. Com 400 nós o desenho fica denso, e por isso os pontos são pequenos,
# como nas redes representativas do 06_Rede_Representativa_e_3Atos.R.
#
# São quatro simulações de cem gerações, uns dois minutos ao todo.
figura_rede_evolucao <- function(estudo = c("2", "3"),
                                 baixo = 0.2, alto = 2.0, fixo = 1.0,
                                 geracoes = 100, N = 200,
                                 tipo = "gaussian", k = 5L, A_max = 200L,
                                 selecao_natural = FALSE, seed = 5) {
  estudo <- match.arg(estudo)

  # Sem seleção natural por padrão, e de propósito: é o regime em que o censo é
  # sempre 200 por construção, então as quatro redes têm o mesmo tamanho e a
  # comparação entre elas é sobre a estrutura e não sobre quantos sobraram.
  uma <- function(sigma) {
    set.seed(seed + round(sigma * 1000))
    if (estudo == "2") {
      simulate_evolution(generations = geracoes, N_machos = N, N_femeas = N,
                         sigma_p = sigma, sigma_z_init = fixo,
                         tipo_selecao = tipo, encounters_n = A_max, k_fixo = k,
                         selecao_natural = selecao_natural, return_details = TRUE)
    } else {
      simulate_espelho(generations = geracoes, N_machos = N, N_femeas = N,
                       sigma_z = sigma, sigma_p_init = fixo,
                       tipo_selecao = tipo, encounters_n = A_max, k_fixo = k,
                       selecao_natural = selecao_natural, return_details = TRUE)
    }
  }

  res <- list(baixo = uma(baixo), alto = uma(alto))
  letra   <- if (estudo == "2") "σp" else "σz"
  o_que   <- if (estudo == "2") "o traço do macho" else "a preferência da fêmea"
  # a coluna que interessa em cada estudo é a da característica que evolui
  coluna  <- if (estudo == "2") "varz_males" else "varp_femeas"
  nome_var <- if (estudo == "2") "var(z)" else "var(p)"

  op <- par(mfrow = c(2, 2), mar = c(1.5, 1.5, 4.5, 1.5), oma = c(3.5, 0, 4, 0))
  on.exit(par(op), add = TRUE)

  for (nome in c("baixo", "alto")) {
    r <- res[[nome]]
    sigma <- if (nome == "baixo") baixo else alto
    for (quando in c("rede_gen1", "rede_final")) {
      d <- r[[quando]]
      tab <- r$dados_tabela
      v <- tab[[coluna]][tab$generation == d$geracao]
      desenhar_rede(preparar_rede(d$M),
                    sprintf("%s = %.1f, geração %d\nmodularidade %.2f | Is %.2f | %s = %.2f",
                            letra, sigma, d$geracao,
                            d$metrics$Modularity, d$metrics$I_s, nome_var, v),
                    tamanho = 4)
    }
  }
  mtext(sprintf("Estudo %s: o que cem gerações fazem com a rede", estudo),
        outer = TRUE, side = 3, line = 1.5, cex = 1.3, font = 2)
  mtext(sprintf("%s evolui | preferência %s | %d machos e %d fêmeas | A_max = %d | k = %d | %s",
                o_que, tipo, N, N, A_max, k,
                if (selecao_natural) "com seleção natural" else "sem seleção natural"),
        outer = TRUE, side = 3, line = 0.2, cex = 0.85, col = "gray30")
  mtext("Quadrados: machos.  Círculos: fêmeas.  Cores: comunidades do Louvain.  Cinza: sem acasalar.",
        outer = TRUE, side = 1, line = 1.2, cex = 0.8, col = "gray30")
  invisible(NULL)
}

# =====================================================================
# O DESENHO DOS QUATRO ESTUDOS NO MESMO PLANO
# =====================================================================
# Um esquema, este sim, e não saída do motor. Serve para dizer numa figura só
# o que cada estudo fixa e o que deixa evoluir.
figura_desenho <- function(valores = c(0.2, 0.5, 1.0, 1.5, 2.0)) {
  grade <- expand.grid(sigma_z = valores, sigma_p = valores)

  painel <- function(titulo, subtitulo, setas = NULL, pontos = TRUE) {
    g <- ggplot(grade, aes(sigma_z, sigma_p)) +
      labs(title = titulo, subtitle = subtitulo,
           x = expression(sigma[z]~"(variação entre machos)"),
           y = expression(sigma[p]~"(variação entre fêmeas)")) +
      theme_light(base_size = 11) +
      theme(plot.title = element_text(face = "bold", size = 12))
    if (pontos) g <- g + geom_point(color = "gray45", size = 1.6)
    if (!is.null(setas))
      g <- g + geom_segment(data = setas,
                            aes(x = x, y = y, xend = xend, yend = yend),
                            inherit.aes = FALSE, color = "#C0392B", linewidth = 0.7,
                            arrow = arrow(length = unit(0.16, "cm"), type = "closed"))
    g
  }

  # Estudo 2: sigma_p é imposto e sigma_z é livre, então o ponto anda na
  # horizontal. Estudo 3 é o espelho. Estudo 4 não tem nada imposto.
  h <- data.frame(x = 1.0, y = valores, xend = 1.75, yend = valores)
  v <- data.frame(x = valores, y = 1.0, xend = valores, yend = 1.75)
  d4 <- data.frame(x = 1.0, y = 1.0, xend = c(1.7, 0.4, 1.6, 0.5),
                   yend = c(1.6, 1.7, 0.45, 0.4))

  (painel("1. Controle", "nada evolui: mede a topologia sobre a grade inteira") |
      painel("2. Fêmeas variando", "sigma_p imposto, o traço do macho evolui", setas = h)) /
    (painel("3. Machos variando", "sigma_z imposto, a preferência evolui", setas = v) |
       painel("4. Co-evolução", "nada imposto: as duas evoluem juntas",
              setas = d4, pontos = FALSE)) +
    plot_annotation(
      title = "Os quatro estudos no mesmo plano",
      subtitle = "Os pontos cinza são as condições iniciais do desenho; as setas vermelhas, o que fica livre para se mover ao longo das 100 gerações",
      theme = theme(plot.title = element_text(face = "bold", size = 15)))
}

# Ao rodar como script, salva os três arquivos. Ao ser lido com source(), só
# define as funções.
if (!interactive() && sys.nframe() == 0) {
  dir.create("Resultados_Artigo/Figuras", recursive = TRUE, showWarnings = FALSE)
  saidas <- list(
    list(f = figura_desenho, nome = "figura_desenho.png",       w = 10, h = 8),
    list(f = figura_cantos,  nome = "figura_quatro_cantos.png", w = 10, h = 8),
    list(f = figura_sigma_p, nome = "figura_sigma_p.png",       w = 11, h = 8.5),
    list(f = figura_sigma_z, nome = "figura_sigma_z.png",       w = 11, h = 8.5)
  )
  for (s in saidas) {
    destino <- file.path("Resultados_Artigo/Figuras", s$nome)
    ggsave(destino, s$f(), width = s$w, height = s$h, dpi = 150)
    cat("Figura em", destino, "\n")
  }
  # figura_redes desenha com o igraph, que escreve direto no dispositivo em vez
  # de devolver um objeto, então precisa de png() e dev.off() em volta.
  base_r <- list(
    list(f = function() figura_redes(),                 nome = "figura_redes.png"),
    list(f = function() figura_rede_evolucao("2"),       nome = "figura_rede_estudo2.png"),
    list(f = function() figura_rede_evolucao("3"),       nome = "figura_rede_estudo3.png")
  )
  for (s in base_r) {
    destino <- file.path("Resultados_Artigo/Figuras", s$nome)
    png(destino, width = 10 * 150, height = 9.5 * 150, res = 150)
    s$f()
    dev.off()
    cat("Figura em", destino, "\n")
  }
}
