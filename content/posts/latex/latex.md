---
draft: false
---
﻿---
layout: post
title: "latex常用手册"
subtitle: "latex"
date: 2025-09-06 19:57:11 +0800
author: "farmer3-c"
header-img: "img/post-bg-2015.jpg"
tags: [latex]
mathjax: true 
---

## 常用符号与表达式

- 根式：$\sqrt[n]{x}$

  ```latex
  \sqrt[n]{x}
  ```

- 分数：$\frac{x}{y}$

  ```latex
  \frac{x}{y}
  ```

- 上下标：$x_i^2, a_{ij}^{kl}, \Gamma_{n}^{k}$

  ```latex
  x_i^2, a_{ij}^{kl}, \Gamma_{n}^{k}
  ```

- 文本：$\textit{f}_a^b$

  ```latex
  \textit{f}_a^b
  ```

- 算子与常见符号：$\nabla, \Delta, \mathrm{i}, \approx, \overline{A}$

  ```latex
  \nabla, \Delta, \mathrm{i}, \approx, \overline{A}
  ```

- 希腊字母：$\alpha, \beta, \gamma, \eta, \xi, \phi, \psi, \omega, \theta, \lambda$

  ```latex
  \alpha, \beta, \gamma, \eta, \xi, \phi, \psi, \omega, \theta, \lambda
  ```

- 向量与矩阵运算：$\mathbf{a} \times \mathbf{b},\ \mathbf{A + B = C}$

  ```latex
  \mathbf{a} \times \mathbf{b}
  \mathbf{A + B = C}
  ```

## 关系与逻辑

- 不等式：$a \le b,\ a \ge b,\ a \neq b,\ a \ll b,\ a \gg b$

  ```latex
  a \le b,\ a \ge b,\ a \neq b,\ a \ll b,\ a \gg b
  ```

- 蕴含与等价：$p \implies q,\ p \iff q$

  ```latex
  p \implies q,\ p \iff q
  ```

- 逻辑运算：$p \land q,\ p \lor q$

  ```latex
  p \land q,\ p \lor q
  ```

- 全称与存在：$\forall x,\ \exists x$

  ```latex
  \forall x,\ \exists x
  ```

- 无穷：$\infty$

  ```latex
  \infty
  ```

## 集合与算子

- 集合表示：$A = \{ x \mid x > 0 \}$

  ```latex
  A = \{ x \mid x > 0 \}
  ```

- 元素关系：$a \in A,\ b \notin A$

  ```latex
  a \in A,\ b \notin A
  ```

- 包含关系：$A \subset B,\ A \subsetneq B,\ B \supset A$

  ```latex
  A \subset B,\ A \subsetneq B,\ B \supset A
  ```

- 常见集合：$\mathbb{R}$

  ```latex
  \mathbb{R}
  ```

## 矩阵与行列式

- 基本矩阵：
  $$
  \begin{matrix}
  a & b & c \\
  d & e & f \\
  g & h & i
  \end{matrix}
  $$

- 常用矩阵环境：
  - `matrix`：无括号
  - `pmatrix`：圆括号
  - `bmatrix`：方括号
  - `Bmatrix`：花括号
  - `vmatrix`：行列式竖线
  - `Vmatrix`：双竖线

- 雅可比行列式：
  $$
  \frac{\partial (f,g)}{\partial (x,y)} =
  \begin{vmatrix}
  \frac{\partial f}{\partial x} & \frac{\partial f}{\partial y} \\
  \frac{\partial g}{\partial x} & \frac{\partial g}{\partial y}
  \end{vmatrix}
  $$

  ```latex
  \frac{\partial (f,g)}{\partial (x,y)} =
  \begin{vmatrix}
  \frac{\partial f}{\partial x} & \frac{\partial f}{\partial y} \\
  \frac{\partial g}{\partial x} & \frac{\partial g}{\partial y}
  \end{vmatrix}
  ```

## 微积分与导数

- 定积分：$\int_{a}^{b} f(x) \, dx$

  ```latex
  \int_{a}^{b} f(x) \, dx
  ```

- 极限：$\lim_{x \to 0} f(x)$

  ```latex
  \lim_{x \to 0} f(x)
  ```

- 偏导数：$\frac{\partial f}{\partial x},\ \frac{\partial^2 f}{\partial x \partial y}$

  ```latex
  \frac{\partial f}{\partial x},\ \frac{\partial^2 f}{\partial x \partial y}
  ```

## 分段函数与条件表达

$$
f(x)=
\begin{cases}
 x^2,      & x>0 \\
 0,        & x=0 \\
 -x^2,     & x<0
\end{cases}
$$

```latex
$$
f(x)=
\begin{cases}
 x^2,      & x>0 \\
 0,        & x=0 \\
 -x^2,     & x<0
\end{cases}
$$
```

- 带条件的箭头：$A \xrightarrow[\text{下方条件}]{\text{上方条件}} B$

  ```latex
  A \xrightarrow[\text{下方条件}]{\text{上方条件}} B
  ```

## 优化与极值

- 目标函数：
  $$
  \min_{\substack{x_1, x_2}} \left( x_1 + x_2 + P(x_1^2 + x_2^2 - 1) \right)
  $$

  ```latex
  $$
  \min_{\substack{x_1, x_2}} \left( x_1 + x_2 + P(x_1^2 + x_2^2 - 1) \right)
  $$
  ```

- 对偶问题：
  $$
  \underset{x_1, x_2}{\text{Min.}}\, x_1 + x_2 + \underset{\lambda \ge 0}{\text{Max.}}\, \lambda(x_1^2 + x_2^2 - 1)
  $$

  ```latex
  \underset{x_1, x_2}{\text{Min.}}\, x_1 + x_2 + \underset{\lambda \ge 0}{\text{Max.}}\, \lambda(x_1^2 + x_2^2 - 1)
  ```

- KKT 梯度条件：
  $$
  \frac{\partial L(x,\lambda^*,\mu^*)}{\partial x}\Big|_{x=x^*}
  = \nabla f(x^*) + \sum_{i=1}^{m} \lambda_i^* \nabla g_i(x^*) + \sum_{j=1}^{p} \mu_j^* \nabla h_j(x^*) = 0
  $$

  ```latex
  \frac{\partial L(x,\lambda^*,\mu^*)}{\partial x}\Big|_{x=x^*}
  = \nabla f(x^*) + \sum_{i=1}^{m} \lambda_i^* \nabla g_i(x^*) + \sum_{j=1}^{p} \mu_j^* \nabla h_j(x^*) = 0
  ```

- 矩阵正定性：
  - $A \succ 0$：严格正定
  - $A \succeq 0$：半正定
  - $A \prec 0$：严格负定
  - $A \preceq 0$：半负定

## 常用数学公式

- 二次公式：
  $$
  x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}
  $$

- 勾股定理：
  $$
  a^2 + b^2 = c^2
  $$

- 完全平方：
  $$
  (a+b)^2 = a^2 + 2ab + b^2
  $$

- 三角恒等式：
  $$
  \sin^2 x + \cos^2 x = 1
  $$

- 幂函数导数：
  $$
  \frac{d}{dx} x^n = nx^{n-1}
  $$

- 积分基本公式：
  $$
  \int_a^b f(x)\,dx = F(b)-F(a)
  $$

- 欧拉公式：
  $$
  e^{\mathrm{i}\theta} = \cos\theta + \mathrm{i}\sin\theta
  $$

- 指数函数展开：
  $$
  e^x = \sum_{n=0}^{\infty} \frac{x^n}{n!}
  $$

