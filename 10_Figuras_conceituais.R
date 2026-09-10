# =====================================================================
# FIGURAS CONCEITUAIS: EXPLICAR O DESENHO, ESTUDO A ESTUDO
# =====================================================================
#     Rscript 10_Figuras_conceituais.R
#
# São duas famílias de figura, e nada mais, para que não haja um gráfico novo
# a aprender em cada seção:
#
#   O MECANISMO, em três linhas. As curvas de aceite das fêmeas, os casais que
#     se formaram, e de que lado cai o sucesso reprodutivo. Serve aos Estudos
#     2 e 3, que são espelhos, com a mesma função e o eixo trocado.
#
#   A REDE. Para o Estudo 1, os quatro cantos do plano sigma_z x sigma_p, que
#     é o desenho inteiro dele. Para os Estudos 2 e 3, a rede da geração 1
#     contra a da geração 100, que é o que a evolução fez com ela.
#
# Nenhuma delas é esquemática, com uma exceção anunciada (figura_desenho):
# saem do motor de verdade, com mate_with_survivors, calc_metrics_from_M e os
# próprios loops evolutivos, e as métricas nos rótulos são as calculadas ali.
#
# COMO ESTAS REDES SÃO ESCOLHIDAS. As figuras de rede desenham uma réplica que
# REALMENTE rodou: dentro da célula, a mais próxima da média, recuperada pela
# semente e conferida contra a métrica guardada (ver 11_Rede_Representativa.R).
# O rodapé de cada painel diz de qual réplica se trata, e se não houver dados,
# ou se a conferência falhar, o painel cai para uma população gerada na hora e
# o rodapé avisa. As figuras de mecanismo (figura_eixo) continuam gerando a
# população na hora, porque o que elas mostram é a regra e não um resultado.
#
# Ficam como funções, para poder serem chamadas da apresentação e dos
# documentos sem duplicar código:
#
#     source("10_Figuras_conceituais.R")
#     figura_sigma_p();  figura_sigma_z()      # o mecanismo, Estudos 2 e 3
#     figura_redes();    figura_cantos()       # o Estudo 1, como rede e como matriz
#     figura_rede_evolucao("2")                # a rede antes e depois
#     figura_desenho()                         # o esquema dos quatro estudos
# =====================================================================

source("01_metricas_e_utilitarios.R")
# O motor do espelho, só as funções: sem a guarda ele roda o experimento inteiro
# ao ser lido.
ESPELHO_SO_FUNCOES <- TRUE
source("Fase_Espelho.R")
# O localizador da réplica representativa dentro dos dados que já rodaram.
source("11_Rede_Representativa.R")
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

  # Rótulos curtos de propósito: a frase inteira não cabe na largura do painel e
  # sai cortada no meio do valor de sigma. A explicação vai na legenda.
  rotulos <- if (varia_femeas) c("Fêmeas concordam", "Fêmeas discordam")
             else              c("Machos parecidos", "Machos variados")

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
        if (varia_femeas)
          "Fêmeas concordam: todas querem o mesmo macho.  Fêmeas discordam: cada uma quer uma coisa.\n"
        else
          "Machos parecidos: pouca coisa para escolher.  Machos variados: há de tudo para escolher.\n",
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

  # O rótulo diz o que a condição significa e também o valor que a produziu,
  # senão quem lê a figura fora do contexto não sabe de que sigma se trata.
  rot <- function(v, quem, letra) {
    texto <- if (quem == "machos")
      ifelse(v == sigma_baixo, "machos parecidos entre si", "machos variados")
    else
      ifelse(v == sigma_baixo, "fêmeas concordam", "fêmeas discordam")
    sprintf("%s  (%s = %.1f)", texto, letra, v)
  }
  dados <- dados %>%
    mutate(col = factor(rot(sigma_z, "machos", "σz"),
                        levels = rot(c(sigma_baixo, sigma_alto), "machos", "σz")),
           lin = factor(rot(sigma_p, "fêmeas", "σp"),
                        levels = rot(c(sigma_alto, sigma_baixo), "fêmeas", "σp")))

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
  paleta <- grDevices::colorRampPalette(
    c("#E41A1C","#377EB8","#4DAF4A","#984EA3","#FF7F00","#A65628","#F781BF","#999999"))(length(unique(memb)))
  cores <- paleta[memb]
  grau  <- igraph::degree(g)
  cores[grau == 0] <- "gray85"

  # Duas contagens, e a diferença entre elas diz coisas diferentes. COMPONENTE é
  # um pedaço da rede sem nenhuma ligação com o resto; COMUNIDADE é o que o
  # Louvain separa, e um componente grande pode conter várias.
  #
  # As duas ignoram quem não acasalou. Sem isso, cada indivíduo isolado conta
  # como um componente e como uma comunidade só dele, e o número explode sem
  # dizer nada sobre a estrutura: era o que fazia a rede em estrela, com muitos
  # machos sem parceira, aparecer com trinta e três "módulos".
  n_com  <- length(unique(memb[grau > 0]))
  tam    <- igraph::components(g)$csize
  n_comp <- sum(tam >= 2)

  set.seed(seed_layout)
  list(g = g, cores = cores, layout = igraph::layout_with_fr(g),
       formas = ifelse(igraph::V(g)$type, "square", "circle"),
       n_com = n_com, n_comp = n_comp,
       sem = sum(grau[(n_m + 1):(n_m + n_f)] == 0))
}

