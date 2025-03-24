%{
#include "yacc.tab.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define MAX_ERRORS 100

typedef struct {
    char message[256];
    int line;
    char token[64];
} LexicalError;

LexicalError lexical_errors[MAX_ERRORS];
int lex_error_count = 0;

void report_lexical_error(const char* token, int line, const char* message) {
    if (lex_error_count < MAX_ERRORS) {
        snprintf(lexical_errors[lex_error_count].message, 256, "%s", message);
        lexical_errors[lex_error_count].line = line;
        snprintf(lexical_errors[lex_error_count].token, 64, "%s", token);
        lex_error_count++;
    }
}

int report_lexical_errors() {
    if (lex_error_count > 0) {
        printf("\n--- Lexical Errors ---\n");
        for (int i = 0; i < lex_error_count; i++) {
            printf("Line %d: %s '%s'\n", 
                   lexical_errors[i].line, 
                   lexical_errors[i].message,
                   lexical_errors[i].token);
        }
    }
    return lex_error_count;
}
%}

%option yylineno


%%

\n              { }
[ \t\r]+        { }

"chal"         { return VAR; }
"pradarshy"    { return PRINT; }
"yada"         { return IF; }
"anyatha"      { return ELSE; }
"samapti"      { return END; }

"=="          { return EQ; }
"!="          { return NE; }
"<="          { return LE; }
">="          { return GE; }
"<"           { return LT; }
">"           { return GT; }
"asti"        { return ASSIGN; }

"("           { return LPAREN; }
")"           { return RPAREN; }
"{"           { return LBRACE; }
"}"           { return RBRACE; }
";"           { return SEMI; }

"samyog"      { return PLUS; }
"viyog"       { return MINUS; }
"gunan"       { return MUL; }
"bhag"        { return DIV; }

[0-9]+(\.[0-9]+)?    { 
    yylval.num = atof(yytext); 
    return NUMBER; 
}

[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.str = strdup(yytext); 
    return IDENTIFIER; 
}

"//"[^\n]*\n   {  }

"/*"([^*]|\*+[^*/])*\*+"/"   {  }
"/*"([^*]|\*+[^*/])*         {
    report_lexical_error("/*", yylineno, "Unterminated comment");
    return ERROR_TOKEN;
}

. { 
    report_lexical_error(yytext, yylineno, "Invalid token");
    return ERROR_TOKEN;
}

%%

int yywrap() {
    return 1;
}
