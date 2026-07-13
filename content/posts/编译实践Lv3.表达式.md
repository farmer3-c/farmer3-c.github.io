---
title: "编译实践Lv3.表达式"
date: 2026-07-13T10:34:21+08:00
author: farmer3-c
tags:
- PKU 编译原理实践
draft: false
---

# 目的

实现一个能够处理表达式 (一元/二元) 的编译器，编译器将可以处理如下的 SysY 程序：

```
int main() {
  return 1 + 2 * -3;
}
```

# 实现

## Lv3.1. 一元表达式

新增/变更的语法规范：

```
Stmt        ::= "return" Exp ";";

Exp         ::= UnaryExp;
PrimaryExp  ::= "(" Exp ")" | Number;
Number      ::= INT_CONST;
UnaryExp    ::= PrimaryExp | UnaryOp UnaryExp;
UnaryOp     ::= "+" | "-" | "!";

```

设计 AST 时，我只为 ::= 左侧的符号设计一种 AST, 使其涵盖 ::= 右侧的所有规则。

* AST.h

添加 ExpAST, PrimaryExpAST, UnaryExpAST，我使用bool标志区别实现右侧的多种规则，更新 StmtAST，原来只支持num，改成exp。

* sysy.y

添加语法规则 for Exp, UnaryExp, PrimaryExp, UnaryOp; 更新 Stmt rule

  ```
  Exp
  : LOrExp {
    auto ast = new ExpAST();
    ast->lor_exp = unique_ptr<BaseAST>($1);
    $$ = ast;
  }
  ;
  ```

  ```
  UnaryExp
  : PrimaryExp {
    auto ast = new UnaryExpAST();
    ast->is_primary = true;
    ast->primary_exp = unique_ptr<BaseAST>($1);
    $$ = ast;
  }
  | UnaryOp UnaryExp {
    auto ast = new UnaryExpAST();
    ast->is_primary = false;
    ast->op = *unique_ptr<string>($1);
    ast->unary_exp = unique_ptr<BaseAST>($2);
    $$ = ast;
  }
  ;

  ```

* KoopaIR.h

添加 寄存器引用, 用于引用前面的指令结果，例如 %0, %1, ...;二元运算指令,例如 %0 = sub 0, 5

  ```
    class RegRef : public Value {
  public:
    int reg_id;

    RegRef(int id) : reg_id(id) {}

    void Dump() const override {
      std::cout << "%" << reg_id;
    }
  };

  class BinaryInst : public Value {
  public:
    int dest;                          // 目标寄存器编号
    std::string op;                    // 操作符: "sub", "eq", "xor" 等
    std::unique_ptr<Value> lhs;        // 左操作数
    std::unique_ptr<Value> rhs;        // 右操作数

    BinaryInst(int d, const std::string &o,
              std::unique_ptr<Value> l, std::unique_ptr<Value> r)
      : dest(d), op(o), lhs(std::move(l)), rhs(std::move(r)) {}

    void Dump() const override {
      std::cout << "%" << dest << " = " << op << " ";
      lhs->Dump();
      std::cout << ", ";
      rhs->Dump();
    }
  };
  ```


* IRGenerator.cpp

添加递归表达式求值，处理降为二元中间表示的单目运算

```
// 计算一元表达式, 返回一个 Value (Integer 或 RegRef)
// 同时将生成的指令添加到 block 中
static unique_ptr<Value> EvaluateUnaryExp(const BaseAST &ast,
                                          BasicBlock &block, int &reg_counter) {
  const auto *unary = dynamic_cast<const UnaryExpAST*>(&ast);
  if (!unary) return nullptr;
    ……
      // +X 等价于 X, 无需生成指令
    ……
      // -X 等价于 sub 0, X
    ……
      // !X 等价于 eq X, 0
    ……
  return nullptr;
}
```

* ASMGenerator.cpp

添加 binary operation handling (KOOPA_RVT_BINARY) and non-integer return values

## Lv3.2. 算术表达式

文法设计
```
Exp     ::= AddExp
AddExp  ::= MulExp | AddExp ("+" | "-") MulExp
MulExp  ::= UnaryExp | MulExp ("*" | "/" | "%") UnaryExp
```
通过文法层级的嵌套自然编码运算符优先级：一元运算（最高）→ 乘除模 → 加减（最低）。两处左递归规则保证了 +、-、*、/、% 均为左结合。

AST.h — 新增 AST 节点
遵循"一种 rule 一种 AST"的设计原则，每个非终结符只对应一个 AST 类，用 tag 字段区分不同分支：

