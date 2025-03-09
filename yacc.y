%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <assert.h>

extern int yylineno;
extern void report_lexical_errors();  // Function to print lexical errors
extern char *yytext;
extern int yylex();
extern FILE *yyin;
// Add this near the top of your yacc.y file, with the other external declarations
extern int yyparse(void);
typedef void* YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

// Error handling
int error_count = 0;
#define MAX_ERRORS 20

// Symbol table
typedef struct {
    char name[100];
    double value;
    int initialized;  // Track if variable has been initialized
    int declared;     // Track if variable has been declared
} Symbol;
Symbol symTable[100];
int symCount = 0;

// For while loops
long saved_position = 0;
int saved_lineno = 0;
int while_condition_result = 0;

double getVariableValue(char *name) {
    for (int i = 0; i < symCount; i++) {
        if (strcmp(symTable[i].name, name) == 0) {
            if (!symTable[i].initialized) {
                fprintf(stderr, "Warning: Using uninitialized variable '%s' at line %d\n", name, yylineno);
            }
            return symTable[i].value;
        }
    }
    fprintf(stderr, "Error: Undefined variable '%s' at line %d\n", name, yylineno);
    error_count++;
    return 0.0;  // Return default value but report error
}

void setVariableValue(char *name, double value) {
    for (int i = 0; i < symCount; i++) {
        if (strcmp(symTable[i].name, name) == 0) {
            symTable[i].value = value;
            symTable[i].initialized = 1;
            return;
        }
    }
    
    // Variable not found - create new entry
    strcpy(symTable[symCount].name, name);
    symTable[symCount].value = value;
    symTable[symCount].initialized = 1;
    symTable[symCount].declared = 0;  // Not formally declared
    symCount++;
    
    fprintf(stderr, "Warning: Implicit declaration of variable '%s' at line %d\n", name, yylineno);
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
    
    // Variable not found - create new entry
    strcpy(symTable[symCount].name, name);
    symTable[symCount].declared = 1;
    symTable[symCount].initialized = initialized;
    symTable[symCount].value = initialized ? value : 0.0;
    symCount++;
}

int skip = 0;
int if_result = 0;
int saved_skip = 0;

void printContextLine(int line_number) {
    if (yyin && !feof(yyin)) {
        char line[256] = {0};
        long pos = ftell(yyin);
        fseek(yyin, 0, SEEK_SET);
        
        // Skip to the correct line
        int curr_line = 1;
        while (curr_line < line_number && fgets(line, sizeof(line), yyin)) {
            curr_line++;
        }
        
        if (curr_line == line_number && fgets(line, sizeof(line), yyin)) {
            printf("Line %d: %s", line_number, line);
            
            // Find the position of yytext in the line
            char *pos_in_line = strstr(line, yytext);
            if (pos_in_line) {
                int offset = pos_in_line - line;
                printf("      ");
                for (int i = 0; i < offset; i++) {
                    printf(" ");
                }
                for (int i = 0; i < strlen(yytext); i++) {
                    printf("^");
                }
                printf("\n");
            }
        }
        
        // Restore file position
        fseek(yyin, pos, SEEK_SET);
    }
}

void yyerror(const char *s);

// Parse string for while loops
int parse_block_from_string(const char *block_str) {
    YY_BUFFER_STATE buffer = yy_scan_string(block_str);
    int result = yyparse();
    yy_delete_buffer(buffer);
    return result;
}

%}

%union {
    double num;
    char *str;
}

%token <str> IDENTIFIER
%token <num> NUMBER
%token VAR PRINT IF ELSE WHILE END
%token EQ NE LE GE LT GT
%token ASSIGN
%token PLUS MINUS MUL DIV
%token LPAREN RPAREN LBRACE RBRACE SEMI
%token ERROR_TOKEN  // Handling invalid tokens

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
    | while_stmt
    | error SEMI { yyerrok; }  /* Error recovery on semicolon */
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
            if (!found) {
                fprintf(stderr, "Warning: Assignment to undeclared variable '%s' at line %d\n", $1, yylineno);
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

while_stmt:
    WHILE 
    {
        // Save position for looping
        if (yyin) {
            saved_position = ftell(yyin);
            saved_lineno = yylineno;
        }
    }
    LPAREN condition RPAREN 
    {
        while_condition_result = $4;
        if (!while_condition_result) {
            skip = 1;  // Skip the block if condition is false
        }
    }
    block
    {
        if (while_condition_result && yyin) {
            // Reposition to evaluate condition again
            fseek(yyin, saved_position, SEEK_SET);
            yylineno = saved_lineno;
            // This is a simplification - real loop handling is more complex
            // Would need to rerun lexer/parser from this point
        }
        skip = 0;  // Reset skip flag
    }
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
    fprintf(stderr, "Syntax error: %s (Unexpected token: '%s')\n", s, yytext);
    
    // Print context line with error position
    printContextLine(yylineno);
    
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
    
    // Report lexical errors
    report_lexical_errors();
    
    // Print summary
    if (error_count > 0) {
        printf("\nCompilation failed with %d error(s).\n", error_count);
    } else {
        printf("\nCompilation successful.\n");
    }
    
    if (yyin && yyin != stdin) {
        fclose(yyin);
    }
    
    return (error_count > 0) ? 1 : 0;
}