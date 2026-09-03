---
title: "luoguP1113[USACO02FEB]杂务"
date: 2026-09-03T20:53:54+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1113 [USACO02FEB] 杂务](https://www.luogu.com.cn/problem/P1113)

## 我理解的题目意思

这是一个图论问题：拓扑排序，题目给出了一个 DAG（有向无环图），n个顶点之间通过有向边连接，顶点具有点权len，要求出任意两点之间的路径上所有顶点的最大总点权和。

$$3≤n≤10000，1≤len≤100$$

## 解题思路

按照题意模拟即可，维护一个数组v记录任意初始点到点i之间路径上所有顶点的最大总点权和，初始点x的v[x]等于自身点权。递归查询非初始点y的所有前缀点qi的v[qi]，v[y]=点权y+max(v[qi])。最后遍历查询v的最大值输出。

代码：

```
#include <iostream>
#include <vector>
#include <cstring>
using namespace std;

struct th
{
    int t;
    vector<int> pre;
} sh[10005];

int n;

int v[10005], ans = 0;

int find(int i)
{
    if (v[i] == 0x3f3f3f3f)
    {
        int k = 0;
        for (int p : sh[i].pre)
        {
            k = max(k, find(p));
        }
        v[i] = sh[i].t + k;
    }
    return v[i];
}

int main()
{
    cin >> n;
    memset(v, 0x3f, sizeof(v));
    for (int i = 1; i <= n; i++)
    {
        int x, tx;
        cin >> x >> tx;
        sh[i].t = tx;
        cin >> x;
        int cnt = 0;
        while (x != 0)
        {
            sh[i].pre.push_back(x);
            cin >> x;
            cnt++;
        }
        if (cnt == 0)
            v[i] = tx;
    }

    for (int i = 1; i <= n; i++)
    {
        ans = max(ans, find(i));
    }
    cout << ans;

    return 0;
}
```