```
class AddExpAST : public BaseAST {
  bool is_mul;                        // true → MulExp; false → AddExp op MulExp
  unique_ptr<BaseAST> mul_exp;        // is_mul 分支
  unique_ptr<BaseAST> lhs, rhs;       // 非 is_mul 分支（左操作数、右操作数）
  string op;                          // "+" 或 "-"
};

class MulExpAST : public BaseAST {
  bool is_unary;                      // true → UnaryExp; false → MulExp op UnaryExp
  unique_ptr<BaseAST> unary_exp;      // is_unary 分支
  unique_ptr<BaseAST> lhs, rhs;       // 非 is_unary 分支
  string op;                          // "*" 或 "/" 或 "%"
};
```

ExpAST 的字段从 unary_exp 改为 add_exp，指向新的 AddExp 根节点。

sysy.y — 语法规则
Bison 规则直接对应文法产生式，在归约动作中构造对应的 AST 节点：

```
Exp     ::= AddExp     { → ExpAST(add_exp = $1) }
AddExp  ::= MulExp     { → AddExpAST(is_mul=true, mul_exp=$1) }
          | AddExp '+' MulExp  { → AddExpAST(is_mul=false, lhs=$1, op="+", rhs=$3) }
          | AddExp '-' MulExp  { → AddExpAST(is_mul=false, lhs=$1, op="-", rhs=$3) }
MulExp  ::= UnaryExp   { → MulExpAST(is_unary=true, unary_exp=$1) }
          | MulExp '*' UnaryExp  { → MulExpAST(is_unary=false, lhs=$1, op="*", rhs=$3) }
          | MulExp '/' UnaryExp  { → MulExpAST(is_unary=false, lhs=$1, op="/", rhs=$3) }
          | MulExp '%' UnaryExp  { → MulExpAST(is_unary=false, lhs=$1, op="%", rhs=$3) }
```

左递归使 Bison 自动生成 LR 解析表，保证左结合性。非终结符类型声明需加上 AddExp、MulExp。

IRGenerator.cpp — 递归求值

新增 EvaluateAddExp 和 EvaluateMulExp 两个递归求值函数，调用链扩展为：`EvaluateExp → EvaluateAddExp → EvaluateMulExp → EvaluateUnaryExp → EvaluatePrimaryExp`

每个函数的模式相同：

dynamic_cast 到对应的 AST 类型
检查 tag 字段：叶子分支直接递归下层，二元分支递归求值左右操作数
根据 op 选择 Koopa IR 操作码
创建 BinaryInst，分配新寄存器编号，将指令追加到基本块
返回 RegRef 指向结果
运算符到 Koopa IR 的映射：

| 运算符 | Koopa IR |
|:------:|:--------:|
| +      | add      |
| -      | sub      |
| *      | mul      |
| /      | div      |
| %      | mod      |


ASMGenerator.cpp — RISC-V 翻译
在 Visit(kOOPA_RVT_BINARY) 和 LoadValueToReg 的 switch(bin.op) 中补充新增操作码的翻译：

Koopa IR	RISC-V
add	add rd, rs1, rs2
sub	sub rd, rs1, rs2
mul	mul rd, rs1, rs2
div	div rd, rs1, rs2
mod	rem rd, rs1, rs2


## Lv3.3 比较和逻辑表达式


在算术表达式基础上，扩展支持六种关系运算（< > <= >= == !=）和两种逻辑运算（&& ||），构成完整的 SysY 表达式层级。

文法设计

```Exp     ::= LOrExp
LOrExp  ::= LAndExp | LOrExp "||" LAndExp
LAndExp ::= EqExp | LAndExp "&&" EqExp
EqExp   ::= RelExp | EqExp ("==" | "!=") RelExp
RelExp  ::= AddExp | RelExp ("<" | ">" | "<=" | ">=") AddExp
```
完整表达式优先级层级：`Exp → LOrExp → LAndExp → EqExp → RelExp → AddExp → MulExp → UnaryExp → PrimaryExp`。共 7 层，从低到高依次是：逻辑或 → 逻辑与 → 相等/不等 → 关系比较 → 加减 → 乘除模 → 一元运算。

sysy.l — 多字符运算符词法
<=、>=、==、!=、&&、|| 是双字符运算符，不能简单地用 . → return yytext[0] 处理。在 sysy.l 的规则表中，将多字符模式放在 . 通配规则之前，Flex 按最长匹配规则自动识别：

```
"<="  { return LE; }
">="  { return GE; }
"=="  { return EQ; }
"!="  { return NE; }
"&&"  { return LAND; }
"||"  { return LOR; }
```
每个运算符映射到唯一的 Token 名，Bison 端用 %token 声明。

AST.h — 新增 4 个 AST 节点

```
RelExpAST  (is_add 区分 AddExp / RelExp op AddExp)
EqExpAST   (is_rel 区分 RelExp / EqExp op RelExp)
LAndExpAST (is_eq  区分 EqExp / LAndExp && EqExp)
LOrExpAST  (is_land 区分 LAndExp / LOrExp || LAndExp)
```

