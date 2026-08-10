# =====================================================================
# POSTER 2 — ESTUDO 2: FÊMEAS VARIANDO (sigma_p)
# =====================================================================
# Sucessor de 08_Graficos_Poster.R, que ficou preso ao modelo antigo
# (regra de escape, segregação de ruído fixo, pool de machos variável).
# Mantém o mesmo estilo visual; o que mudou está listado no cabeçalho de
# 08_Poster2_comum.R.
#
#   Rscript 08_Graficos_Poster2_Femeas.R
#
# As figuras saem em Resultados_Artigo/Poster2/, com prefixo "Femeas".
#
# Para mudar o cenário mostrado (k, A_max, sigma alto e baixo, fundo
# escuro, resolução), edite o bloco de parâmetros de 08_Poster2_comum.R.
# =====================================================================

source("08_Poster2_comum.R")

# Neste estudo o eixo é sigma_p, a variação do pico de preferência entre
# as fêmeas, e quem evolui é o traço do macho. A preferência é re-sorteada
# a cada geração, então ela é a CAUSA da seleção e não muda com o tempo.
MODELO_FEMEAS <- list(
  nome    = "Fêmeas variando",
  prefixo = "Femeas",
  script  = "Fase4_TodasAsCurvas.R",

  # A pasta é Fase5_MiudoV2 por herança do nome passado a
  # configurar_diretorios(); é histórico e não vale renomear no meio.
  pasta   = "Resultados_Artigo/Fase5_MiudoV2/Dados",
  # O prefixo do arquivo. Qual rodada usar é decidido em 08_Poster2_comum.R:
  # a mais nova que existir, sem nunca misturar duas.
  estudo  = "Femeas",

  # Eixo do experimento
  eixo     = "sigma_p",
  eixo_txt = "σp",
  eixo_lab = expression(bold(paste("Preference Variation (", sigma[p], ")"))),

  # A característica que evolui: o traço do macho
  faixa_evo  = "MALE TRAIT EVOLUTION",
  cor_evo    = "#6B3A8C",
  titulo_evo = "Male Trait Mean",
  col_media  = "zbar_males",
  col_var    = "varz_males",
  lab_media  = "bold(paste('Male Trait Mean (', bar(z), ')'))",
  lab_var    = "Male Trait Variance (Var z)",
  y_media    = expression(bold(paste("Male Trait Mean (", bar(z), ")"))),

  # Referências: phi é o ótimo ecológico e a média inicial; a variância
  # do traço parte de sigma_z_init = 1.0 neste estudo.
  ref_media     = 5.0,
  ref_media_txt = "φ = 5  (initial)",
  ref_var       = 1.0,
  ref_var_txt   = "Var z = 1  (initial)",

  titulo = "How female preference variation shapes\nnetwork architecture and male trait evolution"
)

gerar_poster2(MODELO_FEMEAS)
