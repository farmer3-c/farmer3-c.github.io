---
title: "luoguP1112波浪数"
date: 2026-09-02T19:58:34+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1112 波浪数](https://www.luogu.com.cn/problem/P1112)

## 我理解的题目意思

波浪数是在一对不同数字之间交替转换的数,双重波浪数则是指在两种进制下都是波浪数的数。特别地，只有一位的数也算作波浪数，例如 1。

输入单独一行包含五个用空格隔开的十进制整数 l,r,L,R,k。[l,r] 表示应当考虑的进制的范围，[L,R] 表示应当考虑的数字的范围，k 表示你应该找的波浪数的重数。

输出从小到大以十进制形式输出指定范围内的指定重数的波浪数。一行输出一个数。

$$2≤l≤r≤32，1≤L≤R≤10^7，k∈{2,3,4}。$$

## 解题思路

最暴力的方法肯定是遍历[L,R]的每个数进行[l,r]进制的波浪数检查，然后输出符合需要重数的数。但这样大概率会超时，而且不美观，肯定有更聪明的解法。

我不找数，让数来找我，构造符合[l,r]进制的波浪数，维护一个数组来记录数的波浪数重数，最后顺序输出就可以了。怎么构造呢，枚举两个不同的k进制数`i、j`，使得在数中`i、j`交替出现，设置一个标志用于判断何时应该放i何时放j。细节：i从1开始枚举，j从0开始枚举，先在数中放i。

代码：
```
#include <iostream>

using namespace std;

int v[10000005];
int m, n, l, r, c;

int main()
{
    cin >> m >> n >> l >> r >> c;
    for (int k = m; k <= n; k++)
    {
        for (int i = 1; i < k; i++)
            for (int j = 0; j < k; j++)
            {
                if (i != j)
                {
                    int x = 0, t = 0;
                    while (x <= r)
                    {
                        if (t % 2 == 0)
                        {
                            x = x * k + i;
                            t++;
                        }
                        else
                        {
                            x = x * k + j;
                            t++;
                        }
                        if (x >= l && x <= r)
                        {
                            v[x]++;
                        }
                    }
                }
            }
    }
    for (int i = l; i <= r; i++)
    {
        if (v[i] == c)
            cout << i << endl;
    }
    return 0;
}
```