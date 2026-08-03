---
title: "编译实践Lv4~Lv9"
date: 2026-07-16T18:30:53+08:00
author: farmer3-c
tags:
- PKU 编译原理实践
draft: false
---

# Lv4

引入符号表统一记录常量、变量的属性与内存标识

```cpp
struct SymbolInfo {
    bool is_const;        // 常量 or 变量
    int const_val;        // 常量值（编译期已知）
    string alloc_name;    // 变量的 alloc 指令名，如 "@x"
};
unordered_map<string, SymbolInfo> symtab;
```

操作：
- `AddConst(name, val)` — 插入常量（同时做重复定义检查）
- `AddVar(name, ...)` — 插入变量 + 生成 `alloc i32` 指令
- `Lookup(name)` — 查询符号

当前仅支持单层作用域（函数体 Block），无嵌套 Block，因此使用单一 `unordered_map`。若后续实验引入嵌套作用域，可扩展为栈式符号表（进入 Block 时 push 新表，离开时 pop）。


# Lv5

Lv4 用 `is_return` bool 区分两种语句，Lv5 需要支持 4 种，改用 `kind` 枚举，重构StmtAST :

```cpp
class StmtAST : public BaseAST {
public:
    enum Kind { RETURN, ASSIGN, EXP_STMT, BLOCK };
    Kind kind;
    unique_ptr<BaseAST> exp;        // RETURN / EXP_STMT
    unique_ptr<BaseAST> lval;       // ASSIGN
    unique_ptr<BaseAST> assign_exp; // ASSIGN
    unique_ptr<BaseAST> block;      // BLOCK
};
```

测试遇到一个问题，

```running test "5_scope" ... CASE ASSEMBLE ERROR
stdout:

stderr:
error: symbol '@a' has already been defined
  at /tmp/tmp65nxt_im/70b1796456734e8e88fc5c4c5c5f44c8.S:8:3
  |
8 |   @a = alloc i32
  |   ^^^^^^^^^^^^^^

1 error emitted
```

嵌套作用域中声明同名变量时，AddVar 生成 @a = alloc i32 两次，和 Koopa IR 的 SSA 单赋值规则冲突，每个 @name 必须唯一。用全局计数器生成唯一 alloc 名就可以了。

初始化一个alloc_counter，每次生成变量名时自增。

```
string alloc_name = "@" + name + "_" + std::to_string(alloc_counter++);
```

# Lv6

将 `&&` 和 `||` 展开为分支控制流，而非简单二元运算。

* `&&` 短路求值
```
// lhs && rhs 展开为:
@sc = alloc i32
store 0, @sc              // 默认结果 = 0
%lhs = 求值 lhs
br %lhs, %rhs_bb, %end_bb  // lhs 非0才进入 rhs

%rhs_bb:
  %rhs = 求值 rhs
  %r = ne %rhs, 0          // 归一化 rhs 为 0/1
  store %r, @sc
  jump %end_bb

%end_bb:
  %result = load @sc       // 加载最终结果
```

* `||` 短路求值
```
// lhs || rhs 展开为:
@sc = alloc i32
store 1, @sc              // 默认结果 = 1
%lhs = 求值 lhs
br %lhs, %end_bb, %rhs_bb  // lhs 非0则短路到 end

%rhs_bb:
  %rhs = 求值 rhs
  %r = ne %rhs, 0
  store %r, @sc
  jump %end_bb

%end_bb:
  %result = load @sc
```

测试遇到一个问题，

```
clang++ -I/root/src -I/root/build -MMD -MP -Wall -Wno-register -std=c++17 -g -O0 -I/opt/include -c /root/src/IRGenerator.cpp -o /root/build/IRGenerator.cpp.o
/root/src/IRGenerator.cpp:43:25: error: use of undeclared identifier 'IsTerminated'
   43 |   if (!insts.empty() && IsTerminated(*entry_block)) {
      |                         ^~~~~~~~~~~~
1 error generated.
make: *** [Makefile:83: /root/build/IRGenerator.cpp.o] Error 1
```

