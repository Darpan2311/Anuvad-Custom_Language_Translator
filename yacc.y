%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylineno;
extern int report_lexical_errors();  
extern char *yytext;
extern int yylex();
extern FILE *yyin;
extern int yyparse(void);

void yyerror(const char *s);
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
    yyerror("Undefined variable"); 
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
    | expression SEMI{    } 
    | expression { yyerror("Missing semicolon at end of statement"); }
    ;

declaration:
    VAR IDENTIFIER ASSIGN expression SEMI{ 
        if (!skip) {
            declareVariable($2, 1, $4);
            printf("Declare %s = %f\n", $2, $4);
        }
    }
    | VAR IDENTIFIER SEMI { 
        if (!skip) {
            declareVariable($2, 0, 0.0);
            printf("Declare %s\n", $2);
        }
    }
    |VAR IDENTIFIER {
        yyerror("Missing semicolon at end of statement");
    }
    |VAR IDENTIFIER ASSIGN expression
    {
        yyerror("Missing semicolon at end of statement");
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression SEMI { 
        if (!skip) {
            setVariableValue($1, $3);
            printf("Assign %s = %f\n", $1, $3);
        }
    }
    |IDENTIFIER ASSIGN expression
    {
        yyerror("Missing semicolon at end of statement");
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
    fprintf(stderr, "Error occurred at line: %d\n%s (Unexpected token: '%s')\n", yylineno, s, yytext);
    
    long pos = ftell(yyin);
    fseek(yyin, 0, SEEK_SET);
    char line[256] = {0};
    for (int i = 1; i < yylineno; i++) {
        if (!fgets(line, sizeof(line), yyin))
            break;
    }
    if (fgets(line, sizeof(line), yyin)) {
        fprintf(stderr, "Line %d: %s \n", yylineno, line);
        char *p = strstr(line, yytext);
        if (p) {
            int offset = (int)(p - line);
            fprintf(stderr, "Error at character offset: %d\n", offset);
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
    }
    else
    {    yyin=stdin;    }
    yyparse();
    
    int lex_errors = report_lexical_errors();
    
    if (error_count+lex_errors > 0) {
        printf("\n Compilation failed with %d lexical errors and %d syntax errors", lex_errors, error_count);
    } else {
        printf("\n Compilation successful.\n");
    }
    
    return (error_count + lex_errors > 0) ? 1 : 0;
}
