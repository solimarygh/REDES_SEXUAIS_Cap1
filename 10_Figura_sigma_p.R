# =====================================================================
# FIGURA CONCEITUAL: O QUE sigma_p FAZ
# =====================================================================
#     Rscript 10_Figura_sigma_p.R
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
#     source("10_Figura_sigma_p.R")
#     figura_sigma_p()
# =====================================================================

source("01_metricas_e_utilitarios.R")
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(patchwork)
})

figura_sigma_p <- function(sigma_p_baixo = 0.2, sigma_p_alto = 2.0,
                           N = 200, phi = 5, sigma_z = 1.0,
                           s_media = 2, sigma_s = 0.2,
                           k = 5L, A_max = 200L,
                           n_curvas = 14, seed = 42) {

  set.seed(seed)
  # Os MESMOS machos nas duas colunas: assim a única coisa que muda entre elas
  # é a dispersão das preferências, que é o que a figura quer isolar.
  male_z <- pmax(0, rnorm(N, phi, sigma_z))
  s_all  <- pmax(0, rnorm(N, s_media, sigma_s))

  um_lado <- function(sigma_p) {
    set.seed(seed + round(sigma_p * 100))
    female_p <- pmax(0, rnorm(N, phi, sigma_p))
    M <- mate_with_survivors(male_z, female_p, s_all, "gaussian",
                             encounters_n = A_max, k_fixo = k)
    met <- calc_metrics_from_M(M, k_alvo = k)
    pares <- which(M == 1L, arr.ind = TRUE)
    list(p = female_p, s = s_all, M = M, met = met,
         pares = tibble(p_femea = female_p[pares[, 2]],
                        z_macho = male_z[pares[, 1]],
                        macho   = pares[, 1]),
         rotulo = sprintf("sigma[p] == %.1f", sigma_p))
  }

  baixo <- um_lado(sigma_p_baixo)
  alto  <- um_lado(sigma_p_alto)

  grade_z <- seq(max(0, phi - 4 * max(sigma_p_alto, 1)), phi + 4 * max(sigma_p_alto, 1),
                 length.out = 400)

  titulo <- function(lado, texto) {
    sprintf("%s\nmodularidade %.2f | centralização %.2f | Is %.2f",
            texto, lado$met$Modularity, lado$met$Centralization, lado$met$I_s)
  }

  # ---- linha 1: cada fêmea é uma curva de aceite -----------------------
  # É aqui que a diferença fica óbvia. Com sigma_p pequeno as curvas se empilham
  # umas sobre as outras: todas as fêmeas querem o mesmo macho. Com sigma_p
  # grande elas se espalham pelo eixo: cada fêmea quer uma coisa diferente.
  curvas <- function(lado) {
    idx <- sample(seq_len(N), n_curvas)
    df <- lapply(idx, function(i) {
      tibble(femea = i, z = grade_z,
             P = exp(-lado$s[i] * (grade_z - lado$p[i])^2))
    }) %>% bind_rows()
    ggplot(df, aes(z, P, group = femea)) +
      geom_line(color = "#E6B800", alpha = 0.75, linewidth = 0.7) +
      geom_rug(data = tibble(z = male_z), aes(x = z), inherit.aes = FALSE,
               sides = "b", alpha = 0.25, length = unit(0.04, "npc")) +
      coord_cartesian(xlim = range(grade_z), ylim = c(0, 1)) +
      labs(x = NULL, y = "P(aceitar)") +
      theme_light(base_size = 12)
  }

  # ---- linha 2: quem acasalou com quem ---------------------------------
  # Cada ponto é um casal, com o traço do macho no eixo x e o pico da fêmea no
  # y. Com sigma_p pequeno tudo se concentra numa faixa estreita. Com sigma_p
  # grande os pontos seguem a diagonal, que é o acasalamento assortativo
  # desenhado: cada fêmea com o macho parecido com o seu próprio pico.
  #
  # O traço do macho fica no x nas TRÊS linhas de propósito: assim o eixo de
  # baixo, que o patchwork compartilha entre elas, quer dizer a mesma coisa em
  # todas. Antes esta linha tinha o pico da fêmea no x e herdava um rótulo que
  # não era o dela.
  casais <- function(lado) {
    ggplot(lado$pares, aes(z_macho, p_femea)) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray55") +
      geom_point(alpha = 0.25, size = 1.5, color = "#3BA273") +
      coord_cartesian(xlim = range(grade_z), ylim = range(grade_z)) +
      labs(x = NULL, y = "pico da fêmea (p)") +
      theme_light(base_size = 12)
  }

  # ---- linha 3: como o sucesso se reparte entre os machos --------------
  # A consequência demográfica: com todas querendo o mesmo, uns poucos machos
  # levam quase tudo e muitos ficam sem nada.
  # O eixo do número de parceiras é o MESMO nas duas colunas, senão a coluna em
  # que poucos machos levam tudo pareceria igual à outra, que é justamente a
  # diferença que a linha quer mostrar.
  grau_max <- max(rowSums(baixo$M), rowSums(alto$M))
  sucesso <- function(lado) {
    g <- tibble(z = male_z, grau = rowSums(lado$M))
    ggplot(g, aes(z, grau)) +
      geom_point(alpha = 0.45, size = 1.6, color = "#9932CC") +
      coord_cartesian(xlim = range(grade_z), ylim = c(0, grau_max)) +
      labs(x = "traço do macho (z)", y = "parceiras") +
      theme_light(base_size = 12)
  }

  col <- function(lado, texto) {
    (curvas(lado) + ggtitle(titulo(lado, texto))) /
      casais(lado) / sucesso(lado)
  }

  (col(baixo, "Fêmeas concordam: todas querem o mesmo") |
      col(alto, "Fêmeas discordam: cada uma quer uma coisa")) +
    plot_annotation(
      title = "O que sigma_p faz",
      subtitle = sprintf(
        "Preferência gaussiana | os MESMOS %d machos nas duas colunas, z ~ N(%g, %g) | A_max = %d | k = %d | uma geração",
        N, phi, sigma_z, A_max, k),
      caption = "O eixo de baixo é o traço do macho nas três linhas.\nLinha 1: a curva de aceite de 14 fêmeas sorteadas, e os machos disponíveis marcados no eixo.\nLinha 2: cada ponto é um casal, e a diagonal marca onde o macho é igual ao pico da fêmea.\nLinha 3: quantas parceiras cada macho teve.",
      theme = theme(plot.title = element_text(face = "bold", size = 15)))
}