是 IsTerminated 函数在第 67 行定义，但在第 43 行的 AddVar 函数中就被调用了，缺少前向声明。

在 AddVar 之前添加 IsTerminated 的前向声明就解决了。

```
// 前向声明 (定义在下方, 但 AddVar 中就需要用到)
static bool IsTerminated(const BasicBlock &bb);
```

# Lv7

新增 while/break/continue，文法和 AST 是机械扩展，核心设计在 IR 层（循环三块结构 + 目标栈处理嵌套 + 终止传播 nullptr），并顺带把"只补最后一个块 ret 0"的 bug 修为"所有未终止块都补 ret 0"。

* BREAK / CONTINUE 

两者对称：取栈顶目标块名，push 一条无条件跳转，然后 return nullptr 表示当前基本块已终止。

```
case StmtAST::BREAK: {
    if (break_targets.empty()) {          // 循环外使用 → 报错
      cerr << "error: break statement outside of a loop" << endl;
      return cur;
    }
    cur->instructions.push_back(make_unique<JumpInst>(break_targets.back()));
    return nullptr;
}
```

**return nullptr** ：调用方根据 body_cont == nullptr 判断"体已经通过 break/return 终止"，从而不补跳回条件块的那条 jump。

* 一个bug

```
// 旧: 只检查 func->blocks 的最后一个块
if (!func->blocks.empty()) {
    auto *last_bb = func->blocks.back().get();
    if (!IsTerminated(*last_bb)) { ... 补 ret 0 ... }
}
// 新: 遍历所有基本块
for (auto &bb : func->blocks) {
    if (!IsTerminated(*bb)) { ... 补 ret 0 ... }
}
```

while_end_N 基本块在创建三个块时先于循环体被 NewBB 创建，所以它不一定是 blocks 的最后一个元素。如果 while 是空体或循环体内的代码在 end 之后又创建了块，end 块就会是"空的且不是最后一个"，旧逻辑漏掉它 → 未终止的基本块会让 libkoopa 解析失败。改成遍历所有块后，空块统一补 ret 0，逻辑上等价于"函数自然结束返回 0"。


# Lv8

## make的时候报错

*1.*

```
mkdir -p /root/build/
flex  -o /root/build/sysy.lex.cpp /root/src/sysy.l
mkdir -p /root/build/
bison -d -o /root/build/sysy.tab.cpp /root/src/sysy.y
/root/src/sysy.y:51.49-50: error: $1 of 'CompUnit' has no declared type
   51 |     auto comp_unit = dynamic_cast<CompUnitAST*>($1);
      |                                                 ^~
/root/src/sysy.y:55.54-55: error: $1 of 'CompUnit' has no declared type
   55 |       comp_unit->items.push_back(unique_ptr<BaseAST>($1));
      |                                                      ^~
/root/src/sysy.y:65.5-6: error: $$ of 'CompUnitItemList' has no declared type
   65 |     $$ = comp;
      |     ^~
/root/src/sysy.y:70.5-6: error: $$ of 'CompUnitItemList' has no declared type
   70 |     $$ = comp;
      |     ^~
/root/src/sysy.y:73.44-45: error: $1 of 'CompUnitItemList' has no declared type
   73 |     auto comp = dynamic_cast<CompUnitAST*>($1);
      |                                            ^~
/root/src/sysy.y:75.5-6: error: $$ of 'CompUnitItemList' has no declared type
   75 |     $$ = comp;
      |     ^~
/root/src/sysy.y:78.44-45: error: $1 of 'CompUnitItemList' has no declared type
   78 |     auto comp = dynamic_cast<CompUnitAST*>($1);
      |                                            ^~
/root/src/sysy.y:80.5-6: error: $$ of 'CompUnitItemList' has no declared type
   80 |     $$ = comp;
      |     ^~
make: *** [Makefile:95: /root/build/sysy.tab.cpp] Error 1
```


发现忘记CompUnit 和 CompUnitItemList 这两个新的非终结符没有在 %type 中声明类型，在 sysy.y 的 %type 声明区域添加这两个符号的类型声明就好了。

