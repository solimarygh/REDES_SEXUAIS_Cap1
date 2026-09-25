# Contexto do projeto

Modelo individual (IBM) de redes sexuais. Solimary García Hernández
(pós-doutoranda, IB-USP, bolsa FAPESP), com Erika M. Santana (UNIFESP Diadema) e
o supervisor Paulo R. Guimarães Jr.

---

## Escrita

**Antes de escrever ou revisar qualquer texto, ler `ESTILO_de_escrita.md`.** Ele
guarda, com o antes e o depois de cada caso, as correções de estilo que já foram
pedidas: frases que anunciam em vez de dizer, antíteses curtas, clivadas de
ênfase, metáforas narrativas, referentes que faltam, aberturas sem verbo. Traz
também a varredura de `grep` para conferir antes de entregar.

É um arquivo vivo: quando aparecer uma correção de estilo nova, acrescentá-la
ali, com o exemplo concreto, em vez de só aplicá-la.

Os relatórios são escritos em **primeira pessoa**: quem relata é a Solimary.

---

## Fluxo de trabalho

- **Commits sim, push só quando ela pedir.** É combinação explícita.
- Mensagens de commit em português, dizendo por que a mudança foi feita e não só
  o que mudou.

---

## O que não se edita à mão

- `Material_Suplementar_Estudos1e2.Rmd` é **gerado** por `13_Anexo_Estudos1e2.R`
  a partir de `Material_Suplementar.Rmd`. Correções vão no documento fonte, ou
  nos remendos do gerador. O gerado está no `.gitignore`.
- O gerador **para** quando um remendo deixa de encaixar, e diz qual. Isso é
  proteção, não defeito: significa que o texto fonte mudou e o remendo precisa
  ser atualizado junto.

## Os números dos documentos

Nenhum número é escrito à mão: todos se interpolam dos dados com `` `r ...` ``,
para que o texto mude quando a rodada mudar. Ao acrescentar um número a um
texto, calculá-lo, não transcrevê-lo.

## O cache das figuras de rede

`rede_representativa()` não guarda as redes: re-simula a réplica a partir da
semente e confere a métrica reproduzida contra a guardada. O cache fica em
`Resultados_Artigo/Figuras/redes_representativas.rds`, e a sua chave inclui uma
impressão digital dos scripts do motor.

Editar qualquer um desses scripts descarta o cache. Quando a edição **não muda
nenhum número**, `14_Revalidar_cache_redes.R` preserva as redes já calculadas;
quando muda, não se revalida. O cabeçalho do script lista os casos.

---

## Histórico das decisões

`NOTA_00_linha_do_tempo.md` põe em ordem cronológica o que as notas de trabalho
registram, e termina com duas listas: o que está decidido e o que continua
aberto. Consultar antes de reabrir uma discussão fechada.

`NOTA_regime_censo_nas_figuras.md` tem um defeito que vale conhecer, porque o
mesmo erro pode voltar por caminhos parecidos: um argumento do motor que era
passado na produção e não na reconstrução das figuras.

---

## Ambiente

O repositório **não deve ficar dentro de `~/Documents`**, que o iCloud
sincroniza. Com ele lá, um render que levava 4 minutos levava 91, quase todos
esperando o `fileproviderd`. Está em `~/REDES_SEXUAIS_cap1`.
