# Follow-up: modelo de CO-EVOLUÇÃO (preferência herdável)

> Rascunho de como mudar o motor (`01_metricas_e_utilitarios.R`) para permitir que a
> **preferência feminina co-evolua** com o traço masculino. NÃO implementado ainda —
> é o próximo experimento. O modelo atual (preferência congelada) fica como **controle**.

## O que muda na pergunta

- **Modelo atual:** "dada uma distribuição *fixa* de preferências, que rede emerge e como o traço evolui?" — a preferência é re-sorteada a cada geração, não herda.
- **Modelo de co-evolução:** "como preferência e traço **evoluem juntos**?" — a preferência vira um genótipo herdável. Território do *Fisherian runaway* (Lande 1981).

## Ideia biológica central

Cada indivíduo (macho E fêmea) passa a carregar **dois genótipos**: o traço `z` (expresso nos machos) e a preferência `p` (expressa nas fêmeas). O acasalamento assortativo faz `z` e `p` ficarem **geneticamente correlacionados** — e essa covariância é o motor do runaway. Por isso é essencial que cada filhote herde `z` e `p` **do mesmo par de pais, mantidos pareados**.

> **Precedente que já existe no motor atual:** as fêmeas **já carregam um `z` não expresso** (`female_z_gen`) — elas o transmitem aos filhotes mas não o exibem, e só o `z` dos machos entra na escolha. Ver `01_metricas_e_utilitarios.R`: inicialização (~linha 345, `female_z_gen1`), herança (~308/311, o `z` da mãe entra no filhote), evolução (~397). Fazer os machos carregarem uma `p` não expressa é **simétrico** a isso — o motor já faz metade do truque.

## Mudanças concretas no motor

### 1. `simulate_evolution` — assinatura
`sigma_p` deixa de ser perilha *por geração* e vira **condição inicial** `sigma_p_init` (igual a `sigma_z_init`). Novos parâmetros: `eps_p` (mutação da preferência) e `phi_p` (ótimo/centro inicial da preferência).

```r
simulate_evolution <- function(generations = 100, N_machos = 200, N_femeas = 200,
    sigma_z_init = 1.0, sigma_p_init = 1.0, sigma_s = 0.2,
    phi = 5, phi_p = 5, gamma = 0.2, eps_sd = 0.2, eps_p = 0.2,
    tipo_selecao = "gaussian", encounters_n = 200, selecao_natural = TRUE,
    k_fixo = NULL, return_details = FALSE, ...) {
```

### 2. Inicialização — ambos os sexos carregam (z, p)
```r
male_z_gen   <- pmax(0, rnorm(N_machos, phi,   sigma_z_init))
male_p_gen   <- pmax(0, rnorm(N_machos, phi_p, sigma_p_init))   # NOVO: machos carregam p (não expresso)
female_z_gen <- pmax(0, rnorm(N_femeas, phi,   sigma_z_init))   # fêmeas carregam z (não expresso)
female_p_gen <- pmax(0, rnorm(N_femeas, phi_p, sigma_p_init))
```

### 3. No loop — REMOVER o re-sorteio da preferência
```r
# ANTES (modelo congelado):
#   if (t == 1) female_p <- female_p_gen1
#   else        female_p <- pmax(0, rnorm(N_femeas, phi, sigma_p))
# AGORA (co-evolução): usa a preferência HERDADA, que evolui
female_p <- female_p_gen
female_s <- pmax(0, rnorm(N_femeas, mean = 2, sd = sigma_s))   # s pode continuar re-sorteado (ou herdável depois)
```
O acasalamento (`mate_with_survivors`) NÃO muda: fêmea usa seu `female_p`, macho seu `male_z`.

### 4. `produce_offspring` — herdar TAMBÉM a preferência, pareada com z
Passar `male_p_surv` e `female_p_gen`; herdar `p` por ponto médio + mutação; e **amostrar índices de juvenis** (não valores soltos) para manter `z` e `p` do mesmo indivíduo juntos.

