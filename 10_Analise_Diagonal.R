# =====================================================================
# ANÁLISE QUE JUSTIFICA (OU NÃO) O DESENHO DIAGONAL DO ESTUDO 4
# =====================================================================
# Pergunta: a divergência entre as quatro curvas de preferência, no espaço das
# métricas de topologia, depende da VARIABILIDADE TOTAL do sistema ou de como
# essa variabilidade está repartida entre os sexos?
#
# Se depende só do total, percorrer a diagonal sigma_p = sigma_z no Estudo 4 já
# cobre o gradiente relevante, e o desenho cai de 70.560 para 10.080 cenários.
# Se a repartição importa, a diagonal não basta.
#
# Usa APENAS os dados do Estudo 1 (controle), que é o único com a superfície
# sigma_p x sigma_z completa.
#
#   Rscript 10_Analise_Diagonal.R
# =====================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2)
})

ARQ <- "Resultados_Artigo/Fase_Controle/Dados/resultados_Controle_censoConst.rds"
if (!file.exists(ARQ)) stop("Não encontrei ", ARQ, ". Copie os dados do controle para cá.")

df <- readRDS(ARQ)
cat(sprintf("Controle carregado: %d linhas, %d réplicas.\n", nrow(df), n_distinct(df$replica)))

dir.create("Resultados_Artigo/Fase_Controle/Graficos", recursive = TRUE, showWarnings = FALSE)

METRICAS <- c("Modularity", "Nestedness", "Centralization", "I_s")

# ---------------------------------------------------------------------
# 1. Divergência entre curvas de preferência, por célula do desenho
# ---------------------------------------------------------------------
# As quatro métricas têm escalas diferentes, então cada uma é padronizada
# (z-score) antes de qualquer comparação. Sem isso, a métrica de maior variância
# domina a distância e o resultado vira um artefato de unidades.
df_z <- df %>% mutate(across(all_of(METRICAS), ~ as.numeric(scale(.x))))

# Média por célula x curva (média sobre réplicas)
por_curva <- df_z %>%
  group_by(sigma_p, sigma_z, encounters_n, k_fixo, selecao_natural, tipo_selecao) %>%
  summarise(across(all_of(METRICAS), ~ mean(.x, na.rm = TRUE)),
            grau = mean(grau_medio_femeas, na.rm = TRUE), .groups = "drop")

