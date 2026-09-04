# =====================================================================
# CO-EVOLUÇÃO: DIAGNÓSTICO E, SE ELE PASSAR, O ESTUDO
# =====================================================================
#     Rscript 01_coevolucao_diagnostico_e_estudo.R
#
# PARTE 1 descobre por que, no teste anterior, as dez réplicas da curva
# gaussiana sem seleção natural subiram TODAS para o mesmo lado, com a
# variância indo de 1 para 58. Num runaway de Fisher sobre a linha de
# equilíbrios de Lande não há lado preferido, então isso é assimetria de
# alguma coisa. Há dois suspeitos, e o diagnóstico os separa ligando e
# desligando cada um:
#
#   truncamento em zero — com média 5 e desvio 7.6, boa parte da
#     distribuição cai abaixo de zero e pmax(0, .) a amontoa em zero, o que
#     empurra a média para cima. Testado movendo phi para 50, longe do zero,
#     onde o truncamento nunca morde.
#
#   inflação da variância — com preferência gaussiana o acasalamento é
#     fortemente assortativo, o que gera desequilíbrio de ligamento positivo
#     e faz a variância TOTAL subir. Como a nossa segregação usa a variância
#     total do pool parental, e não a génica, mais variância gera mais
#     variância, sem freio. Testado com segregacao = "fixa", em que a
#     variância de segregação não depende da parental e o laço se abre.
#
# PARTE 2 só roda se o diagnóstico passar. Se o motor estiver inflando a
# variância sozinho, gastar horas de simulação em cima disso não adianta.
# =====================================================================

COEVO_SO_FUNCOES <- TRUE
source("Fase_Coevolucao.R")

# A pasta tem de existir antes de o diagnóstico salvar, e o
# configurar_diretorios() só é chamado na parte 2.
dir.create("Resultados_Artigo/Fase_Coevolucao/Dados", recursive = TRUE, showWarnings = FALSE)
suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

# ---------------------------------------------------------------------
# PARÂMETROS
# ---------------------------------------------------------------------
G_DIAG <- 100L   # gerações no diagnóstico
R_DIAG <- 10L    # réplicas por braço do diagnóstico

# "piloto" é um recorte que roda em cerca de uma hora; "completo" é o desenho
# da proposta, com 12.960 cenários. Mude com  COEVO_ESTUDO=completo Rscript ...
ESTUDO     <- Sys.getenv("COEVO_ESTUDO", unset = "piloto")
N_CORES    <- as.integer(Sys.getenv("N_CORES", unset = "5"))
SEED_BASE  <- 2030

cat("\n=====================================================================\n")
cat("PARTE 1: DIAGNÓSTICO\n")
cat("=====================================================================\n")
cat(sprintf("Quatro braços, %d réplicas de %d gerações cada, sempre com a curva\n", R_DIAG, G_DIAG))
cat("gaussiana e sem seleção natural, que foi onde o problema apareceu.\n\n")

bracos <- list(
  list(nome = "A. como está",              phi = 5,  seg = "infinitesimal"),
  list(nome = "B. phi longe do zero",      phi = 50, seg = "infinitesimal"),
  list(nome = "C. segregação fixa",        phi = 5,  seg = "fixa"),
  list(nome = "D. os dois desligados",     phi = 50, seg = "fixa")
)

diag <- bind_rows(lapply(bracos, function(b) {
  cat(sprintf("  rodando %s ...\n", b$nome))
  bind_rows(lapply(seq_len(R_DIAG), function(r) {
    set.seed(9000 + r)   # mesma semente entre braços: o contraste fica limpo
    x <- simulate_coevolucao(generations = G_DIAG, tipo_selecao = "gaussian",
                             encounters_n = 200, k_fixo = 5L,
                             selecao_natural = FALSE,
                             phi = b$phi, segregacao = b$seg)
    x$braco <- b$nome; x$phi_usado <- b$phi; x$replica <- r
    x
  }))
}))

resumo <- diag %>%
  filter(generation == G_DIAG) %>%
  group_by(braco) %>%
  summarise(
    # o deslocamento é medido em relação ao phi daquele braço
    desloc_medio = round(mean(abs(zbar_pop - first(phi_usado))), 2),
    subiram      = sum(zbar_pop > first(phi_usado)),
    n            = n(),
    varz_final   = round(mean(varz_pop), 1),
    cov_zp       = round(mean(cov_zp), 2),
    cor_zp       = round(mean(cor_zp), 2),
    .groups = "drop")

cat("\n")
print(as.data.frame(resumo), row.names = FALSE)

cat("\nComo ler: 'subiram' perto da metade de n é direção aleatória, que é o que\n")
cat("um runaway sobre a linha de equilíbrios deve dar. 'varz_final' partindo de\n")
cat("1: se continuar na casa das dezenas, a variância está se inflando sozinha.\n")

# ---------------------------------------------------------------------
# VEREDITO
# ---------------------------------------------------------------------
pega <- function(nome, col) resumo[[col]][resumo$braco == nome]
equilibrado <- function(nome) {
  s <- pega(nome, "subiram"); n <- pega(nome, "n")
  s >= 0.25 * n && s <= 0.75 * n          # nem todas para o mesmo lado
}
contida <- function(nome) pega(nome, "varz_final") < 10   # partiu de 1

cat("\n--- veredito ---\n")
ok_A <- equilibrado("A. como está") && contida("A. como está")
ok_B <- equilibrado("B. phi longe do zero")
ok_C <- contida("C. segregação fixa") && equilibrado("C. segregação fixa")

