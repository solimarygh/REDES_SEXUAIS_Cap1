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
    descasado = abs(log(sigma_p / sigma_z)),   # REPARTIÇÃO, simétrica
    # A versão COM SINAL. Positiva quando os machos são mais variados que as
    # fêmeas. Faz diferença: se o efeito for assimétrico, a versão em valor
    # absoluto mistura duas situações biologicamente opostas e subestima tudo.
    assimetria  = log(sigma_z / sigma_p),
    na_diagonal = abs(sigma_p - sigma_z) < 1e-9
  )

cat(sprintf("Células com divergência calculada: %d\n\n", nrow(divergencia)))

# ---------------------------------------------------------------------
# 2. Total ou repartição? Duas perguntas diferentes, dois ajustes
# ---------------------------------------------------------------------
# ATENÇÃO À ESPECIFICAÇÃO. As células variam em sigma_p, sigma_z, A_max, k e
# seleção natural. Um modelo só com os termos de sigma joga TODO o efeito de
# A_max e de k no resíduo, e como esse efeito é grande (ver a tabela de
# poliandria realizada), todos os R2 saem esmagados. Por isso aqui há dois
# ajustes, que respondem a perguntas distintas e cujos R2 NÃO são comparáveis.

# (a) DENTRO de cada condição de busca: um modelo base com A_max, k e seleção
# natural, e depois o ganho de acrescentar os termos de sigma. O que interessa é
# o R2 PARCIAL, ou seja, quanto do que sobra depois do base cada termo explica.
base <- lm(div ~ factor(encounters_n) * factor(k_fixo) * selecao_natural,
           data = divergencia)
r2_base <- summary(base)$r.squared

parcial <- function(extra) {
  m  <- update(base, as.formula(paste(". ~ . +", extra)))
  r2 <- summary(m)$r.squared
  c(R2_total = r2, R2_parcial = (r2 - r2_base) / (1 - r2_base), AIC = AIC(m))
}

dentro <- rbind(
  norma      = parcial("norma"),
  maximo     = parcial("maximo"),
  descasado  = parcial("descasado"),
  assimetria = parcial("assimetria"),
  ambos      = parcial("norma + descasado"),
  ambos_sin  = parcial("norma + assimetria")
)

cat(sprintf("=== (a) DENTRO de cada condicao de busca (A_max x k x selecao natural) ===\n"))
cat(sprintf("R2 do modelo base, so com A_max, k e selecao natural: %.3f\n", r2_base))
cat("O R2 parcial e o que cada termo de sigma acrescenta SOBRE esse base.\n\n")
print(round(as.data.frame(dentro), 4))

# (b) AGREGADO por célula sigma_p x sigma_z, mediando sobre A_max, k e seleção
# natural. É a pergunta "a divergência MÉDIA depende da posição no plano?", e é
# quase certamente a forma do cálculo antigo que deu R2 = 0.54. Como a média
# elimina a variação de A_max e k, o R2 aqui é naturalmente muito maior: ele
# NÃO mede a mesma coisa que o de cima.
agg <- divergencia %>%
  group_by(sigma_p, sigma_z) %>%
  summarise(div = mean(div, na.rm = TRUE), .groups = "drop") %>%
  mutate(norma      = sqrt(sigma_p^2 + sigma_z^2),
         maximo     = pmax(sigma_p, sigma_z),
         descasado  = abs(log(sigma_p / sigma_z)),
         assimetria = log(sigma_z / sigma_p))

mods_agg <- list(norma      = lm(div ~ norma,      data = agg),
                 maximo     = lm(div ~ maximo,     data = agg),
                 descasado  = lm(div ~ descasado,  data = agg),
                 assimetria = lm(div ~ assimetria, data = agg),
                 ambos      = lm(div ~ norma + descasado,  data = agg),
                 ambos_sin  = lm(div ~ norma + assimetria, data = agg))

comp_agg <- tibble(modelo = names(mods_agg),
                   R2  = sapply(mods_agg, function(m) summary(m)$r.squared),
                   AIC = sapply(mods_agg, AIC)) %>%
  mutate(dAIC = AIC - min(AIC)) %>% arrange(AIC)

cat(sprintf("\n=== (b) AGREGADO nas %d celulas sigma_p x sigma_z ===\n", nrow(agg)))
print(as.data.frame(comp_agg), row.names = FALSE, digits = 4)
cat("\nLeitura: em (a), se 'descasado' tem R2 parcial perto de zero, a reparticao\n")
cat("entre os sexos nao importa e a diagonal basta. Em (b) le-se a mesma coisa,\n")
cat("mas sobre a divergencia media. Se as duas discordam, vale mais a de cima:\n")
cat("a agregacao esconde o quanto A_max e k dominam o fenomeno.\n")

# ---------------------------------------------------------------------
# 3. A diagonal cobre a mesma faixa que a superfície inteira?
# ---------------------------------------------------------------------
# Este é o teste direto da decisão de desenho, e não depende de nenhum ajuste:
# não basta saber de que a divergência depende, é preciso que a diagonal PERCORRA
# a mesma faixa de valores que a superfície completa.
cobertura <- divergencia %>%
  group_by(na_diagonal) %>%
  summarise(n = n(), min = min(div), q25 = quantile(div, .25),
            mediana = median(div), q75 = quantile(div, .75), max = max(div),
            .groups = "drop")

