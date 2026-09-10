---
title: "luoguP1122 最大子树和"
date: 2026-09-10T22:29:21+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1122 最大子树和](https://www.luogu.com.cn/problem/P1122)


## 我理解的题目意思

给出n个点，点具有点权a[i]，n-1条双向边将点连接为一个树，通过剪枝使得剩下的点权和最大，输出最大值。

$$1≤n≤16000，a_i范围在 [−10^9,10^9] 内$$

## 解题思路

使用vector数组记录点的邻接点，使用f[i]记录保留a[i]的最大点权和。初始化f[i]为a[i],dfs点i的邻接点k的最大点权和，若f[k]>0，则f[i]=f[i]+f[k]，同时设置一个fa用于避免反向搜索到起点。

代码：

```
#include <iostream>
#include <vector>

using namespace std;

vector<int> ad[20000];
int n;
int ans = 1 << 31;
int a[20000];
int f[20000];
void dfs(int u, int fa)
{
    f[u] = a[u];
    for (int i = 0; i < ad[u].size(); i++)
    {
        int t = ad[u][i];
        if (t != fa)
        {
            dfs(t, u);
            if (f[t] > 0)
            {
                f[u] += f[t];
            }
        }
    }
}
int main()
{
    cin >> n;

    for (int i = 1; i <= n; i++)
    {
        cin >> a[i];
    }
    for (int i = 1; i <= n - 1; i++)
    {
        int x, y;
        cin >> x >> y;

        ad[x].push_back(y);
        ad[y].push_back(x);
    }
    dfs(1, 0);
    for (int i = 1; i <= n; i++)
        ans = max(ans, f[i]);

    cout << ans;

    return 0;
}
```

* 参考
[Mutsumi_0114](https://www.luogu.com.cn/article/b4dvzxoi)