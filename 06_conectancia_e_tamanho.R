# =====================================================================
# CONECTÂNCIA CONTRA O TAMANHO DA REDE
# =====================================================================
#     Rscript 06_conectancia_e_tamanho.R
#
# A rede de acasalamentos é bipartida, não dirigida e binária, então a
# conectância é
#
#     C = arestas / (n_machos * n_femeas)
#
# e NÃO 2E/n^2, que é a fórmula unipartida: ali o denominador é n(n-1)/2,
# os pares possíveis quando qualquer indivíduo pode interagir com qualquer
# outro. Aqui os pares macho-macho e fêmea-fêmea não são zeros observados,
# são zeros estruturais, e metê-los no denominador partiria a conectância
# pela metade sem significar nada.
#
# O ponto do gráfico: neste modelo o número de arestas é fixado pelo lado
# das FÊMEAS, porque cada uma busca até k parceiros. O número de machos
# entra só no denominador. Substituindo E = N_f * k,
#
#     C = (N_f * k) / (n_m * N_f) = k / n_m
#
# ou seja a conectância é k dividido pelo censo de machos, e N_f se cancela.
# Com um tecto: a conectância é uma proporção e não passa de 1, e nenhuma
# fêmea consegue mais parceiros do que há machos. A conta completa é
#
#     C = min(k, A_max, n_m) / n_m
#
# Então, à medida que o censo encurta, a conectância SOBE, até saturar.
# É por isso que as métricas de topologia das células de censo curto não
# são comparáveis com as das outras: aninhamento e centralização respondem
# forte à conectância.
# =====================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(patchwork)
})

N_FEMEAS <- 200L   # as fêmeas não passam por viabilidade: são sempre 200
KS       <- c(5L, 10L, 20L)

dir.create("Resultados_Artigo/Figuras", recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------------
# (a) A conta, sem dado nenhum: C = k / n_m
# ---------------------------------------------------------------------
# O tecto de 1 não é decoração: a conectância é uma proporção. A conta
# C = k/n_m supõe que cada fêmea consegue k parceiros, o que é impossível
# quando há menos de k machos: com 2 machos nenhuma fêmea tem 5 parceiros,
# tem 2. O grau de uma fêmea é no máximo min(k, A_max, machos disponíveis),
# então a curva fica em 1 enquanto o censo não passar de k, e só depois cai.
curva <- expand.grid(n_m = 2:200, k = KS) %>%
  mutate(C = pmin(k, n_m) / n_m, k = factor(k, levels = KS))

# Os pontos do desenho: censo cheio, um por k.
desenho <- data.frame(n_m = 200, k = factor(KS, levels = KS), C = KS / 200)

pa <- ggplot(curva, aes(n_m, C, color = k)) +
  geom_hline(yintercept = 1, linetype = "dotted", color = "gray40") +
  geom_line(linewidth = 1.1) +
  geom_point(data = desenho, size = 2.6) +
  scale_color_brewer(palette = "Dark2", name = "k") +
  scale_x_continuous(breaks = c(2, 38, 50, 100, 150, 200)) +
  labs(title = "a. A conta: conectância = min(k, censo) / censo de machos",
       subtitle = "Cada fêmea busca até k parceiros, então o número de arestas não depende de quantos\nmachos existem: o censo entra só no denominador. Quando o censo encurta a\nconectância SOBE, até saturar em 1. Os pontos marcam o censo cheio de 200.",
       x = "censo de machos", y = "conectância") +
  theme_light(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 8.5), legend.position = "bottom")

# O mesmo em log-log, onde a relação vira uma reta de inclinação -1.
pb <- ggplot(curva, aes(n_m, C, color = k)) +
  geom_hline(yintercept = 1, linetype = "dotted", color = "gray40") +
  geom_line(linewidth = 1.1) +
  geom_point(data = desenho, size = 2.6) +
  scale_color_brewer(palette = "Dark2", guide = "none") +
  scale_x_log10() + scale_y_log10() +
  labs(title = "b. O mesmo em escala log",
       subtitle = "Acima de k a relação é uma reta de inclinação -1: cada vez que o censo cai pela\nmetade, a conectância dobra. Abaixo de k ela satura em 1 e não pode subir mais.",
       x = "censo de machos (log)", y = "conectância (log)") +
  theme_light(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 11),
        plot.subtitle = element_text(size = 8.5))