*2.*

```
mkdir -p /root/build/
flex  -o /root/build/sysy.lex.cpp /root/src/sysy.l
mkdir -p /root/build/
bison -d -o /root/build/sysy.tab.cpp /root/src/sysy.y
/root/src/sysy.y: warning: 1 reduce/reduce conflict [-Wconflicts-rr]
/root/src/sysy.y: note: rerun with option '-Wcounterexamples' to generate conflict counterexamples
mkdir -p /root/build/
clang++ -I/root/src -I/root/build -MMD -MP -Wall -Wno-register -std=c++17 -g -O0 -I/opt/include -c /root/build/sysy.lex.cpp -o /root/build/sysy.lex.cpp.o
mkdir -p /root/build/
clang++ -I/root/src -I/root/build -MMD -MP -Wall -Wno-register -std=c++17 -g -O0 -I/opt/include -c /root/build/sysy.tab.cpp -o /root/build/sysy.tab.cpp.o
mkdir -p /root/build/
clang++ -I/root/src -I/root/build -MMD -MP -Wall -Wno-register -std=c++17 -g -O0 -I/opt/include -c /root/src/ASMGenerator.cpp -o /root/build/ASMGenerator.cpp.o
/root/src/ASMGenerator.cpp:42:54: error: extraneous ')' before ';'
   42 |         os << "  lw " << reg << ", 0(" << reg << "\n");
      |                                                      ^
/root/src/ASMGenerator.cpp:232:54: error: extraneous ')' before ';'
  232 |             os << "  lw " << r << ", 0(" << r << "\n");
      |                                                      ^
2 errors generated.
make: *** [Makefile:83: /root/build/ASMGenerator.cpp.o] Error 1
```

问题原因：

在 `")\n"` 这个字符串字面量中，文件里实际存储的是 `"\n"` — 缺少了 `)`。`)"` 被解析为：`<< reg << ")"` + 换行符，但 `")"` 在 << reg << "\n" 中间变成了游离的 `)` 字符出现在字符串外部，导致 `extraneous ')' before ';'` 编译错误。

修复方式：将 `")\n"` 拆成 `")" << "\n"`，确保 `)` 明确位于字符串字面量内部。



## 测试 Koopa IR:

报错：

```
running test "09_globals" ... CASE COMPILE ERROR
compiler: /root/src/main.cpp:31: int main(int, const char **): Assertion `!ret' failed.

running test "11_short_circuit" ... CASE COMPILE ERROR
stdout:

stderr:
error: syntax error
compiler: /root/src/main.cpp:31: int main(int, const char **): Assertion `!ret' failed.
```

Bison 语法文件中的 reduce/reduce 冲突（之前编译时也有警告 1 reduce/reduce conflict）。

FuncType ::= "int" 和 BType ::= "int" 有相同的右侧（都是 INT）。当 Bison 遇到 INT 时，无法决定应该归约为 FuncType 还是 BType，Bison 按规则出现顺序选择 FuncType（先出现）。这导致：

09_globals 测试：int var; 中 int 被归约为 FuncType，后续文法期望 `(` 而不是 `var`，解析失败
11_short_circuit 测试：函数体内的 int a = 5; 同理，int 被错误归约导致后续不匹配

将 FuncType 和 BType 合并为统一的 Type 非终结符，消除歧义。

## 测试 RISC-V 汇编:

报错：

```
/tmp/c4955cafeeac4673aeacc94997c81a9a-469f32.s:60:1: error: symbol '.entry' is already defined
.entry:
^
```

每个函数都有一个 %entry 基本块，翻译成汇编都叫 .entry，多个函数就产生重复标签。需要对所有基本块标签加函数名前缀使其全局唯一。



# Lv9

## 问题 1：多维全局数组 Aggregate 必须是嵌套结构

### 影响的测试
`05_global_arr_init`, `08_arr_access`

### 现象

```
error: expected array length 5, found length 15
global @b = alloc [[i32, 3], 5], {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
```

