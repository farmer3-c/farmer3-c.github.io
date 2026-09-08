---
title: "luoguP1120 [CERC 1995] 小木棍"
date: 2026-09-08T19:52:53+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1120 [CERC 1995] 小木棍](https://www.luogu.com.cn/problem/P1120)

## 我理解的题目意思

有一些同样长的木棍，把这些木棍随意砍成几段，直到每段的长都不超过 50。给出n段小木棍的长度,找出原始木棍的最小可能长度。

$$1≤n≤65，1≤a_i​≤50$$

## 解题思路

首先确定原始木棍的长度范围，也就是搜索范围：

* 原始木棍数量大于等于2，长度len上限是$\frac{1}{2} \sum_{i=1}^{n}a_i$，下限为$max(a_i)$。
* 原始木棍数量等于1,长度len$=\sum_{i=1}^{n}a_i$，直接输出就行。

对于原始木棍数量大于等于2的情况，使用dfs进行搜索，要进行几个剪枝，下面是构造过程：

1. 先对a[i]进行从大到小排序，因为更小的小木棍可以更灵活地组成木棍，要后使用。
2. 设置一个used数组记录哪些小木棍已使用。
3. 使用参数last,rest,k分别表示上一个使用的小木棍、木棍剩余需要长度、填充的第几个木棍。
4. 当rest=0时，判断凑成木棍个数是否满足，若不满足则从1到n进行dfs搜索未访问的小木棍；
当rest!=0时，从last到n进行进行dfs搜索未访问的小木棍，这里可以进行几个剪枝：a[i] > rest就跳过，搜索下一个；搜索完之后，如果a[i] = rest，直接返回false；跳过相同长度的木棍。

代码：

```
#include <iostream>
#include <algorithm>
#include <cstring>

using namespace std;

int n;
int a[70];
bool used[70];

int sum;

int len;
int m;

bool cmp(int a, int b) { return a > b; }

bool dfs(int last, int rest, int k)
{

    if (rest == 0)
    {
        if (k == m)
            return true;
        int i = 1;
        while (i <= n && used[i])
            i++;
        if (i > n)
            return false;
        used[i] = true;
        if (dfs(i, len - a[i], k + 1))
            return true;
        used[i] = false;
        return false;
    }

    for (int i = last; i <= n; i++)
    {
        if (used[i] || a[i] > rest)
            continue;
        used[i] = true;
        if (dfs(i, rest - a[i], k))
            return true;
        used[i] = false;
        
        if (a[i] == rest)
            return false;
        // 跳过相同长度的木棍
        while (i + 1 <= n && a[i + 1] == a[i])
            i++;
    }

    return false;
}

int main()
{
    cin >> n;
    for (int i = 1; i <= n; i++)
    {
        cin >> a[i];
        sum += a[i];
    }

    sort(a + 1, a + 1 + n, cmp);

    for (len = a[1]; len <= sum / 2; len++)
    {
        if (sum % len != 0)
            continue;
        fill(used, used + n + 1, false);
        m = sum / len;
        used[1] = true;
        if (dfs(1, len - a[1], 1))
        {
            cout << len;
            return 0;
        }
        // used[1] = false;
        //搜索程序本身已经处于时间复杂度临界状态，而这条语句本身不改变搜索逻辑。虽然只是一次赋值，但整个程序可能运行了大量 DFS。
    }
    cout << sum;
    return 0;
}
```

* 参考
[Kaori](https://www.luogu.com.cn/article/fxoshw2y)
