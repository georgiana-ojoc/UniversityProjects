%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>
#include <map>
#include <string>
#include <vector>

#define CLASS_DEF                  "class definition"

#define GLOBAL_CLASS_DECL		"global class declaration"
#define MAIN_FUNC_CLASS_DECL	     "class declaration in main function"

#define GLOBAL_FUNC_DEF			"global function definition"
#define CLASS_FUNC_DEF			"function definition in class"

#define GLOBAL_ARR_DECL            "global array declaration"
#define CLASS_ARR_DECL			"array declaration in class"
#define GLOBAL_FUNC_ARR_DECL	     "array declaration in global function"
#define CLASS_FUNC_ARR_DECL		"array declaration in class function"
#define MAIN_FUNC_ARR_DECL		"array declaration in main function"

#define GLOBAL_VAR_DECL			"global variable declaration"
#define CLASS_VAR_DECL			"variable declaration in class"	
#define GLOBAL_FUNC_VAR_DECL	     "variable declaration in global function"
#define CLASS_FUNC_VAR_DECL		"variable declaration in class function"
#define MAIN_FUNC_VAR_DECL		"variable declaration in main function"

#define GLOBAL_CONST_DECL		"global constant declaration"
#define CLASS_CONST_DECL		     "constant declaration in class"	
#define GLOBAL_FUNC_CONST_DECL	"constant declaration in global function"
#define CLASS_FUNC_CONST_DECL	     "constant declaration in class function"
#define MAIN_FUNC_CONST_DECL	     "constant declaration in main function"

#define ARRAY_PARAM                "array parameter"
#define VAR_PARAM				"variable parameter"
#define CONST_PARAM				"constant parameter"

#define GLOBAL_FUNC_RET            "global function return"
#define CLASS_FUNC_RET             "class function return"

#define ALREADY_USED(name, line) \
     { \
          string error(name); \
          error += " is already declared or defined at line "; \
          char buffer[10]; \
          sprintf(buffer, "%d", line); \
          error += buffer; \
          yyerror(error.c_str()); \
          exit(1); \
     }
#define HAS_SAME_SIGNATURE(name, line) \
     { \
          string error(name); \
          error += " is already defined with the same signature at line "; \
          char buffer[10]; \
          sprintf(buffer, "%d", line); \
          error += buffer; \
          yyerror(error.c_str()); \
          exit(1); \
     }

#define NOT_USED(name, message) \
     { \
          string error(name); \
          error += message; \
          yyerror(error.c_str()); \
          exit(1); \
     }
#define NOT_SAME_SIGNATURE \
     { \
          args.clear(); \
          yyerror("the arguments of the function call does not have the same types as the parameters of the function definition"); \
          exit(1); \
     }
#define NOT_ALLOWED(message) \
     { \
          yyerror(message); \
          exit(1); \
     }

using namespace std;

enum {
     INT_TYPE,
     FLOAT_TYPE,
     CHAR_TYPE,
     STRING_TYPE,
     BOOL_TYPE,
     CONST_INT_TYPE,
     CONST_FLOAT_TYPE,
     CONST_CHAR_TYPE,
     CONST_STRING_TYPE,
     CONST_BOOL_TYPE,
     ARRAY_INT_TYPE,
     ARRAY_FLOAT_TYPE,
     ARRAY_CHAR_TYPE,
     ARRAY_STRING_TYPE,
     ARRAY_BOOL_TYPE
};

struct info {
     string scope;
     string type;
     int value=0;
     int line;
     int CLASS = 0; // owning class
     int function = 0; // owning function
     int assign = 0; // owning assignment
};

map<string,vector<info>> symbol_table;
map<string, string> types;
map<int, vector<string>> params;
vector<int> evals;
vector<int> args;
int classes = 0;
int functions = 0;
int assigns = 0;

extern "C" int yylex();
extern "C" int yyerror(char *s);
extern "C" FILE *yyin;
extern "C" char* yytext;
extern "C" int yylineno;

void add(const char* new_name, const char* new_scope, const char* new_type, int new_value, int new_class, int new_function, int new_assign) {
     info obj;
     obj.scope = new_scope;
     obj.type = types[new_type];
     obj.value = new_value;
     obj.line = yylineno;
     obj.CLASS = new_class;
     obj.function = new_function;
     obj.assign = new_assign;
     symbol_table[new_name].push_back(obj);
}

int yyerror(const char* s)
{
     printf("error at line %d: %s\n", yylineno, s);
}
%}
%union {
     char charval;
     char* strval;
     int intval;
     struct {
          int type;
          int value;
     } exp_info;
}
%token         BGIN_PROG END_PROG BGIN_CLS END_CLS FUNC BGIN_FUNC RETURN END_FUNC BGIN_MAIN END_MAIN
%token         <strval> CLS
%token         IF THEN BGIN_THEN END_THEN ELSE BGIN_ELSE END_ELSE WHILE BGIN_WHILE END_WHILE L_FOR C_FOR R_FOR BGIN_FOR END_FOR
%token         CPY CAT EVAL
%token         <strval> A_INT A_FLOAT A_CHAR A_STRING A_BOOL
%token         <strval> V_INT V_FLOAT V_CHAR V_STRING V_BOOL
%token         <strval> C_INT C_FLOAT C_CHAR C_STRING C_BOOL
%token         TRUE FALSE NOT AND OR
%token         <strval> ID
%token         <intval> NAT INT
%token         FLOAT CHAR STRING
%token         BIT_COMPL BIT_AND BIT_OR BIT_XOR INC DEC EQ DIFF ASSIGN COMP_ASSIGN
%token         <strval> BIT_SHIFT
%token         <charval> ARITP ARITO
%token         END
%type          <strval> array
%type          <strval> var
%type          <strval> const
%type          <strval> func_type
%type          <intval> global_call
%type          <intval> class_call
%type          <intval> main_call
%type          <exp_info> global_exp
%type          <exp_info> class_exp
%type          <exp_info> main_exp
%type          <intval> global_expint
%type          <intval> global_func_expint
%type          <intval> class_expint
%type          <intval> class_func_expint
%type          <intval> main_func_expint
%nonassoc      IFT
%nonassoc      ELSE
%left          ASSIGN
%left          OR
%left          AND
%left          BIT_OR
%left          BIT_XOR
%left          BIT_AND
%left          EQ
%left          DIFF
%left          BIT_SHIFT
%left          ARITP
%left          ARITO
%nonassoc      INC DEC
%left          NOT BIT_COMPL
%left          '_' '.'
%start         program
%%
program        : BGIN_PROG globals main END_PROG
               ;
globals        : /*epsilon*/
               | globals global END
               ;
main           : BGIN_MAIN main_func_ins END_MAIN
               ;
global         : class
               | global_func
               | global_decl
               | global class
               | global global_func
               | global global_decl
               ;
class          : CLS ID BGIN_CLS defs END_CLS {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_DEF, $1, 0, ++classes, 0, 0);
                    }
                    else {
                         ALREADY_USED($2, it->second[0].line);
                    }
               }
               ;
global_func    : global_header BGIN_FUNC global_func_ins END_FUNC {
                    for (auto it1 : symbol_table) {
                         for (auto it2 : symbol_table[it1.first]) {
                              if (it2.scope.find("function definition") != string::npos) {
                                   bool found = false;
                                   for (auto it3 : symbol_table[it1.first]) {
                                        if (it2.function == it3.function && it3.scope.find("return") != string::npos) {
                                             found = true;
                                             break;
                                        }
                                   }
                                   if (!found) {
                                        NOT_USED(it1.first, " does not have return");
                                   }
                              }
                         }
                    }
               }
               ;
global_header  : FUNC func_type ID '(' ')' {
                    auto it = symbol_table.find($3);
                    if (it == symbol_table.end()) {
                         add($3, GLOBAL_FUNC_DEF, $2, 0, 0, ++functions, 0);
                    }
                    else {
                         for (auto symbol : symbol_table[$3]) {
                              if (symbol.scope.find("in class") == string::npos && symbol.scope.find("in global function") == string::npos) {
                                   if (symbol.scope == GLOBAL_FUNC_DEF) {
                                        if (params[symbol.function].size() > 0) {
                                             HAS_SAME_SIGNATURE($3, it->second[0].line);
                                        }
                                   }
                                   else {
                                        if (symbol.scope.find("return") == string::npos) {
                                             ALREADY_USED($3, it->second[0].line);
                                        }
                                   }
                              }
                         }
                         add($3, GLOBAL_FUNC_DEF, $2, 0, 0, ++functions, 0);
                    }
               }
               | FUNC func_type ID '(' global_params ')' {
                    auto it = symbol_table.find($3);
                    if (it == symbol_table.end()) {
                         add($3, GLOBAL_FUNC_DEF, $2, 0, 0, ++functions, 0);
                    }
                    else {
                         for (auto symbol : symbol_table[$3]) {
                              if (symbol.scope.find("in class") == string::npos && symbol.scope.find("in global function") == string::npos) {
                                   if (symbol.scope == GLOBAL_FUNC_DEF) {
                                        if (params[functions + 1].size() == params[symbol.function].size() &&
                                             equal(params[functions + 1].begin(), params[functions + 1].end(), params[symbol.function].begin())) {
                                             HAS_SAME_SIGNATURE($3, it->second[0].line);
                                        }
                                   }
                                   else {
                                        if (symbol.scope.find("return") == string::npos) {
                                             ALREADY_USED($3, it->second[0].line);
                                        }
                                   }
                              }
                         }
                         add($3, GLOBAL_FUNC_DEF, $2, 0, 0, ++functions, 0);
                    }
               }
               ;
