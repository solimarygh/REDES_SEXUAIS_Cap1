# =====================================================================
# AS REDES QUE COMPARAMOS TÊM O MESMO TAMANHO E A MESMA DENSIDADE?
# =====================================================================
#     Rscript 04_tamanho_e_densidade_das_redes.R
#
# Não simula nada: lê os .rds que já existem.
#
# A pergunta veio de olhar as figuras. Em calc_metrics_from_M as fêmeas que não
# acasalaram são retiradas da rede antes de medir, e os machos que não
# acasalaram ficam:
#
#     Mm <- M[, grau_femeas > 0, drop = FALSE]
#
# A decisão tem razão de ser (uma fêmea isolada infla tribos e modularidade sem
# dizer nada sobre a estrutura), mas tem duas consequências que precisam ser
# medidas antes de virarem resultado:
#
#   1. O NÚMERO DE NÓS varia entre células. Onde muitas fêmeas ficam sem
#      acasalar, a rede é menor.
#
#   2. A DENSIDADE varia muito mais. O número de arestas depende de k, de A_max
#      e da taxa de aceite de cada curva. A modularidade de Newman não é
#      invariante à densidade, então duas redes com o mesmo número de nós e
#      metade das arestas não têm Q comparável só porque o índice é o mesmo.
#
# O que este script responde: quanto tamanho e densidade variam de fato, e se as
# diferenças entre curvas que reportamos sobrevivem a controlar por elas.
# =====================================================================

suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

carregar <- function(paths) {
  hit <- paths[file.exists(paths)]
  if (!length(hit)) return(NULL)
  obj <- readRDS(hit[1])
  if (is.data.frame(obj)) obj else bind_rows(obj[!vapply(obj, is.null, logical(1))])
}
juntar_pedacos <- function(pasta, padrao) {
  arqs <- list.files(pasta, pattern = padrao, full.names = TRUE)
  if (!length(arqs)) return(NULL)
  distinct(bind_rows(lapply(arqs, carregar)))
}
carregar_rodada <- function(pasta, estudo) {
  for (r in c("bestOfN", "censoConst")) {
    df <- juntar_pedacos(pasta, sprintf("^(backup|resultados)_%s_%s.*\\.rds$", estudo, r))
    if (!is.null(df) && nrow(df) > 0) return(df)
  }
  NULL
}

ct <- carregar_rodada("Resultados_Artigo/Fase_Controle/Dados", "Controle")
if (is.null(ct)) stop("Não achei os dados do Controle.")

# O Controle é o caso mais limpo para esta pergunta: uma geração só, sem
# evolução, então tudo o que varia é o desenho.
d <- ct %>%
  filter(!is.na(Modularity)) %>%
  mutate(
    # fêmeas que entraram na rede: as que acasalaram
    n_femeas = 200 * (1 - prop_femeas_sem_acasalar),
    n_machos = if ("n_machos_surv" %in% names(.)) n_machos_surv else 200,
    n_nos    = n_femeas + n_machos,
    # densidade da rede bipartida: arestas sobre o máximo possível
    densidade = arestas / (n_femeas * n_machos))

cat(sprintf("\nControle: %s linhas com métricas.\n", format(nrow(d), big.mark = " ")))

# ---------------------------------------------------------------------
cat("\n=== 1. Quanto variam o tamanho e a densidade ===\n\n")
print(as.data.frame(
  d %>% summarise(
    across(c(n_femeas, n_nos, arestas, densidade, grau_medio_femeas),
           list(min = ~ round(min(.x), 3), mediana = ~ round(median(.x), 3),
                max = ~ round(max(.x), 3)))) %>%
    pivot_longer(everything(),
                 names_to = c("variável", "estatística"), names_sep = "_(?=[^_]+$)") %>%
    pivot_wider(names_from = "estatística", values_from = "value")
), row.names = FALSE)