### 原因

`[[i32, 3], 5]` 表示 5 个元素，每个元素是 `[i32, 3]`。Aggregate 必须匹配类型结构——5 个嵌套 aggregate，每个含 3 个 `i32`：

```
错误 (flat):  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
正确 (嵌套):  {{0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}, {0,0,0}}
```

`FlattenConstInit` 展平得到 `vector<int>`，原代码直接将展平值全部作为 `Integer` 放入一个 Aggregate 内层，忽略了维度结构。

### 修复 

写一个递归函数 `BuildNestedAggregate`，将展平值按维度构建嵌套 Aggregate：

```cpp
// dims = [2, 3], flat = [1,2,3,4,5,6] → {{1,2,3},{4,5,6}}
static unique_ptr<Aggregate> BuildNestedAggregate(
    const vector<int> &dims, int dim_start,
    const vector<int> &flat, size_t &pos) {
  auto agg = make_unique<Aggregate>();
  int cur_dim = dims[dim_start];
  if (dim_start == (int)dims.size() - 1) {
    // 最内层: 直接填充 Integer
    for (int i = 0; i < cur_dim; i++)
      agg->elements.push_back(make_unique<Integer>(flat[pos++]));
  } else {
    // 外层: 递归创建嵌套 Aggregate
    for (int i = 0; i < cur_dim; i++)
      agg->elements.push_back(
          BuildNestedAggregate(dims, dim_start + 1, flat, pos));
  }
  return agg;
}
```

`ProcessConstDecl` 和 `ProcessVarDecl` 中全局数组初始化均改为：`dims.size() <= 1` 时用 flat Aggregate，否则用嵌套 Aggregate。

---

## 问题 2：部分解引用缺少 Array Decay

### 影响的测试
`12_more_arr_params`, `13_complex_arr_params`

### 现象

```
error: type mismatch, expected '*[i32, 10]', found '*[[i32, 10], 10]'
  %61 = call @f2(%35, %38, ...)
```

### 原因

3D 数组 `int a[10][10][10]` 的 `a[0]` 是 `int[10][10]`（2D 子数组）。作为函数实参传递时，需要 decay 一层变为 `int(*)[10]`（`*[i32, 10]`）。

但原代码**仅在 remaining dims == 1 时才执行 decay**：

```cpp
// 原代码: 只在子数组恰好剩 1 维时才 decay
if ((int)primary->indices.size() == total_dims - 1) {
    // decay: getelemptr ptr, 0
}
return make_unique<AllocRef>(ptr);  // 否则直接返回，缺少 decay
```

对于 `a[0]`（3D→1索引→剩2维），条件 `1 == 2` 不成立，decay 被跳过，结果类型仍是 `*[[i32,10],10]`。

### 修复 

子数组作为值使用时**始终**执行 decay（对应 C 标准的数组到指针隐式转换）：

```cpp
if ((int)primary->indices.size() < total_dims) {
  // 部分解引用, 子数组作为值使用 → 始终 decay 一层
  vector<unique_ptr<Value>> decay_idx;
  decay_idx.push_back(make_unique<Integer>(0));
  string p2 = GenerateArrayAccess(ptr, {}, false, decay_idx, block, reg_counter);
  return make_unique<AllocRef>(p2);
}
```

**验证各种情况：**

| 数组 | 表达式 | indices | total_dims | 第一次 getelemptr | decay getelemptr(0) | 最终类型 |
|------|--------|---------|------------|-------------------|---------------------|---------|
| `int[10][10]` | `a[0]` | 1 | 2 | `*[i32,10]` | `*i32` | `*i32` |
| `int[10][10][10]` | `a[0]` | 1 | 3 | `*[[i32,10],10]` | `*[i32,10]` | `*[i32,10]` |
| `int[10][10][10]` | `a[0][0]` | 2 | 3 | `*[i32,10]` | `*i32` | `*i32` |
| `int[10][10][10]` | `a` (无索引) | 0 | — | — | — | 走 `!has_indices` 路径 |

