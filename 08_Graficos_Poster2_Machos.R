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
# A preferência é registrada de duas formas. pbar_pop é o pool genotípico,
# os dois sexos juntos, que é a variável evolutiva propriamente dita, já
# que o macho também carrega p sem expressar. pbar_femeas é a preferência
# efetivamente expressa, a que gera a rede. As figuras usam o pool; para
# ver a expressa, troque col_media e col_var abaixo.
MODELO_MACHOS <- list(
  nome    = "Machos variando",
  prefixo = "Machos",
  script  = "Fase_Espelho.R",

  pasta   = "Resultados_Artigo/Fase_Espelho/Dados",
  padrao  = "^(backup|resultados)_Espelho_censoConst.*\\.rds$",

  # Eixo do experimento
  eixo     = "sigma_z",
  eixo_txt = "σz",
  eixo_lab = expression(bold(paste("Male Trait Variation (", sigma[z], ")"))),

  # A característica que evolui: a preferência da fêmea
  faixa_evo  = "FEMALE PREFERENCE EVOLUTION",
  cor_evo    = "#1F7A4C",
  titulo_evo = "Preference Peak Mean",
  col_media  = "pbar_pop",
  col_var    = "varp_pop",
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
