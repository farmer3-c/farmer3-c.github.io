---
title: "luoguP1123 取数游戏"
date: 2026-09-11T21:49:48+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1123 取数游戏](https://www.luogu.com.cn/problem/P1123)


## 我理解的题目意思

一个 N×M 的由非负整数构成的数字矩阵，你需要在其中取出**若干**个数字，使得取出的任意两个数字**不相邻**（若一个数字在另外一个数字相邻 8 个格子中的一个即认为这两个数字相邻），求取出数字和最大是多少。

$$1≤N,M≤6，1≤T≤20，ai,j​≤10^5$$

## 解题思路

注意到数据量很小，可以dfs最大的数字和，维护一个chosen数组做一个待选择数字是否有相邻数字被选择的判断。

代码：

```
#include <iostream>
#include <algorithm>
using namespace std;

int t, n, m, ans;
int a[10][10];

// 检查 (x,y) 是否与已选的格子相邻
bool ok(int x, int y, bool chosen[10][10])
{
    for (int dx = -1; dx <= 1; dx++)
    {
        for (int dy = -1; dy <= 1; dy++)
        {
            if (dx == 0 && dy == 0)
                continue;
            int nx = x + dx;
            int ny = y + dy;
            if (nx >= 1 && ny >= 1 && nx <= n && ny <= m && chosen[nx][ny])
                return false;
        }
    }
    return true;
}

void dfs(int x, int y, int sum, bool chosen[10][10])
{
    if (x > n)
    {
        ans = max(ans, sum);
        return;
    }
    int nx = (y == m) ? x + 1 : x;
    int ny = (y == m) ? 1 : y + 1;

    dfs(nx, ny, sum, chosen);

    if (ok(x, y, chosen))
    {
        chosen[x][y] = true;
        dfs(nx, ny, sum + a[x][y], chosen);
        chosen[x][y] = false;
    }
}

int main()
{
    cin >> t;
    while (t--)
    {
        cin >> n >> m;
        for (int i = 1; i <= n; i++)
            for (int j = 1; j <= m; j++)
                cin >> a[i][j];
        ans = 0;
        bool chosen[10][10] = {};
        dfs(1, 1, 0, chosen);
        cout << ans << endl;
    }
    return 0;
}
```