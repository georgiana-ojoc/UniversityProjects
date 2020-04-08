%{
#include "y.tab.h"
#define YY_DECL extern "C" int yylex()
%}
nat                         natural
int                         int
float                       float
rchar                       signum
rstring                     scriptum
rbool                       centaur-answer
echar                       hierogliph
estring                     papyrus
ebool                       sphynx-answer
const                       invincible
array                       bunch-of
id                          [a-zA-Z][a-zA-Z0-9]*
%START ROME EGYPT
%%
~start-epoch:Rome~          { BEGIN ROME; return BGIN_PROG; }
~start-epoch:Egypt~         { BEGIN EGYPT; return BGIN_PROG; }
<ROME>~end-epoch:Rome~      { BEGIN 0; return END_PROG; }
<EGYPT>~end-epoch:Egypt~    { BEGIN 0; return END_PROG; }
<ROME>Roman                 { yylval.strval = strdup(yytext); return CLS; }
<EGYPT>Egyptian             { yylval.strval = strdup(yytext); return CLS; }
<ROME>~start-Roman~         { return BGIN_CLS; }
<EGYPT>~start-Egyptian~     { return BGIN_CLS; }
<ROME>~end-Roman~           { return END_CLS; }
<EGYPT>~end-Egyptian~       { return END_CLS; }
battle                      { return FUNC; }
~start-battle~              { return BGIN_FUNC; }
<ROME>Orcus                 { return RETURN; }
<EGYPT>Anubis               { return RETURN; }
~end-battle~                { return END_FUNC; }
~start-war~                 { return BGIN_MAIN; }
~end-war~                   { return END_MAIN; }
<ROME>Nero                  { return IF; }
<EGYPT>Cleopatra            { return IF; }
<ROME>burn                  { return THEN; }
<EGYPT>poison               { return THEN; }
<ROME>~start-burn~          { return BGIN_THEN; }
<EGYPT>~start-poison~       { return BGIN_THEN; }
<ROME>~end-burn~            { return END_THEN; }
<EGYPT>~end-poison~         { return END_THEN; }
<ROME>save                  { return ELSE; }
<EGYPT>snake                { return ELSE; }
<ROME>~start-save~          { return BGIN_ELSE; }
<EGYPT>~start-snake~        { return BGIN_ELSE; }
<ROME>~end-save~            { return END_ELSE; }
<EGYPT>~end-snake~          { return END_ELSE; }
<ROME>build-empire-as       { return WHILE; }
<EGYPT>cross-Nile-as        { return WHILE; }
<ROME>~start-build~         { return BGIN_WHILE; }
<EGYPT>~start-cross~        { return BGIN_WHILE; }
<ROME>~end-build~           { return END_WHILE; }
<EGYPT>~end-cross~          { return END_WHILE; }
<ROME>conquer-between-      { return L_FOR; }
<EGYPT>build-pyramid-with-  { return L_FOR; }
<ROME>-and-                 { return C_FOR; }
<EGYPT>-to-                 { return C_FOR; }
<ROME>-lands                { return R_FOR; }
<EGYPT>-bricks              { return R_FOR; }
<ROME>~start-conquer~       { return BGIN_FOR; }
<EGYPT>~start-build~        { return BGIN_FOR; }
<ROME>~end-conquer~         { return END_FOR; }
<EGYPT>~end-build~          { return END_FOR; }
<ROME>{rstring}CPY          { return CPY; }
<EGYPT>{estring}CPY         { return CPY; }
<ROME>{rstring}CAT          { return CAT; }
<EGYPT>{estring}CAT         { return CAT; }
eval                        { return EVAL; }
{array}-{int}               { yylval.strval = strdup(yytext); return A_INT; }
{array}-{float}             { yylval.strval = strdup(yytext); return A_FLOAT; }
<ROME>{array}-{rchar}       { yylval.strval = strdup(yytext); return A_CHAR; }
<EGYPT>{array}-{echar}      { yylval.strval = strdup(yytext); return A_CHAR; }
<ROME>{array}-{rstring}     { yylval.strval = strdup(yytext); return A_STRING; }
<EGYPT>{array}-{estring}    { yylval.strval = strdup(yytext); return A_STRING; }
<ROME>{array}-{rbool}       { yylval.strval = strdup(yytext); return A_BOOL; }
<EGYPT>{array}-{ebool}      { yylval.strval = strdup(yytext); return A_BOOL; }
{int}                       { yylval.strval = strdup(yytext); return V_INT; }
{float}                     { yylval.strval = strdup(yytext); return V_FLOAT; }
<ROME>{rchar}               { yylval.strval = strdup(yytext); return V_CHAR; }
<EGYPT>{echar}              { yylval.strval = strdup(yytext); return V_CHAR; }
<ROME>{rstring}             { yylval.strval = strdup(yytext); return V_STRING; }
<EGYPT>{estring}            { yylval.strval = strdup(yytext); return V_STRING; }
<ROME>{rbool}               { yylval.strval = strdup(yytext); return V_BOOL; }
<EGYPT>{ebool}              { yylval.strval = strdup(yytext); return V_BOOL; }
{const}-{int}               { yylval.strval = strdup(yytext); return C_INT; }
{const}-{float}             { yylval.strval = strdup(yytext); return C_FLOAT; }
<ROME>{const}-{rchar}       { yylval.strval = strdup(yytext); return C_CHAR; }
<EGYPT>{const}-{echar}      { yylval.strval = strdup(yytext); return C_CHAR; }
<ROME>{const}-{rstring}     { yylval.strval = strdup(yytext); return C_STRING; }
<EGYPT>{const}-{estring}    { yylval.strval = strdup(yytext); return C_STRING; }
<ROME>{const}-{rbool}       { yylval.strval = strdup(yytext); return C_BOOL; }
<EGYPT>{const}-{ebool}      { yylval.strval = strdup(yytext); return C_BOOL; }
<ROME>etiam                 { return TRUE; }
<EGYPT>nem                  { return TRUE; }
<ROME>non                   { return FALSE; }
<EGYPT>la                   { return FALSE; }
not                         { return NOT; }
and                         { return AND; }
or                          { return OR; }
{id}                        { yylval.strval = strdup(yytext); return ID; }
[1-9][0-9]*|0               { yylval.intval = atoi(yytext); return NAT; }
(-?[1-9][0-9]*)|0           { yylval.intval = atoi(yytext); return INT; }
(-?[1-9][0-9]*\.[0-9]+)|0   { return FLOAT; }
~                           { return BIT_COMPL; }
\&                          { return BIT_AND; }
\|                          { return BIT_OR; }
\^                          { return BIT_XOR; }
"<<"|">>"                   { yylval.strval = strdup(yytext); return BIT_SHIFT; }
"++"                        { return INC; }
--                          { return DEC; }
[-+]                        { yylval.charval = (strdup(yytext))[0]; return ARITP; }
[/*%]                       { yylval.charval = (strdup(yytext))[0]; return ARITO; }
"="|"<>"                    { return EQ; }
"<"|"<="|">="|">"           { return DIFF; }
\<~                         { return ASSIGN; }
[-+/*%~&|^"<<"">>"]<~       { return COMP_ASSIGN; }
\*.{0,1}\*                  { return CHAR; }
#.*#                        { return STRING; }
:P                          { return END;}
~~(.|\n)*~~                 /*empty*/
[ \t]                       /*empty*/
\n                          { yylineno++; }
.                           { return yytext[0]; }
