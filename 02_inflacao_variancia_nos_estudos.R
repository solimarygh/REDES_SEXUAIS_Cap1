# =====================================================================
# A INFLAÇÃO DA VARIÂNCIA CHEGOU AOS ESTUDOS JÁ RODADOS?
# =====================================================================
#     Rscript 02_inflacao_variancia_nos_estudos.R
#
# Não simula nada: lê os dados que já existem.
#
# O diagnóstico da co-evolução mostrou que a segregação alimentada pela
# variância TOTAL do pool parental realimenta o acasalamento assortativo, e a
# variância cresce sem freio. Fêmeas variando usa exatamente a mesma
# segregação, e a curva gaussiana gera exatamente o mesmo assortamento. A
# pergunta é se o mesmo laço está lá.
#
# A previsão, se estiver: a variância do traço deve subir acima do sigma_z
# inicial (1.0) nas curvas que geram acasalamento assortativo, e ficar parada
# na aleatória, que não gera nenhum. Se a aleatória também subir, é deriva e
# não assortamento, e o laço não é o culpado.
#
# E há uma segunda coisa em jogo. A "diagonal" que apareceu na exploração — o
# sigma_z da geração 100 acompanhando o sigma_p imposto, sob a gaussiana —
# pode ser biologia ou pode ser este laço parando num equilíbrio fixado por
# sigma_p. Se for o laço, varz_final tem de acompanhar sigma_p^2.
# =====================================================================

suppressPackageStartupMessages({ library(dplyr) })

carregar <- function(paths) {
  hit <- paths[file.exists(paths)]
  if (!length(hit)) return(NULL)
  obj <- readRDS(hit[1])
  if (is.data.frame(obj)) obj else bind_rows(obj[!vapply(obj, is.null, logical(1))])
}
d <- carregar(c("Resultados_Artigo/Reunidos/Estudo2_femeas.rds"))
if (is.null(d)) stop("Não achei Resultados_Artigo/Reunidos/Estudo2_femeas.rds. Rode 99_juntar_resultados.R.")

G <- max(d$generation, na.rm = TRUE)
cat(sprintf("\nFêmeas variando: %s linhas, %d gerações, %d réplicas.\n",
            format(nrow(d), big.mark = "."), G, n_distinct(d$replica)))
cat("Todas as contas abaixo são SEM seleção natural, para o efeito da\n")
cat("viabilidade não se misturar com o do acasalamento.\n")

sem_ns <- d %>% filter(!selecao_natural, encounters_n == 200)

# ---------------------------------------------------------------------
cat("\n=== 1. A variância do traço sobe? (parte de sigma_z = 1, ou seja var = 1) ===\n\n")
tab1 <- sem_ns %>%
  filter(generation %in% c(1L, G)) %>%
  group_by(tipo_selecao, generation) %>%
  summarise(varz = mean(varz_males, na.rm = TRUE), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = generation, values_from = varz,
                     names_prefix = "gen_") %>%
  mutate(across(where(is.numeric), ~ round(.x, 2)),
         razao = round(.data[[paste0("gen_", G)]] / .data$gen_1, 1))
print(as.data.frame(tab1), row.names = FALSE)

cat("\nA aleatória não gera acasalamento assortativo nenhum, então serve de\n")
cat("régua: o quanto ela sobe é o que a deriva e a mutação fazem sozinhas.\n")

# ---------------------------------------------------------------------
cat("\n=== 2. A subida acompanha o assortamento de cada curva? ===\n\n")
cat("Ordem esperada, se for o laço: gaussiana (assortamento forte) acima de\n")
cat("todas, aleatória embaixo, e a u-shaped, que é dissortativa, também baixa.\n\n")

tab2 <- sem_ns %>%
  filter(generation == G) %>%
  group_by(tipo_selecao) %>%
  summarise(varz_final = round(mean(varz_males, na.rm = TRUE), 2),
            zbar_final = round(mean(zbar_males, na.rm = TRUE), 2),
            .groups = "drop") %>%
  arrange(desc(varz_final))
print(as.data.frame(tab2), row.names = FALSE)

# ---------------------------------------------------------------------
cat("\n=== 3. A diagonal: varz_final acompanha sigma_p^2? ===\n\n")
cat("Este é o teste da diagonal. Se o laço para num equilíbrio fixado pelo\n")
cat("sigma_p imposto, a razão varz_final / sigma_p^2 tem de ficar constante ao\n")
cat("longo do gradiente. Se variar muito, a diagonal não é só o laço.\n\n")

tab3 <- sem_ns %>%
  filter(generation == G, tipo_selecao %in% c("gaussian", "uniform")) %>%
  group_by(tipo_selecao, sigma_p) %>%
  summarise(varz_final = mean(varz_males, na.rm = TRUE),
            sigma_z_final = sqrt(mean(varz_males, na.rm = TRUE)),
            .groups = "drop") %>%
  mutate(razao_var = round(varz_final / sigma_p^2, 2),
         varz_final = round(varz_final, 2),
         sigma_z_final = round(sigma_z_final, 2))
print(as.data.frame(tab3), row.names = FALSE)

gau <- tab3 %>% filter(tipo_selecao == "gaussian")
cat(sprintf("\n  Gaussiana: correlação entre sigma_p e sigma_z_final = %.2f\n",
            cor(gau$sigma_p, gau$sigma_z_final)))
cat(sprintf("  A razão varz_final/sigma_p^2 varia de %.2f a %.2f\n",
            min(gau$razao_var), max(gau$razao_var)))

# ---------------------------------------------------------------------
cat("\n=== 4. Quando começa a subir ===\n\n")
print(as.data.frame(
  sem_ns %>%
    filter(generation %% 20 == 0 | generation == 1,
           sigma_p == 1.0) %>%
    group_by(tipo_selecao, generation) %>%
    summarise(varz = round(mean(varz_males, na.rm = TRUE), 2), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = tipo_selecao, values_from = varz)
), row.names = FALSE)

cat("\n  Com sigma_p = 1.0. Se a gaussiana descola das outras logo nas primeiras\n")
cat("  gerações, é o laço; se todas sobem parecido, é deriva.\n")

cat("\n--- o que isto decide ---\n")
cat("Se a gaussiana subir muito mais que a aleatória, o mesmo laço da\n")
cat("co-evolução está em Fêmeas variando, e a diagonal precisa ser reexaminada\n")
cat("antes de virar resultado. Se subirem parecido, a diagonal se sustenta e o\n")
cat("problema fica restrito à co-evolução, onde as duas características evoluem.\n")
