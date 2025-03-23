%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>

extern int yylineno;
extern int report_lexical_errors();  
extern char *yytext;
extern int yylex();
extern FILE *yyin;
extern int yyparse(void);


int error_count = 0;
#define MAX_ERRORS 20

typedef struct {
    char name[100];
    double value;
    int initialized;
    int declared;     
} Symbol;
Symbol symTable[100];
int symCount = 0;

double getVariableValue(char *name) {
    for (int i = 0; i < symCount; i++) {
        if (strcmp(symTable[i].name, name) == 0) {
            return symTable[i].value;
        }
    } 
    fprintf(stderr, "Error: Undefined variable '%s' at line %d\n", name, yylineno);
    error_count++;
    return 0.0; 
}

void setVariableValue(char *name, double value) {
    for (int i = 0; i < symCount; i++) {
        if (strcmp(symTable[i].name, name) == 0) {
            symTable[i].value = value;
            symTable[i].initialized = 1;
            return;
        }
    }
    
    strcpy(symTable[symCount].name, name);
    symTable[symCount].value = value;
    symTable[symCount].initialized = 1;
    symTable[symCount].declared = 0;
    symCount++;

}

void declareVariable(char *name, int initialized, double value) {
    for (int i = 0; i < symCount; i++) {
        if (strcmp(symTable[i].name, name) == 0) {
            if (symTable[i].declared) {
                fprintf(stderr, "Error: Redeclaration of variable '%s' at line %d\n", name, yylineno);
                error_count++;
                return;
            }
            symTable[i].declared = 1;
            if (initialized) {
                symTable[i].initialized = 1;
                symTable[i].value = value;
            }
            return;
        }
    }
    
    strcpy(symTable[symCount].name, name);
    symTable[symCount].declared = 1;
    symTable[symCount].initialized = initialized;
    symTable[symCount].value = initialized ? value : 0.0;
    symCount++;
}

int skip = 0;
int if_result = 0;
int saved_skip = 0;

void yyerror(const char *s);

%}

%union {
    double num;
    char *str;
}

%token <str> IDENTIFIER
%token <num> NUMBER
%token VAR PRINT IF ELSE END
%token EQ NE LE GE LT GT
%token ASSIGN
%token PLUS MINUS MUL DIV
%token LPAREN RPAREN LBRACE RBRACE SEMI
%token ERROR_TOKEN  

%type <num> expression term factor condition

%start program

%%

program:
    statement_list
    ;

statement_list:
    statement_list statement
    | statement
    ;

statement:
      declaration
    | assignment
    | print_stmt
    | if_stmt
    | error SEMI { yyerrok; } 
    | expression error { yyerror("Missing semicolon at end of statement"); }
     ERROR_TOKEN { yyerror("Lexical error detected"); }
    ;

declaration:
    VAR IDENTIFIER ASSIGN expression SEMI { 
        if (!skip) {
            declareVariable($2, 1, $4);
            printf("Declare %s = %f\n", $2, $4);
        }
        free($2);
    }
    | VAR IDENTIFIER SEMI { 
        if (!skip) {
            declareVariable($2, 0, 0.0);
            printf("Declare %s\n", $2);
        }
        free($2);
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression SEMI { 
        if (!skip) {
            int found = 0;
            for (int i = 0; i < symCount; i++) {
                if (strcmp(symTable[i].name, $1) == 0) {
                    found = 1;
                    break;
                }
            }
            setVariableValue($1, $3);
            printf("Assign %s = %f\n", $1, $3);
        }
        free($1);
    }
    ;

print_stmt:
    PRINT LPAREN expression RPAREN SEMI { 
        if (!skip) {
            printf("Output: %f\n", $3);
        }
    }
    ;

if_stmt:
    IF LPAREN condition RPAREN 
    { 
        if_result = $3; 
        saved_skip = skip; 
        if (!if_result) skip = 1;
    }
    block
    { 
        skip = saved_skip;
    }
    else_opt
    ;

else_opt:
    ELSE 
    { 
        saved_skip = skip; 
        if (if_result) 
            skip = 1; 
        else 
            skip = 0; 
    } 
    block
    { 
        skip = saved_skip;
    }
    | /* empty */ { }
    ;

block:
    LBRACE statement_list RBRACE END { }
    ;

condition:
    expression EQ expression { $$ = ($1 == $3); }
    | expression NE expression { $$ = ($1 != $3); }
    | expression LE expression { $$ = ($1 <= $3); }
    | expression GE expression { $$ = ($1 >= $3); }
    | expression LT expression { $$ = ($1 < $3); }
    | expression GT expression { $$ = ($1 > $3); }
    ;

expression:
    expression PLUS term { $$ = $1 + $3; }
    | expression MINUS term { $$ = $1 - $3; }
    | term { $$ = $1; }
    ;

term: 
    term MUL factor { $$ = $1 * $3; }
    | term DIV factor { 
        if ($3 == 0.0) {
            yyerror("Division by zero");
            $$ = 0.0;
        } else {
            $$ = $1 / $3; 
        }
    }
    | factor { $$ = $1; }
    ;

factor:
    NUMBER { $$ = $1; }
    | IDENTIFIER { $$ = getVariableValue($1); free($1); }
    | LPAREN expression RPAREN { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    error_count++;
    printf("Error occurred at line: %d\n", yylineno);
    fprintf(stderr, "%s (Unexpected token: '%s')\n", s, yytext);
    long pos = ftell(yyin);
    fseek(yyin, 0, SEEK_SET); 
    char line[256] = {0};
    int curr_line = 1;
    while (curr_line < yylineno && fgets(line, sizeof(line), yyin)) {
        curr_line++;
    }
    if (curr_line == yylineno && fgets(line, sizeof(line), yyin)) {
       

        char *pos_in_line = strstr(line, yytext);
        if (pos_in_line) {
            int offset = pos_in_line - line;
            printf("Error at character offset: %d\n", offset);
            printf("\n");
        }
    }

    fseek(yyin, pos, SEEK_SET);

    if (error_count >= MAX_ERRORS) {
        fprintf(stderr, "Too many errors, aborting compilation.\n");
        exit(1);
    }
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror(argv[1]);
            return 1;
        }
    }
    
    int result = yyparse();
    
    int lex_errors=report_lexical_errors();
    
    if (error_count > 0) {
        printf("\nCompilation failed with %d lexical errors %d syntax errors",lex_errors,error_count);
    } else {
        printf("\nCompilation successful.\n");
    }
    
    return (error_count+lex_errors > 0) ? 1 : 0;
}