# ---------------------------------------------------------------------
# (c) A mesma relação nos dados, se eles estiverem à mão
# ---------------------------------------------------------------------
# Lê o Estudo 2, que é onde o censo varia, separando os dois regimes de
# censo: sob a cota o censo é sempre 200 e todos os pontos caem numa
# coluna só; sob o teto eles se espalham para a esquerda, com a
# conectância subindo. É esse contraste que o painel mostra.
ler <- function(a) {
  o <- readRDS(a)
  if (is.data.frame(o)) o else bind_rows(o[!vapply(o, is.null, logical(1))])
}
juntar <- function(pasta, padrao) {
  arqs <- list.files(pasta, full.names = TRUE)
  arqs <- arqs[grepl(padrao, basename(arqs), perl = TRUE)]
  if (!length(arqs)) return(NULL)
  distinct(bind_rows(lapply(arqs, ler)))
}

PASTA <- "Resultados_Artigo/Fase5_MiudoV2/Dados"
teto <- juntar(PASTA, "^(backup|resultados)_Femeas_bestOfN(?!.*cota).*\\.rds$")
cota <- juntar(PASTA, "^(backup|resultados)_Femeas_bestOfN.*cota.*\\.rds$")

preparar <- function(x, nome) {
  if (is.null(x) || !nrow(x)) return(NULL)
  if (!all(c("arestas", "n_machos_surv") %in% names(x))) return(NULL)
  x %>%
    filter(generation == max(generation, na.rm = TRUE)) %>%
    mutate(regime = nome,
           C = arestas / (n_machos_surv * N_FEMEAS)) %>%
    filter(is.finite(C)) %>%
    dplyr::select(regime, n_machos_surv, C, k_fixo, tipo_selecao)
}

dados <- bind_rows(preparar(teto, "teto"), preparar(cota, "cota"))

pc <- if (!nrow(dados)) {
  ggplot() + theme_void() +
    labs(title = "c. Sem dados do Estudo 2 nesta máquina",
         subtitle = "Os painéis a e b são só a conta e não precisam de dados.")
} else {
  ggplot(dados, aes(n_machos_surv, C, color = factor(k_fixo))) +
    geom_point(alpha = 0.25, size = 1.1) +
    geom_line(data = curva %>% mutate(k_fixo = as.integer(as.character(k))),
              aes(n_m, C, group = k_fixo), color = "gray30",
              linewidth = 0.6, linetype = "dashed", inherit.aes = FALSE) +
    facet_wrap(~ regime, labeller = labeller(regime = c(
      teto = "TETO: o censo varia", cota = "COTA: o censo é sempre 200"))) +
    scale_color_brewer(palette = "Dark2", name = "k") +
    labs(title = "c. Nos dados do Estudo 2, geração final",
         subtitle = "Um ponto por cenário. As linhas tracejadas são a conta do painel a: os pontos ficam\nabaixo delas porque a poliandria realizada é menor que k.",
         x = "censo de machos", y = "conectância") +
    theme_light(base_size = 11) +
    theme(plot.title = element_text(face = "bold", size = 11),
          plot.subtitle = element_text(size = 8.5), legend.position = "bottom")
}

figura <- (pa | pb) / pc +
  plot_layout(heights = c(1, 1.1)) +
  plot_annotation(
    title = "Conectância e tamanho da rede",
    caption = paste("Rede bipartida, não dirigida e binária: C = arestas / (n_machos x n_femeas), com n_femeas = 200.",
                    "\nNão 2E/n^2, que é a fórmula unipartida e incluiria no denominador os pares macho-macho e fêmea-fêmea, que são impossíveis."),
    theme = theme(plot.title = element_text(face = "bold", size = 14),
                  plot.caption = element_text(hjust = 0, face = "italic", size = 8)))

destino <- "Resultados_Artigo/Figuras/conectancia_e_tamanho.png"
ggsave(destino, figura, width = 11, height = 8.5, dpi = 150)
cat("\nFigura em", destino, "\n")

if (nrow(dados)) {
  cat("\nConectância média por regime e censo:\n\n")
  print(as.data.frame(
    dados %>%
      mutate(faixa = cut(n_machos_surv, c(0, 10, 50, 100, 199, 200),
                         labels = c("2-10", "11-50", "51-100", "101-199", "200"))) %>%
      group_by(regime, faixa) %>%
      summarise(cenarios = n(), `conectância média` = round(mean(C), 4),
                .groups = "drop")
  ), row.names = FALSE)
  cat("\nSe a coluna do teto mostrar conectância bem mais alta nas faixas de\n")
  cat("censo pequeno, é a confirmação nos dados do que a conta do painel a diz.\n")
}
