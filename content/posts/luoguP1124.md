---
title: "luoguP1124 [ZJOI2001] 文件压缩"
date: 2026-09-12T12:03:17+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1124 [ZJOI2001] 文件压缩](https://www.luogu.com.cn/problem/P1124)


## 我理解的题目意思

对一个长度为 n 的字符串 S，首先根据它构造 n 个字符串，其中第 i 个字符串由将 S 的前 i−1 个字符置于末尾得到。然后把这 n 个字符串按照首字符从小到大排序，如果两个字符串的首字符相等，则按照它们**在 S 中的位置**从小到大排序。排序后的字符串的尾字符可以组成一个新的字符串 S′ ，它的长度也是 n，并且包含了 S 中的每一个字符。最后输出 S′ 以及 S 的首字符在 S′ 中的位置 p。

读入 S′ 和 p，输出字符串 S.

$$1≤n≤10000，S 仅含小写字母$$


## 解题思路



* 输入输出样例 #1

* 输入 #1

```
7
xelpame
7

```

* 输出 #1

```
example

```
![bwt](/img/algo_p/bwt.png)

注意到，`S'` 只是把原字符串 `S` 中的所有字符重新排列了一下，所以 `S'` 和 `S` 包含的字符完全相同。

我们把 `S'` 从小到大排序，得到：

```
F = sort(S')
```

现在观察排序后的每一行。

原来的第 `j` 个字符串是：

```
S[j] S[j+1] ... S[n] S[1] ... S[j-1]
```

所以：

-   这个字符串的**第一个字符**是 `S[j]`
-   这个字符串的**最后一个字符**是 `S[j-1]`

排序以后，这一行的：

```
首字符 = F[i] = S[j]
尾字符 = S'[i] = S[j-1]
```

因此，`F[i]` 和 `S'[i]` 放在一起看，就表示了原字符串中两个相邻的字符：

```
S'[i] → F[i]
```

也就是说，每一行都可以看成一条“前一个字符 → 后一个字符”的关系。

例如：

```
F[i]   = a
S'[i]  = x
```

就说明原字符串中存在：

```
x → a
```


还有一个非常重要的地方：

如果 `F` 中出现了多个相同的字符，例如有两个 `e`：

```
e  e
```

它们并不是随便排列的。

题目规定：

> 如果两个字符串的首字符相同，就按照这个首字符在原字符串 `S` 中出现的位置从小到大排列。

所以，原字符串中第一个出现的 `e`，会排在第二个 `e` 前面；第三个 `e` 也会排在它们后面。

因此，我们不仅要知道“当前字符是 `e`”，还要知道：

> **它是原字符串中第几个 `e`。**

这样才能准确找到它在 `F` 中对应的位置，避免重复字符造成错位。

代码：
```
#include <iostream>
#include <algorithm>
using namespace std;

int n, p;
char a[10005], b[10005], ans[10005];

int main()
{
    cin >> n >> a >> p;
    for (int i = 0; i < n; i++)
        b[i] = a[i];
    sort(b, b + n);

    int now = 0;
    for (int i = 0; i < n; i++)
    {
        if (b[i] == a[p - 1])
        {
            now = i;
            b[i] = ')';
            break;
        }
    }
    ans[0] = a[now];
    for (int i = 1; i < n; i++)
    {
        for (int j = n - 1; j >= 0; j--)
        {
            if (a[now] == b[j])
            {
                ans[i] = a[j];
                now = j;
                b[j] = ')';
                break;
            }
        }
    }
    for (int i = n - 1; i >= 0; i--)
        cout << ans[i];
    return 0;
}
```

* 参考
[MC_Launcher](https://www.luogu.com.cn/article/9rwznhza)