`!has_indices` 路径对任意维度数组都只做一次 getelemptr(0)，符合 C 语义（N 维数组 decay 为 N-1 维指针，无法跳到 N-2）。

---

## 问题 3：函数参数名与全局变量名冲突

### 影响的测试
`18_sort4`, `20_sort6`

### 现象

```
error: type mismatch, expected 'i32', found '*i32'
  store @n, @n_1
```

### 原因

当同时存在全局 `int n` 和函数参数 `int n` 时，Koopa IR 输出：

```
global @n = alloc i32, zeroinit    → @n: *i32 (全局)
fun @sort(@n: i32): void {         → @n: i32  (参数)
  @n_1 = alloc i32
  store @n, @n_1                   → Koopa 解析器将 @n 解析为全局 *i32
```

Koopa IR 在函数体内遇到 `@n` 时，**优先匹配全局变量名**而非同名参数，导致 `store` 的值类型是 `*i32`（全局地址），而非 `i32`（参数值）。

尝试用 `sub @n, 0` 间接引用参数也失败——`@n` 在任何指令中都被解析为全局变量。

### 修复 (IRGenerator.cpp, ProcessFuncDef)

检测参数名是否与全局作用域冲突，冲突时将 Koopa IR 参数名改为 `@_param_n`：

```cpp
string param_ref;
if (!scope_stack.empty()) {
  auto &global = scope_stack[0];
  if (global.count(fparam->ident)) {
    param_ref = "@_param_" + fparam->ident;   // 避免与全局冲突
  } else {
    param_ref = "@" + fparam->ident;
  }
}
func->params.push_back({param_ref, koopa_type});
```

生成的 IR 变为：

```
global @n = alloc i32, zeroinit
fun @sort(@_param_n: i32): void {    → @_param_n 唯一，不冲突
  @n_1 = alloc i32
  store @_param_n, @n_1              → @_param_n: i32, @n_1: *i32 ✓
```

参数重命名不影响 RISC-V 汇编输出——汇编层面参数通过 a0–a7 传递，不与符号名关联。

---

## 问题 4：大栈帧导致 RISC-V 立即数溢出

### 影响的测试
所有涉及大数组的函数（`main` 中有 `int arr[10][10][10]` 占 4000 字节）

### 现象

```
error: operand must be an integer in the range [-2048, 2047]
  lw t3, 4032(sp)
```

### 原因

`int[10][10][10]` 需要 10×10×10×4 = 4000 字节，加临时变量和 ra，栈帧 > 4096。RISC-V `lw`/`sw`/`addi` 的 12 位立即数范围 [-2048, 2047]，高于 2047 的 sp-relative 偏移全部越界。

### 修复

写 3 个辅助函数，对 offset > 2047 用 `li` + `add` 间接计算地址：

**EmitLoadSp(dst, offset)** — sp+offset 加载到 dst：
```asm
# offset ≤ 2047:  lw dst, offset(sp)
# offset > 2047:  li t5, offset; add t5, sp, t5; lw dst, 0(t5)
```

**EmitStoreSp(src, offset)** — src 存储到 sp+offset：
```asm
# offset ≤ 2047:  sw src, offset(sp)
# offset > 2047:  mv a7, src; li t5, offset; add t5, sp, t5; sw a7, 0(t5)
```

> **为什么用 a7 保存值？** `AllocReg()` 池 (t0–t6) 可能返回与 `src` 相同的寄存器，`li t5, offset` 后的 `add` 不破坏值，但 `li addr, offset`（如果用池）会覆盖 `src` 值。用固定 a7 先保存值，再用 t5 算地址，两条线互不干扰。

**EmitSpAdd(dst, offset)** — 计算 sp+offset 到 dst：
```asm
# offset ≤ 2047:  addi dst, sp, offset
# offset > 2047:  li off_reg, offset; add dst, sp, off_reg
```

