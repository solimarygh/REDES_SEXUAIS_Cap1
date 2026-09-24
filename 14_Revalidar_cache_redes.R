# =====================================================================
# Script 14: revalida o cache de redes representativas
# =====================================================================
# O cache de 11_Rede_Representativa.R guarda, junto com as redes, uma impressão
# digital dos scripts do motor: tamanho e data de cada um. Se qualquer um deles
# for editado, a impressão muda, o cache é descartado e as redes são
# recalculadas. É a regra certa, porque uma rede desenhada por um motor que já
# não existe seria uma figura errada.
#
# Só que a regra não distingue uma mudança no motor de uma mudança que não toca
# no cálculo. Editar um comentário, ou mudar de quanto em quanto tempo o cache é
# gravado, custa o mesmo que mudar a regra de escolha da réplica: tudo é
# recalculado.
#
# Este script existe para esse caso, e SÓ para esse caso. Ele lê o arquivo do
# cache, troca a impressão antiga pela atual e grava de volta, sem tocar nas
# redes. Quem o roda está afirmando que a edição feita não muda nenhum número.
#
# NÃO o rode depois de mexer em:
#   - a regra de escolha da réplica (escolher_replica, rede_representativa)
#   - o motor de acasalamento (01_metricas_e_utilitarios.R)
#   - as fases (Fase_Controle.R, Fase_Espelho.R, Fase_Coevolucao.R)
#
# Na dúvida, não rode: recalcular custa tempo, desenhar a rede errada custa o
# relatório.
#
# Uso:
#     Rscript 14_Revalidar_cache_redes.R
# =====================================================================

suppressPackageStartupMessages(source("11_Rede_Representativa.R"))

if (!file.exists(ARQUIVO_CACHE_REDES))
  stop("Não existe cache em ", ARQUIVO_CACHE_REDES, ".", call. = FALSE)

c0 <- readRDS(ARQUIVO_CACHE_REDES)
if (is.null(c0$entradas))
  stop("O arquivo não tem o formato esperado do cache.", call. = FALSE)

antes <- c0$motores
c0$motores <- .impressao_motores()

if (identical(antes, c0$motores)) {
  cat("O cache já estava válido:", length(c0$entradas), "redes. Nada a fazer.\n")
} else {
  saveRDS(c0, ARQUIVO_CACHE_REDES)
  cat("Cache revalidado:", length(c0$entradas), "redes preservadas.\n")
  cat("Tamanho do arquivo:",
      format(structure(file.size(ARQUIVO_CACHE_REDES), class = "object_size"),
             units = "auto"), "\n")
}