# =====================================================================
# OS QUATRO CANTOS DO PLANO sigma_z x sigma_p
# =====================================================================
# A figura acima mexe num eixo só. Esta mexe nos dois, e é a que explica de
# uma vez o resultado de H1: o que importa não é quanta variação existe, é de
# que LADO ela está.
#
# Cada painel é a matriz de acasalamentos, com as fêmeas ordenadas pelo seu
# pico de preferência e os machos ordenados pelo seu traço. Assim a topologia
# fica visível sem precisar de índice nenhum: uma faixa na diagonal é
# modularidade, um canto cheio é aninhamento, uma listra vertical é
# centralização.
figura_cantos <- function(sigma_baixo = 0.2, sigma_alto = 2.0,
                          N = 200, phi = 5, s_media = 2, sigma_s = 0.2,
                          k = 5L, A_max = 200L, tipo = "gaussian", seed = 7) {

  combinacoes <- expand.grid(sigma_z = c(sigma_baixo, sigma_alto),
                             sigma_p = c(sigma_baixo, sigma_alto))

  um_canto <- function(sz, sp) {
    set.seed(seed + round(100 * sz) + round(10000 * sp))
    male_z   <- pmax(0, rnorm(N, phi, sz))
    female_p <- pmax(0, rnorm(N, phi, sp))
    s_all    <- pmax(0, rnorm(N, s_media, sigma_s))
    M   <- mate_with_survivors(male_z, female_p, s_all, tipo,
                               encounters_n = A_max, k_fixo = k)
    met <- calc_metrics_from_M(M, k_alvo = k)
    # ordenar é o que torna a estrutura legível: sem isso qualquer matriz
    # parece ruído, por mais estruturada que esteja.
    om <- order(male_z); of <- order(female_p)
    ar <- which(M[om, of] == 1L, arr.ind = TRUE)
    tibble(sigma_z = sz, sigma_p = sp,
           macho = ar[, 1], femea = ar[, 2],
           met_txt = sprintf("mod %.2f | centr %.2f | Is %.2f | %.0f%% sem acasalar",
                             met$Modularity, met$Centralization, met$I_s,
                             100 * met$prop_femeas_sem_acasalar))
  }

  dados <- bind_rows(Map(um_canto, combinacoes$sigma_z, combinacoes$sigma_p))

  rot <- function(v, quem) ifelse(v == sigma_baixo,
                                  sprintf("%s parecidos entre si", quem),
                                  sprintf("%s variados", quem))
  dados <- dados %>%
    mutate(col = factor(rot(sigma_z, "machos"),
                        levels = rot(c(sigma_baixo, sigma_alto), "machos")),
           lin = factor(rot(sigma_p, "fêmeas"),
                        levels = rot(c(sigma_alto, sigma_baixo), "fêmeas")))

  legendas <- dados %>% distinct(col, lin, met_txt)

  ggplot(dados, aes(femea, macho)) +
    geom_point(size = 0.35, alpha = 0.6, color = "#2C3E50") +
    geom_text(data = legendas, aes(x = N / 2, y = -18, label = met_txt),
              inherit.aes = FALSE, size = 3, color = "gray30") +
    facet_grid(lin ~ col, switch = "y") +
    coord_cartesian(ylim = c(-25, N), clip = "off") +
    labs(title = "O que importa não é quanta variação há, é de que lado ela está",
         subtitle = sprintf("Preferência gaussiana | %d machos e %d fêmeas | A_max = %d | k = %d | uma geração", N, N, A_max, k),
         x = "fêmeas, ordenadas pelo seu pico de preferência",
         y = "machos, ordenados pelo seu traço",
         caption = "Cada ponto é um acasalamento. Faixa na diagonal: acasalamento assortativo, que gera módulos.\nListra horizontal: poucos machos levam quase tudo. Matriz cheia e sem forma: a preferência não discrimina.") +
    theme_light(base_size = 12) +
    theme(plot.title = element_text(face = "bold"),
          strip.text = element_text(size = 11),
          panel.grid.minor = element_blank())
}

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

    adj <- matrix(0L, 2 * N, 2 * N)
    adj[1:N, (N + 1):(2 * N)] <- M
    adj[(N + 1):(2 * N), 1:N] <- t(M)
    g <- igraph::graph_from_adjacency_matrix(adj, mode = "undirected")
    igraph::V(g)$type <- c(rep(TRUE, N), rep(FALSE, N))

    com   <- igraph::cluster_louvain(g)
    memb  <- igraph::membership(com)
    n_com <- length(unique(memb))
    paleta <- grDevices::colorRampPalette(
      c("#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00","#A65628","#F781BF","#999999"))(n_com)
    cores <- paleta[memb]
    # quem não acasalou fica cinza claro: é informação, não sujeira
    cores[igraph::degree(g) == 0] <- "gray85"

    set.seed(2026)
    list(g = g, cores = cores, layout = igraph::layout_with_fr(g),
         formas = ifelse(igraph::V(g)$type, "square", "circle"),
         met = met, n_com = n_com,
         sem = sum(igraph::degree(g)[(N + 1):(2 * N)] == 0))
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
    plot(r$g, layout = r$layout, vertex.color = r$cores,
         vertex.shape = r$formas, vertex.size = 7, vertex.label = NA,
         vertex.frame.color = grDevices::rgb(0, 0, 0, 0.25),
         edge.color = grDevices::rgb(0.4, 0.4, 0.4, 0.35), edge.width = 1)
    title(main = sprintf("%s\nmodularidade %.2f | %d módulos | %d fêmeas sem acasalar",
                         cc$tit, r$met$Modularity, r$n_com, r$sem),
          cex.main = 1.05, font.main = 1)
  }
  mtext("A mesma regra de escolha, quatro composições da população",
        outer = TRUE, side = 3, line = 0.5, cex = 1.3, font = 2)
  mtext("Quadrados: machos.  Círculos: fêmeas.  Cores: comunidades do Louvain, que é o algoritmo da métrica de modularidade.  Cinza: sem acasalar.",
        outer = TRUE, side = 1, line = 1, cex = 0.8, col = "gray30")
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
    list(f = figura_sigma_p, nome = "figura_sigma_p.png",       w = 11, h = 8.5),
    list(f = figura_cantos,  nome = "figura_quatro_cantos.png", w = 10, h = 8),
    list(f = figura_desenho, nome = "figura_desenho.png",       w = 10, h = 8)
  )
  for (s in saidas) {
    destino <- file.path("Resultados_Artigo/Figuras", s$nome)
    ggsave(destino, s$f(), width = s$w, height = s$h, dpi = 150)
    cat("Figura em", destino, "\n")
  }
  # figura_redes desenha com o igraph, que escreve direto no dispositivo em vez
  # de devolver um objeto, então precisa de png() e dev.off() em volta.
  destino <- "Resultados_Artigo/Figuras/figura_redes.png"
  png(destino, width = 10 * 150, height = 9 * 150, res = 150)
  figura_redes()
  dev.off()
  cat("Figura em", destino, "\n")
}
