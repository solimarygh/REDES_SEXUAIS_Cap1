# =====================================================================
# CO-EVOLUÇÃO: LEITURA DOS RESULTADOS
# =====================================================================
#     Rscript 03_analise_coevolucao.R
#
# Não simula nada: lê o que 01_coevolucao_diagnostico_e_estudo.R deixou em
# Resultados_Artigo/Fase_Coevolucao/Dados/.
#
# Duas coisas só ficaram mensuráveis depois da correção da segregação. Antes,
# com a segregação alimentada pela variância TOTAL, a variância se realimentava
# e não dava para separar nada.
#
#   O desequilíbrio de ligamento. varz_pop é a variância total da população e
#     var_genica_z é a génica, a que governa a segregação. A distância entre as
#     duas é o desequilíbrio que o acasalamento assortativo criou. No braço D do
#     diagnóstico, sob a gaussiana, foi 3.6 contra 1.1.
#
#   O Ne. No diagnóstico, sob a gaussiana, ficou em 347 de 400, ou seja quase
#     não caiu. Sob a sigmoide todas as fêmeas querem os mesmos machos, então a
#     variância no número de filhos deve ser bem maior e o Ne deve despencar.
#     Esta é uma previsão que os dados do estudo respondem.
# =====================================================================

suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

pasta <- "Resultados_Artigo/Fase_Coevolucao/Dados"

# O modo de segregação está no nome do arquivo justamente para não misturar o
# motor antigo com o corrigido. Aqui só leio os do modo génica.
candidatos <- c(file.path(pasta, "resultados_Coevolucao_genica_completo.rds"),
                file.path(pasta, "resultados_Coevolucao_genica_piloto.rds"),
                file.path(pasta, "backup_Coevolucao_genica_completo.rds"),
                file.path(pasta, "backup_Coevolucao_genica_piloto.rds"))
achou <- candidatos[file.exists(candidatos)]
if (!length(achou)) {
  stop("Não achei nenhum resultado de co-evolução em ", pasta,
       ".\nRode antes: COEVO_ESTUDO=completo Rscript 01_coevolucao_diagnostico_e_estudo.R")
}
arquivo <- achou[1]
obj <- readRDS(arquivo)
d <- if (is.data.frame(obj)) obj else bind_rows(obj[!vapply(obj, is.null, logical(1))])

if (grepl("backup", arquivo)) {
  cat("\nATENÇÃO: li um BACKUP, não o arquivo final. Se o estudo ainda estiver\n")
  cat("rodando, os números abaixo são de um recorte incompleto do desenho.\n")
}

G <- max(d$generation, na.rm = TRUE)
cat(sprintf("\nArquivo: %s\n", arquivo))
cat(sprintf("%s linhas, %d gerações, %d réplicas, %d combinações de cenário.\n",
            format(nrow(d), big.mark = "."), G, n_distinct(d$replica),
            nrow(distinct(d, tipo_selecao, sigma_p_init, sigma_z_init,
                          encounters_n, k_fixo, selecao_natural))))

fim <- d %>% filter(generation == G)

# ---------------------------------------------------------------------
cat("\n=== 0. Saúde da rodada ===\n\n")
cat(sprintf("  Censo adulto (machos sobreviventes): %s\n",
            paste(range(d$n_machos_surv, na.rm = TRUE), collapse = " a ")))
celula <- c("tipo_selecao", "sigma_p_init", "sigma_z_init",
            "encounters_n", "k_fixo", "selecao_natural", "replica")
curtas   <- distinct(d[d$n_machos_surv < 200, celula, drop = FALSE])
n_celulas <- nrow(distinct(d[, celula, drop = FALSE]))
cat(sprintf("  Células que em algum momento ficaram abaixo de 200: %d de %d (%.1f%%)\n",
            nrow(curtas), n_celulas, 100 * nrow(curtas) / n_celulas))
n_encerradas <- nrow(distinct(d[!is.na(d$extincao_gen), celula, drop = FALSE]))
n_fuga       <- nrow(distinct(d[!is.na(d$fuga_gen), celula, drop = FALSE]))
cat(sprintf("  Réplicas encerradas antes da geração %d: %d\n", G, n_encerradas))
cat(sprintf("  Réplicas com fuga do traço: %d\n", n_fuga))
if (n_fuga) {
  cat("\n  Onde o traço foge, por curva:\n")
  print(as.data.frame(
    count(distinct(d[!is.na(d$fuga_gen), celula, drop = FALSE]),
          tipo_selecao, selecao_natural)
  ), row.names = FALSE)
  cat("\n  Fuga concentrada numa curva é a preferência daquela curva, não uma\n")
  cat("  assimetria do motor. Espalhada por todas seria outra conversa.\n")
}
if (nrow(curtas)) {
  cat("\n  Onde o censo encurta, por curva:\n")
  print(as.data.frame(count(curtas, tipo_selecao, selecao_natural)), row.names = FALSE)
  cat("\n  O censo curto é consequência de como selecionar_machos_adultos ficou\n")
  cat("  depois da mudança para best-of-n: entre 2 e 200 sobreviventes ele\n")
  cat("  devolve o que sobreviveu, sem repor. A cota está descrita na\n")
  cat("  NOTA_quatro_estudos.md e ainda não foi implementada.\n")
}