**修改范围：**
- `EmitPrologue` / `EmitEpilogue`：`addi sp, sp, ±N` → 大帧用 `li` + `sub`/`add`
- `GetOperand`：`lw reg, offset(sp)` → `EmitLoadSp`
- `Visit(LOAD/STORE/GET_ELEM_PTR/GET_PTR/BINARY/CALL/RETURN)`：所有 sp 相对访问

---

## 问题 5：函数调用时 sp 修改导致参数加载地址错误

### 影响的测试
`12_more_arr_params`

### 现象

RISC-V 执行结果：WRONG ANSWER (-11)

### 原因

原 `Visit(CALL)` 代码：当参数 > 8 个时，**先** `addi sp, sp, -8` 为 extra args 预留空间，**再**通过 `GetOperand` 加载 a0–a7 的参数值。

但 `GetOperand` 使用 `stack_offsets`（在 `AssignStackOffsets` 中按函数入口时的 sp 计算）。sp 降低 8 之后：

```asm
addi sp, sp, -8        # sp → sp - 8
li t5, 4024
add t5, sp, t5          # t5 = (sp-8) + 4024 = 原sp + 4016 ← 偏移错！
lw t4, 0(t5)            # 从错误地址读取
mv a0, t4               # a0 用错误值
```

每个参数都偏移 8 字节，全部读到错误的值。

### 修复

改为**先加载全部参数，再改 sp**：

```cpp
// 1. a0-a7: 逐个加载并立即 mv (临时寄存器即用即释放)
for (int i = 0; i < num_args && i < 8; ++i) {
    auto arg = ...;
    std::string arg_reg = GetOperand(arg);  // 此时 sp 未被修改
    os << "  mv a" << i << ", " << arg_reg << "\n";
}

// 2. extra args: 先全部加载, 再改 sp, 再存栈
std::vector<std::string> extra_regs;
for (int i = 8; i < num_args; ++i) {
    extra_regs.push_back(GetOperand(arg));  // 此时 sp 未被修改
}
if (extra_args > 0) {
    os << "  addi sp, sp, -" << (extra_args * 4) << "\n";  // 最后才改 sp
    for (int i = 0; i < extra_args; ++i)
        os << "  sw " << extra_regs[i] << ", " << (i * 4) << "(sp)\n";
}

// 3. call + 恢复 sp
os << "  call " << func_name << "\n";
if (extra_args > 0)
    os << "  addi sp, sp, " << (extra_args * 4) << "\n";
```

### 为什么不能一次性 GetOperand 全部 10 个参数

临时寄存器池 `t0–t6` 只有 **7 个**，10 个 `GetOperand` 全先加载会溢出。解法是 **a0–a7 逐个加载→立即 mv 到参数寄存器**，即用即释放。


### 完成Lv9导致Lv8的一个测试点过不了

###### 现象