# Divergência = distância média ao centroide das quatro curvas, no espaço das
# quatro métricas padronizadas. É zero se as curvas produzem a mesma topologia.
divergencia <- por_curva %>%
  group_by(sigma_p, sigma_z, encounters_n, k_fixo, selecao_natural) %>%
  summarise(
    div = {
      M <- as.matrix(across(all_of(METRICAS)))
      M <- M[stats::complete.cases(M), , drop = FALSE]
      if (nrow(M) < 2) NA_real_ else mean(sqrt(rowSums((M - colMeans(M))^2)))
    },
    # espalhamento da poliandria REALIZADA entre as curvas, na mesma célula.
    # É o candidato a mediador: se as curvas diferem em densidade de rede, parte
    # da divergência topológica pode vir daí e não da geometria da escolha.
    spread_grau = diff(range(grau, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  filter(!is.na(div)) %>%
  mutate(
    norma     = sqrt(sigma_p^2 + sigma_z^2),   # variabilidade TOTAL
    maximo    = pmax(sigma_p, sigma_z),
    descasado = abs(log(sigma_p / sigma_z)),   # REPARTIÇÃO entre os sexos
    na_diagonal = abs(sigma_p - sigma_z) < 1e-9
  )

cat(sprintf("Células com divergência calculada: %d\n\n", nrow(divergencia)))

# ---------------------------------------------------------------------
# 2. Total ou repartição? Os três modelos concorrentes
# ---------------------------------------------------------------------
mods <- list(
  norma     = lm(div ~ norma,     data = divergencia),
  maximo    = lm(div ~ maximo,    data = divergencia),
  descasado = lm(div ~ descasado, data = divergencia),
  ambos     = lm(div ~ norma + descasado, data = divergencia)
)

comparacao <- tibble(
  modelo = names(mods),
  R2     = sapply(mods, function(m) summary(m)$r.squared),
  AIC    = sapply(mods, AIC)
) %>% mutate(dAIC = AIC - min(AIC)) %>% arrange(AIC)

cat("=== Do que depende a divergência entre curvas de preferência? ===\n")
print(as.data.frame(comparacao), row.names = FALSE, digits = 4)
cat("\nLeitura: se 'descasado' (a repartição entre os sexos) tem R2 perto de zero,\n")
cat("o que importa é a variabilidade total e a diagonal basta. Se ele compete com\n")
cat("'norma', a diagonal deixa de fora informação e o Estudo 4 precisa da superfície.\n\n")

cat("--- coeficiente do descasamento no modelo com os dois termos ---\n")
print(summary(mods$ambos)$coefficients, digits = 4)

# ---------------------------------------------------------------------
# 3. A diagonal cobre a mesma faixa que a superfície inteira?
# ---------------------------------------------------------------------
# Este é o teste direto da decisão de desenho: não basta saber de que a
# divergência depende, é preciso que a diagonal PERCORRA a mesma faixa de valores
# que a superfície completa. Se a superfície chega a divergências que a diagonal
# nunca alcança, estaríamos cortando justamente os cenários mais informativos.
cobertura <- divergencia %>%
  group_by(na_diagonal) %>%
  summarise(n = n(), min = min(div), q25 = quantile(div, .25),
            mediana = median(div), q75 = quantile(div, .75), max = max(div),
            .groups = "drop")

cat("\n=== Faixa de divergência: diagonal contra superfície inteira ===\n")
print(as.data.frame(cobertura), row.names = FALSE, digits = 3)

fora <- divergencia %>% filter(!na_diagonal)
dentro <- divergencia %>% filter(na_diagonal)
prop_coberta <- mean(fora$div >= min(dentro$div) & fora$div <= max(dentro$div))
cat(sprintf("\nProporção das células FORA da diagonal cuja divergência cai dentro da\n"))
cat(sprintf("faixa percorrida pela diagonal: %.1f%%\n", 100 * prop_coberta))
cat("Quanto mais perto de 100%, mais defensável é rodar só a diagonal.\n")

# ---------------------------------------------------------------------
# 4. O mediador: a divergência é só diferença de poliandria realizada?
# ---------------------------------------------------------------------
# Pergunta nova, que só se pode fazer agora que gravamos grau_medio_femeas.
# Se a divergência entre curvas for explicada pelo espalhamento do grau, então
# o que separa as curvas é densidade de rede, e não geometria da escolha.
mod_grau  <- lm(div ~ spread_grau, data = divergencia)
mod_ambos <- lm(div ~ norma + spread_grau, data = divergencia)

cat("\n=== A divergência é apenas diferença de poliandria realizada? ===\n")
cat(sprintf("div ~ spread_grau            : R2 = %.3f\n", summary(mod_grau)$r.squared))
cat(sprintf("div ~ norma + spread_grau    : R2 = %.3f\n", summary(mod_ambos)$r.squared))
cat(sprintf("div ~ norma (sozinho)        : R2 = %.3f\n", summary(mods$norma)$r.squared))
cat("\nSe spread_grau sozinho já explica quase tudo, a comparação entre curvas está\n")
cat("confundida com densidade e precisa ser feita em A_max = 200, onde a tabela do\n")
cat("teste mostra que todas as curvas atingem o k e a densidade fica equiparada.\n")

# ---------------------------------------------------------------------
# 5. Gráficos
# ---------------------------------------------------------------------
mapa <- divergencia %>%
  group_by(sigma_p, sigma_z) %>%
  summarise(div = mean(div), .groups = "drop")

g1 <- ggplot(mapa, aes(sigma_z, sigma_p, fill = div)) +
  geom_tile() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", linewidth = 0.8, color = "white") +
  scale_fill_viridis_c(option = "magma") +
  labs(title = "Divergência entre curvas de preferência na superfície sigma_p x sigma_z",
       subtitle = "A linha tracejada é a diagonal proposta para o Estudo 4",
       x = expression(sigma[z]), y = expression(sigma[p]), fill = "Divergência") +
  theme_light(base_size = 13)

g2 <- ggplot(divergencia, aes(norma, div)) +
  geom_point(aes(color = na_diagonal), alpha = 0.35, size = 1.4) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linewidth = 0.7) +
  scale_color_manual(values = c(`FALSE` = "gray65", `TRUE` = "#C0392B"),
                     labels = c("fora da diagonal", "na diagonal"), name = NULL) +
  labs(title = "Divergência contra variabilidade total",
       subtitle = "Se os pontos vermelhos percorrem a mesma faixa vertical que os cinzas, a diagonal basta",
       x = expression(sqrt(sigma[p]^2 + sigma[z]^2)), y = "Divergência entre curvas") +
  theme_light(base_size = 13) + theme(legend.position = "bottom")

ggsave("Resultados_Artigo/Fase_Controle/Graficos/Diagonal_mapa.png", g1,
       width = 7.5, height = 6, dpi = 150, bg = "white")
ggsave("Resultados_Artigo/Fase_Controle/Graficos/Diagonal_norma.png", g2,
       width = 7.5, height = 5.5, dpi = 150, bg = "white")

saveRDS(divergencia, "Resultados_Artigo/Fase_Controle/Dados/divergencia_por_celula.rds")
cat("\nGráficos e tabela de divergência salvos em Resultados_Artigo/Fase_Controle/\n")
