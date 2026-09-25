# O regime de censo na reconstrução das figuras

Setembro de 2026. Esta nota registra um defeito que esteve no código desde que
a cota entrou no projeto, o que ele estragava, como foi encontrado e o que
*não* afeta. Fica aqui porque o mesmo erro pode voltar por caminhos parecidos, e
porque o caminho até ele passou por duas hipóteses erradas que vale a pena não
repetir.

A decisão biológica entre teto e cota está em `NOTA_teto_contra_cota.md`. Esta
nota é sobre outra coisa: sobre o código que desenha as figuras.

---

## O sintoma

No Material suplementar, no tópico 2.0 do Estudo 2, as abas *com seleção
natural* vinham todas vazias. As seis, em todas as curvas. As abas *sem seleção
natural* funcionavam.

A primeira versão do código nem dizia isso: escrevia a palavra `NULL` no meio da
página, porque o laço das abas imprimia o que a função devolvia sem olhar o que
era.

---

## Por que não era falta de dados

A primeira suspeita foi que a metade com seleção natural não tivesse sido
rodada, ou que estivesse em arquivos que o leitor não encontrava. As duas coisas
foram descartadas:

```
linhas com NS : 504.000
curvas        : gaussian, sigmoid, u-shaped, uniform
sigma_p       : 0.2, 0.5, 0.8, 1, 1.2, 1.5, 2
A_max         : 10, 40, 200
k             : 5, 10, 20
replicas      : 20
geracoes      : 1 a 100
```

O desenho está inteiro. E os arquivos da cota se chamam
`resultados_Femeas_bestOfN_cota_nscom.rds`, ou seja levam `Femeas_bestOfN` no
nome e o padrão de leitura os encontra.

---

## A causa

`rede_representativa()` não guarda as redes: guarda a semente e **volta a
simular** a réplica quando precisa dela. É o que garante que a rede desenhada é
a que de fato rodou, e não um esquema parecido. Logo depois, compara a métrica
reproduzida com a que estava guardada:

```r
confere <- isTRUE(abs(obtido - esperado) < 1e-8)
if (!confere) {
  warning("a rede reproduzida NÃO é a réplica dos dados ...")
  return(NULL)
}
```

Essa verificação estava fazendo exatamente o que deve fazer: recusando-se a
desenhar uma rede que não corresponde ao número.

O que ela detectou foi isto. `simulate_evolution()` tem um argumento
`regime_censo`, que vale `"teto"` ou `"cota"` e decide se os 200 machos adultos
são o que sobrou da viabilidade ou um sorteio ponderado por ela. Os quatro
scripts de produção passam esse argumento, e `Fase4_TodasAsCurvas.R` rodou a
metade com seleção natural com `CENSO=cota`. Mas `11_Rede_Representativa.R` não
o passava em lugar nenhum, de modo que reconstruía sempre com o default, que é
`"teto"`.

Duas populações diferentes, duas métricas diferentes:

```
Modularity obtido 0.4456, guardado 0.4380
```

A diferença é pequena porque o regime muda *quais* machos ocupam as 200 vagas, e
não quantos. Por isso não dava erro nenhum: dava uma rede plausível e errada, e
só a verificação a pegou.

**Só aparecia na metade com seleção natural** porque sem ela os dois regimes dão
o mesmo resultado — o código nem chega à parte da cota. Foi o que fez o defeito
sobreviver tanto tempo.

---

## A correção

O regime passou a viajar com o dado, em vez de ser suposto:

1. `dados_do_estudo()` marca cada linha com o regime sob o qual foi produzida,
   no momento em que junta os arquivos da cota com os do teto.
2. `rede_representativa()` lê o regime da réplica escolhida e o passa ao motor.
3. As quatro funções `rodar()` de `ESTUDOS` o repassam.
4. A chave do cache ganhou um sufixo de versão, porque as entradas gravadas
   antes disto foram calculadas com o regime errado.

Afetava os Estudos 1, 2 e 3. No Estudo 4 a grade é só sem seleção natural, e ali
nunca mudou nada. Nos Estudos 1 e 3 o defeito estava latente: as figuras que os
documentos pedem usam `selecao_natural = FALSE`, de modo que ninguém tinha
esbarrado nele.

---

## O que isto NÃO afeta

**As simulações não precisam ser rodadas de novo.** O defeito estava na
reconstrução para as figuras, não na produção. Os scripts de produção sempre
passaram `regime_censo` corretamente — é por isso que o arquivo `cota_nscom`
existe. Os `.rds` de resultados estão certos, e os números do relatório e dos
anexos, que saem deles, também.

O único material a refazer é o cache de redes representativas
(`Resultados_Artigo/Figuras/redes_representativas.rds`), que é derivado e se
reconstrói sozinho no render seguinte.

---

## As duas hipóteses erradas pelo caminho

Ficam registradas porque custaram tempo.

**Primeira: o cache gravando devagar.** O render do documento recortado levou 91
minutos de relógio contra 32 de processador, e a explicação proposta foi que
`.gravar_cache()` reescrevia o arquivo inteiro depois de cada rede, com custo
crescendo ao quadrado. A gravação foi passada a periódica, o que é uma melhora
real, mas o arquivo tem 2,7 MB: reescrevê-lo 125 vezes são segundos, não uma
hora. A hipótese estava errada.

**Segunda: memória.** A máquina mostrava 58 MB livres e 6,5 GB no compressor, o
que parecia bastante. Mas o que apareceu no Monitor de Atividade foi
`fileproviderd` a 134% de CPU, com 421 horas acumuladas: o repositório estava em
`~/Documents`, que o iCloud sincroniza, e cada arquivo que o render escrevia era
capturado pela sincronização. Movido o repositório para fora de `Documents`, o
mesmo render passou a 4 minutos e 43 segundos, com `user` praticamente igual a
`real` — que é como se vê um processo que calcula sem esperar.

A lição das duas: quando `real` é muito maior que `user`, o processo está
esperando, e convém descobrir por quem antes de propor a causa.

---

## O que vigiar daqui para a frente

- Qualquer argumento novo do motor que mude o resultado precisa ser passado
  também na reconstrução, e não só na produção. A verificação de `confere`
  avisa, mas só depois de a figura sumir.
- `11_Rede_Representativa.R` entra na impressão digital que valida o cache, de
  modo que editá-lo descarta tudo. Quando a edição não mudar número nenhum,
  `14_Revalidar_cache_redes.R` preserva o cache; quando mudar, como foi o caso
  aqui, **não** se revalida.
- O repositório não deve voltar para dentro de `~/Documents`.