```
root@64c69cd37f9c:~# autotest -riscv -s lv8 /root
run test in "-riscv" mode
working directory: /tmp/tmpz1erq66a
make: Entering directory '/root'
mkdir -p /tmp/tmpz1erq66a/
flex  -o /tmp/tmpz1erq66a/sysy.lex.cpp /root/src/sysy.l
mkdir -p /tmp/tmpz1erq66a/
bison -d -o /tmp/tmpz1erq66a/sysy.tab.cpp /root/src/sysy.y
mkdir -p /tmp/tmpz1erq66a/
clang++ -I/root/src -I/tmp/tmpz1erq66a -MMD -MP -Wall -Wno-register -std=c++17 -O2 -I/opt/include -c /tmp/tmpz1erq66a/sysy.lex.cpp -o /tmp/tmpz1erq66a/sysy.lex.cpp.o
mkdir -p /tmp/tmpz1erq66a/
clang++ -I/root/src -I/tmp/tmpz1erq66a -MMD -MP -Wall -Wno-register -std=c++17 -O2 -I/opt/include -c /tmp/tmpz1erq66a/sysy.tab.cpp -o /tmp/tmpz1erq66a/sysy.tab.cpp.o
mkdir -p /tmp/tmpz1erq66a/
clang++ -I/root/src -I/tmp/tmpz1erq66a -MMD -MP -Wall -Wno-register -std=c++17 -O2 -I/opt/include -c /root/src/ASMGenerator.cpp -o /tmp/tmpz1erq66a/ASMGenerator.cpp.o
mkdir -p /tmp/tmpz1erq66a/
clang++ -I/root/src -I/tmp/tmpz1erq66a -MMD -MP -Wall -Wno-register -std=c++17 -O2 -I/opt/include -c /root/src/IRGenerator.cpp -o /tmp/tmpz1erq66a/IRGenerator.cpp.o
mkdir -p /tmp/tmpz1erq66a/
clang++ -I/root/src -I/tmp/tmpz1erq66a -MMD -MP -Wall -Wno-register -std=c++17 -O2 -I/opt/include -c /root/src/main.cpp -o /tmp/tmpz1erq66a/main.cpp.o
clang++ /tmp/tmpz1erq66a/sysy.lex.cpp.o /tmp/tmpz1erq66a/sysy.tab.cpp.o /tmp/tmpz1erq66a/ASMGenerator.cpp.o /tmp/tmpz1erq66a/IRGenerator.cpp.o /tmp/tmpz1erq66a/main.cpp.o -L/opt/lib/native -lkoopa -lpthread -ldl -o /tmp/tmpz1erq66a/compiler
make: Leaving directory '/root'
running test "00_int_func" ... PASSED
running test "01_void_func" ... PASSED
running test "02_params" ... PASSED
running test "03_more_params" ... WRONG ANSWER
your answer:
179
running test "04_param_name" ... PASSED
running test "05_func_name" ... PASSED
running test "06_complex_call" ... PASSED
running test "07_recursion" ... PASSED
running test "08_lib_funcs" ... PASSED
running test "09_globals" ... PASSED
running test "10_complex" ... PASSED
running test "11_short_circuit" ... PASSED
WRONG ANSWER (11/12)
```

错误是答案错误（输出 179，期望值不同）,lv8 的一个坑就是 RISC-V 传参超过 8 个时要用栈传参。

###### 写一个t8_3.c：

```
int f(int a, int b, int c, int d, int e, int f2, int g, int h, int i, int j) {
  return a + b + c + d + e + f2 + g + h + i + j;
}
int main() {
  return f(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
} 
```

手工走了一遍汇编:

```
/root/build/compiler  -riscv t8_3.c -o t8_3.s
```

f(1..10)=55 逻辑上是正确的（参数 9/10 通过栈传，偏移 128(sp)/132(sp) 与调用方 addi sp,-8 对应）。所以 t8_3 本身不是 03_more_params（答案 179 不同）。这也说明 03_more_params 不是 10 个参数这么简单。

关键还是在 lv8→lv9 的改动里。

通过比对ASMGenerator.cpp 发生的改动 between lv8 and lv9，发现关键改动在 CALL 指令处理和 alloc/load/store。lv8 是"每存一个参数就立即 GetOperand+sw"（用完即弃寄存器），lv9 改为"先把所有额外参数值缓存进寄存器，再统一减 sp 存入"。如果额外参数 ≥8 个，缓存寄存器循环分配必然冲突。

lv8 版：


```
if (extra_args > 0) {
    addi sp, sp, -N;
    for (i = 8; i < num_args; ++i) {
        arg_reg = GetOperand(arg);     // 取一个，立刻 sw 一个，寄存器用完即弃
        sw arg_reg, (i-8)*4(sp);
    }
}
// 之后再设 a0-a7
```
lv9 版：

```
for (i = 0; i < 8; ++i) { GetOperand(arg); mv a_i, arg_reg; }   // 先设 a0-a7
std::vector<std::string> extra_regs;                             // 缓存所有额外参数
for (i = 8; i < num_args; ++i) extra_regs.push_back(GetOperand(arg));
addi sp, sp, -N;
for (i = 0; i < extra; ++i) sw extra_regs[i], i*4(sp);           // 最后统一存
```