cat("\nSe n_femeas quase não se mexe e a densidade varia por um fator grande, o\n")
cat("problema não é o tamanho da rede, é a densidade.\n")

cat("\n  Por curva de preferência:\n\n")
print(as.data.frame(
  d %>% group_by(tipo_selecao) %>%
    summarise(n_femeas = round(mean(n_femeas)),
              arestas = round(mean(arestas)),
              densidade = round(mean(densidade), 3),
              Modularity = round(mean(Modularity), 3), .groups = "drop")
), row.names = FALSE)

cat("\n  Por k, que é o que mais mexe na densidade:\n\n")
print(as.data.frame(
  d %>% group_by(k_fixo) %>%
    summarise(n_femeas = round(mean(n_femeas)),
              arestas = round(mean(arestas)),
              densidade = round(mean(densidade), 3),
              Modularity = round(mean(Modularity), 3), .groups = "drop")
), row.names = FALSE)

# ---------------------------------------------------------------------
cat("\n=== 2. As métricas seguem o tamanho ou a densidade? ===\n\n")
METRICAS <- c("Modularity", "Nestedness", "Centralization", "I_s")
print(as.data.frame(
  bind_rows(lapply(METRICAS, function(m) {
    tibble(métrica = m,
           `com n_femeas`  = round(cor(d[[m]], d$n_femeas,  use = "complete.obs"), 2),
           `com arestas`   = round(cor(d[[m]], d$arestas,   use = "complete.obs"), 2),
           `com densidade` = round(cor(d[[m]], d$densidade, use = "complete.obs"), 2))
  }))
), row.names = FALSE)

cat("\nCorrelação alta com a densidade não invalida a métrica: quer dizer que ela\n")
cat("não pode ser comparada entre células de densidades diferentes sem controlar.\n")

# ---------------------------------------------------------------------
cat("\n=== 3. A diferença entre curvas sobrevive a controlar por densidade? ===\n\n")
cat("Dois modelos por métrica. O primeiro só com a curva de preferência; o\n")
cat("segundo com a curva mais o número de nós e a densidade. Se o efeito da\n")
cat("curva encolher muito do primeiro para o segundo, boa parte do que\n")
cat("chamamos de 'diferença entre curvas' era diferença de densidade.\n\n")

# Uma medida do tamanho do efeito da curva que não depende de escala: quanto da
# variância da métrica a curva explica, antes e depois de o resto entrar.
efeito_curva <- function(m) {
  f0 <- as.formula(paste(m, "~ tipo_selecao"))
  f1 <- as.formula(paste(m, "~ tipo_selecao + n_nos + densidade"))
  f2 <- as.formula(paste(m, "~ n_nos + densidade"))
  r2 <- function(f) summary(lm(f, data = d))$r.squared
  tibble(métrica = m,
         `R2 só da curva` = round(r2(f0), 3),
         `R2 só de tamanho e densidade` = round(r2(f2), 3),
         `R2 dos três juntos` = round(r2(f1), 3),
         # o que a curva acrescenta depois de tamanho e densidade já estarem lá
         `R2 parcial da curva` = round((r2(f1) - r2(f2)) / (1 - r2(f2)), 3))
}
print(as.data.frame(bind_rows(lapply(METRICAS, efeito_curva))), row.names = FALSE)

cat("\n--- o que isto decide ---\n")
cat("Se o R2 parcial da curva continuar alto, as diferenças entre curvas são\n")
cat("delas e não da densidade, e basta declarar nos Métodos que as redes têm\n")
cat("tamanhos e densidades diferentes por construção.\n\n")
cat("Se despencar, a comparação precisa de um modelo nulo: comparar a\n")
cat("modularidade observada com a de redes aleatorizadas com a MESMA sequência\n")
cat("de graus, e reportar a diferença padronizada em vez do Q cru. É o padrão\n")
cat("em redes ecológicas, e resolve tamanho e densidade de uma vez.\n")
