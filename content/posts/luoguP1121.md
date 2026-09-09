---
title: "luoguP1121"
date: 2026-09-09T22:56:39+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1121 环状最大两段子段和](https://www.luogu.com.cn/problem/P1121)

## 我理解的题目意思

给出一段长度为 n 的环状序列 a，即认为 a1​ 和 an​ 是相邻的，选出其中连续不重叠且非空的两段使得这两段和最大。

$$2≤n≤2×10^5，−10^4≤a_i​≤10^4$$

## 解题思路

从前到后计算出到a[i]之前的最大字段和af[i]，从后到前计算出到a[i+1]之前的最大字段和ab[i],遍历枚举出最大的af[i]+ab[i+1]作为初始的环状最大两段子段和ans。

再计算将max方法改为min，从前到后计算出到a[i]之前的最小字段和mf[i]，从后到前计算出到a[i+1]之前的最小字段和mb[i],遍历枚举出最小的af[i-1]+ab[i+1]作为环状最小两段子段和t。

比较ans和sum-t，ans=max(ans,sum-t).

代码：

```
#include <iostream>
#include <algorithm>
#include <cstring>
#define size 300000
using namespace std;

int n;
int a[size], af[size], ab[size], mf[size], mb[size];

int sum;

int getmin(int *arr, int l)
{
    mf[1] = a[1];
    for (int i = 2; i <= l; i++)
        mf[i] = min(mf[i - 1], 0) + a[i];
    for (int i = 2; i <= l; i++)
        mf[i] = min(mf[i - 1], mf[i]);
    int ans = 1ll << 31ll - 1ll;
    mb[l] = a[l];
    for (int i = l - 1; i > 1; i--)
        mb[i] = min(mb[i + 1], 0) + a[i];
    for (int i = l - 1; i > 1; i--)
        mb[i] = min(mb[i + 1], mb[i]);

    for (int i = 2; i <= l- 1; i++)
        ans = min(ans, mf[i - 1] + mb[i + 1]);
    return ans;
}

int main()
{
    cin >> n;
    for (int i = 1; i <= n; i++)
    {
        cin >> a[i];
        sum += a[i];
    }
    af[1] = a[1];
    for (int i = 2; i <= n; i++)
        af[i] = max(af[i - 1], 0) + a[i];
    for (int i = 2; i <= n; i++)
        af[i] = max(af[i - 1], af[i]);
    int ans = 1ll << 31ll;
    ab[n] = a[n];
    for (int i = n - 1; i > 1; i--)
        ab[i] = max(ab[i + 1], 0) + a[i];
    for (int i = n - 1; i > 1; i--)
        ab[i] = max(ab[i + 1], ab[i]);

    for (int i = 1; i <= n - 1; i++)
        ans = max(ans, af[i] + ab[i + 1]);

    // ans = max(ans, sum - getmin(a, n - 1));
    ans = max(ans, sum - getmin(a + 1, n - 1));
    cout << ans;

    return 0;
}
```

* 参考
[zhy137036](https://www.luogu.com.cn/article/7fsg49ww)