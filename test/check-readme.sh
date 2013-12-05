perl -ne 'if (/```/ ... /```/) { s/```.*//; s|imjs|./js/index|; print }' README.md | node
