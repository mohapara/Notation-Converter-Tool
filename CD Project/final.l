%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define MAX 200

char tokens[MAX][32];
char postfix[MAX][32];
char opstack[MAX];

int count = 0, top = -1, invalid = 0;

typedef struct Node {
    char value[32];
    struct Node *left;
    struct Node *right;
} Node;

void add_token(char *s) {
    if (count < MAX)
        strcpy(tokens[count++], s);
    else
        invalid = 1;
}

int precedence(char c) {
    if (c == '+' || c == '-') return 1;
    if (c == '*' || c == '/') return 2;
    return 0;
}

int convert(void) {
    int out = 0;
    top = -1;

    for (int i = 0; i < count; i++) {
        char *t = tokens[i];

        if (t[0] >= '0' && t[0] <= '9') {
            strcpy(postfix[out++], t);
        }
        else if (strcmp(t, "(") == 0) {
            opstack[++top] = '(';
        }
        else if (strcmp(t, ")") == 0) {
            while (top >= 0 && opstack[top] != '(') {
                char s[2] = {opstack[top--], '\0'};
                strcpy(postfix[out++], s);
            }

            if (top < 0) return -1;
            top--;
        }
        else {
            char c = t[0];

            if (c != '+' && c != '-' &&
                c != '*' && c != '/')
                return -1;

            while (top >= 0 && opstack[top] != '(' &&
                   precedence(opstack[top]) >= precedence(c)) {
                char s[2] = {opstack[top--], '\0'};
                strcpy(postfix[out++], s);
            }

            opstack[++top] = c;
        }
    }

    while (top >= 0) {
        if (opstack[top] == '(') return -1;

        char s[2] = {opstack[top--], '\0'};
        strcpy(postfix[out++], s);
    }

    return out;
}

Node *new_node(char *value, Node *left, Node *right) {
    Node *n = malloc(sizeof(Node));

    if (n == NULL) {
        printf("Memory allocation failed.\n");
        exit(1);
    }

    strcpy(n->value, value);
    n->left = left;
    n->right = right;

    return n;
}

int is_operator(char *s) {
    return strlen(s) == 1 &&
           strchr("+-*/", s[0]) != NULL;
}

Node *build_tree(int n) {
    Node *stack[MAX];
    int sp = -1;

    for (int i = 0; i < n; i++) {
        if (!is_operator(postfix[i])) {
            stack[++sp] = new_node(postfix[i], NULL, NULL);
        }
        else {
            if (sp < 1) return NULL;

            Node *right = stack[sp--];
            Node *left = stack[sp--];

            stack[++sp] = new_node(
                postfix[i], left, right
            );
        }
    }

    if (sp != 0) return NULL;

    return stack[sp];
}

void print_prefix(Node *root) {
    if (root == NULL) return;

    printf("%s ", root->value);
    print_prefix(root->left);
    print_prefix(root->right);
}

double evaluate(Node *root) {
    if (!is_operator(root->value))
        return atof(root->value);

    double a = evaluate(root->left);
    double b = evaluate(root->right);

    switch (root->value[0]) {
        case '+': return a + b;
        case '-': return a - b;
        case '*': return a * b;

        case '/':
            if (b == 0) {
                printf("Error: Division by zero.\n");
                exit(1);
            }
            return a / b;
    }

    return 0;
}

void print_tree(Node *root, char *prefix, int is_left) {
    if (root == NULL) return;

    printf("%s%s%s\n", prefix,
           is_left ? "|-- " : "\\-- ",
           root->value);

    char next[MAX];

    snprintf(next, sizeof(next), "%s%s",
             prefix, is_left ? "|   " : "    ");

    if (root->left || root->right) {
        print_tree(root->left, next, 1);
        print_tree(root->right, next, 0);
    }
}

void free_tree(Node *root) {
    if (root == NULL) return;

    free_tree(root->left);
    free_tree(root->right);
    free(root);
}
%}

%%
[0-9]+       { add_token(yytext); }
[()+*/-]     { add_token(yytext); }
[ \t\r]+     ;
\n           { return 0; }
.            { invalid = 1; }
%%

int main(void) {
    printf("Enter infix expression: ");
    yylex();

    if (invalid || count == 0) {
        printf("Invalid input.\n");
        return 1;
    }

    int n = convert();

    if (n < 0) {
        printf("Invalid expression or parentheses.\n");
        return 1;
    }

    Node *root = build_tree(n);

    if (root == NULL) {
        printf("Invalid arithmetic expression.\n");
        return 1;
    }

    double result = evaluate(root);

    printf("\nInfix:   ");
    for (int i = 0; i < count; i++)
        printf("%s ", tokens[i]);

    printf("\nPostfix: ");
    for (int i = 0; i < n; i++)
        printf("%s ", postfix[i]);

    printf("\nPrefix:  ");
    print_prefix(root);

    if (fabs(result - round(result)) < 1e-9)
        printf("\nValue:   %.0f\n", result);
    else
        printf("\nValue:   %.2f\n", result);

    printf("\nParse Tree:\n");
    print_tree(root, "", 0);

    free_tree(root);
    return 0;
}
