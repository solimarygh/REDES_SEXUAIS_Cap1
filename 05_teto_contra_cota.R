# =====================================================================
# O CENSO DE MACHOS: TETO CONTRA COTA
# =====================================================================
#     Rscript 05_teto_contra_cota.R
#
# Não simula nada: lê as duas rodadas que já existem.
#
# O QUE ESTÁ EM JOGO
# Com a regra de escolha best-of-n, nas curvas sigmoide e disruptiva com seleção
# natural ligada, o traço se afasta tanto do ótimo ecológico que a viabilidade
# desaba para todos ao mesmo tempo e sobram pouquíssimos machos adultos. Nessas
# células a rede saiu de 200 fêmeas por dois ou três machos, e modularidade,
# aninhamento e centralização não são comparáveis com as das outras.
#
# São duas leituras possíveis do mesmo 200:
#
#   TETO — 200 é um máximo. Cada juvenil sobrevive com probabilidade V de forma
#     independente, e o censo é quem sobrou. A viabilidade é mortalidade
#     absoluta, e o tamanho da população é um resultado do modelo.
#
#   COTA — 200 é a capacidade de suporte. Sorteia-se sempre 200 juvenis com
#     peso proporcional a V, de modo que a seleção decide QUAIS machos ocupam
#     as vagas e nunca QUANTAS vagas há. A população fica regulada por
#     densidade.
#
# POR QUE A COMPARAÇÃO É LIMPA
# As duas rodadas usam a MESMA semente por cenário (seed_base + índice global da
# grade inteira), então cada célula da cota tem a sua gêmea no teto, com a mesma
# população inicial. A diferença entre as duas é do regime e não do acaso, e por
# isso a comparação é PAREADA.
#
# E só a metade COM seleção natural muda: com ela desligada,
# selecionar_machos_adultos devolve por outro caminho de código, uma amostra
# aleatória de 200, idêntica nos dois regimes.
# =====================================================================

suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

# Qual estudo:  Rscript 05_teto_contra_cota.R 2   (ou 4)
ESTUDO <- {
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a)) a[1] else "2"
}
stopifnot(ESTUDO %in% c("2", "4"))

ler <- function(caminho) {
  if (!file.exists(caminho)) return(NULL)
  o <- readRDS(caminho)
  if (is.data.frame(o)) o else bind_rows(o[!vapply(o, is.null, logical(1))])
}

# Onde estão as duas rodadas de cada estudo, e o que define uma célula.
# O teto é a rodada anterior à decisão; a cota, a nova. Em ambos os casos
# excluo explicitamente os arquivos do outro regime, para que os dois nunca se
# misturem num conjunto só.
CFG <- list(
  "2" = list(
    nome   = "Fêmeas variando",
    pasta  = "Resultados_Artigo/Fase5_MiudoV2/Dados",
    teto   = "^resultados_Femeas_bestOfN(?!.*cota).*\\.rds$",
    cota   = "^resultados_Femeas_bestOfN_cota.*\\.rds$",
    celula = c("tipo_selecao", "sigma_p", "encounters_n", "k_fixo", "replica")),
  "4" = list(
    nome   = "Co-evolução",
    pasta  = "Resultados_Artigo/Fase_Coevolucao/Dados",
    teto   = "^resultados_Coevolucao_genica(?!.*cota).*\\.rds$",
    cota   = "^resultados_Coevolucao_genica.*cota.*\\.rds$",
    celula = c("tipo_selecao", "sigma_p_init", "sigma_z_init",
               "encounters_n", "k_fixo", "replica"))
)[[ESTUDO]]

junta <- function(padrao) {
  arqs <- list.files(CFG$pasta, pattern = padrao, full.names = TRUE, perl = TRUE)
  if (!length(arqs)) return(NULL)
  cat("  lendo:", paste(basename(arqs), collapse = ", "), "\n")
  distinct(bind_rows(lapply(arqs, ler)))
}

cat(sprintf("\nEstudo %s (%s)\n", ESTUDO, CFG$nome))
teto <- junta(CFG$teto)
cota <- junta(CFG$cota)

if (is.null(teto) || is.null(cota))
  stop("Faltam dados para o estudo ", ESTUDO, ". Preciso das duas rodadas, ",
       "a do teto e a da cota, na pasta ", CFG$pasta)

# Só a metade que a decisão afeta: com a seleção natural desligada os dois
# regimes percorrem o mesmo caminho de código e dão resultados idênticos.
teto <- teto %>% filter(selecao_natural) %>% mutate(regime = "teto")
cota <- cota %>% filter(selecao_natural) %>% mutate(regime = "cota")
if (!nrow(teto) || !nrow(cota))
  stop("Uma das rodadas não tem células com seleção natural ligada.")
G <- max(c(teto$generation, cota$generation), na.rm = TRUE)

cat(sprintf("\nTeto: %s linhas. Cota: %s linhas. %d gerações.\n",
            format(nrow(teto), big.mark = " "), format(nrow(cota), big.mark = " "), G))

CELULA   <- CFG$celula
METRICAS <- c("Modularity", "Nestedness", "Centralization", "I_s")

