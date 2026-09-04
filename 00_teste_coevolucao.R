# =====================================================================
# PRIMEIRO TESTE DE CO-EVOLUÇÃO
# =====================================================================
#     Rscript 00_teste_coevolucao.R
#
# Não é o estudo, é um recorte pequeno para responder três coisas:
#   1. O motor roda, e a covariância sobrevive à passagem de gerações?
#   2. Cada curva de preferência faz o que a teoria prevê com cov(z, p)?
#   3. O runaway aparece, e quando aparece o censo aguenta?
#
# Leva uns poucos minutos. O desenho completo continua em aberto: os quatro
# pontos estão em NOTA_material_removido_2026-08-16.md.
# =====================================================================

COEVO_SO_FUNCOES <- TRUE
source("Fase_Coevolucao.R")
suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

falhas <- 0L
checar <- function(nome, condicao, detalhe = "") {
  ok <- isTRUE(condicao)
  if (!ok) falhas <<- falhas + 1L
  cat(sprintf("  [%s] %s%s\n", if (ok) "OK" else "FALHOU", nome,
              if (nzchar(detalhe)) paste0("  -> ", detalhe) else ""))
}

G <- 60L   # gerações por réplica no teste; o estudo usará 100
R <- 3L    # réplicas por cenário

# ---------------------------------------------------------------------
cat("\n=== 1. O motor roda? ===\n")
set.seed(1)
d1 <- simulate_coevolucao(generations = 10, tipo_selecao = "gaussian",
                          encounters_n = 200, k_fixo = 5L, selecao_natural = TRUE)

checar("10 linhas para 10 gerações", nrow(d1) == 10, sprintf("nrow = %d", nrow(d1)))
checar("as colunas centrais existem",
       all(c("cov_zp", "cor_zp", "cov_casais", "zbar_pop", "pbar_pop") %in% names(d1)))
checar("regra e segregação gravadas",
       d1$regra[1] == "best_of_n" && d1$segregacao[1] == "infinitesimal")
checar("réplica completa: extincao_gen é NA", all(is.na(d1$extincao_gen)))
checar("nenhum NA em cov_zp", !any(is.na(d1$cov_zp)))

# A covariância tem de ser MEDIDA sobre 400 indivíduos (censo adulto dos dois
# sexos). Se alguém trocar o pool por um dos sexos só, isto pega.
checar("censo adulto de machos", all(d1$n_machos_surv == 200),
       paste(unique(d1$n_machos_surv), collapse = ", "))

# ---------------------------------------------------------------------
cat("\n=== 2. A covariância sobrevive ao embaralhamento dos filhotes? ===\n")
# É o erro silencioso mais perigoso deste estudo: se z e p forem amostrados
# separadamente, cov(z, p) vira zero e o runaway some por bug, não por
# biologia. O teste é direto: com preferência gaussiana o acasalamento é
# fortemente assortativo, então a covariância TEM de subir acima de zero.
set.seed(2)
d_gau <- bind_rows(lapply(1:R, function(r) {
  set.seed(200 + r)
  x <- simulate_coevolucao(generations = G, tipo_selecao = "gaussian",
                           encounters_n = 200, k_fixo = 5L, selecao_natural = TRUE)
  x$replica <- r; x
}))
cov_final_gau <- mean(d_gau$cov_zp[d_gau$generation == G])
checar("gaussiana acumula covariância positiva", cov_final_gau > 0.05,
       sprintf("cov(z,p) na geração %d = %.3f", G, cov_final_gau))

# ---------------------------------------------------------------------
cat("\n=== 3. As quatro curvas fazem o que a teoria prevê? ===\n")
cat("Esperado: aleatória em torno de zero (não há acasalamento assortativo),\n")
cat("gaussiana e sigmoide positivas, u-shaped negativa (dissortativo).\n\n")

curvas <- c("uniform", "gaussian", "sigmoid", "u-shaped")
res <- bind_rows(lapply(curvas, function(cv) {
  bind_rows(lapply(1:R, function(r) {
    set.seed(300 + r)
    x <- simulate_coevolucao(generations = G, tipo_selecao = cv,
                             encounters_n = 200, k_fixo = 5L, selecao_natural = TRUE)
    x$replica <- r; x
  }))
}))

resumo <- res %>%
  filter(generation == G) %>%
  group_by(tipo_selecao) %>%
  summarise(cov_zp   = round(mean(cov_zp), 3),
            cor_zp   = round(mean(cor_zp), 3),
            cov_casais = round(mean(cov_casais, na.rm = TRUE), 3),
            zbar     = round(mean(zbar_pop), 2),
            pbar     = round(mean(pbar_pop), 2),
            varz     = round(mean(varz_pop), 2),
            censo    = round(mean(n_machos_surv)),
            .groups  = "drop")
