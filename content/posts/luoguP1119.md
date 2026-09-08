---
title: "luoguP1119 灾后重建"
date: 2026-09-07T22:18:00+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1119 灾后重建](https://www.luogu.com.cn/problem/P1119)

## 我理解的题目意思

给出N个点、M条双向边、点存在的最早时间ti。做Q次查询t时刻点x和y之间的最短距离，若此时无法连通，则输出-1。

$$t_0​≤t_1​≤⋯≤t_{N−1}​$$
$$查询的 t 是不下降的$$
$$1≤N≤200，0≤M≤N×(N−1)/2​，1≤Q≤50000,所有输入数据涉及整数均不超过 10^5$$

## 解题思路

每次查询时遍历小于等于t的tk,使用floyd算法计算加入点k之和的最短路径长度数组，初始化最短路径长度数组为一个较大的数inf，若f[x][y]=inf则输出-1，否则输出f[x][y]。

代码：

```
#include <iostream>
#include <algorithm>
#define len 205

using namespace std;

int a[len];
int f[len][len];

int n, m;

void update(int k)
{
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            if (f[i][j] > f[i][k] + f[k][j])
                f[i][j] = f[i][k] + f[k][j];
        }
    }
    return;
}

int main()
{
    cin >> n >> m;

    for (int i = 0; i < n; i++)
    {
        cin >> a[i];
        f[i][i] = 0;
    }
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            if (i != j)
                f[i][j] = 1e9;
        }
    }

    for (int s = 1; s <= m; s++)
    {
        int x, y, w;
        cin >> x >> y >> w;
        f[x][y] = f[y][x] = w;
    }

    int q;
    int k = 0;
    cin >> q;
    for (int s = 1; s <= q; s++)
    {
        int x, y, t;
        cin >> x >> y >> t;
        while (a[k] <= t && k < n)
        {
            update(k);
            k++;
        }
        if (t < a[x] || t < a[y])
            cout << -1 << endl;
        else
        {
            if (f[x][y] == 1e9)
                cout << -1 << endl;
            else
                cout << f[x][y] << endl;
        }
    }

    return 0;
}
```

* 参考
[Time_Rune](https://www.luogu.com.cn/article/exd26lmn)
