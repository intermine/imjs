perl -ne 'if (/```/ ... /```/) { s/```.*//; s|imjs|./bin/index|; print }' README.md | node
