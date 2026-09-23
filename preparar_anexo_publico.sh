#!/usr/bin/env bash
# =====================================================================
# Monta a pasta do repositório público do anexo do Relatório Científico.
# =====================================================================
# Diferente de preparar_repo_publico.sh, que publica os documentos de trabalho
# para os colaboradores, este publica UMA coisa só: o Material suplementar dos
# Estudos 1 e 2, que é o anexo do Relatório Científico de 30/08 a 31/12 de 2025.
#
# Vai para a pasta pública: o HTML do anexo, a pasta de figuras e estilos que
# ele precisa, uma capa de uma linha e o .nojekyll. Nada mais. Nem código, nem
# dados, nem notas de reunião, nem manuscritos, nem os outros documentos.
#
# Uso, a partir da raiz do repositório de trabalho:
#
#     LANG=C.UTF-8 Rscript 13_Anexo_Estudos1e2.R
#     Rscript -e 'rmarkdown::render("Material_Suplementar_Estudos1e2.Rmd")'
#     bash preparar_anexo_publico.sh
#
# =====================================================================
set -euo pipefail

DOC="Material_Suplementar_Estudos1e2"
DESTINO="../anexo-relatorio-2025"

if [ ! -f "$DOC.html" ]; then
  echo "ERRO: não existe $DOC.html."
  echo "Rode primeiro o gerador e o render:"
  echo "  LANG=C.UTF-8 Rscript 13_Anexo_Estudos1e2.R"
  echo "  Rscript -e 'rmarkdown::render(\"$DOC.Rmd\")'"
  exit 1
fi

rm -rf "$DESTINO"
mkdir -p "$DESTINO"

cp .nojekyll "$DESTINO/"
cp "$DOC.html" "$DESTINO/"

# self_contained: false no YAML, de modo que as figuras e os estilos ficam numa
# pasta ao lado. Sem ela o documento abre sem nenhuma figura.
if [ -d "${DOC}_files" ]; then
  cp -R "${DOC}_files" "$DESTINO/"
else
  echo "AVISO: não achei ${DOC}_files. O documento vai abrir sem as figuras."
fi

# A capa. Uma linha, porque o repositório tem um documento só.
cat > "$DESTINO/index.html" <<HTML
<!doctype html>
<meta charset="utf-8">
<title>Material suplementar — Relatório Científico FAPESP 2025</title>
<meta http-equiv="refresh" content="0; url=$DOC.html">
<p>Redirecionando para o
   <a href="$DOC.html">Material suplementar</a>.</p>
HTML

cat > "$DESTINO/README.md" <<'MD'
# Material suplementar — Relatório Científico FAPESP

Anexo do Relatório Científico do período de 30 de agosto a 31 de dezembro de
2025, referente ao processo de bolsa de pós-doutorado FAPESP nº 2024/18754-6,
vinculado ao Projeto Regular nº 2024/02198-7.

Documenta os dois estudos de simulação concluídos no período: a estrutura da
rede de acasalamento numa geração e a evolução do traço masculino ao longo de
cem gerações. A navegação é por abas, dentro de cada painel.

O código de simulação e os dados ficam no repositório de trabalho, e serão
abertos junto com a submissão dos manuscritos, conforme o Plano de Gestão de
Dados descrito no relatório.
MD

echo
echo "Pronto. Conteúdo em $DESTINO:"
du -sh "$DESTINO"
find "$DESTINO" -maxdepth 1 -mindepth 1 -printf "  %f\n" 2>/dev/null || ls -1 "$DESTINO" | sed 's/^/  /'
echo
echo "No GitHub: New repository, nome 'anexo-relatorio-2025', PUBLIC,"
echo "sem README nem .gitignore. Depois:"
echo
echo "  cd $DESTINO"
echo "  git init -b main"
echo "  git add ."
echo "  git commit -m 'Material suplementar do Relatorio Cientifico 2025'"
echo "  git remote add origin https://github.com/solimarygh/anexo-relatorio-2025.git"
echo "  git push -u origin main"
echo
echo "E por fim Settings > Pages > Deploy from a branch > main > / (root)."
echo "O link para o relatório fica:"
echo "  https://solimarygh.github.io/anexo-relatorio-2025/"