if (ok_A) {
  cat("O braço A já se comporta: direção aleatória e variância contida.\n")
  cat("O que vimos antes não se repetiu, o que em si merece um olhar.\n")
  motor_ok <- TRUE
} else {
  motor_ok <- FALSE
  cat("O braço A confirma o problema.\n")
  if (ok_B && !ok_C) {
    cat("Afastar phi do zero resolve, e a segregação fixa não. Ou seja, é o\n")
    cat("TRUNCAMENTO em zero que empurra a média, e não a inflação da variância.\n")
    cat("Saída: manter phi mas trabalhar numa escala em que o truncamento não\n")
    cat("morda, ou substituir pmax(0,.) por outro tratamento do limite inferior.\n")
  } else if (ok_C && !ok_B) {
    cat("A segregação fixa resolve e afastar phi não. Ou seja, é a INFLAÇÃO DA\n")
    cat("VARIÂNCIA: a segregação alimentada pela variância TOTAL do pool parental\n")
    cat("realimenta o acasalamento assortativo, sem freio.\n")
    cat("Saída: acompanhar a variância GÉNICA à parte, como o modelo infinitesimal\n")
    cat("estrito faz. É a pergunta 6 da lista do Miudo, agora com evidência.\n")
  } else if (ok_B && ok_C) {
    cat("Os dois braços resolvem sozinhos, então os dois contribuem e se somam.\n")
  } else {
    cat("Nenhum dos dois resolve sozinho. Há uma terceira coisa em jogo, e não\n")
    cat("vale rodar o estudo antes de entender qual.\n")
  }
}

saveRDS(diag, "Resultados_Artigo/Fase_Coevolucao/Dados/diagnostico_coevolucao.rds")
cat("\nDados do diagnóstico em Resultados_Artigo/Fase_Coevolucao/Dados/\n")

# =====================================================================
# PARTE 2: O ESTUDO, só se o diagnóstico passar
# =====================================================================
cat("\n=====================================================================\n")
cat("PARTE 2: ESTUDO\n")
cat("=====================================================================\n")

if (!motor_ok) {
  cat("NÃO vou rodar o estudo: o diagnóstico mostrou que o motor ainda tem uma\n")
  cat("assimetria por resolver, e horas de simulação em cima disso não ajudam.\n")
  cat("Corrija o ponto que o veredito apontou e rode de novo.\n")
  cat("\nSe quiser rodar assim mesmo, para ver o que dá:\n")
  cat("  COEVO_FORCAR=1 Rscript 01_coevolucao_diagnostico_e_estudo.R\n")
}

forcar <- Sys.getenv("COEVO_FORCAR", unset = "") == "1"
if (motor_ok || forcar) {

  if (forcar && !motor_ok) cat("\nRodando mesmo assim, a pedido (COEVO_FORCAR=1).\n")

  diretorios <- configurar_diretorios("Fase_Coevolucao")
  valores_sigma <- c(0.5, 1.0, 2.0)

  if (ESTUDO == "completo") {
    n_replicas <- 20L; amax <- c(200, 40, 10); ks <- c(5L, 10L, 20L)
  } else {
    n_replicas <- 5L;  amax <- 200;            ks <- 5L
  }

  cenarios <- expand.grid(
    tipo_selecao    = c("uniform", "gaussian", "sigmoid", "u-shaped"),
    sigma_p_init    = valores_sigma,
    sigma_z_init    = valores_sigma,
    encounters_n    = amax,
    k_fixo          = ks,
    selecao_natural = c(TRUE, FALSE),
    replica         = seq_len(n_replicas),
    stringsAsFactors = FALSE
  )
  cenarios$idx_global <- seq_len(nrow(cenarios))

  cat(sprintf("\nDesenho '%s': %s cenários de 100 gerações, %d núcleos.\n",
              ESTUDO, format(nrow(cenarios), big.mark = "."), N_CORES))

  arquivo_backup <- file.path(diretorios$dados, sprintf("backup_Coevolucao_%s.rds", ESTUDO))
  arquivo_final  <- file.path(diretorios$dados, sprintf("resultados_Coevolucao_%s.rds", ESTUDO))

  lista <- if (file.exists(arquivo_backup)) {
    l <- readRDS(arquivo_backup)
    cat("Backup encontrado, retomando.\n")
    if (length(l) != nrow(cenarios)) length(l) <- nrow(cenarios)
    l
  } else {
    cat("Nenhum backup, começando do zero.\n")
    vector("list", nrow(cenarios))
  }

  simular_i <- function(i) {
    res <- simulate_coevolucao(
      generations     = 100,
      tipo_selecao    = as.character(cenarios$tipo_selecao[i]),
      sigma_p_init    = cenarios$sigma_p_init[i],
      sigma_z_init    = cenarios$sigma_z_init[i],
      encounters_n    = cenarios$encounters_n[i],
      k_fixo          = cenarios$k_fixo[i],
      selecao_natural = cenarios$selecao_natural[i]
    )
    if (is.null(res) || nrow(res) == 0) return(NULL)
    res$replica <- cenarios$replica[i]
    res
  }

  lista <- rodar_cenarios(cenarios, lista, arquivo_backup, simular_i,
                          n_cores = N_CORES, seed_base = SEED_BASE,
                          idx_global = cenarios$idx_global)

  saveRDS(lista, arquivo_backup)
  df <- bind_rows(lista[!vapply(lista, is.null, logical(1))])
  saveRDS(df, arquivo_final)

  cat(sprintf("\nConcluído: %s linhas em %s\n", format(nrow(df), big.mark = "."), arquivo_final))
  cat(sprintf("Censo adulto: %s\n", paste(sort(unique(df$n_machos_surv)), collapse = ", ")))
  cat(sprintf("Réplicas encerradas antes do fim: %d\n", sum(!is.na(df$extincao_gen))))
  cat(sprintf("Réplicas com fuga do traço: %d\n", sum(!is.na(df$fuga_gen))))
}
