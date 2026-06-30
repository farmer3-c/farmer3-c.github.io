---
title: 编译实践Lv2.初试目标代码生成
date: 2026-06-30T09:41:16+08:00
author: farmer3-c
tags:
- PKU 编译原理实践
draft: false
---

# 目的

实现一个能处理 main 函数和 return 语句的编译器, 同时输出编译后的 RISC-V 汇编。

编译器会将如下的 SysY 程序:

```
int main() {
  // 摊牌了, 我是注释
  return 0;
}
```

编译为对应的 RISC-V 汇编:

``` 
  .text
  .globl main
main:
  li a0, 0
  ret
```
或:

```
  .text
  .globl main
main:
  li t0, 0
  mv a0, t0
  ret
```

# 实现

## Lv2.1. 处理 Koopa IR

这一节的任务是建立内存形式的 Koopa IR。

libkoopa 中的接口并没有我定义的AST数据类型，所以可以先把 Program Dump 到 string 中，再用koopa_parse_from_string解析这个 string，得到内存形式的 Koopa IR。

## Lv2.2. 目标代码生成

这一节的任务是生成 RISC-V 汇编。

可以写一个头文件和cpp文件（ASMGenerator.h,ASMGenerator.cpp）专门用来生成汇编。在ASMGenerator.h中声明需要用到的函数，

```
class ASMGenerator {
public:
    ASMGenerator(std::ostream &os) : os(os) {}
    void Generate(const koopa_raw_program_t &program);

private:
    // DFS 遍历族
    void Visit(const koopa_raw_program_t &program);
    void Visit(const koopa_raw_slice_t &slice);
    void Visit(const koopa_raw_function_t &func);
    void Visit(const koopa_raw_basic_block_t &bb);
    void Visit(const koopa_raw_value_t &value);

    // 辅助
    void EmitPrologue();
    void EmitEpilogue();

    // 共享状态
    std::ostream &os;
    int frame_size = 0;                  // 对齐后的栈帧大小
    std::string cur_func;                // 当前函数名（已去 @）
};
```

在ASMGenerator.cpp分别实现这些函数，

#### EmitPrologue()


EmitPrologue() 生成函数开头的固定汇编代码，负责声明符号 、分配栈帧、保存返回地址 、保存旧的帧指针、设置新的帧指针。

    ```
        void ASMGenerator::EmitPrologue() {
        os << "  .text\n";
        os << "  .globl " << cur_func << "\n";
        os << cur_func << ":\n";
        // 栈帧: 保存 ra(4) + s0(4), 对齐到 16 字节
        frame_size = 16;
        os << "  addi sp, sp, -" << frame_size << "\n";
        os << "  sw ra, " << (frame_size - 4) << "(sp)\n";
        os << "  sw s0, " << (frame_size - 8) << "(sp)\n";
        os << "  addi s0, sp, " << frame_size << "\n";
        }
    ```
    RISC-V 的某些指令（比如加载/存储双字 ld/sd）要求地址按 16 字节对齐，否则触发异常。目前 frame_size 写死为 16，刚好匹配。

#### EmitEpilogue()

对应 EmitEpilogue()（尾声）做相反的操作：恢复 ra/s0 → 回收栈帧 → ret。
    ```
        void ASMGenerator::EmitEpilogue() {
        os << ".L" << cur_func << "_exit:\n";
        os << "  lw ra, " << (frame_size - 4) << "(sp)\n";
        os << "  lw s0, " << (frame_size - 8) << "(sp)\n";
        os << "  addi sp, sp, " << frame_size << "\n";
        os << "  ret\n";
        }
    ```

#### DFS 遍历族

Generate 开启 visit program 的 funcs, Visit(const koopa_raw_slice_t &slice) 遍历 slice 的 buffer 进行下一步的visit，
        
* KOOPA_RSIK_FUNCTION 则进行 ASMGenerator::Visit(const koopa_raw_function_t &func)。因为 Koopa IR 和 RISC-V 汇编的语法规则不同，Koopa IR 中，函数名带 @ 前缀：`@main 、call @getint`是标签名的合法字符, 而RISC-V 汇编（GNU assembler）中，@ 不是标签名的合法字符：`.globl @main、 @main:、call @getint ` , 而汇编器要求标签名只能由字母、数字、.、_ 组成，所以必须去掉 @ 。函数体为空（仅有声明）则跳过，然后是EmitPrologue()，遍历基本块，最后是 EmitEpilogue()。

* KOOPA_RSIK_BASIC_BLOCK 则进行 ASMGenerator::Visit(const koopa_raw_basic_block_t &bb)。发射基本块标签，然后再遍历指令。

* KOOPA_RSIK_VALUE 则进行 ASMGenerator::Visit(const koopa_raw_value_t &value)。switch(value->kind.tag) 判断继续执行什么操作，当前只要完成return功能就可以了。

## Lv2.3. 测试

make完成后，先执行

```
/root/build/compiler -riscv hello.c -o hello.s
```

可以完成对汇编的转化。

再测试

```
autotest -riscv -s lv1 /root
```


测试结果：
![2](/img/pku-compiler/image%282%29.png)