lv9 这么改的动机是对的：lv8 是"先减 sp、再 GetOperand 加载额外参数"，如果额外参数是当前函数的栈变量，偏移就全错了；lv9 改成"sp 未变时先加载、后减 sp 再存"。

但它引入了一个新的 bug——寄存器覆盖：

AllocReg() 只在 t0–t6 七个寄存器里循环分配（ASMGenerator.cpp:42-44）。lv9 把所有额外参数的值一次性缓存进 extra_regs 寄存器数组，等最后一个才统一 sw。当额外参数（或其累计分配）达到 8 个时，第 8 个参数分到的寄存器必然与第 1 个相同：


```
extra[0] → t0   ← 值 9
extra[1] → t1
 ...
extra[7] → t0   ← 值 16 覆盖了 extra[0] 的 9
```

于是 sw t0, 0(sp) 存进去的是 16 而不是 9 → 被调函数第 9 个参数收到错误的值 → WRONG ANSWER。

触发条件：单个调用的实参 ≥ 16 个（额外参数 ≥ 8）。lv8 之所以没事，是因为它每个额外参数"取一个就存一个"，寄存器不用长期存活，永远不会冲突。

###### 用03_more_params 的源码验证一下：

```
root@64c69cd37f9c:~# cat /opt/bin/testcases/lv8/03_more_params.c
int sum(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7) {
  return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7;
}

int sum2(int a0, int a1, int a2, int a3, int a4, int a5, int a6, int a7, int a8,
         int a9, int a10, int a11, int a12, int a13, int a14, int a15) {
  return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9 + a10 + a11 + a12 +
         a13 + a14 + a15;
}

int main() {
  int x = sum(1, 2, 3, 4, 5, 6, 7, 8);
  int y = sum2(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
  return x + y;
}
```


sum2 有 16 个参数，其中 8 个（第 9~16 个）走栈传递。

sum2(1,2,...,16) 时，第 9~16 个实参（值 9..16）被 lv9 的 CALL 代码 ASMGenerator.cpp:594-605 一次性缓存进 extra_regs 寄存器数组，而 AllocReg() 只在 t0–t6 循环：

```
extra[0] 值9  → t0
extra[1] 值10 → t1
extra[2] 值11 → t2
extra[3] 值12 → t3
extra[4] 值13 → t4
extra[5] 值14 → t5
extra[6] 值15 → t6
extra[7] 值16 → t0   ← 循环回 t0，覆盖了 extra[0] 的 9
```


随后统一 sw 到栈：


```
sw t0, 0(sp)   ← 存进去的是 16（本应 9）
sw t1, 4(sp)   ← 10
...
sw t6, 24(sp)  ← 15
sw t0, 28(sp)  ← 16
```


于是 sum2 收到的栈参数变成 16,10,11,12,13,14,15,16，寄存器参数 1..8 正常：

```
sum  = 1+..+8              = 36
sum2 = 36 + (16+10+11+12+13+14+15+16) = 36 + 107 = 143
总   = 36 + 143 = 179  ← 正是 WRONG ANSWER 的值
```


对上了。正确结果应该是 36 + (9+10+..+16)=36+100 = 172。

lv8 为什么没问题：lv8 的 CALL 是"取一个额外参数就立即 sw 一个"，寄存器用完即弃，从不长期存活，所以 t0–t6 循环不会造成覆盖。lv9 改成"全部缓存后再统一存"引入了这个回归。


###### 修复

回到"即取即存"避免寄存器覆盖，但保持在 sp 未调整时取值以保证偏移正确。做法是把额外参数在 sp 未减时直接写入"负偏移"位置（减 sp 后正好落到 0..extra_size-4），并先处理额外参数、再设 a0–a7，这样 EmitStoreSp 里用 a7 做 scratch 也不会破坏已设的参数寄存器。


### 总结

大致完成了实验要求，Lv1~9可以通过koopa&&riscv的章节单独测试，测试所有章节有一些测试点过不了，不想做了。

* [我的实现](https://github.com/farmer3-c/sysy-compiler-lab/tree/main)