# ---------------------------------------------------------------------
cat("\n=== 1. O censo, que é o problema que a cota resolve ===\n\n")
print(as.data.frame(
  bind_rows(teto, cota) %>%
    group_by(regime, tipo_selecao) %>%
    summarise(`censo mínimo`  = min(n_machos_surv, na.rm = TRUE),
              `censo médio`   = round(mean(n_machos_surv, na.rm = TRUE)),
              `linhas < 200`  = sprintf("%.1f%%", 100 * mean(n_machos_surv < 200, na.rm = TRUE)),
              .groups = "drop") %>%
    pivot_wider(names_from = regime,
                values_from = c(`censo mínimo`, `censo médio`, `linhas < 200`))
), row.names = FALSE)

cat("\nNa cota o censo tem de ser 200 em toda linha, por construção. Se não for,\n")
cat("há algo errado e o resto desta leitura não vale.\n")

# ---------------------------------------------------------------------
cat("\n=== 2. As métricas de rede na geração 100 ===\n\n")
cat("É aqui que estava o resultado que não se podia reportar: sob a sigmoide\n")
cat("com seleção natural, a centralização subia de 0.18 para 0.37 ao longo das\n")
cat("gerações, mas nas mesmas células em que o censo desabava. Com dois ou\n")
cat("cinco machos, uma rede é centralizada por construção.\n\n")

fim <- bind_rows(teto, cota) %>% filter(generation == G)
print(as.data.frame(
  fim %>%
    group_by(regime, tipo_selecao) %>%
    summarise(across(all_of(METRICAS), ~ round(mean(.x, na.rm = TRUE), 3)),
              .groups = "drop") %>%
    pivot_longer(all_of(METRICAS), names_to = "métrica") %>%
    pivot_wider(names_from = regime, values_from = value) %>%
    mutate(diferenca = round(cota - teto, 3)) %>%
    arrange(`métrica`, tipo_selecao)
), row.names = FALSE)

# ---------------------------------------------------------------------
cat("\n=== 3. A comparação PAREADA, célula a célula ===\n\n")
cat("A tabela acima compara médias, que podem diferir só porque as células\n")
cat("com censo curto pesam diferente. Esta compara cada célula com a sua\n")
cat("gêmea de mesma semente, e por isso isola o efeito do regime.\n\n")

pareado <- inner_join(
  teto %>% filter(generation == G) %>% select(all_of(CELULA), all_of(METRICAS),
                                              zbar_males, varz_males, n_machos_surv),
  cota %>% filter(generation == G) %>% select(all_of(CELULA), all_of(METRICAS),
                                              zbar_males, varz_males, n_machos_surv),
  by = CELULA, suffix = c("_teto", "_cota"))

cat(sprintf("  %s células emparelhadas.\n\n", format(nrow(pareado), big.mark = " ")))

diferenca_pareada <- function(col) {
  d <- pareado[[paste0(col, "_cota")]] - pareado[[paste0(col, "_teto")]]
  d <- d[is.finite(d)]
  if (!length(d)) return(NULL)
  tibble(variável = col,
         `diferença média` = round(mean(d), 3),
         `mediana` = round(median(d), 3),
         `% de células em que a cota dá mais` = sprintf("%.0f%%", 100 * mean(d > 0)))
}
print(as.data.frame(bind_rows(lapply(
  c(METRICAS, "zbar_males", "varz_males", "n_machos_surv"), diferenca_pareada))),
  row.names = FALSE)

cat("\n  E só nas células em que o teto encurtou o censo, que são as que a\n")
cat("  decisão de fato muda:\n\n")
curtas <- pareado %>% filter(n_machos_surv_teto < 200)
if (nrow(curtas)) {
  cat(sprintf("  %s células (%.1f%% do total).\n\n",
              format(nrow(curtas), big.mark = " "), 100 * nrow(curtas) / nrow(pareado)))
  print(as.data.frame(
    curtas %>%
      summarise(across(ends_with(c("_teto", "_cota")), ~ round(mean(.x, na.rm = TRUE), 3))) %>%
      pivot_longer(everything(), names_to = c("variável", "regime"), names_sep = "_(?=[^_]+$)") %>%
      pivot_wider(names_from = regime, values_from = value)
  ), row.names = FALSE)
} else {
  cat("  Nenhuma: o teto não encurtou o censo em célula nenhuma desta metade.\n")
}

# ---------------------------------------------------------------------
cat("\n=== 4. E o traço, que é o que a seleção natural devia conter ===\n\n")
print(as.data.frame(
  fim %>%
    group_by(regime, tipo_selecao) %>%
    summarise(zbar = round(mean(zbar_males, na.rm = TRUE), 2),
              varz = round(mean(varz_males, na.rm = TRUE), 2),
              .groups = "drop") %>%
    pivot_wider(names_from = regime, values_from = c(zbar, varz))
), row.names = FALSE)

cat("\nCom o teto, a seleção natural mata quase todo mundo mas contém pouco o\n")
cat("traço: com dois ou três machos sobrando, a diferença de sobrevivência\n")
cat("entre eles é um canal estreito demais para segurar a média. Com a cota a\n")
cat("seleção age sobre 200 vagas disputadas, então deve conter mais.\n")

cat("\n--- o que isto decide ---\n")
cat("Se sob a cota a centralização da sigmoide continuar subindo, o resultado\n")
cat("é real e passa a ser reportável. Se ela desaparecer, era o censo curto, e\n")
cat("o que temos é uma lição de método em vez de um resultado.\n")