```r
produce_offspring <- function(M, male_z_surv, male_p_surv, female_z_gen, female_p_gen,
                              N_males_next = 200, N_females_next = 200,
                              fecundidade_base = 50, eps_sd = 0.2, eps_p = 0.2) {
  # ... (moms_of_juveniles, dads_of_juveniles: igual ao atual) ...
  z_dads <- male_z_surv[dads_of_juveniles]; z_moms <- female_z_gen[moms_of_juveniles]
  p_dads <- male_p_surv[dads_of_juveniles]; p_moms <- female_p_gen[moms_of_juveniles]   # NOVO

  z_juv <- pmax(0, (z_dads + z_moms)/2 + rnorm(total_juveniles, 0, eps_sd))
  p_juv <- pmax(0, (p_dads + p_moms)/2 + rnorm(total_juveniles, 0, eps_p))              # NOVO

  vagas <- min(N_males_next + N_females_next, total_juveniles)
  idx   <- sample(seq_len(total_juveniles), size = vagas, replace = FALSE)  # <-- índices, p/ manter (z,p) pareados!
  meio  <- floor(vagas/2)
  list(
    male_z_next   = z_juv[idx[1:meio]],            male_p_next   = p_juv[idx[1:meio]],
    female_z_next = z_juv[idx[(meio+1):(2*meio)]], female_p_next = p_juv[idx[(meio+1):(2*meio)]]
  )
}
```
> ⚠️ **Ponto crítico de correção:** o motor atual faz `sample(z_todos, ...)` — embaralha só o `z`.
> Na co-evolução isso destruiria a covariância p–z. Tem que amostrar **índices** e levar `z` e `p` juntos.

### 5. No loop — atualizar os quatro vetores
```r
off <- produce_offspring(M, male_z_surv, male_p_surv, female_z_gen, female_p_gen, ...)
male_z_gen <- off$male_z_next; male_p_gen <- off$male_p_next
female_z_gen <- off$female_z_next; female_p_gen <- off$female_p_next
```
(Precisa também aplicar a sobrevivência/`survive` ao `male_p` junto com o `male_z`: `male_p_surv <- male_p_gen[survive]`.)

## O que medir (para detectar runaway)

> **A grandeza central NÃO é a característica de cada sexo — é a COVARIÂNCIA genética entre elas.**
> Na teoria de Lande (1981) / Kirkpatrick (1982), o acasalamento assortativo cria uma associação
> estatística (desequilíbrio de ligação / covariância genética) entre os genes de preferência `p` e de
> traço `z`. É **essa covariância** que permite a seleção sobre o traço "arrastar" a preferência (e
> vice-versa) → evolução correlacionada / runaway. As médias por sexo são *resultado*; a covariância é o
> *motor*. Portanto o foco da análise é `cov(z, p)`, não `mean` de um sexo isolado.

Salvar por geração:

- **`cov_zp`** — a grandeza-chave. Calculada **por indivíduo, na população inteira** (cada um tem seu par `(z, p)`):
  ```r
  pool <- rbind(data.frame(z = male_z_gen,   p = male_p_gen),
                data.frame(z = female_z_gen, p = female_p_gen))
  cov_zp <- cov(pool$z, pool$p)
  ```
  `cov_zp` cresce e se mantém > 0 → o Fisher está operando; fica ≈ 0 → sem runaway.
- **`zbar` e `pbar`** — médias **genotípicas poolizadas** (machos + fêmeas juntos), pois `z` e `p` são
  genótipos carregados pelos dois sexos: `mean(c(male_z_gen, female_z_gen))`, idem para `p`. (A preferência
  *expressa* na conduta é `female_p`; numericamente ≈ à poolizada, pois `p` herda de ambos os pais sem viés de sexo.)
- **Trajetórias** `zbar` e `pbar` vs geração: divergência sustentada e conjunta = runaway; retorno a φ = estável.

> ⚠️ Só dá para medir `cov_zp` de verdade se `z` e `p` forem herdados **pareados** por indivíduo (ver
> `produce_offspring` acima). Embaralhar `z` e `p` separadamente zera `cov_zp` artificialmente — o runaway
> sumiria por *bug*, não por biologia.

## Cuidados

- **Explosão:** sem custo de preferência nem seleção natural, `z` e `p` podem disparar ao infinito (linha de Lande). Manter `gamma > 0` (seleção de viabilidade em `z`) e/ou adicionar um custo em `p` para limitar.
- **`phi_p`:** centro inicial das preferências (usar 5 para casar com o traço; explorar depois).
- **Simetria:** aqui `sigma_p_init` e `sigma_z_init` são **ambos** condições iniciais → os dois experimentos (fêmea/macho) ficam finalmente simétricos.

## Desenho experimental sugerido

Cruzar `sigma_z_init × sigma_p_init` (ambos variando), 4 curvas, e comparar contra o modelo congelado (controle). Nova pasta `Resultados_Artigo/Fase_Coevolucao/`, `SEED_BASE` novo (ex.: 2028).