# tamanho 4 é o que deixa 400 nós legíveis, e 400 é o tamanho de todos os
# estudos, então é o default.
desenhar_rede <- function(r, titulo, tamanho = 4) {
  plot(r$g, layout = r$layout, vertex.color = r$cores,
       vertex.shape = r$formas, vertex.size = tamanho, vertex.label = NA,
       vertex.frame.color = grDevices::rgb(0, 0, 0, 0.25),
       edge.color = grDevices::rgb(0.4, 0.4, 0.4, 0.35), edge.width = 1)
  title(main = titulo, cex.main = 1.05, font.main = 1)
}

figura_redes <- function(sigma_baixo = 0.2, sigma_alto = 2.0,
                         N = 200, phi = 5, s_media = 2, sigma_s = 0.2,
                         k = 5L, tipo = "gaussian", seed = 11,
                         A_max = 200L, selecao_natural = FALSE,
                         usar_dados = TRUE) {

  # Com usar_dados, a rede desenhada é a de uma réplica que realmente rodou: a
  # mais próxima da média da célula, recuperada pela semente e conferida contra
  # a métrica guardada. Se não houver dados, ou se a conferência falhar, cai
  # para uma população gerada na hora, e o rótulo do painel diz qual é qual.
  um_canto <- function(sz, sp) {
    if (usar_dados) {
      r <- rede_representativa("1", sigma_z = sz, sigma_p = sp, tipo_selecao = tipo,
                               encounters_n = A_max, k_fixo = k,
                               selecao_natural = selecao_natural, verboso = FALSE)
      if (!is.null(r))
        return(c(preparar_rede(r$M), list(met = r$metrics, fonte = r$rotulo)))
    }
    set.seed(seed + round(100 * sz) + round(10000 * sp))
    male_z   <- pmax(0, rnorm(N, phi, sz))
    female_p <- pmax(0, rnorm(N, phi, sp))
    s_all    <- pmax(0, rnorm(N, s_media, sigma_s))
    M   <- mate_with_survivors(male_z, female_p, s_all, tipo,
                               encounters_n = min(A_max, N), k_fixo = k)
    met <- calc_metrics_from_M(M, k_alvo = k)

    c(preparar_rede(M), list(met = met, fonte = "população gerada agora"))
  }

  cantos <- list(
    list(sz = sigma_baixo, sp = sigma_baixo, tit = "machos parecidos, fêmeas concordam"),
    list(sz = sigma_alto,  sp = sigma_baixo, tit = "machos variados, fêmeas concordam"),
    list(sz = sigma_baixo, sp = sigma_alto,  tit = "machos parecidos, fêmeas discordam"),
    list(sz = sigma_alto,  sp = sigma_alto,  tit = "machos variados, fêmeas discordam")
  )

  op <- par(mfrow = c(2, 2), mar = c(1.5, 1.5, 6.5, 1.5), oma = c(3, 0, 3, 0))
  on.exit(par(op), add = TRUE)
  for (cc in cantos) {
    r <- um_canto(cc$sz, cc$sp)
    desenhar_rede(r, sprintf("%s  (σz = %.1f, σp = %.1f)\nmodularidade %.2f | aninhamento %.2f | Is %.2f\n%d componentes | %d comunidades | %d fêmeas sem acasalar\n%s",
                             cc$tit, cc$sz, cc$sp,
                             r$met$Modularity, r$met$Nestedness, r$met$I_s,
                             r$n_comp, r$n_com, r$sem, r$fonte))
  }
  mtext("A mesma regra de escolha, quatro composições da população",
        outer = TRUE, side = 3, line = 0.5, cex = 1.3, font = 2)
  mtext("Quadrados: machos.  Círculos: fêmeas.  Cores: comunidades do Louvain, que é o algoritmo da métrica de modularidade.  Cinza: sem acasalar.\nComponente é um pedaço sem ligação com o resto; comunidade é o que o Louvain separa dentro dele. As duas contagens ignoram quem não acasalou.",
        outer = TRUE, side = 1, line = 1, cex = 0.8, col = "gray30")
  invisible(NULL)
}