global_decl    : V_INT ID ASSIGN global_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_VAR_DECL, $1, $4, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_VAR_DECL, $1, $4, 0, 0, ++assigns);
                    }
               }
               | V_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | V_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | V_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | V_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | C_INT ID ASSIGN global_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_CONST_DECL, $1, $4, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_CONST_DECL, $1, $4, 0, 0, ++assigns);
                    }
               }
               | C_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | C_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | C_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | C_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | array ID ASSIGN '[' ']' {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_ARR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("in class") == string::npos || symbol.scope.find("in class function") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_ARR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | CLS ID ID '{' '}' {
                    auto it1 = symbol_table.find($2);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($2, " is not defined");
                    }
                    for (auto symbol : symbol_table[$2]) {
                         if (symbol.scope != CLASS_DEF) {
                              ALREADY_USED($2, it1->second[0].line);
                         }
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         types[$2] = $2;
                         add($3, GLOBAL_CLASS_DECL, $2, 0, it1->second[0].CLASS, 0, 0);
                    }
                    else {
                         ALREADY_USED($3, it2->second[0].line);
                    }
               }
               ;
defs           : /*epsilon*/
               | defs def
               ;
def            : class_func
               | class_decl
               ;
class_func     : class_header BGIN_FUNC class_func_ins END_FUNC {
                    for (auto it1 : symbol_table) {
                         for (auto it2 : symbol_table[it1.first]) {
                              if (it2.scope.find("function definition") != string::npos) {
                                   bool found = false;
                                   for (auto it3 : symbol_table[it1.first]) {
                                        if (it2.function == it3.function && it3.scope.find("return") != string::npos) {
                                             found = true;
                                             break;
                                        }
                                   }
                                   if (!found) {
                                        NOT_USED(it1.first, " does not have return");
                                   }
                              }
                         }
                    }
               }
               ;
class_header   : FUNC func_type ID '(' ')' {
                    auto it = symbol_table.find($3);
                    if (it == symbol_table.end()) {
                         add($3, CLASS_FUNC_DEF, $2, 0, classes + 1, ++functions, 0);
                    }
                    else {
                         for (auto symbol : symbol_table[$3]) {
                              if (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos && symbol.scope.find("parameter") == string::npos) {
                                   if (symbol.scope == CLASS_FUNC_DEF) {
                                        if (params[symbol.function].size() > 0) {
                                             HAS_SAME_SIGNATURE($3, it->second[0].line);
                                        }
                                   }
                                   else {
                                        if (symbol.scope.find("return") == string::npos) {
                                             ALREADY_USED($3, it->second[0].line);
                                        }
                                   }                              }
                         }
                         add($3, CLASS_FUNC_DEF, $2, 0, classes + 1, ++functions, 0);
                    }
               }
               | FUNC func_type ID '(' class_params ')' {
                    auto it = symbol_table.find($3);
                    if (it == symbol_table.end()) {
                         add($3, CLASS_FUNC_DEF, $2, 0, classes + 1, ++functions, 0);
                    }
                    else {
                         for (auto symbol : symbol_table[$3]) {
                              if (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos && symbol.scope.find("parameter") == string::npos) {
                                   if (symbol.scope == CLASS_FUNC_DEF) {
                                        if (params[functions + 1].size() == params[symbol.function].size() &&
                                             equal(params[functions + 1].begin(), params[functions + 1].end(), params[symbol.function].begin())) {
                                             HAS_SAME_SIGNATURE($3, it->second[0].line);
                                        }
                                   }
                                   else {
                                        if (symbol.scope.find("return") == string::npos) {
                                             ALREADY_USED($3, it->second[0].line);
                                        }
                                   }                              }
                         }
                         add($3, CLASS_FUNC_DEF, $2, 0, classes + 1, ++functions, 0);
                    }
               }
               ;
class_decl 	: V_INT ID ASSIGN class_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_VAR_DECL, $1, $4, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_VAR_DECL, $1, $4, classes + 1, 0, ++assigns);
                    }
               }
               | V_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_VAR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_VAR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               | V_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_VAR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_VAR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               | V_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_VAR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_VAR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               | V_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_VAR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_VAR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               | C_INT ID ASSIGN class_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_CONST_DECL, $1, $4, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_CONST_DECL, $1, $4, classes + 1, 0, ++assigns);
                    }
               }
               | C_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_CONST_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_CONST_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               | C_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_CONST_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_CONST_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               | C_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_CONST_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_CONST_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               | C_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_CONST_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_CONST_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               | array ID ASSIGN '[' ']' {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_ARR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.CLASS == classes && classes > 0) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_ARR_DECL, $1, 0, classes + 1, 0, ++assigns);
                    }
               }
               ;
global_func_ins: /*epsilon*/
               | global_func_ins global_func_in;
global_func_in	: global_func_decl
               | IF '(' global_conds ')' THEN BGIN_THEN global_func_ins END_THEN %prec IFT
               | IF '(' global_conds ')' THEN BGIN_THEN global_func_ins END_THEN ELSE BGIN_ELSE global_func_ins END_ELSE
               | WHILE '(' global_conds ')' BGIN_WHILE global_func_ins END_WHILE
               | L_FOR ind C_FOR ind R_FOR BGIN_FOR global_func_ins END_FOR
               | ID assign global_exp {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_VAR_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_VAR_DECL || symbol->scope == VAR_PARAM)))) {
                              if (symbol->type == "int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol->type == "float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol->type == "char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol->type == "string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol->type == "bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                        NOT_USED($1, " does not have the same type as the assigned expression");
                    }   
               }
               | ID '.' ID assign global_exp {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) {
                              if (symbol2->type == "int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol2->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol2->type == "float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol2->type == "char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol2->type == "string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol2->type == "bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class or does not have the same type as the assigned expression";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT assign global_exp {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM))) {
                              if (symbol->type == "array of int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol->type == "array of float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol->type == "array of char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol->type == "array of string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol->type == "array of bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " does not have the same type as the assigned expression");
                    } 
               }
               | global_call
               | string '(' global_func1 '$' global_func2 ')'
               | EVAL '(' global_expint ')' { evals.push_back($<intval>3); }
               | RETURN global_exp {
                    bool ok = false;
                    string func_name;
                    string func_type;
                    for (auto it1 : symbol_table) {
                         if (!ok) {
                              for (auto it2 : symbol_table[it1.first]) {
                                   if (!ok && it2.function == functions && it2.scope == GLOBAL_FUNC_DEF) {
                                        func_name = it1.first;
                                        func_type = it2.type;
                                        if (it2.type.find("int") != string::npos)
                                             if ($<exp_info.type>2 == INT_TYPE || $<exp_info.type>2 == CONST_INT_TYPE) ok = true;
                                        if (it2.type.find("float") != string::npos)
                                             if ($<exp_info.type>2 == INT_TYPE || $<exp_info.type>2 == CONST_INT_TYPE ||
                                                  $<exp_info.type>2 == FLOAT_TYPE || $<exp_info.type>2 == CONST_FLOAT_TYPE) ok = true;
                                        if (it2.type.find("char") != string::npos)
                                             if ($<exp_info.type>2 == CHAR_TYPE) ok = true;
                                        if (it2.type.find("string") != string::npos)
                                             if ($<exp_info.type>2 == STRING_TYPE) ok = true;
                                        if (it2.type.find("bool") != string::npos)
                                             if ($<exp_info.type>2 == BOOL_TYPE) ok = true;
                                   }
                              }
                         }
                    }
                    if (!ok) {
                         NOT_USED(func_name.c_str(), " does not have the same type as the returned expression");
                    }
                    else {
                         add(func_name.c_str(), GLOBAL_FUNC_RET, func_type.c_str(), 0, 0, functions, 0);
                    }
               }
               ;
global_func_decl: V_INT ID ASSIGN global_func_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, $4, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, $4, 0, functions, ++assigns);
                    }
               }
               | V_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               | V_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               | V_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               | V_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_VAR_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               | C_INT ID ASSIGN global_func_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, $4, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, $4, 0, functions, ++assigns);
                    }
               }
               | C_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               | C_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               | C_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               | C_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_CONST_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               | array ID ASSIGN '[' ']' {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, GLOBAL_FUNC_ARR_DECL, $1, 0, 0, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, GLOBAL_FUNC_ARR_DECL, $1, 0, 0, functions, ++assigns);
                    }
               }
               ;
global_func1   : ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == "string" && (symbol->scope == GLOBAL_VAR_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_VAR_DECL || symbol->scope == VAR_PARAM)))) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
               }
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol2->type == "string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) {
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a string variable of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == "array of string" && (symbol->scope == GLOBAL_ARR_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM)))) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    } 
               }
               ;
global_func2   : ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->type == "string" && (symbol->scope == GLOBAL_VAR_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_VAR_DECL || symbol->scope == VAR_PARAM)))) ||
                              (symbol->type == "const string" && (symbol->scope == GLOBAL_CONST_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_CONST_DECL || symbol->scope == CONST_PARAM))))) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
               }
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if ((symbol2->type == "string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) ||
                              (symbol2->type == "const string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_CONST_DECL)) {
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a string member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == " array of string" && (symbol->scope == GLOBAL_ARR_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM)))) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    } 
               }
               | STRING
               ;
class_func_ins	: /*epsilon*/
               | class_func_ins class_func_in;
