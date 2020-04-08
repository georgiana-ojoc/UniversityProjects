yacc -d -v $1.y
mv y.tab.c y.tab.cpp
lex $1.l
mv lex.yy.c lex.yy.cpp
g++ lex.yy.cpp y.tab.cpp -ll -ly -w -o $1
./$1 $2