# =====================================================================
# O OUTRO EIXO DO ESTUDO 1: O REGIME DE BUSCA
# =====================================================================
# O Controle cruza dois níveis, e as figuras acima só mostram um deles. O outro
# é o regime de busca: A_max, quantos machos a fêmea avalia, e k, quantos ela
# aceita. Nos resultados é o nível que mais pesa, mais de dois terços da
# divergência entre curvas, e mesmo assim é o que não tinha figura nenhuma.
#
# A composição da população é a mesma nos quatro painéis, com sigma_z e sigma_p
# fixos. O que muda é só quanto a fêmea consegue amostrar antes de decidir e
# quantos parceiros ela aceita. A proporção k/A_max é a intensidade de seleção
# por truncamento, e vem escrita em cada painel.
figura_busca <- function(amax = c(10L, 200L), ks = c(5L, 20L),
                         N = 200, phi = 5, sigma_z = 1.0, sigma_p = 1.0,
                         s_media = 2, sigma_s = 0.2, tipo = "gaussian",
                         seed = 13, selecao_natural = FALSE, usar_dados = TRUE) {

  celulas <- expand.grid(k = ks, A = amax)

  uma <- function(A, k) {
    if (usar_dados) {
      r <- rede_representativa("1", sigma_z = sigma_z, sigma_p = sigma_p,
                               tipo_selecao = tipo, encounters_n = A, k_fixo = k,
                               selecao_natural = selecao_natural, verboso = FALSE)
      if (!is.null(r))
        return(c(preparar_rede(r$M), list(met = r$metrics, fonte = r$rotulo)))
    }
    set.seed(seed + A * 100 + k)
    male_z   <- pmax(0, rnorm(N, phi, sigma_z))
    female_p <- pmax(0, rnorm(N, phi, sigma_p))
    s_all    <- pmax(0, rnorm(N, s_media, sigma_s))
    # A_max nunca passa do número de machos que existem: se o tratamento pedir
    # 200 e a população tiver 40, ela avalia 40. Vale registrar porque é a mesma
    # limitação que o buraco do censo explora nos estudos.
    M   <- mate_with_survivors(male_z, female_p, s_all, tipo,
                               encounters_n = min(A, N), k_fixo = k)
    c(preparar_rede(M), list(met = calc_metrics_from_M(M, k_alvo = k),
                             fonte = "população gerada agora"))
  }

  op <- par(mfrow = c(2, 2), mar = c(1.5, 1.5, 6.5, 1.5), oma = c(3.5, 0, 4, 0))
  on.exit(par(op), add = TRUE)
  for (i in seq_len(nrow(celulas))) {
    A <- celulas$A[i]; k <- celulas$k[i]
    r <- uma(A, k)
    desenhar_rede(r, sprintf("A_max = %d, k = %d  (aceita %.0f%% do que avalia)\nmodularidade %.2f | aninhamento %.2f | Is %.2f\n%d componentes | %d comunidades | %d fêmeas sem acasalar\n%s",
                             min(A, N), k, 100 * k / min(A, N),
                             r$met$Modularity, r$met$Nestedness, r$met$I_s,
                             r$n_comp, r$n_com, r$sem, r$fonte))
  }
  mtext("Estudo 1: o mesmo material, quatro regimes de busca",
        outer = TRUE, side = 3, line = 1.5, cex = 1.3, font = 2)
  mtext(sprintf("preferência %s | sigma_z = %.1f e sigma_p = %.1f nos quatro painéis | %d machos e %d fêmeas | uma geração",
                tipo, sigma_z, sigma_p, N, N),
        outer = TRUE, side = 3, line = 0.2, cex = 0.85, col = "gray30")
  mtext("Quadrados: machos.  Círculos: fêmeas.  Cores: comunidades do Louvain.  Cinza: sem acasalar.\nComponente é um pedaço sem ligação com o resto; comunidade é o que o Louvain separa dentro dele. As duas ignoram quem não acasalou.",
        outer = TRUE, side = 1, line = 1.2, cex = 0.8, col = "gray30")
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
  #
  # As duas gerações vêm da MESMA réplica, pedidas de uma vez só. Se fossem duas
  # chamadas separadas, a representativa da geração 1 e a da 100 poderiam ser
  # réplicas diferentes, e o antes e depois deixaria de ser da mesma população.
  eixo_nome <- if (estudo == "2") "sigma_p" else "sigma_z"
  uma <- function(sigma) {
    args <- list(estudo)
    args[[eixo_nome]] <- sigma
    r <- do.call(rede_representativa,
                 c(args, list(tipo_selecao = tipo, encounters_n = A_max, k_fixo = k,
                              selecao_natural = selecao_natural,
                              capturar = c(1L, as.integer(geracoes)), verboso = FALSE)))
    if (!is.null(r)) return(r)

    # Sem dados, ou conferência falhada: uma réplica nova, e o rótulo avisa.
    set.seed(seed + round(sigma * 1000))
    bruto <- if (estudo == "2") {
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
    list(redes = list(gen1 = bruto$rede_gen1,
                      gen100 = bruto$rede_final),
         linhas = bruto$dados_tabela, rotulo = "réplica gerada agora")
  }

  res <- list(baixo = uma(baixo), alto = uma(alto))
  letra   <- if (estudo == "2") "σp" else "σz"
  o_que   <- if (estudo == "2") "o traço do macho" else "a preferência da fêmea"
  # a coluna que interessa em cada estudo é a da característica que evolui
  coluna  <- if (estudo == "2") "varz_males" else "varp_femeas"
  nome_var <- if (estudo == "2") "var(z)" else "var(p)"

  op <- par(mfrow = c(2, 2), mar = c(1.5, 1.5, 6.5, 1.5), oma = c(3.5, 0, 4, 0))
  on.exit(par(op), add = TRUE)

  for (nome in c("baixo", "alto")) {
    r <- res[[nome]]
    sigma <- if (nome == "baixo") baixo else alto
    for (g in c(1L, as.integer(geracoes))) {
      d <- r$redes[[paste0("gen", g)]]
      if (is.null(d)) next
      v  <- r$linhas[[coluna]][r$linhas$generation == g]
      rr <- preparar_rede(d$M)
      desenhar_rede(rr,
                    sprintf("%s = %.1f, geração %d\nmodularidade %.2f | aninhamento %.2f | Is %.2f\n%d componentes | %d comunidades | %s = %.2f\n%s",
                            letra, sigma, g,
                            d$metrics$Modularity, d$metrics$Nestedness, d$metrics$I_s,
                            rr$n_comp, rr$n_com, nome_var, v[1], r$rotulo))
    }
  }
  mtext(sprintf("Estudo %s: o que cem gerações fazem com a rede", estudo),
        outer = TRUE, side = 3, line = 1.5, cex = 1.3, font = 2)
  mtext(sprintf("%s evolui | preferência %s | %d machos e %d fêmeas | A_max = %d | k = %d | %s",
                o_que, tipo, N, N, A_max, k,
                if (selecao_natural) "com seleção natural" else "sem seleção natural"),
        outer = TRUE, side = 3, line = 0.2, cex = 0.85, col = "gray30")
  mtext("Quadrados: machos.  Círculos: fêmeas.  Cores: comunidades do Louvain.  Cinza: sem acasalar.\nComponente é um pedaço sem ligação com o resto; comunidade é o que o Louvain separa dentro dele. As duas ignoram quem não acasalou.",
        outer = TRUE, side = 1, line = 1.2, cex = 0.8, col = "gray30")
  invisible(NULL)
}

# =====================================================================
# O ESTUDO 4 EM UMA FIGURA: A ESTRUTURA SE APAGA
# =====================================================================
# Esta é a figura da conversa com o pessoal de redes, e conta o resultado
# inteiro sozinha.
#
# Cada linha é uma curva de preferência; as colunas são a geração 1 e a 100 da
# MESMA réplica. Sob a sigmoide, a rede da geração 1 é uma estrela, com poucos
# machos levando quase todas as fêmeas, e a da geração 100 é indistinguível de
# uma rede aleatória. A variância do traço, que vai no rótulo, é praticamente a
# mesma nas duas: não é perda de variação, é a média do traço saindo da faixa
# em que a preferência distingue.
#
# O Estudo 4 traz o seu próprio controle e o seu próprio nulo, e por isso esta
# figura não precisa emprestar nada do Estudo 1. A GERAÇÃO 1 é a rede antes de
# qualquer resposta evolutiva, e a CURVA ALEATÓRIA é o nulo, na mesma
# simulação e com os mesmos parâmetros. Dizer "aqui, na geração 1, as curvas já
# dão topologias diferentes; olhem a geração 100" é mais limpo do que pedir ao
# público que acredite num experimento que não está vendo.
figura_estrutura_se_apaga <- function(curvas = c("sigmoid", "uniform"),
                                      geracoes = 100L,
                                      sigma_p_init = 1.0, sigma_z_init = 1.0,
                                      A_max = 200L, k = 5L,
                                      selecao_natural = FALSE) {

  op <- par(mfrow = c(length(curvas), 2), mar = c(1.5, 1.5, 6, 1.5),
            oma = c(3.5, 0, 4, 0))
  on.exit(par(op), add = TRUE)

  for (cv in curvas) {
    r <- rede_representativa("4", sigma_p_init = sigma_p_init,
                             sigma_z_init = sigma_z_init, tipo_selecao = cv,
                             encounters_n = A_max, k_fixo = k,
                             selecao_natural = selecao_natural,
                             capturar = c(1L, as.integer(geracoes)), verboso = FALSE)
    for (g in c(1L, as.integer(geracoes))) {
      if (is.null(r) || is.null(r$redes[[paste0("gen", g)]])) {
        plot.new(); title(main = sprintf("%s, geração %d\n(sem dados)",
                                         labels_curva(cv), g), font.main = 1)
        next
      }
      d  <- r$redes[[paste0("gen", g)]]
      li <- r$linhas[r$linhas$generation == g, ]
      rr <- preparar_rede(d$M)
      desenhar_rede(rr, sprintf(
        "%s, geração %d\nIs %.2f | modularidade %.2f | centralização %.3f\nvar(z) %.2f | zbar - pbar %.1f\n%s",
        labels_curva(cv), g, d$metrics$I_s, d$metrics$Modularity, d$metrics$Centralization,
        li$varz_pop[1], li$zbar_pop[1] - li$pbar_pop[1], r$rotulo))
    }
  }
  # O título é DESCRITIVO de propósito. Já foi "a seleção sexual apaga a própria
  # estrutura", que é verdade sob a sigmoide e sob a disruptiva mas FALSO sob a
  # gaussiana, onde a modularidade se mantém e o acoplamento persiste. Um título
  # que afirma o resultado não pode encabeçar as quatro abas; quem diz o que
  # aconteceu é o texto de cada uma.
  mtext("Estudo 4: a rede na geração 1 e na geração 100",
        outer = TRUE, side = 3, line = 1.5, cex = 1.3, font = 2)
  mtext(sprintf("as duas características evoluem | %d machos e %d fêmeas | A_max = %d | k = %d | sem seleção natural",
                200L, 200L, A_max, k),
        outer = TRUE, side = 3, line = 0.2, cex = 0.85, col = "gray30")
  mtext("Quadrados: machos.  Círculos: fêmeas.  Cores: comunidades do Louvain.  Cinza: sem acasalar.",
        outer = TRUE, side = 1, line = 1.2, cex = 0.8, col = "gray30")
  invisible(NULL)
}

labels_curva <- function(cv) c(uniform = "Aleatória", gaussian = "Gaussiana",
                               sigmoid = "Sigmoide", `u-shaped` = "Disruptiva")[[cv]]

# =====================================================================
# O MECANISMO DA CO-EVOLUÇÃO: A GERAÇÃO 1 CONTRA A 100
# =====================================================================
# O equivalente de figura_eixo() para o Estudo 4, com uma diferença de fundo.
#
# Nos Estudos 2 e 3 há um eixo IMPOSTO, e a figura contrasta sigma baixo contra
# sigma alto: duas populações diferentes, montadas de propósito. No Estudo 4 não
# há nada imposto, as duas características evoluem, então o contraste que faz
# sentido é OUTRO: a mesma população na geração 1 e na geração 100.
#
# As três linhas são as mesmas de sempre, e é aí que está a graça:
#
#   linha 1 — as curvas de aceite de catorze fêmeas, com os machos disponíveis
#     marcados no eixo. Na geração 1 as curvas estão em cima dos machos. Na
#     geração 100, sob a sigmoide, os machos correram para a direita e as curvas
#     ficaram para trás: dá para VER a preferência deixando de discriminar.
#
#   linha 2 — os casais, com a diagonal. Mostra se o acasalamento é assortativo
#     e como isso muda ao longo das cem gerações.
#
#   linha 3 — quantas parceiras cada macho teve. Na geração 1 uns poucos levam
#     tudo; na geração 100, sob a sigmoide, todos levam quase o mesmo.
figura_mecanismo_coevolucao <- function(tipo = "sigmoid", geracoes = 100L,
                                        sigma_p_init = 1.0, sigma_z_init = 1.0,
                                        A_max = 200L, k = 5L,
                                        selecao_natural = FALSE, n_curvas = 14) {

  r <- rede_representativa("4", sigma_p_init = sigma_p_init,
                           sigma_z_init = sigma_z_init, tipo_selecao = tipo,
                           encounters_n = A_max, k_fixo = k,
                           selecao_natural = selecao_natural,
                           capturar = c(1L, as.integer(geracoes)), verboso = FALSE)
  if (is.null(r)) {
    warning("Sem dados para esta célula do Estudo 4.")
    return(invisible(NULL))
  }

  ger <- c(1L, as.integer(geracoes))
  lados <- lapply(ger, function(g) r$redes[[paste0("gen", g)]])
  names(lados) <- paste0("gen", ger)
  if (any(vapply(lados, is.null, logical(1)))) {
    warning("Falta uma das gerações.")
    return(invisible(NULL))
  }
  if (is.null(lados[[1]]$female_s)) {
    warning("Esta rede foi guardada antes de female_s entrar na captura. ",
            "Apague o cache (", ARQUIVO_CACHE_REDES, ") e rode de novo.")
    return(invisible(NULL))
  }

  # O eixo é o MESMO nas duas colunas, senão a fuga do traço não se vê: com
  # eixos livres, uma população em z = 5 e outra em z = 25 sairiam idênticas.
  todos_z <- unlist(lapply(lados, function(d) d$male_z))
  todos_p <- unlist(lapply(lados, function(d) d$female_p))
  faixa   <- range(c(todos_z, todos_p))
  grade_z <- seq(faixa[1], faixa[2], length.out = 400)
  grau_max <- max(unlist(lapply(lados, function(d) rowSums(d$M))))

  curvas <- function(d) {
    idx <- sample(seq_along(d$female_p), min(n_curvas, length(d$female_p)))
    df <- bind_rows(lapply(idx, function(i) {
      tibble(femea = i, z = grade_z,
             P = prob_de_aceite(grade_z, d$female_p[i], d$female_s[i], tipo))
    }))
    ggplot(df, aes(z, P, group = femea)) +
      geom_line(color = "#E6B800", alpha = 0.75, linewidth = 0.7) +
      geom_rug(data = tibble(z = d$male_z), aes(x = z), inherit.aes = FALSE,
               sides = "b", alpha = 0.25, length = unit(0.05, "npc")) +
      coord_cartesian(xlim = faixa, ylim = c(0, 1)) +
      labs(x = NULL, y = "P(aceitar)") + theme_light(base_size = 12)
  }

  casais <- function(d) {
    ar <- which(d$M == 1L, arr.ind = TRUE)
    ggplot(tibble(z = d$male_z[ar[, 1]], p = d$female_p[ar[, 2]]), aes(z, p)) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray55") +
      geom_point(alpha = 0.25, size = 1.5, color = "#3BA273") +
      coord_cartesian(xlim = faixa, ylim = faixa) +
      labs(x = NULL, y = "pico da fêmea (p)") + theme_light(base_size = 12)
  }

  sucesso <- function(d) {
    ggplot(tibble(z = d$male_z, grau = rowSums(d$M)), aes(z, grau)) +
      geom_point(alpha = 0.45, size = 1.6, color = "#9932CC") +
      coord_cartesian(xlim = faixa, ylim = c(0, grau_max)) +
      labs(x = "traço do macho (z)", y = "parceiras do macho") +
      theme_light(base_size = 12)
  }

  col <- function(d) {
    titulo <- sprintf("Geração %d\nIs %.2f | modularidade %.2f\nzbar - pbar %.1f",
                      d$geracao, d$metrics$I_s, d$metrics$Modularity,
                      mean(d$male_z) - mean(d$female_p))
    (curvas(d) + ggtitle(titulo)) / casais(d) / sucesso(d)
  }

  (col(lados[[1]]) | col(lados[[2]])) +
    plot_annotation(
      title = sprintf("Estudo 4, preferência %s: a mesma população, cem gerações depois",
                      labels_curva(tipo)),
      subtitle = sprintf("as duas características evoluem | %s | A_max = %d | k = %d | %s",
                         r$rotulo, A_max, k,
                         if (selecao_natural) "com seleção natural" else "sem seleção natural"),
      caption = paste0(
        "O eixo de baixo é o traço do macho nas três linhas, e é O MESMO nas duas colunas: sem isso a fuga do traço não se veria.\n",
        "Linha 1: a curva de aceite de ", n_curvas, " fêmeas sorteadas, e os machos disponíveis marcados no eixo.\n",
        "Linha 2: cada ponto é um casal, e a diagonal marca onde o macho é igual ao pico da fêmea.\n",
        "Linha 3: quantas parceiras cada macho teve."),
      theme = theme(plot.title = element_text(face = "bold", size = 15)))
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
  # Cada figura num tryCatch: se uma falhar, as outras continuam saindo e o erro
  # aparece na hora, em vez de o script morrer e parecer que nada funcionou.
  tentar <- function(nome, expr) {
    tryCatch({ force(expr); cat("Figura em Resultados_Artigo/Figuras/", nome, "\n", sep = "") },
             error = function(e) cat("FALHOU", nome, ":", conditionMessage(e), "\n"))
  }

  for (s in saidas) {
    destino <- file.path("Resultados_Artigo/Figuras", s$nome)
    tentar(s$nome, ggsave(destino, s$f(), width = s$w, height = s$h, dpi = 150))
  }
  # figura_redes desenha com o igraph, que escreve direto no dispositivo em vez
  # de devolver um objeto, então precisa de png() e dev.off() em volta.
  base_r <- list(
    list(f = function() figura_redes(),                  nome = "figura_redes.png"),
    list(f = function() figura_busca(),                  nome = "figura_busca.png"),
    list(f = function() figura_rede_evolucao("2"),       nome = "figura_rede_estudo2.png"),
    list(f = function() figura_rede_evolucao("3"),       nome = "figura_rede_estudo3.png"),
    list(f = function() figura_estrutura_se_apaga(),     nome = "figura_estrutura_se_apaga.png")
  )
  for (s in base_r) {
    destino <- file.path("Resultados_Artigo/Figuras", s$nome)
    png(destino, width = 10 * 150, height = 9.5 * 150, res = 150)
    # o dev.off() vai no on.exit do tryCatch, senão um erro deixa o dispositivo
    # aberto e a figura seguinte é desenhada por cima desta
    tentar(s$nome, tryCatch(s$f(), finally = dev.off()))
  }
}