class_func_in	: class_func_decl
               | IF '(' class_conds ')' THEN BGIN_THEN class_func_ins END_THEN %prec IFT
               | IF '(' class_conds ')' THEN BGIN_THEN class_func_ins END_THEN ELSE BGIN_ELSE class_func_ins END_ELSE
               | WHILE '(' class_conds ')' BGIN_WHILE class_func_ins END_WHILE
               | L_FOR ind C_FOR ind R_FOR BGIN_FOR class_func_ins END_FOR
               | ID assign class_exp {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                          if (symbol->scope == GLOBAL_VAR_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_VAR_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_VAR_DECL || symbol->scope == VAR_PARAM))) {
                              if (symbol->type == "int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol->type == "float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol->type == "char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol->type == "string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol->type == "bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " does not have the same type as the assigned expression");
                    }   
               }
               | ID '.' ID assign class_exp {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) {
                              if (symbol2->type == "int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol2->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol2->type == "float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol2->type == "char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol2->type == "string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol2->type == "bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class or does not have the same type as the assigned expression";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT assign class_exp {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || (symbol->CLASS == classes + 1 &&
                              symbol->scope == CLASS_ARR_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM))) {
                              if (symbol->type == "array of int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol->type == "array of float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol->type == "array of char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol->type == "array of string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol->type == "array of bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " does not have the same type as the assigned expression");
                    }
               }
               | class_call
               | string '(' class_func1 '$' class_func2 ')'
               | EVAL '(' class_expint ')' { evals.push_back($<intval>3); }
               | RETURN class_exp {
                    bool ok = false;
                    string func_name;
                    string func_type;
                    for (auto it1 : symbol_table) {
                         if (!ok) {
                              for (auto it2 : symbol_table[it1.first]) {
                                   if (!ok && it2.function == functions && it2.scope == CLASS_FUNC_DEF) {
                                        func_name = it1.first;
                                        func_type = it2.type;
                                        if (it2.type.find("int") != string::npos)
                                             if ($<exp_info.type>2 == INT_TYPE || $<exp_info.type>2 == CONST_INT_TYPE) ok = true;
                                        if (it2.type.find("float") != string::npos)
                                             if ($<exp_info.type>2 == INT_TYPE || $<exp_info.type>2 == CONST_INT_TYPE ||
                                                  $<exp_info.type>2 == FLOAT_TYPE || $<exp_info.type>2 == CONST_FLOAT_TYPE) ok = true;
                                        if (it2.type.find("char") != string::npos)
                                             if ($<exp_info.type>2 == CHAR_TYPE) ok = true;
                                        if (it2.type.find("string") != string::npos)
                                             if ($<exp_info.type>2 == STRING_TYPE) ok = true;
                                        if (it2.type.find("bool") != string::npos)
                                             if ($<exp_info.type>2 == BOOL_TYPE) ok = true;
                                   }
                              }
                         }
                    }
                    if (!ok) {
                         NOT_USED(func_name.c_str(), " does not have the same type as the returned expression");
                    }
                    else {
                         add(func_name.c_str(), CLASS_FUNC_RET, func_type.c_str(), 0, classes + 1, functions, 0);
                    }
               }
               ;
class_func_decl: V_INT ID ASSIGN class_func_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_VAR_DECL, $1, $4, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_VAR_DECL, $1, $4, classes, functions, ++assigns);
                    }
               }
               | V_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_VAR_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_VAR_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               | V_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_VAR_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_VAR_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               | V_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_VAR_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_VAR_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               | V_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_VAR_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_VAR_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               | C_INT ID ASSIGN class_func_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_CONST_DECL, $1, $4, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_CONST_DECL, $1, $4, classes, functions, ++assigns);
                    }
               }
               | C_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_CONST_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_CONST_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               | C_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_CONST_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_CONST_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               | C_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_CONST_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_CONST_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               | C_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_CONST_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_CONST_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               | array ID ASSIGN '[' ']' {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, CLASS_FUNC_ARR_DECL, $1, 0, classes, functions, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 ||
                                   (symbol.CLASS == classes && classes > 0 && symbol.scope.find("in class function") == string::npos) ||
                                   symbol.function == functions) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, CLASS_FUNC_ARR_DECL, $1, 0, classes, functions, ++assigns);
                    }
               }
               ;
class_func1    : ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == "string" && (symbol->scope == GLOBAL_VAR_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_VAR_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_VAR_DECL || symbol->scope == VAR_PARAM)))) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    }
               }
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol2->type == "string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) {
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a string variable of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == "array of string" && (symbol->scope == GLOBAL_ARR_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_ARR_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM)))) {
                              break;                        }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    } 
               }
               ;
class_func2    : ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->type == "string" && (symbol->scope == GLOBAL_VAR_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_VAR_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_VAR_DECL || symbol->scope == VAR_PARAM)))) ||
                              (symbol->type == "const string" && (symbol->scope == GLOBAL_CONST_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_CONST_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_CONST_DECL || symbol->scope == VAR_PARAM))))) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
               }
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if ((symbol2->type == "string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) ||
                              (symbol2->type == "const string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_CONST_DECL)) {
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a string member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == "array of string" && (symbol->scope == GLOBAL_ARR_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_ARR_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM)))) {
                              break;                        }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    } 
               }
               | STRING
               ;
main_func_ins	: /*epsilon*/
               | main_func_ins main_func_in;
main_func_in	: main_func_decl
               | IF '(' main_conds ')' THEN BGIN_THEN main_func_ins END_THEN %prec IFT
               | IF '(' main_conds ')' THEN BGIN_THEN main_func_ins END_THEN ELSE BGIN_ELSE main_func_ins END_ELSE
               | WHILE '(' main_conds ')' BGIN_WHILE main_func_ins END_WHILE
               | L_FOR ind C_FOR ind R_FOR BGIN_FOR main_func_ins END_FOR
               | ID assign main_exp {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }                   
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_VAR_DECL || symbol->scope == MAIN_FUNC_VAR_DECL)) {
                              if (symbol->type == "int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol->type == "float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol->type == "char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol->type == "string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol->type == "bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " does not have the same type as the assigned expression");
                    }   
               }
               | ID '.' ID assign main_exp {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL || symbol1->scope == MAIN_FUNC_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) {
                              if (symbol2->type == "int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol2->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol2->type == "float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol2->type == "char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol2->type == "string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol2->type == "bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " does not have the same type as the assigned expression";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT assign main_exp {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || symbol->scope == MAIN_FUNC_ARR_DECL) {
                              if (symbol->type == "array of int" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE)) { 
                                   symbol->value = $<exp_info.value>3;
                                   break;
                              }
                              if (symbol->type == "array of float" && ($<exp_info.type>3 == INT_TYPE || $<exp_info.type>3 == CONST_INT_TYPE ||
                                   $<exp_info.type>3 == FLOAT_TYPE || $<exp_info.type>3 == CONST_FLOAT_TYPE)) break;
                              if (symbol->type == "array of char" && ($<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == CONST_CHAR_TYPE)) break;
                              if (symbol->type == "array of string" && ($<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == CONST_STRING_TYPE)) break;
                              if (symbol->type == "array of bool" && ($<exp_info.type>3 == BOOL_TYPE ||$<exp_info.type>3 == CONST_BOOL_TYPE)) break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " does not have the same type as the assigned expression");
                    } 
               }
               | main_call
               | string '(' main_func1 '$' main_func2 ')'
               | EVAL '(' main_func_expint ')' { evals.push_back($<intval>3); }
               ;
main_func_decl : V_INT ID ASSIGN main_func_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_VAR_DECL, $1, $4, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_VAR_DECL, $1, $4, 0, 0, ++assigns);
                    }
               }
               | V_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | V_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | V_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | V_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_VAR_DECL, $1, 0, 0, 0, ++assigns);
                    }                           
               }
               | C_INT ID ASSIGN main_func_expint {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_CONST_DECL, $1, $4, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_CONST_DECL, $1, $4, 0, 0, ++assigns);
                    }
               }
               | C_FLOAT ID ASSIGN expfloat {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | C_CHAR ID ASSIGN CHAR {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | C_STRING ID ASSIGN STRING {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | C_BOOL ID ASSIGN expbool {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_CONST_DECL, $1, 0, 0, 0, ++assigns);
                    }                           
               }
               | array ID ASSIGN '[' ']' {
                    auto it = symbol_table.find($2);
                    if (it == symbol_table.end()) {
                         add($2, MAIN_FUNC_ARR_DECL, $1, 0, 0, 0, ++assigns);
                    }
                    else {
                         for (auto symbol : symbol_table[$2]) {
                              if (symbol.scope.find("global") == 0 || symbol.scope.find("in main") != string::npos) {
                                   ALREADY_USED($2, it->second[0].line);
                              }
                         }
                         add($2, MAIN_FUNC_ARR_DECL, $1, 0, 0, 0, ++assigns);
                    }
               }
               | CLS ID ID '{' '}' {
                    auto it1 = symbol_table.find($2);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($2, " is not defined");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         types[$2] = $2;
                         add($3, MAIN_FUNC_CLASS_DECL, $2, 0, it1->second[0].CLASS, 0, 0);
                    }
                    else {
                         ALREADY_USED($3, it2->second[0].line);
                    }
               }
               ;
main_func1     : ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == "string" && (symbol->scope == GLOBAL_VAR_DECL || symbol->scope == MAIN_FUNC_VAR_DECL)) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    }
               }
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL || symbol1->scope == MAIN_FUNC_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol2->type == "string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) {
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a string variable of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == "array of string" && (symbol->scope == GLOBAL_ARR_DECL || symbol->scope == MAIN_FUNC_ARR_DECL)) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    } 
               }
               ;
main_func2     : ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->type == "string" && (symbol->scope == GLOBAL_VAR_DECL || symbol->scope == MAIN_FUNC_VAR_DECL)) ||
                              (symbol->type == "const string" && (symbol->scope == GLOBAL_CONST_DECL || symbol->scope == MAIN_FUNC_CONST_DECL))) {
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    }
               }
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL || symbol1->scope == MAIN_FUNC_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if ((symbol2->type == "string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_VAR_DECL) ||
                              (symbol2->type == "const string" && symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_CONST_DECL)) {
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a string member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->type == "array of string" && (symbol->scope == GLOBAL_ARR_DECL || symbol->scope == MAIN_FUNC_ARR_DECL)) {
                              break;                        }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    } 
               }
               | STRING
               ;
global_params  : global_param
               | global_params '$' global_param
               ;
global_param   : array ID {
                    add($2, ARRAY_PARAM, $1, 0, 0, functions + 1, 0);
                    string type($1);
                    params[functions + 1].push_back(types[type]);
               }
               | var ID {
                    add($2, VAR_PARAM, $1, 0, 0, functions + 1, 0);
                    string type($1);
                    params[functions + 1].push_back(types[type]);
               }
               | const ID {
                    add($2, CONST_PARAM, $1, 0, 0, functions + 1, 0);
                    string type($1);
                    params[functions + 1].push_back(types[type]);
               }
               ;
class_params   : class_param
               | class_params '$' class_param
               ;