# ---------------------------------------------------------------------
cat("\n=== 1. Desequilíbrio de ligamento: total menos génica ===\n\n")
cat("var_genica é a que governa a segregação; varz_pop é o que a população\n")
cat("exibe. A diferença é o que o acasalamento assortativo empilhou.\n\n")

ld <- fim %>%
  filter(!selecao_natural) %>%
  group_by(tipo_selecao) %>%
  summarise(varz_total  = round(mean(varz_pop), 2),
            var_genica  = round(mean(var_genica_z), 2),
            LD          = round(mean(varz_pop - var_genica_z), 2),
            # a razão entre as MÉDIAS, coerente com as duas colunas acima. A
            # média das razões célula a célula não serve: a distribuição é
            # torta, umas poucas células com génica pequena puxam tudo.
            razao       = round(mean(varz_pop) / mean(var_genica_z), 2),
            razao_med   = round(median(varz_pop / var_genica_z), 2),
            .groups = "drop") %>%
  arrange(desc(LD))
print(as.data.frame(ld), row.names = FALSE)

cat("\nA aleatória não gera assortamento nenhum, então serve de régua: nela a\n")
cat("razão deve ficar perto de 1. O quanto as outras se afastam disso é o\n")
cat("efeito do acasalamento, não da segregação.\n")

cat("\n  O mesmo para a preferência:\n\n")
print(as.data.frame(
  fim %>% filter(!selecao_natural) %>%
    group_by(tipo_selecao) %>%
    summarise(varp_total = round(mean(varp_pop), 2),
              var_genica = round(mean(var_genica_p), 2),
              LD         = round(mean(varp_pop - var_genica_p), 2),
              .groups = "drop") %>%
    arrange(desc(LD))
), row.names = FALSE)

# ---------------------------------------------------------------------
cat("\n=== 2. O Ne despenca sob a sigmoide? ===\n\n")
cat("Censo de 400 adultos. No diagnóstico, sob a gaussiana, o Ne ficou em 347.\n")
cat("Sob a sigmoide, em que todas as fêmeas querem os mesmos machos, a\n")
cat("variância no número de filhos deve ser maior e o Ne menor.\n\n")

ne <- fim %>%
  group_by(tipo_selecao, selecao_natural) %>%
  summarise(Ne = round(mean(Ne, na.rm = TRUE)),
            razao_censo = round(mean(Ne, na.rm = TRUE) / 400, 2),
            I_s = round(mean(I_s, na.rm = TRUE), 2),
            .groups = "drop") %>%
  pivot_wider(names_from = selecao_natural,
              values_from = c(Ne, razao_censo, I_s))
print(as.data.frame(ne), row.names = FALSE)

cat("\nI_s e Ne medem o mesmo desequilíbrio por dois caminhos: I_s é a variância\n")
cat("relativa no sucesso dos machos, Ne é o tamanho que uma população ideal\n")
cat("precisaria ter para derivar tanto quanto esta. Se as duas colunas\n")
cat("concordarem na ordem das curvas, é o mesmo fenômeno visto duas vezes.\n\n")
ok <- is.finite(fim$I_s) & is.finite(fim$Ne)
if (sum(ok) > 2) {
  cat(sprintf("  Correlação entre I_s e Ne entre todas as células finais: %+.2f\n",
              suppressWarnings(cor(fim$I_s[ok], fim$Ne[ok]))))
} else {
  cat("  Poucas células com I_s e Ne finitos para correlacionar.\n")
}

# ---------------------------------------------------------------------
cat("\n=== 3. O Ne e a intensidade da seleção sexual ===\n\n")
cat("k é quantos machos a fêmea aceita de A_max avaliados. k menor é seleção\n")
cat("mais intensa, então o Ne deve cair com k menor e com A_max maior.\n\n")
print(as.data.frame(
  fim %>% filter(!selecao_natural, tipo_selecao != "uniform") %>%
    group_by(encounters_n, k_fixo) %>%
    summarise(Ne = round(mean(Ne, na.rm = TRUE)),
              I_s = round(mean(I_s, na.rm = TRUE), 2),
              LD = round(mean(varz_pop - var_genica_z), 2),
              .groups = "drop") %>%
    arrange(encounters_n, k_fixo)
), row.names = FALSE)

# ---------------------------------------------------------------------
cat("\n=== 4. A cadeia causal de Fisher ===\n\n")
cat("cov_casais é a covariância entre o traço do macho e a preferência da fêmea\n")
cat("nos pares que de fato acasalaram. cov_zp é a covariância genética na\n")
cat("população. A primeira é a causa, a segunda o acúmulo.\n\n")
print(as.data.frame(
  fim %>% filter(!selecao_natural) %>%
    group_by(tipo_selecao) %>%
    summarise(cov_casais = round(mean(cov_casais, na.rm = TRUE), 2),
              cov_zp = round(mean(cov_zp), 2),
              cor_zp = round(mean(cor_zp), 2),
              .groups = "drop") %>%
    arrange(desc(cov_zp))
), row.names = FALSE)

