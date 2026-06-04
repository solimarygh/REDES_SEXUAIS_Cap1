# =====================================================================
# TESTE RÁPIDO: verifica os novos parâmetros k_fixo e selecao_natural
# Execute antes de rodar o Fase4_TodasAsCurvas.R completo.
# Tempo esperado: < 2 minutos.
# =====================================================================

source("01_metricas_e_utilitarios.R")

cat("=== TESTE 1: k_fixo funciona? ===\n")

# Com k=5 fixo, TODAS as fêmeas devem ter exatamente 5 cópulas
set.seed(42)
res_k5 <- simulate_evolution(
  generations = 5, N_machos = 50, N_femeas = 50,
  sigma_p = 1.0, tipo_selecao = "gaussian",
  k_fixo = 5, selecao_natural = TRUE, return_details = FALSE
)
cat("k_fixo=5, sel.nat=TRUE — colunas presentes:", paste(c("k_fixo","selecao_natural") %in% names(res_k5), collapse=" | "), "\n")
cat("k_fixo no output:", unique(res_k5$k_fixo), " | selecao_natural:", unique(res_k5$selecao_natural), "\n\n")

cat("=== TESTE 2: selecao_natural=FALSE (V_j=1) ===\n")

set.seed(42)
res_no_ns <- simulate_evolution(
  generations = 5, N_machos = 50, N_femeas = 50,
  sigma_p = 1.0, tipo_selecao = "gaussian",
  k_fixo = 5, selecao_natural = FALSE, return_details = FALSE
)
cat("k_fixo=5, sel.nat=FALSE — k_fixo:", unique(res_no_ns$k_fixo),
    " | selecao_natural:", unique(res_no_ns$selecao_natural), "\n\n")

cat("=== TESTE 3: grade reduzida (2 cenários × 2 réplicas) ===\n")

library(dplyr)

cenarios_teste <- expand.grid(
  tipo_selecao    = c("gaussian", "sigmoid"),
  sigma_p         = c(0.5, 2.0),
  encounters_n    = 200,
  k_fixo          = c(5L, 10L),
  selecao_natural = c(TRUE, FALSE),
  replica         = 1:2
)
cat("Total de linhas na grade de teste:", nrow(cenarios_teste), "\n")

lista_teste <- vector("list", nrow(cenarios_teste))
for (i in seq_len(nrow(cenarios_teste))) {
  set.seed(2026 + i)
  lista_teste[[i]] <- tryCatch(
    simulate_evolution(
      generations     = 10,
      N_machos        = 50, N_femeas = 50,
      tipo_selecao    = cenarios_teste$tipo_selecao[i],
      sigma_p         = cenarios_teste$sigma_p[i],
      encounters_n    = cenarios_teste$encounters_n[i],
      k_fixo          = cenarios_teste$k_fixo[i],
      selecao_natural = cenarios_teste$selecao_natural[i],
      return_details  = FALSE
    ),
    error = function(e) { cat("ERRO no cenário", i, ":", conditionMessage(e), "\n"); NULL }
  )
}

df_teste <- bind_rows(lista_teste[!sapply(lista_teste, is.null)])

cat("\nLinhas geradas:", nrow(df_teste), "(esperado:", nrow(cenarios_teste) * 10, ")\n")
cat("Combinações k_fixo × selecao_natural:\n")
print(df_teste %>% distinct(k_fixo, selecao_natural, tipo_selecao) %>% arrange(k_fixo, selecao_natural))

cat("\n=== RESULTADO ===\n")
erros <- sum(sapply(lista_teste, is.null))
if (erros == 0) {
  cat("TUDO OK! Pode rodar o Fase4_TodasAsCurvas.R completo.\n")
} else {
  cat("ATENÇÃO:", erros, "cenários com erro. Verifique as mensagens acima.\n")
}