class_param    : array ID {
                    add($2, ARRAY_PARAM, $1, 0, classes + 1, functions + 1, 0);
                    string type($1);
                    params[functions + 1].push_back(types[type]);
               }
               | var ID {
                    add($2, VAR_PARAM, $1, 0, classes + 1, functions + 1, 0);
                    string type($1);
                    params[functions + 1].push_back(types[type]);
               }
               | const ID {
                    add($2, CONST_PARAM, $1, 0, classes + 1, functions + 1, 0);
                    string type($1);
                    params[functions + 1].push_back(types[type]);
               }
               ;
func_type	     : var
               | const
               ;
var            : V_INT         
               | V_FLOAT                 
               | V_CHAR          
               | V_STRING        
               | V_BOOL           
               ;
const          : C_INT
               | C_FLOAT
               | C_CHAR
               | C_STRING
               | C_BOOL
               ;
array          : A_INT
               | A_FLOAT
               | A_CHAR
               | A_STRING
               | A_BOOL
               ;
ind            : ID
               | NAT
               ;
global_conds   : global_cond
               | global_conds AND global_conds
               | global_conds OR global_conds
               | '(' global_conds ')'
               ;
class_conds    : class_cond
               | class_conds AND class_conds
               | class_conds OR class_conds
               | '(' class_conds ')'
               ;
main_conds     : main_cond
               | main_conds AND main_conds
               | main_conds OR main_conds
               | '(' main_conds ')'
               ;
global_cond    : global_exp EQ global_exp
               | global_exp DIFF global_exp
               | NOT '(' global_exp EQ global_exp ')'
               | NOT '(' global_exp DIFF global_exp ')'
               ;
class_cond     : class_exp EQ class_exp
               | class_exp DIFF class_exp
               | NOT '(' class_exp EQ class_exp ')'
               | NOT '(' class_exp DIFF class_exp ')'
               ;
main_cond      : main_exp EQ main_exp
               | main_exp DIFF main_exp
               | NOT '(' main_exp EQ main_exp ')'
               | NOT '(' main_exp DIFF main_exp ')'
               ;
global_call    : ID '(' ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_FUNC_DEF && params[symbol->function].size() == 0) {
                              if (symbol->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    args.clear();
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared with this signature");
                    }
               }
               | ID '(' global_args ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_FUNC_DEF && params[symbol->function].size() == args.size()) {
                              for (int i = 0; i < params[symbol->function].size(); i++) {
                                   if (params[symbol->function][i] == "int" && args[i] != INT_TYPE && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "float" && args[i] != FLOAT_TYPE&& args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "char" && args[i] != CHAR_TYPE && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "string" && args[i] != STRING_TYPE && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "bool" && args[i] != BOOL_TYPE && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const int" && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const float" && args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const char" && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const string" && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const bool" && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of int" && args[i] != ARRAY_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of float" && args[i] != ARRAY_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of char" && args[i] != ARRAY_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of string" && args[i] != ARRAY_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of bool" && args[i] != ARRAY_BOOL_TYPE) NOT_SAME_SIGNATURE;
                              }
                              args.clear();
                              if (symbol->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared with this signature");
                    }
               }
               | ID '.' ID '(' ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_FUNC_DEF && params[symbol2->function].size() == 0) {
                              if (symbol2->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    args.clear();
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '.' ID '(' global_args ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_FUNC_DEF && params[symbol2->function].size() == args.size()) {
                              for (int i = 0; i < params[symbol2->function].size(); i++) {
                                   if (params[symbol2->function][i] == "int" && args[i] != INT_TYPE && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "float" && args[i] != FLOAT_TYPE&& args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "char" && args[i] != CHAR_TYPE && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "string" && args[i] != STRING_TYPE && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "bool" && args[i] != BOOL_TYPE && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const int" && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const float" && args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const char" && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const string" && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const bool" && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of int" && args[i] != ARRAY_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of float" && args[i] != ARRAY_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of char" && args[i] != ARRAY_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of string" && args[i] != ARRAY_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of bool" && args[i] != ARRAY_BOOL_TYPE) NOT_SAME_SIGNATURE;
                              }
                              args.clear();
                              if (symbol2->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               ;
class_call     : ID '(' ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_FUNC_DEF || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_FUNC_DEF)) && params[symbol->function].size() == 0) {
                              if (symbol->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    args.clear();
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared with this signature");
                    }
               }
               | ID '(' class_args ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_FUNC_DEF || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_FUNC_DEF)) && params[symbol->function].size() == args.size()) {
                              for (int i = 0; i < params[symbol->function].size(); i++) {
                                   if (params[symbol->function][i] == "int" && args[i] != INT_TYPE && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "float" && args[i] != FLOAT_TYPE&& args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "char" && args[i] != CHAR_TYPE && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "string" && args[i] != STRING_TYPE && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "bool" && args[i] != BOOL_TYPE && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const int" && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const float" && args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const char" && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const string" && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const bool" && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of int" && args[i] != ARRAY_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of float" && args[i] != ARRAY_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of char" && args[i] != ARRAY_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of string" && args[i] != ARRAY_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of bool" && args[i] != ARRAY_BOOL_TYPE) NOT_SAME_SIGNATURE;
                              }
                              args.clear();
                              if (symbol->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared with this signature");
                    }
               }
               | ID '.' ID '(' ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_FUNC_DEF && params[symbol2->function].size() == 0) {
                              if (symbol2->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    args.clear();
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '.' ID '(' class_args ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_FUNC_DEF && params[symbol2->function].size() == args.size()) {
                              for (int i = 0; i < params[symbol2->function].size(); i++) {
                                   if (params[symbol2->function][i] == "int" && args[i] != INT_TYPE && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "float" && args[i] != FLOAT_TYPE&& args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "char" && args[i] != CHAR_TYPE && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "string" && args[i] != STRING_TYPE && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "bool" && args[i] != BOOL_TYPE && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const int" && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const float" && args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const char" && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const string" && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const bool" && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of int" && args[i] != ARRAY_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of float" && args[i] != ARRAY_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of char" && args[i] != ARRAY_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of string" && args[i] != ARRAY_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of bool" && args[i] != ARRAY_BOOL_TYPE) NOT_SAME_SIGNATURE;
                              }
                              args.clear();
                              if (symbol2->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               ;
main_call      : ID '(' ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_FUNC_DEF && params[symbol->function].size() == 0) {
                              if (symbol->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    args.clear();
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared with this signature");
                    }
               }
               | ID '(' main_args ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_FUNC_DEF && params[symbol->function].size() == args.size()) {                              
                              for (int i = 0; i < params[symbol->function].size(); i++) {
                                   if (params[symbol->function][i] == "int" && args[i] != INT_TYPE && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "float" && args[i] != FLOAT_TYPE&& args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "char" && args[i] != CHAR_TYPE && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "string" && args[i] != STRING_TYPE && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "bool" && args[i] != BOOL_TYPE && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const int" && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const float" && args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const char" && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const string" && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "const bool" && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of int" && args[i] != ARRAY_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of float" && args[i] != ARRAY_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of char" && args[i] != ARRAY_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of string" && args[i] != ARRAY_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol->function][i] == "array of bool" && args[i] != ARRAY_BOOL_TYPE) NOT_SAME_SIGNATURE;
                              }
                              args.clear();
                              if (symbol->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared with this signature");
                    }

               }
               | ID '.' ID '(' ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL || symbol1->scope == MAIN_FUNC_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_FUNC_DEF && params[symbol2->function].size() == 0) {
                              if (symbol2->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    args.clear();
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '.' ID '(' class_args ')' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL || symbol1->scope == MAIN_FUNC_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_FUNC_DEF && params[symbol2->function].size() == args.size()) {
                              for (int i = 0; i < params[symbol2->function].size(); i++) {
                                   if (params[symbol2->function][i] == "int" && args[i] != INT_TYPE && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "float" && args[i] != FLOAT_TYPE&& args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "char" && args[i] != CHAR_TYPE && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "string" && args[i] != STRING_TYPE && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "bool" && args[i] != BOOL_TYPE && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const int" && args[i] != CONST_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const float" && args[i] != CONST_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const char" && args[i] != CONST_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const string" && args[i] != CONST_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "const bool" && args[i] != CONST_BOOL_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of int" && args[i] != ARRAY_INT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of float" && args[i] != ARRAY_FLOAT_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of char" && args[i] != ARRAY_CHAR_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of string" && args[i] != ARRAY_STRING_TYPE) NOT_SAME_SIGNATURE;
                                   if (params[symbol2->function][i] == "array of bool" && args[i] != ARRAY_BOOL_TYPE) NOT_SAME_SIGNATURE;
                              }
                              args.clear();
                              if (symbol2->type == "int") { $$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               ;
string         : CPY
               | CAT
               ;
global_args    : ID '[' ']' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || symbol->scope == GLOBAL_FUNC_ARR_DECL) {
                              if (symbol->type == "array of int") { args.push_back(ARRAY_INT_TYPE); break; }
                              if (symbol->type == "array of float") { args.push_back(ARRAY_FLOAT_TYPE); break; }
                              if (symbol->type == "array of char") { args.push_back(ARRAY_CHAR_TYPE); break; }
                              if (symbol->type == "array of string") { args.push_back(ARRAY_STRING_TYPE); break; }
                              if (symbol->type == "array of bool") { args.push_back(ARRAY_BOOL_TYPE); break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
               }
               | ID '.' ID '[' ']' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_ARR_DECL) {
                              if (symbol2->type == "array of int") { args.push_back(ARRAY_INT_TYPE); break; }
                              if (symbol2->type == "array of float") { args.push_back(ARRAY_FLOAT_TYPE); break; }
                              if (symbol2->type == "array of char") { args.push_back(ARRAY_CHAR_TYPE); break; }
                              if (symbol2->type == "array of string") { args.push_back(ARRAY_STRING_TYPE); break; }
                              if (symbol2->type == "array of bool") { args.push_back(ARRAY_BOOL_TYPE); break; }
                         }
                    }
                    if (symbol2 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
               }
               | global_exp                            { args.push_back($<exp_info.type>1); }
               | global_args '$' ID '[' ']'            { args.push_back($<exp_info.type>3); }
               | global_args '$' ID '.' ID '[' ']'     { args.push_back($<exp_info.type>5); }
               | global_args '$' global_exp            { args.push_back($<exp_info.type>3); }
               ;
class_args     : ID '[' ']' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || symbol->scope == CLASS_ARR_DECL || symbol->scope == CLASS_FUNC_ARR_DECL) {
                              if (symbol->type == "array of int") { args.push_back(ARRAY_INT_TYPE); break; }
                              if (symbol->type == "array of float") { args.push_back(ARRAY_FLOAT_TYPE); break; }
                              if (symbol->type == "array of char") { args.push_back(ARRAY_CHAR_TYPE); break; }
                              if (symbol->type == "array of string") { args.push_back(ARRAY_STRING_TYPE); break; }
                              if (symbol->type == "array of bool") { args.push_back(ARRAY_BOOL_TYPE); break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    }
               }
               | ID '.' ID '[' ']' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_ARR_DECL) {
                              if (symbol2->type == "array of int") { args.push_back(ARRAY_INT_TYPE); break; }
                              if (symbol2->type == "array of float") { args.push_back(ARRAY_FLOAT_TYPE); break; }
                              if (symbol2->type == "array of char") { args.push_back(ARRAY_CHAR_TYPE); break; }
                              if (symbol2->type == "array of string") { args.push_back(ARRAY_STRING_TYPE); break; }
                              if (symbol2->type == "array of bool") { args.push_back(ARRAY_BOOL_TYPE); break; }
                         }
                    }
                    if (symbol2 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    }
               }
               | class_exp                             { args.push_back($<exp_info.type>1); }
               | class_args '$' ID '[' ']'             { args.push_back($<exp_info.type>3); }
               | class_args '$' ID '.' ID '[' ']'      { args.push_back($<exp_info.type>5); }
               | class_args '$' class_exp              { args.push_back($<exp_info.type>3); }
               ;
