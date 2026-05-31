# =============================================================================
# Janzen (1970) — Modelo de Recrutamento Populacional
# "Herbivores and the Number of Tree Species in Tropical Forests"
# The American Naturalist, Vol. 104, No. 940
#
# Aplicativo Shiny interativo que reproduz as Figuras 1–5 do paper.
#
# COMO RODAR:
#   1. Instale os pacotes necessários (só precisa fazer uma vez):
#      install.packages(c("shiny", "ggplot2", "dplyr", "tidyr", "shinythemes"))
#   2. Abra este arquivo no RStudio e clique em "Run App"
#      OU no console R: shiny::runApp("janzen1970_shiny.R")
#
# ESTRUTURA:
#   - Funções do modelo (seedI, survP, build_curves): calculam I, P e PRC
#   - UI: define a interface (sliders, abas, gráfico)
#   - Server: conecta os controles ao gráfico
# =============================================================================

library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(shinythemes)

# =============================================================================
# FUNÇÕES DO MODELO
# =============================================================================

#' Curva de imigração de sementes I(x)
#' Retorna a densidade de sementes a uma distância x do progenitor.
#'
#' @param x        Vetor de distâncias do progenitor
#' @param sc       Tamanho da safra (quantidade de sementes, 0–1)
#' @param disp     Agente de dispersão: "wind", "bird", "mammal"
#' @param scale_shape Se TRUE, safra maior → sombra de sementes mais larga
#'                   (adequado para predadores distância-dependentes, Figs 1–2)
seedI <- function(x, sc, disp, scale_shape = FALSE) {
  # Parâmetros de forma da curva exponencial por agente dispersor
  # s = escala (maior = dispersão mais ampla)
  # sh = forma (maior = queda mais abrupta perto do progenitor)
  params <- list(
    wind   = c(s = 3.8, sh = 2.6),  # vento: concentrado perto
    bird   = c(s = 2.4, sh = 1.9),  # aves/roedores: dispersão moderada
    mammal = c(s = 1.6, sh = 1.3)   # mamíferos: distribuição achatada e longa
  )
  s  <- params[[disp]]["s"]
  sh <- params[[disp]]["sh"]

  # Com predadores distância-dependentes: safra maior → sementes dispersam mais longe
  # (a escala s cresce proporcionalmente à safra)
  if (scale_shape) {
    s <- s * (0.30 + 0.70 * sc)
  }

  sc * exp(-(x / s)^sh)
}


#' Probabilidade de sobrevivência P(x)
#' Retorna a probabilidade de uma semente/plântula escapar dos predadores.
#'
#' PREDADORES DISTÂNCIA-DEPENDENTES:
#'   P é função da distância do progenitor (foco de predadores).
#'   Curva sigmoide: P baixo perto, P alto longe.
#'   O parâmetro 'pr' (alcance) desloca o ponto de inflexão.
#'
#' PREDADORES DENSIDADE-DEPENDENTES:
#'   P depende da DENSIDADE LOCAL de sementes (iv), não da distância per se.
#'   Limiar absoluto T: acima de T → predadores sustentados → P baixo.
#'   Abaixo de T → predadores colapsam → P alto.
#'   Com safra grande: densidade permanece acima de T por mais distância
#'   → P sobe tarde → pico da PRC mais longe. (Fig. 3 do paper)
#'
#' @param x   Vetor de distâncias
#' @param pr  Alcance de predação (só usado para pred. distância-dependentes)
#' @param ptype Tipo: "distance" ou "density"
#' @param iv  Densidade local de sementes (necessário para "density")
survP <- function(x, pr, ptype, iv) {
  T_limiar <- 0.06  # limiar absoluto de densidade para predadores densidade-depend.

  if (ptype == "distance") {
    # Sigmoide centrada em pr * 1.8
    mid <- pr * 1.8
    1 / (1 + exp(-(x - mid) * 1.8))

  } else {  # "density"
    ifelse(
      iv > T_limiar,
      # Densidade alta: predadores ativos, P permanece baixo
      pmax(0.02, 0.12 * (1 - pmin(1, iv / (T_limiar * 4)) * 0.8)),
      # Densidade baixa: predadores colapsam, P sobe rapidamente
      pmin(0.94, 0.12 + 0.82 * (1 - iv / T_limiar))
    )
  }
}


