#!/usr/bin/env bash
# =====================================================================
# Monta a pasta do repositório público, só com o que vai ao site.
# =====================================================================
# Rodar a partir da raiz do repositório de trabalho:
#     bash preparar_repo_publico.sh
#
# Ele cria ../redes-sexuais-cap1 com os arquivos do site e nada mais.
# O manuscrito, as notas de reunião e os dados ficam de fora.
# =====================================================================
set -e

DESTINO="../redes-sexuais-cap1"
mkdir -p "$DESTINO"

# A capa e o arquivo que desliga o Jekyll
cp index.html .nojekyll "$DESTINO/"

# A exploração, com a pasta de figuras e estilos que o acompanha
cp Exploracao_Paineis_MiudoV2.html "$DESTINO/"
rm -rf "$DESTINO/Exploracao_Paineis_MiudoV2_files"
cp -R Exploracao_Paineis_MiudoV2_files "$DESTINO/"

# A nota. O .html só existe depois de rodar o render; se ainda não houver,
# copia o .md para o repositório não ficar sem ela.
if [ -f NOTA_quatro_estudos.html ]; then
  cp NOTA_quatro_estudos.html "$DESTINO/"
else
  cp NOTA_quatro_estudos.md "$DESTINO/"
  echo "AVISO: NOTA_quatro_estudos.html ainda não existe, copiei o .md."
fi

cat > "$DESTINO/README.md" <<'MD'
# Redes sexuais — Capítulo 1

Parte pública do meu repositório, para compartilhar documentos dinâmicos com os
colaboradores. O código e os dados ficam no repositório de trabalho.

**Site:** https://solimarygh.github.io/redes-sexuais-cap1/

- **Exploração por painéis** — os três estudos, um de cada vez
- **Nota: os quatro estudos complementares** — o desenho, o ciclo de vida e as hipóteses
MD

echo
echo "Pronto. Conteúdo em $DESTINO:"
du -sh "$DESTINO"
echo
echo "Agora, no GitHub: New repository, nome 'redes-sexuais-cap1', PUBLIC,"
echo "sem README nem .gitignore. Depois:"
echo
echo "  cd $DESTINO"
echo "  git init -b main"
echo "  git add ."
echo "  git commit -m 'Documentos do capitulo 1'"
echo "  git remote add origin https://github.com/solimarygh/redes-sexuais-cap1.git"
echo "  git push -u origin main"
echo
echo "E por fim Settings > Pages > Deploy from a branch > main > / (root)."