print(as.data.frame(resumo), row.names = FALSE)

cov_unif <- resumo$cov_zp[resumo$tipo_selecao == "uniform"]
cov_gaus <- resumo$cov_zp[resumo$tipo_selecao == "gaussian"]
cov_ushp <- resumo$cov_zp[resumo$tipo_selecao == "u-shaped"]

cat("\n")
checar("aleatória fica perto de zero", abs(cov_unif) < 0.1,
       sprintf("cov = %.3f", cov_unif))
checar("gaussiana acima da aleatória", cov_gaus > cov_unif,
       sprintf("%.3f contra %.3f", cov_gaus, cov_unif))
checar("u-shaped abaixo da aleatória (dissortativo)", cov_ushp < cov_unif,
       sprintf("%.3f contra %.3f", cov_ushp, cov_unif))

# ---------------------------------------------------------------------
cat("\n=== 4. O runaway, e o que ele faz com o censo ===\n")
cat("Sem seleção natural o traço não tem nada que o segure, então é onde a\n")
cat("fuga deve aparecer. Com seleção natural, é onde o censo pode desandar.\n\n")

fuga <- bind_rows(lapply(c(TRUE, FALSE), function(ns) {
  bind_rows(lapply(curvas, function(cv) {
    set.seed(400)
    x <- simulate_coevolucao(generations = G, tipo_selecao = cv,
                             encounters_n = 200, k_fixo = 5L, selecao_natural = ns)
    x$replica <- 1L; x
  }))
}))

print(as.data.frame(
  fuga %>%
    filter(generation == G) %>%
    group_by(selecao_natural, tipo_selecao) %>%
    summarise(zbar = round(mean(zbar_pop), 1),
              pbar = round(mean(pbar_pop), 1),
              cov_zp = round(mean(cov_zp), 2),
              censo_min = min(n_machos_surv),
              fuga_gen = ifelse(all(is.na(fuga_gen)), NA_integer_, min(fuga_gen, na.rm = TRUE)),
              .groups = "drop")
), row.names = FALSE)

curtos <- fuga %>% filter(n_machos_surv < 200)
cat(sprintf("\n  Linhas com censo abaixo de 200: %d de %d (%.1f%%)\n",
            nrow(curtos), nrow(fuga), 100 * nrow(curtos) / nrow(fuga)))
if (nrow(curtos) > 0) {
  cat("  Acontece em: ",
      paste(unique(paste0(curtos$tipo_selecao,
                          ifelse(curtos$selecao_natural, " (com NS)", " (sem NS)"))),
            collapse = ", "), "\n")
  cat("  É o mesmo problema do estudo das fêmeas, e aqui deve ser pior porque\n")
  cat("  as duas características evoluem. Reforça a discussão da cota.\n")
}

# ---------------------------------------------------------------------
cat("\n=== 5. A cadeia causal: casais primeiro, genótipo depois ===\n")
# cov_casais mede o acasalamento assortativo (o passo anterior) e cov_zp mede
# a covariância genética que ele constrói. Se a cadeia funciona, as duas têm
# de andar juntas entre curvas.
cc <- res %>% filter(generation == G) %>%
  group_by(tipo_selecao) %>%
  summarise(casais = mean(cov_casais, na.rm = TRUE),
            genot  = mean(cov_zp), .groups = "drop")
r_cadeia <- suppressWarnings(cor(cc$casais, cc$genot))
cat(sprintf("  correlação entre cov_casais e cov_zp entre as quatro curvas: %.2f\n", r_cadeia))
checar("as duas medidas andam juntas", !is.na(r_cadeia) && r_cadeia > 0.5,
       sprintf("r = %.2f", r_cadeia))

# ---------------------------------------------------------------------
dir.create("Resultados_Artigo/Fase_Coevolucao/Dados", recursive = TRUE, showWarnings = FALSE)
saveRDS(bind_rows(res, fuga), "Resultados_Artigo/Fase_Coevolucao/Dados/teste_coevolucao.rds")
cat("\nDados do teste em Resultados_Artigo/Fase_Coevolucao/Dados/teste_coevolucao.rds\n")

cat("\n=====================================================\n")
if (falhas == 0L) {
  cat("TODOS OS TESTES PASSARAM. O motor de co-evolução está de pé.\n")
} else {
  cat(sprintf("ATENÇÃO: %d teste(s) falharam.\n", falhas))
}
cat("=====================================================\n")