main_args      : ID '[' ']' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || symbol->scope == MAIN_FUNC_ARR_DECL) {
                              if (symbol->type == "array of int") { args.push_back(ARRAY_INT_TYPE); break; }
                              if (symbol->type == "array of float") { args.push_back(ARRAY_FLOAT_TYPE); break; }
                              if (symbol->type == "array of char") { args.push_back(ARRAY_CHAR_TYPE); break; }
                              if (symbol->type == "array of string") { args.push_back(ARRAY_STRING_TYPE); break; }
                              if (symbol->type == "array of bool") { args.push_back(ARRAY_BOOL_TYPE); break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    }
               }
               | ID '.' ID '[' ']' {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL || symbol1->scope == MAIN_FUNC_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && symbol2->scope == CLASS_ARR_DECL) {
                              if (symbol2->type == "array of int") { args.push_back(ARRAY_INT_TYPE); break; }
                              if (symbol2->type == "array of float") { args.push_back(ARRAY_FLOAT_TYPE); break; }
                              if (symbol2->type == "array of char") { args.push_back(ARRAY_CHAR_TYPE); break; }
                              if (symbol2->type == "array of string") { args.push_back(ARRAY_STRING_TYPE); break; }
                              if (symbol2->type == "array of bool") { args.push_back(ARRAY_BOOL_TYPE); break; }
                         }
                    }
                    if (symbol2 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not accesible");
                    }
               }
               | main_exp                              { args.push_back($<exp_info.type>1); }
               | main_args '$' ID '[' ']'              { args.push_back($<exp_info.type>3); }
               | main_args '$' ID '.' ID '[' ']'       { args.push_back($<exp_info.type>5); }
               | main_args '$' main_exp                { args.push_back($<exp_info.type>3); }
               ;
assign         : ASSIGN
               | COMP_ASSIGN
               ;
