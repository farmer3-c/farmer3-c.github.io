---
title: "luoguP1115最大子段和"
date: 2026-09-05T14:36:03+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1115 最大子段和](https://www.luogu.com.cn/problem/P1115)

## 我理解的题目意思

给出一个长度为 n 的序列 a，选出其中连续且非空的一段使得这段和最大,输出最大值。

$$1≤n≤2×10^5，−10^4≤a_i​≤10^4$$

## 解题思路

用贪心来做，初始化 ans 为 a1 。从前往后想，维护 bi 记录末尾是 ai 的最大连续子段和，从 a2 开始，设 c=ai+bi ,若 ai≤c ，则 bi=c ；若 ai>c ，则 bi=ai ，每次判断后，维护 ans 为 ans 和 bi 的较大者。

> 为什么可以这么做？
第一个数为一个有效序列。
如果一个数加上上一个有效序列得到的结果比这个数大，那么该数也属于这个有效序列。
如果一个数加上上一个有效序列得到的结果比这个数小，那么这个数单独成为一个新的有效序列。
在执行上述处理的过程中实时更新当前有效序列的所有元素之和并取最大值。

代码：

```
#include <iostream>

using namespace std;

int n,a,b,ans=-0x7fffffff;

int main(){
    cin>>n;
    for(int i=1;i<=n;i++){
        cin>>a;
        if(i==1)b=a;
        else {
            b=max(b+a,a);
        }
        ans=max(ans,b);
    }
    cout<<ans;
    return 0;
}
```

* 参考
    [_Arahc_](https://www.luogu.com.cn/article/6zbw4hi6)
