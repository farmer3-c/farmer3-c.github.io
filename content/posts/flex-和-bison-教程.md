---
title: Flex 和 Bison 教程
date: '2026-05-23T16:26:30'
author: farmer3-c
tags:
- flex
- bison
draft: false
---
> 说明：本篇内容译自 Santa Clara University COEN 259 编译原理课程讲义，用于学习 Flex 和 Bison 编译器工具。
> 本篇内容为个人学习，不构成任何商业用途。

## Flex

Flex 是一个用于词法分析的扫描器生成工具，它基于有限状态机 (FSM)。输入是一组正则表达式，输出是根据输入规则实现扫描器的代码。

为了实现计算器的一个扫描器，我们可以将文件 “cal1.l” 编写如下：

```
/* this is only for scanner, not link with parser yet */ 
%{ 
int lineNum = 0; 
%} 
 
%% 
 
"(" { printf("(\n"); } 
")" { printf(")\n"); } 
"+" { printf("+\n"); } 
"*" { printf("*\n"); } 
\n { lineNum++; } 
[ \t]+ { } 
[0-9]+ { printf("%s\n", yytext); } 
 
%% 
 
int yywrap() { 
 return 1; 
} 
 
int main () { 
 yylex(); 
 return 0; 
} 
```

这是用于构建扫描器的 Makefile：

```
p1: lex.yy.o 
 gcc -g -o p1 lex.yy.o 
 
lex.yy.o: cal1.l 
 flex cal1.l; gcc -g -c lex.yy.c 
 
clean: 
 rm -f p1 *.o lex.yy.c
```

**注意**：对于更复杂的 flex 输入文件，你可能会收到类似的错误信息

```
parse tree too big, try %a num (or %e num)" 
```

然后你需要定义 `%e <num>`。你应该把它放在宏和 `%start` 符号之间。其他选项有 `%a、%o、%n、%p` 等。

## Bison

Bison 是一个用于语法分析的 LALR(1) 解析器生成工具，它基于下推自动机 (PDA)。输入是一组上下文无关文法 (CFG) 规则，输出是根据输入规则实现解析器的代码。

要实现计算器的一个解析器，我们可以按如下方式编写文件“cal.y”:

```
%{ 
#include <stdio.h> 
#include <ctype.h> 
int lineNum = 1; 
void yyerror(char *ps, ...) {  /* need this to avoid 
link problem */ 
 printf("%s\n", ps); 
} 
%} 
 
%union { 
 int d; 
} 
// need to choose token type from union above 
%token <d> NUMBER 
%token '(' ')' 
%left '+' 
%left '*' 
%type <d> exp factor term 
 
%start cal 
 
%% 
 
cal 
  : exp 
 { printf("The result is %d\n", $1); } 
  ; 
 
exp 
  : exp '+' factor 
 { $$ = $1 + $3; } 
  | factor 
 { $$ = $1; } 
  ; 
 
factor
 : factor '*' term 
 { $$ = $1 * $3; } 
  | term 
 { $$ = $1; } 
  ; 
 
term 
  : NUMBER 
 { $$ = $1; } 
  | '(' exp ')' 
 { $$ = $2; } 
  ; 
 
%% 
 
int main() { 
 yyparse(); 
 return 0; 
}
```

为了整合扫描器和解析器，我们需要修改扫描器输入文件“cal1.l”，并将其保存为“cal.l”，如下所示：

```
%{ 
#include <stdlib.h> /* for atoi call */ 
#define DEBUG  /* for debuging: print tokens and 
their line numbers */ 
#define NUMBER 258 /* copy this from cal.tab.c */ 
typedef union {  /* copy this from cal.tab.c */ 
 int d; 
} YYSTYPE; 
YYSTYPE yylval; /* for passing value to parser */ 
extern int lineNum; /* line number from cal.tab.c */ 
%} 
 
%% 
 
[ \t]+ {} 
[\n] { lineNum++; } 
"(" { 
#ifdef DEBUG 
  printf("token '(' at line %d\n", lineNum); 
#endif 
  return '('; 
 } 
")" { 
#ifdef DEBUG 
  printf("token ')' at line %d\n", lineNum); 
#endif 
  return ')'; 
 } 
"+" {
#ifdef DEBUG 
  printf("token '+' at line %d\n", lineNum); 
#endif 
  return '+'; 
 } 
"*" { 
#ifdef DEBUG 
  printf("token '*' at line %d\n", lineNum); 
#endif 
  return '*'; 
 } 
[0-9]+ { 
#ifdef DEBUG 
 printf("token %s at line %d\n", yytext, lineNum); 
#endif 
 yylval.d = atoi(yytext); 
 return NUMBER; 
} 
 
%% 
 
int yywrap() {  /* need this to avoid link problem */ 
 return 1; 
}
```

这是用于构建扫描器和解析器的 Makefile：

```
p2: lex.yy.o cal.tab.o 
 gcc -o p2 lex.yy.o cal.tab.o 
 
lex.yy.o: cal.l 
 flex cal.l; gcc -c lex.yy.c 
 
cal.tab.o: cal.y 
 bison -d cal.y; gcc -c cal.tab.c 
 
clean: 
 rm -f p2 cal.output *.o cal.tab.c lex.yy.c 
```

有一些调试 Bison 的技巧。
1. 使用 -v 选项运行 Bison，然后会生成一个名为 cal.output 的文件。它包含所有的冲突和/或永远不会被归约的规则，以及 Bison 生成的所有状态。
2. 获取 Bison 的调试信息：首先，在编译 cal.tab.c 时添加 -DYYDEBUG；其次，设置环境变量 YYDEBUG=1。然后它会打印大量的调试信息，例如如何进行移入或归约。

---
[原文](https://www.cse.scu.edu/~m1wang/compiler/TutorialFlexBison.pdf)