每个节点遵循相同的模式：一个 tag 布尔值、一个叶子分支字段、一对 lhs/rhs + op 二元分支字段。

sysy.y — Token 声明与语法规则
首先声明 6 个新 Token：


%token LE GE EQ NE LAND LOR
然后添加 LOrExp、LAndExp、EqExp、RelExp 四条规则，同理均为左递归。

RelExp 规则示例：


```RelExp  : AddExp
        | RelExp '<' AddExp
        | RelExp '>' AddExp
        | RelExp LE AddExp
        | RelExp GE AddExp
        ;
```

注意 < 和 > 是单字符，直接写 '<'、'>'，而 <=、>= 使用 Token LE、GE。

IRGenerator.cpp — 新增求值函数
新增 4 个求值函数：


EvaluateExp → EvaluateLOrExp → EvaluateLAndExp → EvaluateEqExp → EvaluateRelExp → EvaluateAddExp → ...
比较运算（< > <= >= == !=）直接映射到 Koopa IR 的原生比较指令：

|运算符	|Koopa IR|	语义|
|:------:|:--------:|:--------:|
|<	   |lt	     |   小于|
|>	   |gt	     |   大于|
|<=	   |le	     |   小于等于|
|>=	   |ge	     |   大于等于|
|==	   |eq	     |   相等|
|!=	   |ne	     |   不等|

逻辑运算（&& ||）需降级为多条指令组合：

X && Y 的降级：

```
%t1 = ne X, 0      // 将 X 归一化为 0/1
%t2 = ne Y, 0      // 将 Y 归一化为 0/1
%t3 = and %t1, %t2 // 按位与: 两个非零才为 1
```

X || Y 的降级：

```
%t1 = ne X, 0      // 将 X 归一化为 0/1
%t2 = ne Y, 0      // 将 Y 归一化为 0/1
%t3 = or %t1, %t2  // 按位或: 任一非零即为 1
```

ASMGenerator.cpp — RISC-V 翻译
RISC-V 没有直接的比较等于/大于等于等指令，需要组合实现：

|Koopa IR	|RISC-V 实现	                      |思路|
|:------:|:--------:|:--------:|
|lt	      |slt rd, rs1, rs2	                |直接用 slt|
|gt	      |slt rd, rs2, rs1	                |交换操作数用 slt|
|le	      |slt rd, rs2, rs1 → xori rd, rd, 1	|!(a > b)|
|ge	      |slt rd, rs1, rs2 → xori rd, rd, 1	|!(a < b)|
|eq	      |sub rd, rs1, rs2 → sltiu rd, rd, 1|	差为 0 则真|
|ne	      |sub rd, rs1, rs2 → sltu rd, x0, rd|	差非 0 则真|
|and/or	  |and/or	                          |  直译|

同时新增 KOOPA_RBO_AND 和 KOOPA_RBO_OR 的处理，支持逻辑运算降级后的指令。

## Lv3.4. 测试

测试 Koopa IR:

```
autotest -koopa -s lv3 /root
```

测试 RISC-V 汇编:

```
autotest -riscv -s lv3 /root
```

结果：

```
……
clang++ /tmp/tmp82gbw_wq/sysy.lex.cpp.o /tmp/tmp82gbw_wq/sysy.tab.cpp.o /tmp/tmp82gbw_wq/ASMGenerator.cpp.o /tmp/tmp82gbw_wq/IRGenerator.cpp.o /tmp/tmp82gbw_wq/main.cpp.o -L/opt/lib/native -lkoopa -lpthread -ldl -o /tmp/tmp82gbw_wq/compiler
make: Leaving directory '/root'
running test "00_pos" ... PASSED
running test "01_neg_0" ... PASSED
running test "02_neg_2" ... PASSED
running test "03_neg_max" ... PASSED
running test "04_not_0" ... PASSED
running test "05_not_10" ... PASSED
running test "06_complex_unary" ... PASSED
running test "07_add" ... PASSED
running test "10_sub_neg" ... PASSED
running test "11_mul" ... PASSED
running test "12_mul_neg" ... PASSED
running test "13_div" ... PASSED
running test "14_div_neg" ... PASSED
running test "15_mod" ... PASSED
running test "16_mod_neg" ... PASSED
running test "17_lt" ... PASSED
running test "18_gt" ... PASSED
running test "19_le" ... PASSED
running test "20_ge" ... PASSED
running test "21_eq" ... PASSED
running test "22_ne" ... PASSED
running test "23_lor" ... PASSED
running test "24_land" ... PASSED
running test "25_int_min" ... PASSED
running test "26_parentheses" ... PASSED
running test "27_complex_binary" ... PASSED
PASSED (28/28)
```