global_exp     : global_call  {
                    $<exp_info.type>$ = $1;
                    $<exp_info.value>$ = 0;
               }
               | BIT_COMPL global_exp { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ~ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = ~$<exp_info.value>2;
                    }
               }
              | INC global_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ++ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>1;
                         $<exp_info.value>$ = $<exp_info.value>1 + 1;
                    }
               }
               | DEC global_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE) {
                         NOT_ALLOWED("can not use -- on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>1;
                         $<exp_info.value>$ = $<exp_info.value>1 - 1;
                    }
               }
               | global_exp INC { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ++ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = $<exp_info.value>2 + 1;
                    }
               }
               | global_exp DEC { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use -- on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = $<exp_info.value>2 - 1;
                    }
               }
               | global_exp BIT_OR global_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use | on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use | between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 | $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | global_exp BIT_AND global_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use & on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use & between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 & $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | global_exp BIT_XOR global_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ^ on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use ^ between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 ^ $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | global_exp BIT_SHIFT global_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use << or >> on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use << or >> between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        if ($2 == "<<") {
                                             $<exp_info.value>$ = $<exp_info.value>1 << $<exp_info.value>3;
                                        }
                                        else {
                                             if ($2 == ">>") {
                                                  $<exp_info.value>$ = $<exp_info.value>1 >> $<exp_info.value>3;
                                             }
                                        }
                                   }
                              }
                         }
                    } 
               }
               | global_exp ARITP global_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE || $<exp_info.type>1 == BOOL_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == BOOL_TYPE) {
                         NOT_ALLOWED("can not use + or - on char, string or bool");
                    }
                    else {
                         if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>3 == FLOAT_TYPE) {
                              $<exp_info.type>$ = FLOAT_TYPE;
                              $<exp_info.value>$ = 0;
                         }
                         else {
                              $<exp_info.type>$ = INT_TYPE;
                              if ($2 == '+') {
                                   $<exp_info.value>$ = $<exp_info.value>1 + $<exp_info.value>3;
                              }
                              else {
                                   if ($2 == '-') {
                                        $<exp_info.value>$ = $<exp_info.value>1 - $<exp_info.value>3;
                                   }
                              }
                         }
                    }
               }
               | global_exp ARITO global_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE || $<exp_info.type>1 == BOOL_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == BOOL_TYPE) {
                         NOT_ALLOWED("can not use *, / or % on char, string or bool");
                    }
                    else {
                         if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>3 == FLOAT_TYPE) {
                              $<exp_info.type>$ = FLOAT_TYPE;
                              $<exp_info.value>$ = 0;
                         }
                         else {
                              $<exp_info.type>$ = INT_TYPE;
                              if ($2 == '*') {
                                   $<exp_info.value>$ = $<exp_info.value>1 * $<exp_info.value>3;
                              }
                              else {
                                   if ($2 == '/') {
                                        $<exp_info.value>$ = $<exp_info.value>1 / $<exp_info.value>3;
                                   }
                                   else {
                                        if ($2 == '%') {
                                             $<exp_info.value>$ = $<exp_info.value>1 % $<exp_info.value>3;
                                        }
                                   }
                              }
                         }
                    }
               }
               | '(' global_exp ')' {
                    $<exp_info.type>$ = $<exp_info.type>2;
                    $<exp_info.value>$ = $<exp_info.value>2;
               }
               | NAT     { $<exp_info.type>$ = INT_TYPE; $<exp_info.value>$ = $1; }
               | INT     { $<exp_info.type>$ = INT_TYPE; $<exp_info.value>$ = $1; }
               | FLOAT   { $<exp_info.type>$ = FLOAT_TYPE; $<exp_info.value>$ = 0; }
               | CHAR    { $<exp_info.type>$ = CHAR_TYPE; $<exp_info.value>$ = 0; }
               | STRING  { $<exp_info.type>$ = STRING_TYPE; $<exp_info.value>$ = 0; }
               | TRUE    { $<exp_info.type>$ = BOOL_TYPE; $<exp_info.value>$ = 0; }
               | FALSE   { $<exp_info.type>$ = BOOL_TYPE; $<exp_info.value>$ = 0; }
               | ID {   
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    else {
                         bool OK = false;
                         for (auto symbol : symbol_table[$1]) {
                              if (symbol.scope == GLOBAL_VAR_DECL || symbol.scope == GLOBAL_CONST_DECL ||
                                   (symbol.function == functions && (symbol.scope == GLOBAL_FUNC_VAR_DECL || symbol.scope == GLOBAL_FUNC_CONST_DECL ||
                                   symbol.scope == VAR_PARAM || symbol.scope == CONST_PARAM))) {
                                   OK = true;
                                   $<exp_info.value>$ = symbol.value;
                                   if (symbol.type == "int") { $<exp_info.type>$ = INT_TYPE; break; }
                                   if (symbol.type == "float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                                   if (symbol.type == "char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                                   if (symbol.type == "string") { $<exp_info.type>$ = STRING_TYPE; break; }
                                   if (symbol.type == "bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                                   if (symbol.type == "const int") { $<exp_info.type>$ = CONST_INT_TYPE; break; }
                                   if (symbol.type == "const float") { $<exp_info.type>$ = CONST_FLOAT_TYPE; break; }
                                   if (symbol.type == "const char") { $<exp_info.type>$ = CONST_CHAR_TYPE; break; }
                                   if (symbol.type == "const string") { $<exp_info.type>$ = CONST_STRING_TYPE; break; }
                                   if (symbol.type == "const bool") { $<exp_info.type>$ = CONST_BOOL_TYPE; break; }
                              }
                         }
                         if (!OK) {
                              NOT_USED($1, " is not accesible");
                         }
                    }
               } 
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && (symbol2->scope == CLASS_VAR_DECL || symbol2->scope == CLASS_CONST_DECL)) {
                              $<exp_info.value>$ = symbol2->value;
                              if (symbol2->type == "int") { $<exp_info.type>$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $<exp_info.type>$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $<exp_info.type>$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $<exp_info.type>$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $<exp_info.type>$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $<exp_info.type>$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $<exp_info.type>$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT  {   
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM))) {
                              $<exp_info.value>$ = 0;
                              if (symbol->type == "array of int") { $<exp_info.type>$ = INT_TYPE; break; }
                              if (symbol->type == "array of float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                              if (symbol->type == "array of char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                              if (symbol->type == "array of string") { $<exp_info.type>$ = STRING_TYPE; break; }
                              if (symbol->type == "array of bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " is not accesible");
                    }
               } 
               ;
class_exp      : class_call  {
                    $<exp_info.type>$ = $1;
                    $<exp_info.value>$ = 0;
               }
               | BIT_COMPL class_exp { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ~ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = ~$<exp_info.value>2;
                    }
               }
              | INC class_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ++ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>1;
                         $<exp_info.value>$ = $<exp_info.value>1 + 1;
                    }
               }
               | DEC class_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE) {
                         NOT_ALLOWED("can not use -- on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>1;
                         $<exp_info.value>$ = $<exp_info.value>1 - 1;
                    }
               }
               | class_exp INC { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ++ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = $<exp_info.value>2 + 1;
                    }
               }
               | class_exp DEC { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use -- on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = $<exp_info.value>2 - 1;
                    }
               }
               | class_exp BIT_OR class_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use | on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use | between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 | $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | class_exp BIT_AND class_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use & on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use & between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 & $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | class_exp BIT_XOR class_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ^ on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use ^ between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 ^ $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | class_exp BIT_SHIFT class_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use << or >> on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use << or >> between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        if ($2 == "<<") {
                                             $<exp_info.value>$ = $<exp_info.value>1 << $<exp_info.value>3;
                                        }
                                        else {
                                             if ($2 == ">>") {
                                                  $<exp_info.value>$ = $<exp_info.value>1 >> $<exp_info.value>3;
                                             }
                                        }
                                   }
                              }
                         }
                    } 
               }
               | class_exp ARITP class_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE || $<exp_info.type>1 == BOOL_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == BOOL_TYPE) {
                         NOT_ALLOWED("can not use + or - on char, string or bool");
                    }
                    else {
                         if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>3 == FLOAT_TYPE) {
                              $<exp_info.type>$ = FLOAT_TYPE;
                              $<exp_info.value>$ = 0;
                         }
                         else {
                              $<exp_info.type>$ = INT_TYPE;
                              if ($2 == '+') {
                                   $<exp_info.value>$ = $<exp_info.value>1 + $<exp_info.value>3;
                              }
                              else {
                                   if ($2 == '-') {
                                        $<exp_info.value>$ = $<exp_info.value>1 - $<exp_info.value>3;
                                   }
                              }
                         }
                    }
               }
               | class_exp ARITO class_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE || $<exp_info.type>1 == BOOL_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == BOOL_TYPE) {
                         NOT_ALLOWED("can not use *, / or % on char, string or bool");
                    }
                    else {
                         if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>3 == FLOAT_TYPE) {
                              $<exp_info.type>$ = FLOAT_TYPE;
                              $<exp_info.value>$ = 0;
                         }
                         else {
                              $<exp_info.type>$ = INT_TYPE;
                              if ($2 == '*') {
                                   $<exp_info.value>$ = $<exp_info.value>1 * $<exp_info.value>3;
                              }
                              else {
                                   if ($2 == '/') {
                                        $<exp_info.value>$ = $<exp_info.value>1 / $<exp_info.value>3;
                                   }
                                   else {
                                        if ($2 == '%') {
                                             $<exp_info.value>$ = $<exp_info.value>1 % $<exp_info.value>3;
                                        }
                                   }
                              }
                         }
                    }
               }
               | '(' class_exp ')' {
                    $<exp_info.type>$ = $<exp_info.type>2;
                    $<exp_info.value>$ = $<exp_info.value>2;
               }
               | NAT     { $<exp_info.type>$ = INT_TYPE; $<exp_info.value>$ = $1; }
               | INT     { $<exp_info.type>$ = INT_TYPE; $<exp_info.value>$ = $1; }
               | FLOAT   { $<exp_info.type>$ = FLOAT_TYPE; $<exp_info.value>$ = 0; }
               | CHAR    { $<exp_info.type>$ = CHAR_TYPE; $<exp_info.value>$ = 0; }
               | STRING  { $<exp_info.type>$ = STRING_TYPE; $<exp_info.value>$ = 0; }
               | TRUE    { $<exp_info.type>$ = BOOL_TYPE; $<exp_info.value>$ = 0; }
               | FALSE   { $<exp_info.type>$ = BOOL_TYPE; $<exp_info.value>$ = 0; }
               | ID {   
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    else {
                         bool OK = false;
                         for (auto symbol : symbol_table[$1]) {
                              if (symbol.scope == GLOBAL_VAR_DECL || symbol.scope == GLOBAL_CONST_DECL ||
                                   (symbol.CLASS == classes && (symbol.scope == CLASS_VAR_DECL || symbol.scope == CLASS_CONST_DECL) ||
                                   (symbol.function == functions && (symbol.scope == CLASS_FUNC_VAR_DECL || symbol.scope == CLASS_FUNC_CONST_DECL ||
                                   symbol.scope == VAR_PARAM || symbol.scope == CONST_PARAM)))) {
                                   OK = true;
                                   $<exp_info.value>$ = symbol.value;
                                   if (symbol.type == "int") { $<exp_info.type>$ = INT_TYPE; break; }
                                   if (symbol.type == "float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                                   if (symbol.type == "char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                                   if (symbol.type == "string") { $<exp_info.type>$ = STRING_TYPE; break; }
                                   if (symbol.type == "bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                                   if (symbol.type == "const int") { $<exp_info.type>$ = CONST_INT_TYPE; break; }
                                   if (symbol.type == "const float") { $<exp_info.type>$ = CONST_FLOAT_TYPE; break; }
                                   if (symbol.type == "const char") { $<exp_info.type>$ = CONST_CHAR_TYPE; break; }
                                   if (symbol.type == "const string") { $<exp_info.type>$ = CONST_STRING_TYPE; break; }
                                   if (symbol.type == "const bool") { $<exp_info.type>$ = CONST_BOOL_TYPE; break; }
                              }
                         }
                         if (!OK) {
                              NOT_USED($1, " is not accesible");
                         }
                    }
               } 
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && (symbol2->scope == CLASS_VAR_DECL || symbol2->scope == CLASS_CONST_DECL)) {
                              $<exp_info.value>$ = symbol2->value;
                              if (symbol2->type == "int") { $<exp_info.type>$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $<exp_info.type>$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $<exp_info.type>$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $<exp_info.type>$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $<exp_info.type>$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $<exp_info.type>$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $<exp_info.type>$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT  {   
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_ARR_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM))) {
                              $<exp_info.value>$ = 0;
                              if (symbol->type == "array of int") { $<exp_info.type>$ = INT_TYPE; break; }
                              if (symbol->type == "array of float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                              if (symbol->type == "array of char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                              if (symbol->type == "array of string") { $<exp_info.type>$ = STRING_TYPE; break; }
                              if (symbol->type == "array of bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " is not accesible");
                    }
               } 
               ;
main_exp       : main_call  {
                    $<exp_info.type>$ = $1;
                    $<exp_info.value>$ = 0;
               }
               | BIT_COMPL main_exp { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ~ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = ~$<exp_info.value>2;
                    }
               }
              | INC main_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ++ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>1;
                         $<exp_info.value>$ = $<exp_info.value>1 + 1;
                    }
               }
               | DEC main_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE) {
                         NOT_ALLOWED("can not use -- on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>1;
                         $<exp_info.value>$ = $<exp_info.value>1 - 1;
                    }
               }
               | main_exp INC { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ++ on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = $<exp_info.value>2 + 1;
                    }
               }
               | main_exp DEC { 
                    if ($<exp_info.type>2 == CHAR_TYPE || $<exp_info.type>2 == STRING_TYPE) {
                         NOT_ALLOWED("can not use -- on char or string");
                    }
                    else {
                         $<exp_info.type>$ = $<exp_info.type>2;
                         $<exp_info.value>$ = $<exp_info.value>2 - 1;
                    }
               }
               | main_exp BIT_OR main_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use | on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use | between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 | $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | main_exp BIT_AND main_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use & on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use & between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 & $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | main_exp BIT_XOR main_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use ^ on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use ^ between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        $<exp_info.value>$ = $<exp_info.value>1 ^ $<exp_info.value>3;
                                   }
                              }
                         }
                    } 
               }
               | main_exp BIT_SHIFT main_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE) {
                         NOT_ALLOWED("can not use << or >> on char or string");
                    }
                    else {
                         if (($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>1 != $<exp_info.type>3) ||
                              ($<exp_info.type>1 != $<exp_info.type>3 && $<exp_info.type>3 == BOOL_TYPE)) {
                              NOT_ALLOWED("can not use << or >> between different types");
                         }
                         else {
                              if ($<exp_info.type>1 == BOOL_TYPE && $<exp_info.type>3 == BOOL_TYPE) {
                                   $<exp_info.type>$ = BOOL_TYPE;
                                   $<exp_info.value>$ = 0;
                              }
                              else {
                                   if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>1 == FLOAT_TYPE) {
                                        $<exp_info.type>$ = FLOAT_TYPE;
                                        $<exp_info.value>$ = 0;
                                   }
                                   else {
                                        $<exp_info.type>$ = INT_TYPE;
                                        if ($2 == "<<") {
                                             $<exp_info.value>$ = $<exp_info.value>1 << $<exp_info.value>3;
                                        }
                                        else {
                                             if ($2 == ">>") {
                                                  $<exp_info.value>$ = $<exp_info.value>1 >> $<exp_info.value>3;
                                             }
                                        }
                                   }
                              }
                         }
                    } 
               }
               | main_exp ARITP main_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE || $<exp_info.type>1 == BOOL_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == BOOL_TYPE) {
                         NOT_ALLOWED("can not use + or - on char, string or bool");
                    }
                    else {
                         if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>3 == FLOAT_TYPE) {
                              $<exp_info.type>$ = FLOAT_TYPE;
                              $<exp_info.value>$ = 0;
                         }
                         else {
                              $<exp_info.type>$ = INT_TYPE;
                              if ($2 == '+') {
                                   $<exp_info.value>$ = $<exp_info.value>1 + $<exp_info.value>3;
                              }
                              else {
                                   if ($2 == '-') {
                                        $<exp_info.value>$ = $<exp_info.value>1 - $<exp_info.value>3;
                                   }
                              }
                         }
                    }
               }
               | main_exp ARITO main_exp { 
                    if ($<exp_info.type>1 == CHAR_TYPE || $<exp_info.type>1 == STRING_TYPE || $<exp_info.type>1 == BOOL_TYPE ||
                         $<exp_info.type>3 == CHAR_TYPE || $<exp_info.type>3 == STRING_TYPE || $<exp_info.type>3 == BOOL_TYPE) {
                         NOT_ALLOWED("can not use *, / or % on char, string or bool");
                    }
                    else {
                         if ($<exp_info.type>1 == FLOAT_TYPE || $<exp_info.type>3 == FLOAT_TYPE) {
                              $<exp_info.type>$ = FLOAT_TYPE;
                              $<exp_info.value>$ = 0;
                         }
                         else {
                              $<exp_info.type>$ = INT_TYPE;
                              if ($2 == '*') {
                                   $<exp_info.value>$ = $<exp_info.value>1 * $<exp_info.value>3;
                              }
                              else {
                                   if ($2 == '/') {
                                        $<exp_info.value>$ = $<exp_info.value>1 / $<exp_info.value>3;
                                   }
                                   else {
                                        if ($2 == '%') {
                                             $<exp_info.value>$ = $<exp_info.value>1 % $<exp_info.value>3;
                                        }
                                   }
                              }
                         }
                    }
               }
               | '(' main_exp ')' {
                    $<exp_info.type>$ = $<exp_info.type>2;
                    $<exp_info.value>$ = $<exp_info.value>2;
               }
               | NAT     { $<exp_info.type>$ = INT_TYPE; $<exp_info.value>$ = $1; }
               | INT     { $<exp_info.type>$ = INT_TYPE; $<exp_info.value>$ = $1; }
               | FLOAT   { $<exp_info.type>$ = FLOAT_TYPE; $<exp_info.value>$ = 0; }
               | CHAR    { $<exp_info.type>$ = CHAR_TYPE; $<exp_info.value>$ = 0; }
               | STRING  { $<exp_info.type>$ = STRING_TYPE; $<exp_info.value>$ = 0; }
               | TRUE    { $<exp_info.type>$ = BOOL_TYPE; $<exp_info.value>$ = 0; }
               | FALSE   { $<exp_info.type>$ = BOOL_TYPE; $<exp_info.value>$ = 0; }
               | ID {   
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    else {
                         bool OK = false;
                         for (auto symbol : symbol_table[$1]) {
                              if (symbol.scope == GLOBAL_VAR_DECL || symbol.scope == GLOBAL_CONST_DECL ||
                                   symbol.scope == MAIN_FUNC_VAR_DECL || symbol.scope == MAIN_FUNC_CONST_DECL) {
                                   OK = true;
                                   $<exp_info.value>$ = symbol.value;
                                   if (symbol.type == "int") { $<exp_info.type>$ = INT_TYPE; break; }
                                   if (symbol.type == "float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                                   if (symbol.type == "char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                                   if (symbol.type == "string") { $<exp_info.type>$ = STRING_TYPE; break; }
                                   if (symbol.type == "bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                                   if (symbol.type == "const int") { $<exp_info.type>$ = CONST_INT_TYPE; break; }
                                   if (symbol.type == "const float") { $<exp_info.type>$ = CONST_FLOAT_TYPE; break; }
                                   if (symbol.type == "const char") { $<exp_info.type>$ = CONST_CHAR_TYPE; break; }
                                   if (symbol.type == "const string") { $<exp_info.type>$ = CONST_STRING_TYPE; break; }
                                   if (symbol.type == "const bool") { $<exp_info.type>$ = CONST_BOOL_TYPE; break; }
                              }
                         }
                         if (!OK) {
                              NOT_USED($1, " is not accesible");
                         }
                    }
               } 
               | ID '.' ID {
                    auto it1 = symbol_table.find($1);
                    if (it1 == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL || symbol1->scope == MAIN_FUNC_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if (symbol1->CLASS == symbol2->CLASS && (symbol2->scope == CLASS_VAR_DECL || symbol2->scope == CLASS_CONST_DECL)) {
                              $<exp_info.value>$ = symbol2->value;
                              if (symbol2->type == "int") { $<exp_info.type>$ = INT_TYPE; break; }
                              if (symbol2->type == "float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                              if (symbol2->type == "char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                              if (symbol2->type == "string") { $<exp_info.type>$ = STRING_TYPE; break; }
                              if (symbol2->type == "bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                              if (symbol2->type == "const int") { $<exp_info.type>$ = CONST_INT_TYPE; break; }
                              if (symbol2->type == "const float") { $<exp_info.type>$ = CONST_FLOAT_TYPE; break; }
                              if (symbol2->type == "const char") { $<exp_info.type>$ = CONST_CHAR_TYPE; break; }
                              if (symbol2->type == "const string") { $<exp_info.type>$ = CONST_STRING_TYPE; break; }
                              if (symbol2->type == "const bool") { $<exp_info.type>$ = CONST_BOOL_TYPE; break; }
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT  {   
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL || symbol->scope == MAIN_FUNC_ARR_DECL) {
                              $<exp_info.value>$ = 0;
                              if (symbol->type == "array of int") { $<exp_info.type>$ = INT_TYPE; break; }
                              if (symbol->type == "array of float") { $<exp_info.type>$ = FLOAT_TYPE; break; }
                              if (symbol->type == "array of char") { $<exp_info.type>$ = CHAR_TYPE; break; }
                              if (symbol->type == "array of string") { $<exp_info.type>$ = STRING_TYPE; break; }
                              if (symbol->type == "array of bool") { $<exp_info.type>$ = BOOL_TYPE; break; }
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " is not accesible");
                    }
               } 
               ;
global_expint  : BIT_COMPL global_expint                    { $$ = ~$2; }
               | INC global_expint                          { $$ = $2 + 1; }
               | DEC global_expint                          { $$ = $2 - 1; }
               | global_expint INC                          { $$ = $1 + 1; }
               | global_expint DEC                          { $$ = $1 - 1; }
               | global_expint BIT_SHIFT global_expint      { $2 == ">>" ? $$ = $1 >> $3 : $$ = $1 << $3; }
               | global_expint BIT_OR global_expint         { $$ = $1 | $3; }
               | global_expint BIT_AND global_expint        { $$ = $1 & $3; }
               | global_expint BIT_XOR global_expint        { $$ = $1 ^ $3; }
               | global_expint ARITP global_expint          { if ($2 == '+') $$ = $1 + $3; else $$ = $1 - $3; }
               | global_expint ARITO global_expint          { if ($2 == '*') $$ = $1 * $3; else if ($2 == '/') $$ = $1 / $3; else $$ = $1 % $3; }               
               | '(' global_expint ')'                      { $$ = $2; }
               | NAT                                        { $$ = $1; }
               | INT                                        { $$ = $1; }
               | ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_VAR_DECL || symbol->scope == GLOBAL_CONST_DECL) &&
                              symbol->type.find("int") != string::npos) {
                              $$ = symbol->value;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " has not type int");
                    }
               }
               | ID '.' ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if ((symbol1->CLASS == symbol2->CLASS && (symbol2->scope == CLASS_VAR_DECL || symbol2->scope == CLASS_CONST_DECL)) &&
                              symbol2->type.find("int") != string::npos) {
                              $$ = symbol2->value;
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if (symbol->scope == GLOBAL_ARR_DECL && symbol->type.find("array of int") != string::npos) {
                              $$ = 0;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " has not type int");
                    }
               }
               ;