cat("\n=== Faixa de divergencia: diagonal contra superficie inteira ===\n")
print(as.data.frame(cobertura), row.names = FALSE, digits = 3)

fora   <- divergencia %>% filter(!na_diagonal)
dentro_d <- divergencia %>% filter(na_diagonal)
prop_coberta <- mean(fora$div >= min(dentro_d$div) & fora$div <= max(dentro_d$div))
cat(sprintf("\nProporcao das celulas FORA da diagonal cuja divergencia cai dentro da\n"))
cat(sprintf("faixa percorrida pela diagonal: %.1f%%\n", 100 * prop_coberta))

# ONDE estão as células que a diagonal não alcança. Se forem os cantos extremos
# (sigma_p muito diferente de sigma_z), a solução barata é diagonal + cantos.
nao_cobertas <- fora %>% filter(div > max(dentro_d$div)) %>%
  count(sigma_p, sigma_z, sort = TRUE)
cat(sprintf("\nCelulas acima do maximo da diagonal: %d. Onde estao:\n", sum(nao_cobertas$n)))
if (nrow(nao_cobertas) > 0) print(as.data.frame(head(nao_cobertas, 12)), row.names = FALSE)

# ---------------------------------------------------------------------
# 3b. CONFRONTO DIRETO COM AS PREVISÕES DO PAPER (H1 e H3a)
# ---------------------------------------------------------------------
# H1 diz que as assinaturas topológicas "intensify with increasing preference
# heterogeneity (sigma_p)". A linha sigma_z = 1.0 do Controle é exatamente o eixo
# de Fêmeas variando, então dá para testar isso direto.
h1 <- divergencia %>%
  filter(abs(sigma_z - 1.0) < 1e-9) %>%
  group_by(sigma_p) %>%
  summarise(div_media = mean(div), n = n(), .groups = "drop")

cat("\n=== H1: a divergencia cresce com sigma_p? (linha sigma_z = 1.0) ===\n")
print(as.data.frame(h1), row.names = FALSE, digits = 3)
tend_h1 <- coef(lm(div ~ sigma_p, data = filter(divergencia, abs(sigma_z - 1.0) < 1e-9)))[2]
cat(sprintf("Inclinacao: %+.3f por unidade de sigma_p.\n", tend_h1))
cat(if (tend_h1 > 0) "Sinal POSITIVO: compativel com H1.\n" else
    "Sinal NEGATIVO: CONTRARIO ao previsto por H1.\n")

# H3a diz que a divergência é MÁXIMA em A_max = 200 e cai quando a busca é
# restringida. Aqui a comparação é direta.
h3 <- divergencia %>%
  group_by(encounters_n) %>%
  summarise(div_media = mean(div), div_mediana = median(div), n = n(), .groups = "drop") %>%
  arrange(desc(encounters_n))

cat("\n=== H3a: a divergencia e maxima em A_max = 200? ===\n")
print(as.data.frame(h3), row.names = FALSE, digits = 3)
maior <- h3$encounters_n[which.max(h3$div_media)]
cat(sprintf("Divergencia media maxima em A_max = %d.\n", maior))
cat(if (maior == 200) "Compativel com H3a.\n" else
    "CONTRARIO a H3a, que preve o maximo em A_max = 200.\n")
cat("\nRessalva para os dois: a divergencia e calculada sobre metricas padronizadas\n")
cat("no conjunto todo, entao ela mede separacao relativa entre curvas e nao\n")
cat("magnitude absoluta das metricas.\n")

# ---------------------------------------------------------------------
# 4. O mediador: a divergência é só diferença de poliandria realizada?
# ---------------------------------------------------------------------
# Pergunta nova, que só se pode fazer agora que gravamos grau_medio_femeas.
# Se a divergência entre curvas for explicada pelo espalhamento do grau, então
# o que separa as curvas é densidade de rede, e não geometria da escolha.
# Aqui também sobre o modelo base, senão o efeito de A_max e k contamina tudo.
med <- rbind(
  spread_grau            = parcial("spread_grau"),
  assimetria             = parcial("assimetria"),
  `assimetria+spread`    = parcial("assimetria + spread_grau")
)
cat("\n=== A divergencia e apenas diferenca de poliandria realizada? ===\n")
print(round(as.data.frame(med), 4))
cat("\nSe 'spread_grau' sozinho ja explica quase tudo, a comparacao entre curvas\n")
cat("esta confundida com densidade, e a H1 precisa ser lida em A_max = 200, onde\n")
cat("a tabela do teste mostra que todas as curvas atingem o k.\n")
cat("Se 'assimetria' mantem o seu efeito depois de incluir 'spread_grau', entao\n")
cat("a reparticao entre os sexos age por outra via, e nao so pela densidade.\n")

# ---------------------------------------------------------------------
# 5. Gráficos
# ---------------------------------------------------------------------

