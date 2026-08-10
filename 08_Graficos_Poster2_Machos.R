# =====================================================================
# POSTER 2 — ESTUDO 3: MACHOS VARIANDO (sigma_z)
# =====================================================================
# Sucessor de 08_Graficos_Poster_MachoVariando.R, que além de estar preso
# ao modelo antigo apontava para o experimento inverso DESCARTADO
# (Fase_MachoVariando.R, em que sigma_z era só condição inicial e quem
# evoluía continuava sendo o traço). Este aqui usa o espelho de verdade,
# Fase_Espelho.R, em que o traço do macho é ambiental e quem evolui é a
# PREFERÊNCIA da fêmea.
#
#   Rscript 08_Graficos_Poster2_Machos.R
#
# As figuras saem em Resultados_Artigo/Poster2/, com prefixo "Machos".
#
# Para mudar o cenário mostrado (k, A_max, sigma alto e baixo, fundo
# escuro, resolução), edite o bloco de parâmetros de 08_Poster2_comum.R.
# =====================================================================

source("08_Poster2_comum.R")

# Aqui o papel da escolha da fêmea se inverte: ela deixa de ser a causa da
# seleção e passa a ser o ALVO dela. A força seletiva é ecológica, a
# disponibilidade de machos com traços variados (sigma_z).
#
# A preferência é registrada de duas formas. pbar_femeas é a preferência
# expressa, medida nas fêmeas adultas, e pbar_pop é o pool genotípico, os
# dois sexos juntos, que é a variável evolutiva em sentido estrito, já que
# o macho carrega p sem expressar.
#
# As figuras usam a expressa, por duas razões. É o espelho exato do estudo
# das fêmeas, onde a figura equivalente é zbar_males: em cada estudo, a
# característica medida no sexo que a expressa. E é a mesma escolha do
# Resultados_Preliminares.Rmd e do Exploracao_Paineis_MiudoV2.Rmd, então os
# três documentos mostram a mesma linha. Nesta rodada as duas versões andam
# praticamente coladas; para ver o pool, troque col_media e col_var por
# pbar_pop e varp_pop abaixo.
MODELO_MACHOS <- list(
  nome    = "Machos variando",
  prefixo = "Machos",
  script  = "Fase_Espelho.R",

  pasta   = "Resultados_Artigo/Fase_Espelho/Dados",
  # O prefixo do arquivo. Qual rodada usar é decidido em 08_Poster2_comum.R:
  # a mais nova que existir, sem nunca misturar duas.
  estudo  = "Espelho",

  # Eixo do experimento
  eixo     = "sigma_z",
  eixo_txt = "σz",
  eixo_lab = expression(bold(paste("Male Trait Variation (", sigma[z], ")"))),

  # A característica que evolui: a preferência da fêmea
  faixa_evo  = "FEMALE PREFERENCE EVOLUTION",
  cor_evo    = "#1F7A4C",
  titulo_evo = "Preference Peak Mean",
  col_media  = "pbar_femeas",
  col_var    = "varp_femeas",
  lab_media  = "bold(paste('Preference Peak Mean (', bar(p), ')'))",
  lab_var    = "Preference Variance (Var p)",
  y_media    = expression(bold(paste("Preference Peak Mean (", bar(p), ")"))),

  # Referências: phi é a média inicial da preferência, e a variância parte
  # de sigma_p_init = 1.0. Atenção, aqui sigma_p_init é só condição
  # inicial: da geração 2 em diante a largura é o que a seleção e a deriva
  # fizerem dela, então a linha de referência é o ponto de partida e não
  # um valor esperado.
  ref_media     = 5.0,
  ref_media_txt = "φ = 5  (initial)",
  ref_var       = 1.0,
  ref_var_txt   = "Var p = 1  (initial)",

  titulo = "How male trait availability shapes\nnetwork architecture and female preference evolution"
)

gerar_poster2(MODELO_MACHOS)