#' Constrói o data frame com todas as curvas para uma configuração
#'
#' @param sc    Tamanho da safra (Iₐ)
#' @param pr    Alcance de predação
#' @param disp  Agente de dispersão
#' @param ptype Tipo de predador
#' @param fig   Número da figura (1–4)
#' @return Data frame com colunas: x, I, P, PRC, curva
build_curves <- function(sc, pr, disp, ptype, fig) {
  x_seq <- seq(0, 10, length.out = 400)

  # Define quais configurações de safra/dispersão plotar por figura
  configs <- switch(as.character(fig),
    "1" = list(
      list(sc = sc,        disp = disp,     label = "Iₐ",         cor_i = "#4CAF50", cor_p = "#FFC107", cor_prc = "#F44336")
    ),
    "2" = list(
      list(sc = sc,        disp = disp,     label = "Iₐ (grande)", cor_i = "#4CAF50", cor_p = "#FFC107", cor_prc = "#F44336"),
      list(sc = sc * 0.50, disp = disp,     label = "Ib (média)",  cor_i = "#2E7D32", cor_p = "#FFC107", cor_prc = "#C62828"),
      list(sc = sc * 0.18, disp = disp,     label = "Ic (pequena)",cor_i = "#1B5E20", cor_p = "#FFC107", cor_prc = "#8B0000")
    ),
    "3" = list(
      list(sc = sc,        disp = disp,     label = "Iₐ (grande)", cor_i = "#4CAF50", cor_p = "#CDDC39", cor_prc = "#F44336"),
      list(sc = sc * 0.50, disp = disp,     label = "Ib (média)",  cor_i = "#2E7D32", cor_p = "#AFB42B", cor_prc = "#C62828"),
      list(sc = sc * 0.18, disp = disp,     label = "Ic (pequena)",cor_i = "#1B5E20", cor_p = "#827717", cor_prc = "#8B0000")
    ),
    "4" = list(
      list(sc = sc, disp = "wind",   label = "Iₐ — Vento",            cor_i = "#4CAF50", cor_p = "#FFC107", cor_prc = "#F44336"),
      list(sc = sc, disp = "bird",   label = "Ib — Aves/roedores",     cor_i = "#00BCD4", cor_p = "#FFC107", cor_prc = "#2196F3"),
      list(sc = sc, disp = "mammal", label = "Ic — Mamíferos",         cor_i = "#CDDC39", cor_p = "#FFC107", cor_prc = "#8BC34A")
    )
  )

  # Fig 2: P é distância-dependente; Fig 3: força densidade-dependente
  ptype_efetivo <- if (fig == 3) "density" else ptype
  # Figs 1 e 2: sombra de sementes escala com safra (scale_shape = TRUE)
  use_scale_shape <- fig %in% c(1, 2)

  # Constrói data frame para cada configuração
  df_list <- lapply(configs, function(cfg) {
    I_vals   <- seedI(x_seq, cfg$sc, cfg$disp, use_scale_shape)
    P_vals   <- survP(x_seq, pr, ptype_efetivo, I_vals)
    PRC_vals <- I_vals * P_vals

    data.frame(
      x       = x_seq,
      I       = I_vals,
      P       = P_vals,
      PRC     = PRC_vals,
      curva   = cfg$label,
      cor_i   = cfg$cor_i,
      cor_p   = cfg$cor_p,
      cor_prc = cfg$cor_prc,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, df_list)
}


# =============================================================================
# TEXTOS EXPLICATIVOS (um por figura)
# =============================================================================
desc_figuras <- list(
  "1" = HTML("<b>Fig. 1 — Modelo base:</b> A curva <b style='color:#4CAF50'>I</b>
    (sementes/área) cai com a distância do progenitor. A curva
    <b style='color:#FFC107'>P</b> (prob. de escape dos predadores específicos)
    sobe. O produto I×P forma a <b style='color:#F44336'>PRC</b>, com pico na
    distância onde novos adultos têm mais chance de surgir.
    <i>Com predadores distância-dependentes: safra maior → sombra de sementes
    mais larga → pico da PRC se afasta. Com densidade-dependentes: safra maior
    → densidade alta persiste mais longe → pico também se afasta.</i>"),

  "2" = HTML("<b>Fig. 2 — Predadores distância-dependentes:</b> Três tamanhos
    de safra (Iₐ > Ib > Ic) com a <i>mesma</i> curva P. Safra maior → sementes
    chegam mais longe → pico da PRC se afasta do progenitor.
    Safra menor → sementes concentradas perto → pico se aproxima.
    <i>O slider 'safra' controla Iₐ; Ib e Ic são proporcionais.</i>"),

  "3" = HTML("<b>Fig. 3 — Predadores densidade-dependentes:</b> Cada curva tem
    sua própria <b style='color:#CDDC39'>P</b>, pois P depende da densidade
    local de sementes. Safra grande → densidade alta persiste até longe →
    predadores ativos longe → P sobe tarde → pico da PRC longe.
    Safra pequena → densidade cai abaixo do limiar perto → P sobe cedo →
    pico mais próximo. <i>Efeito oposto à Fig. 2!</i>"),

  "4" = HTML("<b>Fig. 4/5 — Agentes de dispersão:</b> Vento (Iₐ): sombra
    concentrada perto do progenitor. Aves/roedores (Ib): dispersão moderada.
    Mamíferos de longa retenção intestinal (Ic): distribuição achatada,
    sementes chegam muito longe. Sombra mais plana → novos adultos surgem mais
    longe → mais espaço para outras espécies → <b>maior diversidade arbórea</b>.")
)


# =============================================================================
# INTERFACE DO USUÁRIO (UI)
# =============================================================================
ui <- fluidPage(
  theme = shinytheme("darkly"),

  tags$head(tags$style(HTML("
    body { background-color: #0e1a0e; color: #d4e8c2; }
    .well { background-color: #141f14; border: 1px solid #2a3d2a; }
    h2 { font-style: italic; color: #a8d080; font-size: 1.4rem; margin-bottom: 2px; }
    .subtitle { font-size: .75rem; color: #5a7a4a; letter-spacing: .08em;
                text-transform: uppercase; margin-bottom: 18px; }
    .desc-box { font-size: .78rem; color: #7a9a6a; line-height: 1.7;
                border-top: 1px solid #2a3d2a; padding-top: 10px; margin-top: 8px; }
    .tab-content { padding-top: 0px; }
    label { color: #7a9a6a !important; font-size: .8rem; }
    .irs-bar, .irs-bar-edge { background: #4a8a3a !important; border-color: #4a8a3a !important; }
    .irs-slider { background: #6ab050 !important; }
    .irs-from, .irs-to, .irs-single { background: #2a3d2a !important; }
    .selectize-input { background: #1a2a1a !important; border-color: #2a3d2a !important;
                       color: #a8d080 !important; }
    .selectize-dropdown { background: #1a2a1a !important; color: #a8d080 !important; }
    .nav-tabs > li > a { color: #7a9a6a !important; }
    .nav-tabs > li.active > a { background-color: #1e3a1e !important;
                                border-color: #4a8a3a !important; color: #a8d080 !important; }
    .note { font-size: .7rem; color: #3a6a3a; font-style: italic; margin-top: 4px; }
  "))),

  h2("Janzen (1970) — Modelo de Recrutamento Populacional"),
  div("Herbivores and the Number of Tree Species in Tropical Forests · The American Naturalist",
      class = "subtitle"),

  sidebarLayout(
    sidebarPanel(
      width = 3,

      # ---- Sliders e controles ----
      sliderInput("sc", "Quantidade de sementes — Iₐ",
                  min = 0.15, max = 1, value = 1, step = 0.05),
      p("Figs 2/3: Ib = Iₐ × 0.50 · Ic = Iₐ × 0.18", class = "note"),

      sliderInput("pr", "Alcance de predação (r)",
                  min = 0.5, max = 3, value = 1, step = 0.1),

      selectInput("disp", "Agente de dispersão",
                  choices = c(
                    "Vento / secundário"          = "wind",
                    "Aves / roedores"             = "bird",
                    "Mamíferos (longa retenção)"  = "mammal"
                  ), selected = "bird"),

      selectInput("ptype", "Tipo de predador (Fig. 1 e 4)",
                  choices = c(
                    "Dependente da distância" = "distance",
                    "Dependente da densidade" = "density"
                  ), selected = "distance"),

      hr(style = "border-color: #2a3d2a;"),

      # ---- Legenda ----
      p(tags$span("—", style="color:#4CAF50; font-weight:bold"),
        " I : Sementes por área (eixo esq.)"),
      p(tags$span("—", style="color:#FFC107; font-weight:bold"),
        " P : Prob. de sobrevivência (eixo dir.)"),
      p(tags$span("---", style="color:#F44336; font-weight:bold"),
        " PRC : Recrutamento (eixo esq.)"),
      p("● Pico da PRC (distância ótima)", style="color:#aaa; font-size:.75rem;")
    ),

    mainPanel(
      width = 9,

      tabsetPanel(id = "fig_tabs",

        tabPanel("Fig. 1 — Modelo base",
          br(),
          plotOutput("plot1", height = "380px"),
          div(desc_figuras[["1"]], class = "desc-box")
        ),

        tabPanel("Fig. 2 — Pred. distância",
          br(),
          plotOutput("plot2", height = "380px"),
          div(desc_figuras[["2"]], class = "desc-box")
        ),

        tabPanel("Fig. 3 — Pred. densidade",
          br(),
          plotOutput("plot3", height = "380px"),
          div(desc_figuras[["3"]], class = "desc-box")
        ),

        tabPanel("Fig. 4 — Dispersão",
          br(),
          plotOutput("plot4", height = "380px"),
          div(desc_figuras[["4"]], class = "desc-box")
        )
      )
    )
  )
)


# =============================================================================
# SERVIDOR (SERVER)
# =============================================================================

#' Função que gera o ggplot para uma figura
#' Separada do server para facilitar modificações
make_plot <- function(df, fig) {
  # Paletas de cor por curva (cada curva tem seu identificador)
  curvas_unicas <- unique(df$curva)

  # Extrair mapeamento de cores do data frame
  cor_I   <- setNames(unique(df$cor_i[match(curvas_unicas, df$curva)]),   curvas_unicas)
  cor_P   <- setNames(unique(df$cor_p[match(curvas_unicas, df$curva)]),   curvas_unicas)
  cor_PRC <- setNames(unique(df$cor_prc[match(curvas_unicas, df$curva)]), curvas_unicas)

  # Encontrar picos da PRC para cada curva
  picos <- df %>%
    group_by(curva) %>%
    slice_max(PRC, n = 1) %>%
    ungroup()

  # Escala para exibir P no mesmo gráfico que I e PRC
  # I e PRC máx ≈ 1; P é 0–1 → escalar P para ficar visível mas não sobrepor
  p_scale <- 0.85

  # Preparar dados em formato longo para ggplot
  df_long <- df %>%
    mutate(P_scaled = P * p_scale) %>%
    select(x, curva, cor_i, cor_p, cor_prc, I, P_scaled, PRC) %>%
    pivot_longer(cols = c(I, P_scaled, PRC),
                 names_to = "variavel", values_to = "valor")

  # Cores e tipos de linha por variável
  df_long <- df_long %>%
    mutate(
      cor = case_when(
        variavel == "I"        ~ cor_i,
        variavel == "P_scaled" ~ cor_p,
        variavel == "PRC"      ~ cor_prc
      ),
      ltype = case_when(
        variavel == "PRC"      ~ "dashed",
        TRUE                   ~ "solid"
      ),
      lwd = case_when(
        variavel == "PRC"      ~ 1.2,
        variavel == "P_scaled" ~ 0.8,
        TRUE                   ~ 1.0
      )
    )

  # Construir combinação curva × variável para escala de cor manual
  df_long <- df_long %>%
    mutate(cv_id = paste(curva, variavel, sep = "__"))

  cor_map <- setNames(df_long$cor, df_long$cv_id)
  cor_map <- cor_map[!duplicated(names(cor_map))]

  ltype_map <- setNames(df_long$ltype, df_long$cv_id)
  ltype_map <- ltype_map[!duplicated(names(ltype_map))]

  lwd_map <- setNames(df_long$lwd, df_long$cv_id)
  lwd_map <- lwd_map[!duplicated(names(lwd_map))]

  # ---- Plot base ----
  p <- ggplot(df_long, aes(x = x, y = valor, group = cv_id,
                            color = cv_id, linetype = cv_id, linewidth = cv_id)) +
    geom_line() +
    # Preenchimento suave sob a PRC
    geom_area(data = df_long %>% filter(variavel == "PRC"),
              aes(fill = cv_id), alpha = 0.08, color = NA) +
    # Picos da PRC
    geom_point(data = picos %>%
                 mutate(P_scaled = P * p_scale) %>%
                 select(x, curva, cor_prc, PRC) %>%
                 mutate(cv_id = paste(curva, "PRC", sep = "__"), valor = PRC),
               aes(x = x, y = valor, color = cv_id),
               size = 3, shape = 16, inherit.aes = FALSE) +
    # Labels dos picos
    geom_text(data = picos %>%
                mutate(valor = PRC * 1.0,
                       label = paste0("d=", round(x, 1))),
              aes(x = x, y = PRC + 0.04, label = label, color = cor_prc),
              size = 2.8, inherit.aes = FALSE, family = "mono") +
    # Escalas manuais
    scale_color_manual(values = cor_map, guide = "none") +
    scale_fill_manual(values = cor_map, guide = "none") +
    scale_linetype_manual(values = ltype_map, guide = "none") +
    scale_linewidth_manual(values = lwd_map, guide = "none") +
    # Eixo secundário para P (0–1)
    scale_y_continuous(
      name = "Sementes / área  ·  PRC",
      limits = c(0, 1.05),
      sec.axis = sec_axis(~ . / p_scale,
                          name = "Prob. de maturação (P)",
                          breaks = seq(0, 1, 0.25))
    ) +
    scale_x_continuous(name = "Distância do progenitor →", expand = c(0, 0)) +
    # Labels de curva (só Figs com múltiplas I)
    { if (length(curvas_unicas) > 1)
        geom_text(
          data = df_long %>%
            filter(variavel == "I") %>%
            group_by(curva) %>%
            slice(which.min(abs(x - 1.5))) %>%
            ungroup() %>%
            mutate(label = curva),
          aes(x = x, y = valor + 0.03, label = label, color = cv_id),
          size = 2.8, hjust = 0, inherit.aes = FALSE, family = "mono"
        )
    } +
    # Tema escuro
    theme_minimal(base_family = "mono") +
    theme(
      plot.background    = element_rect(fill = "#0e1a0e", color = NA),
      panel.background   = element_rect(fill = "#0e1a0e", color = NA),
      panel.grid.major   = element_line(color = "#1a2a1a", linewidth = 0.4),
      panel.grid.minor   = element_blank(),
      axis.text          = element_text(color = "#4a7a4a", size = 8),
      axis.title         = element_text(color = "#4a9a4a", size = 9),
      axis.title.y.right = element_text(color = "#8a7030", size = 9),
      axis.text.y.right  = element_text(color = "#8a7030"),
      axis.line          = element_line(color = "#3a5a3a"),
      plot.margin        = margin(10, 20, 5, 5)
    )

  p
}


server <- function(input, output, session) {

  # Dados reativos: recalcular quando qualquer slider/select muda
  dados <- reactive({
    build_curves(
      sc    = input$sc,
      pr    = input$pr,
      disp  = input$disp,
      ptype = input$ptype,
      fig   = as.integer(gsub("plot", "", req(input$fig_tabs == input$fig_tabs)))
    )
  })

  # Render para cada aba
  output$plot1 <- renderPlot({
    df <- build_curves(input$sc, input$pr, input$disp, input$ptype, fig = 1)
    make_plot(df, fig = 1)
  })

  output$plot2 <- renderPlot({
    df <- build_curves(input$sc, input$pr, input$disp, input$ptype, fig = 2)
    make_plot(df, fig = 2)
  })

  output$plot3 <- renderPlot({
    df <- build_curves(input$sc, input$pr, input$disp, input$ptype, fig = 3)
    make_plot(df, fig = 3)
  })

  output$plot4 <- renderPlot({
    df <- build_curves(input$sc, input$pr, input$disp, input$ptype, fig = 4)
    make_plot(df, fig = 4)
  })
}


# =============================================================================
# INICIAR O APP
# =============================================================================
shinyApp(ui = ui, server = server)