# (1) O MAPA. A superfície sigma_p x sigma_z, um painel por nível de A_max,
# porque a busca é o fator dominante e convém ver se o padrão se repete nos três.
# A linha tracejada é a diagonal. Se o gradiente de cor correr PERPENDICULAR a
# ela, a diagonal atravessa uma faixa de divergência quase constante, ou seja,
# não varia justamente o que importa.
mapa <- divergencia %>%
  group_by(sigma_p, sigma_z, encounters_n) %>%
  summarise(div = mean(div), .groups = "drop") %>%
  mutate(painel = factor(paste("A_max =", encounters_n),
                         levels = paste("A_max =", c(200, 40, 10))))

g1 <- ggplot(mapa, aes(sigma_z, sigma_p, fill = div)) +
  geom_tile() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              linewidth = 0.9, color = "white") +
  facet_wrap(~painel) +
  scale_fill_viridis_c(option = "magma") +
  labs(title = "Divergência entre curvas de preferência na superfície sigma_p x sigma_z",
       subtitle = "Tracejado: a diagonal proposta. O canto quente é fêmeas homogêneas com machos variados",
       x = expression(sigma[z]~"(variação entre machos)"),
       y = expression(sigma[p]~"(variação entre fêmeas)"),
       fill = "Divergência") +
  theme_light(base_size = 12) +
  theme(panel.spacing = unit(1, "lines"))

# (2) O CONTRASTE. A mesma divergência contra os dois candidatos, lado a lado.
# Os pontos vermelhos são as células da diagonal. No painel da assimetria eles
# ficam TODOS empilhados em zero: a diagonal é um único ponto do eixo que manda.
comp <- divergencia %>%
  select(div, na_diagonal, norma, assimetria) %>%
  tidyr::pivot_longer(c(norma, assimetria), names_to = "preditor", values_to = "x") %>%
  mutate(preditor = factor(preditor, levels = c("norma", "assimetria"),
                           labels = c("Variabilidade total  sqrt(sp^2 + sz^2)",
                                      "Assimetria  log(sz / sp)")))

g2 <- ggplot(comp, aes(x, div)) +
  geom_point(aes(color = na_diagonal), alpha = 0.35, size = 1.3) +
  geom_smooth(method = "lm", se = FALSE, color = "black", linewidth = 0.8) +
  facet_wrap(~preditor, scales = "free_x") +
  scale_color_manual(values = c(`FALSE` = "gray70", `TRUE` = "#C0392B"),
                     labels = c("fora da diagonal", "na diagonal"), name = NULL) +
  labs(title = "De que depende a divergência entre curvas de preferência",
       subtitle = "Na esquerda quase não há inclinação. Na direita, os pontos da diagonal colapsam todos em x = 0",
       x = NULL, y = "Divergência entre curvas") +
  theme_light(base_size = 12) +
  theme(legend.position = "bottom", panel.spacing = unit(1, "lines"))

# (3) O PERFIL. Divergência média ao longo do eixo da assimetria, com a faixa
# entre quartis. É a leitura mais direta: mostra quanto se perde ao ficar só no
# zero, e de que lado está o sinal.
perfil <- divergencia %>%
  group_by(assimetria) %>%
  summarise(mediana = median(div), q25 = quantile(div, .25),
            q75 = quantile(div, .75), .groups = "drop")

g3 <- ggplot(perfil, aes(assimetria, mediana)) +
  geom_ribbon(aes(ymin = q25, ymax = q75), fill = "#C0392B", alpha = 0.18) +
  geom_line(color = "#C0392B", linewidth = 1) +
  geom_point(color = "#C0392B", size = 2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40") +
  annotate("text", x = 0, y = max(perfil$q75), label = "  a diagonal está toda aqui",
           hjust = 0, size = 3.5, color = "gray30") +
  labs(title = "Perfil da divergência ao longo do eixo da assimetria",
       subtitle = "Negativo: fêmeas mais variadas que machos.  Positivo: machos mais variados que fêmeas",
       x = expression(log(sigma[z]/sigma[p])), y = "Divergência (mediana e quartis)") +
  theme_light(base_size = 12)

ggsave("Resultados_Artigo/Fase_Controle/Graficos/Diagonal_1_mapa.png", g1,
       width = 11, height = 4.2, dpi = 150, bg = "white")
ggsave("Resultados_Artigo/Fase_Controle/Graficos/Diagonal_2_contraste.png", g2,
       width = 10, height = 5, dpi = 150, bg = "white")
ggsave("Resultados_Artigo/Fase_Controle/Graficos/Diagonal_3_perfil.png", g3,
       width = 8, height = 5, dpi = 150, bg = "white")

saveRDS(divergencia, "Resultados_Artigo/Fase_Controle/Dados/divergencia_por_celula.rds")
cat("\nTres graficos salvos em Resultados_Artigo/Fase_Controle/Graficos/:\n")
cat("  Diagonal_1_mapa.png       a superficie, um painel por A_max\n")
cat("  Diagonal_2_contraste.png  norma contra assimetria, lado a lado\n")
cat("  Diagonal_3_perfil.png     o perfil ao longo do eixo da assimetria\n")
