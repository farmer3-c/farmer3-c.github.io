---
title: "luoguP1125 [NOIP 2008 提高组] 笨小猴"
date: 2026-09-13T13:45:11+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1125 [NOIP 2008 提高组] 笨小猴](https://www.luogu.com.cn/problem/P1125)

## 我理解的题目意思

一个字符串中出现次数最多的字母的出现次数是 maxn ，minn 是出现次数最少的字母的出现次数，如果 maxn−minn 是一个质数,那么输出 Lucky Word，再换行输出 maxn−minn 的值；否则输出 No Answer,，换行输出 0。

$$字符串长度小于 100$$

## 解题思路

依题意模拟即可，用数组b记录字母出现次数，遍历出maxn、minn，再判断maxn−minn是否为质数。

代码：

```
#include <iostream>
#include <algorithm>
using namespace std;

char a[105];

int main()
{
    cin >> a;
    int b[26] = {0};
    for (int i = 0; a[i] != '\0'; i++)
    {
        b[a[i] - 'a']++;
    }
    int maxn = -1, minn = 105;
    for (int i = 0; i < 26; i++)
    {
        if (b[i] > 0)
        {
            maxn = max(maxn, b[i]);
            minn = min(minn, b[i]);
        }
    }
    int ans = maxn - minn;
    for (int i = 2; i <= ans / 2; i++)
    {
        if (ans % i == 0 && ans != 2)
        {
            cout << "No Answer" << endl
                 << 0;
            return 0;
        }
    }
    if (ans < 2)
        cout << "No Answer" << endl
             << 0;
    else cout << "Lucky Word" << endl
         << ans;

    return 0;
}
```