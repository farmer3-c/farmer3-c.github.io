---
title: "luoguP1114非常男女计划"
date: 2026-09-04T20:37:44+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1114 “非常男女”计划](https://www.luogu.com.cn/problem/P1114)

## 我理解的题目意思

给出一个数组由n个 0 或 1 组成，找出包含相同数目的0和1的最长子数组的长度。

$$1≤n≤10^5$$

## 解题思路

一开始想的很简单，维护一个前缀和数组a记录到当前位置一共多少1，再用一个嵌套for循环遍历子数组，$a[j]-a[i-1]=(j-i+1)/2,j-i+1%2=0$ 满足的条件下输出最大的 j-i+1。注意到 $1≤n≤10^5$ ，O(n²)的复杂度下会超时，需要改换复杂度更低的方法。

O(n)解法：将女视为-1，将男视为1，问题转换为最长的和为0的子数组。用哈希表fs记录前缀和sum，先插入一个 fs[0]=0,再遍历查找是否有 fs[i]=sum ,若有则输出最大的 i-fs[sum] ,否则插入 fs[sum]=i 。

代码：

```
#include <iostream>
#include <unordered_map>
using namespace std;

int n;
int main()
{
    cin >> n;
    unordered_map<int,int>fp;
    fp[0]=0;
    int ans=0,sum=0;
    for (int i = 1; i <= n; i++)
    {
        int x;
        cin >> x;
        sum+=(x==1)?1:-1;
        if(fp.find(sum)!=fp.end()){
            ans=max(ans,i-fp[sum]);
        }
        else{
            fp[sum]=i;
        }
    }
    cout<<ans;

    return 0;

}
```