cat("\n  Ao longo das gerações, sob cada curva (sem seleção natural):\n\n")
print(as.data.frame(
  d %>% filter(!selecao_natural, generation %% 20 == 0) %>%
    group_by(tipo_selecao, generation) %>%
    summarise(cov_casais = round(mean(cov_casais, na.rm = TRUE), 1),
              cov_zp = round(mean(cov_zp), 1), .groups = "drop") %>%
    pivot_wider(names_from = tipo_selecao,
                values_from = c(cov_casais, cov_zp))
), row.names = FALSE)

cat("\n  Se cov_casais sobe antes de cov_zp, a ordem é a que Fisher prevê:\n")
cat("  primeiro o acasalamento não aleatório, depois a covariância genética.\n")

# ---------------------------------------------------------------------
cat("\n=== 5. Para onde as médias foram, e se a direção é aleatória ===\n\n")
cat("Sobre a linha de equilíbrios de Lande não há lado preferido, então metade\n")
cat("das réplicas deveria subir. Todas para o mesmo lado seria assimetria do\n")
cat("modelo, e foi exatamente o que denunciou a inflação da variância.\n\n")
print(as.data.frame(
  fim %>%
    group_by(tipo_selecao, selecao_natural) %>%
    summarise(zbar = round(mean(zbar_pop), 2),
              pbar = round(mean(pbar_pop), 2),
              desloc = round(mean(abs(zbar_pop - 5)), 2),
              subiram = sum(zbar_pop > 5), n = n(),
              .groups = "drop")
), row.names = FALSE)

# ---------------------------------------------------------------------
cat("\n=== 6. As métricas de rede: início contra fim ===\n\n")
ini_fim <- d %>%
  filter(generation %in% c(1L, G), !selecao_natural) %>%
  group_by(tipo_selecao, generation) %>%
  summarise(across(c(Modularity, Nestedness, Centralization, I_s,
                     grau_medio_femeas, prop_femeas_sem_acasalar),
                   ~ round(mean(.x, na.rm = TRUE), 3)),
            .groups = "drop")
print(as.data.frame(ini_fim), row.names = FALSE)

cat("\nAqui as duas características evoluem, então a rede da geração 100 é\n")
cat("resultado do que a população virou, e não de um sigma imposto. É a\n")
cat("diferença entre este estudo e os dois anteriores.\n")

# ---------------------------------------------------------------------
cat("\n=== 7. A estrutura se apaga? ===\n\n")
cat("Sob a sigmoide o I_s começa em 7.4 e termina em 0.15, e a centralização\n")
cat("cai de 0.19 para 0.03. A leitura é que o traço se afasta tanto da\n")
cat("preferência que a curva satura: com zbar muito acima de pbar, a sigmoide\n")
cat("aceita qualquer macho e deixa de discriminar. A coluna z_menos_p é a\n")
cat("distância que faz isso acontecer. Se ela cresce enquanto I_s cai, é essa\n")
cat("a explicação, e não uma perda de variância no traço.\n\n")

for (ns in c(FALSE, TRUE)) {
  cat(sprintf("  selecao_natural = %s\n\n", ns))
  print(as.data.frame(
    d %>% filter(selecao_natural == ns,
                 generation %in% c(1L, 5L, 10L, 25L, 50L, 100L)) %>%
      group_by(tipo_selecao, generation) %>%
      summarise(z_menos_p = round(mean(zbar_pop - pbar_pop), 1),
                I_s = round(mean(I_s, na.rm = TRUE), 2),
                Centr = round(mean(Centralization, na.rm = TRUE), 3),
                varz = round(mean(varz_pop), 2),
                # o Ne da tabela 2 está na geração 100, quando sob a sigmoide
                # já não sobrou seleção nenhuma. Aqui dá para ver se ele
                # despenca cedo, enquanto o I_s ainda está alto.
                Ne = round(mean(Ne, na.rm = TRUE)),
                .groups = "drop") %>%
      pivot_wider(names_from = tipo_selecao,
                  values_from = c(z_menos_p, I_s, Centr, varz, Ne))
  ), row.names = FALSE)
  cat("\n")
}

cat("Com seleção natural a viabilidade segura o traço perto de phi, a distância\n")
cat("não cresce e a preferência continua discriminando. Se for isso que as duas\n")
cat("tabelas mostram, a seleção natural não apaga a assinatura da seleção\n")
cat("sexual: é ela que mantém a assinatura de pé.\n")

cat("\n--- o que fica pendente ---\n")
cat("A cota do censo, que ainda não foi implementada, e a escolha entre\n")
cat("variância total e génica declarada no Methods dos outros estudos. As duas\n")
cat("estão na NOTA_quatro_estudos.md, à espera do Miudo.\n")