global_func_expint: BIT_COMPL global_func_expint                 { $$ = ~$2; }
               | INC global_func_expint                          { $$ = $2 + 1; }
               | DEC global_func_expint                          { $$ = $2 - 1; }
               | global_func_expint INC                          { $$ = $1 + 1; }
               | global_func_expint DEC                          { $$ = $1 - 1; }
               | global_func_expint BIT_SHIFT global_func_expint { $2 == ">>" ? $$ = $1 >> $3 : $$ = $1 << $3; }
               | global_func_expint BIT_OR global_func_expint    { $$ = $1 | $3; }
               | global_func_expint BIT_AND global_func_expint   { $$ = $1 & $3; }
               | global_func_expint BIT_XOR global_func_expint   { $$ = $1 ^ $3; }
               | global_func_expint ARITP global_func_expint     { if ($2 == '+') $$ = $1 + $3; else $$ = $1 - $3; }
               | global_func_expint ARITO global_func_expint     { if ($2 == '*') $$ = $1 * $3; else if ($2 == '/') $$ = $1 / $3; else $$ = $1 % $3; }               
               | '(' global_func_expint ')'                      { $$ = $2; }
               | NAT                                             { $$ = $1; }
               | INT                                             { $$ = $1; }
               | ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_VAR_DECL || symbol->scope == GLOBAL_CONST_DECL ||
                              (symbol->function == functions && (symbol->scope == GLOBAL_FUNC_VAR_DECL || symbol->scope == GLOBAL_FUNC_CONST_DECL ||
                              symbol->scope == VAR_PARAM || symbol->scope == CONST_PARAM))) &&
                              symbol->type.find("int") != string::npos) {
                              $$ = symbol->value;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " has not type int");
                    }
               }
               | ID '.' ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if ((symbol1->CLASS == symbol2->CLASS && (symbol2->scope == CLASS_VAR_DECL || symbol2->scope == CLASS_CONST_DECL)) &&
                              symbol2->type.find("int") != string::npos) {
                              $$ = symbol2->value;
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_ARR_DECL || (symbol->function == functions &&
                              (symbol->scope == GLOBAL_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM))) &&
                              symbol->type.find("array of int") != string::npos) {
                              $$ = 0;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " has not type int");
                    }
               }
               ;
class_expint   : BIT_COMPL class_expint                     { $$ = ~$2; }
               | INC class_expint                           { $$ = $2 + 1; }
               | DEC class_expint                           { $$ = $2 - 1; }
               | class_expint INC                           { $$ = $1 + 1; }
               | class_expint DEC                           { $$ = $1 - 1; }
               | class_expint BIT_SHIFT class_expint        { $2 == ">>" ? $$ = $1 >> $3 : $$ = $1 << $3; }
               | class_expint BIT_OR class_expint           { $$ = $1 | $3; }
               | class_expint BIT_AND class_expint          { $$ = $1 & $3; }
               | class_expint BIT_XOR class_expint          { $$ = $1 ^ $3; }
               | class_expint ARITP class_expint            { if ($2 == '+') $$ = $1 + $3; else $$ = $1 - $3; }
               | class_expint ARITO class_expint            { if ($2 == '*') $$ = $1 * $3; else if ($2 == '/') $$ = $1 / $3; else $$ = $1 % $3; }               
               | '(' class_expint ')'                       { $$ = $2; }
               | NAT                                        { $$ = $1; }
               | INT                                        { $$ = $1; }
               | ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_VAR_DECL || symbol->scope == GLOBAL_CONST_DECL ||
                              (symbol->CLASS == classes && (symbol->scope == CLASS_FUNC_VAR_DECL || symbol->scope == CLASS_FUNC_CONST_DECL))) &&
                              symbol->type.find("int") != string::npos) {
                              $$ = symbol->value;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " has not type int");
                    }
               }
               | ID '.' ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if ((symbol1->CLASS == symbol2->CLASS && (symbol2->scope == CLASS_VAR_DECL || symbol2->scope == CLASS_CONST_DECL)) &&
                              symbol2->type.find("int") != string::npos) {
                              $$ = symbol2->value;
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_ARR_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_FUNC_ARR_DECL)) && symbol->type.find("array of int") != string::npos) {
                              $$ = 0;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " has not type int");
                    }
               }
               ;
class_func_expint: BIT_COMPL class_func_expint                   { $$ = ~$2; }
               | INC class_func_expint                           { $$ = $2 + 1; }
               | DEC class_func_expint                           { $$ = $2 - 1; }
               | class_func_expint INC                           { $$ = $1 + 1; }
               | class_func_expint DEC                           { $$ = $1 - 1; }
               | class_func_expint BIT_SHIFT class_func_expint   { $2 == ">>" ? $$ = $1 >> $3 : $$ = $1 << $3; }
               | class_func_expint BIT_OR class_func_expint      { $$ = $1 | $3; }
               | class_func_expint BIT_AND class_func_expint     { $$ = $1 & $3; }
               | class_func_expint BIT_XOR class_func_expint     { $$ = $1 ^ $3; }
               | class_func_expint ARITP class_func_expint       { if ($2 == '+') $$ = $1 + $3; else $$ = $1 - $3; }
               | class_func_expint ARITO class_func_expint       { if ($2 == '*') $$ = $1 * $3; else if ($2 == '/') $$ = $1 / $3; else $$ = $1 % $3; }               
               | '(' class_func_expint ')'                       { $$ = $2; }
               | NAT                                             { $$ = $1; }
               | INT                                             { $$ = $1; }
               | ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_VAR_DECL || symbol->scope == GLOBAL_CONST_DECL ||
                              (symbol->CLASS == classes && (symbol->scope == CLASS_VAR_DECL || symbol->scope == CLASS_CONST_DECL) ||
                              (symbol->function == functions && (symbol->scope == CLASS_FUNC_VAR_DECL || symbol->scope == CLASS_FUNC_CONST_DECL ||
                              symbol->scope == VAR_PARAM || symbol->scope == CONST_PARAM)))) &&
                              symbol->type.find("int") != string::npos) {
                              $$ = symbol->value;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " has not type int");
                    }
               }
               | ID '.' ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if ((symbol1->CLASS == symbol2->CLASS && (symbol2->scope == CLASS_VAR_DECL || symbol2->scope == CLASS_CONST_DECL)) &&
                              symbol2->type.find("int") != string::npos) {
                              $$ = symbol2->value;
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_ARR_DECL || (symbol->CLASS == classes &&
                              symbol->scope == CLASS_ARR_DECL) || (symbol->function == functions &&
                              (symbol->scope == CLASS_FUNC_ARR_DECL || symbol->scope == ARRAY_PARAM))) &&
                              symbol->type.find("array of int") != string::npos) {
                              $$ = 0;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " has not type int");
                    }
               }
               ;
main_func_expint: BIT_COMPL main_func_expint                     { $$ = ~$2; }
               | INC main_func_expint                            { $$ = $2 + 1; }
               | DEC main_func_expint                            { $$ = $2 - 1; }
               | main_func_expint INC                            { $$ = $1 + 1; }
               | main_func_expint DEC                            { $$ = $1 - 1; }
               | main_func_expint BIT_SHIFT main_func_expint     { $2 == ">>" ? $$ = $1 >> $3 : $$ = $1 << $3; }
               | main_func_expint BIT_OR main_func_expint        { $$ = $1 | $3; }
               | main_func_expint BIT_AND main_func_expint       { $$ = $1 & $3; }
               | main_func_expint BIT_XOR main_func_expint       { $$ = $1 ^ $3; }
               | main_func_expint ARITP main_func_expint         { if ($2 == '+') $$ = $1 + $3; else $$ = $1 - $3; }
               | main_func_expint ARITO main_func_expint         { if ($2 == '*') $$ = $1 * $3; else if ($2 == '/') $$ = $1 / $3; else $$ = $1 % $3; }               
               | '(' main_func_expint ')'                        { $$ = $2; }
               | NAT                                             { $$ = $1; }
               | INT                                             { $$ = $1; }
               | ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_VAR_DECL || symbol->scope == GLOBAL_CONST_DECL ||
                              symbol->scope == MAIN_FUNC_VAR_DECL || symbol->scope == MAIN_FUNC_CONST_DECL) &&
                              symbol->type.find("int") != string::npos) {
                              $$ = symbol->value;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end()) {
                         NOT_USED($1, " has not type int");
                    }
               }
               | ID '.' ID {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not defined");
                    }
                    auto symbol1 = symbol_table[$1].begin();
                    for (; symbol1 != symbol_table[$1].end(); symbol1++) {
                         if (symbol1->scope == GLOBAL_CLASS_DECL || symbol1->scope == MAIN_FUNC_CLASS_DECL) {
                              break;
                         }
                    }
                    if (symbol1 == symbol_table[$1].end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto it2 = symbol_table.find($3);
                    if (it2 == symbol_table.end()) {
                         NOT_USED($3, " is not declared");
                    }
                    auto symbol2 = symbol_table[$3].begin();
                    for (; symbol2 != symbol_table[$3].end(); symbol2++) {
                         if ((symbol1->CLASS == symbol2->CLASS && (symbol2->scope == CLASS_VAR_DECL || symbol2->scope == CLASS_CONST_DECL)) &&
                              symbol2->type.find("int") != string::npos) {
                              $$ = symbol2->value;
                              break;
                         }
                    }
                    if (symbol2 == symbol_table[$3].end()) {
                         string error($3);
                         error += " is not a member of the class ";
                         error += $1;
                         yyerror(error.c_str());
                         exit(1);
                    }
               }
               | ID '_' NAT {
                    auto it = symbol_table.find($1);
                    if (it == symbol_table.end()) {
                         NOT_USED($1, " is not declared");
                    }
                    auto symbol = symbol_table[$1].begin();
                    for (; symbol != symbol_table[$1].end(); symbol++) {
                         if ((symbol->scope == GLOBAL_ARR_DECL || symbol->scope == MAIN_FUNC_ARR_DECL) &&
                              symbol->type.find("array of int") != string::npos) {
                              $$ = 0;
                              break;
                         }
                    }
                    if (symbol == symbol_table[$1].end() ) {
                         NOT_USED($1, " has not type int");
                    }
               }
               ;
expfloat       : '(' expfloat ')'
               | INC expfloat
               | DEC expfloat
               | expfloat INC
               | expfloat DEC
               | expfloat ARITP expfloat
               | expfloat ARITO expfloat
               | FLOAT
               | NAT
               | INT
               ;
expbool        : '(' expbool ')' 
               | BIT_COMPL expbool
               | expbool BIT_OR expbool
               | expbool BIT_AND expbool
               | expbool BIT_XOR expbool
               | TRUE
               | FALSE
               ;
%%
int main(int argc, char** argv) {
     types["Roman"] = "class";
     types["Egyptian"] = "class";
     types["int"] = "int";
     types["float"] = "float";
     types["signum"] = "char";
     types["hierogliph"] = "char";
     types["scriptum"] = "string";
     types["papyrus"] = "string";
     types["centaur-answer"] = "bool";
     types["sphynx-answer"] = "bool";
     types["invincible-int"] = "const int";
     types["invincible-float"] = "const float";
     types["invincible-signum"] = "const char";
     types["invincible-hierogliph"] = "const char";
     types["invincible-scriptum"] = "const string";
     types["invincible-papyrus"] = "const string";
     types["invincible-centaur-answer"] = "const bool";
     types["invincible-sphynx-answer"] = "const bool";
     types["bunch-of-int"] = "array of int";
     types["bunch-of-float"] = "array of float";
     types["bunch-of-signum"] = "array of char";
     types["bunch-of-hierogliph"] = "array of char";
     types["bunch-of-scriptum"] = "array of string";
     types["bunch-of-papyrus"] = "array of string";
     types["bunch-of-centaur-answer"] = "array of bool";
     types["bunch-of-sphynx-answer"] = "array of bool";
     yyin = fopen(argv[1], "r");
     yyparse();
     for (auto eval : evals) {
          printf("%d\n", eval);
     }
     char* input = new char[strlen(argv[1]) + 1];
     int i = 0;
     while (argv[1][i] != '.') {
          input[i] = argv[1][i];
          i++;
     }
     input[i] = '\0';
     string output(input);
     delete[] input;
     output += "_symbol_table.txt";
     FILE* file = fopen(output.c_str(), "w");
     fprintf(file, "%-20s%40s%20s%10s%10s%10s%10s%11s\n", "Name", "Scope", "Type", "Value", "Line", "Class", "Function", "Assignment");
     for (auto it1 : symbol_table) {
          for (auto it2 : symbol_table[it1.first]) {
               fprintf(file, "%-20s%40s%20s%10d%10d%10d%10d%11d\n",
               it1.first.c_str(), it2.scope.c_str(), it2.type.c_str(), it2.value, it2.line, it2.CLASS, it2.function, it2.assign);
          }
     }
}