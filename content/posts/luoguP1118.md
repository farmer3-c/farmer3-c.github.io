---
title: "luoguP1118 Backward Digit Sums G/S"
date: 2026-09-06T18:15:32+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1118 [USACO06FEB] Backward Digit Sums G/S](https://www.luogu.com.cn/problem/P1118)

## 我理解的题目意思

给两个正整数 n,sum 。将数字从 1 到 n 按某种顺序写下来，然后将相邻的数字相加，得到一个数字更少的新列表,重复这个过程，直到只剩下一个数字,若这个数字等于sum，则输出满足这个条件的字典序最小的序列1~n;否则不输出。

$$1≤N≤12，1≤sum≤12345$$

## 解题思路

数组ai每次相邻相加的过程，最终结果的系数就是杨辉三角的对应行。所以先预处理出c记录杨辉三角系数，再进行深度优先搜索尝试所有顺序，设置一个pos，按字典序尝试数字填入a[pos]，结合剪枝优化时间，在字典序尝试之前先判断已经填入的 a[i]*c[i] 之和是否大于sum，大于则停止搜索。当pos等于n时，判断 a[i]*c[i] 之和是否等于sum。

代码：

```
#include <iostream>
#include <algorithm>
using namespace std;

int n, sum;
int a[15],c[15];

bool vis[15];

void ini(){
    for(int i=0;i<n;i++){
        c[i]=1;
        for(int j=1;j<=i;j++){
            c[i]=c[i]*(n-j)/j;
        }
    }
}

int calc(){
    int res=0;
    for(int i=0;i<n;i++){
        res+=a[i]*c[i];
    }
    return res;
}

bool dfs(int pos){
    if(pos==n)return calc()==sum;

    int csum=0;
    for(int i=0;i<pos;i++){
        csum+=a[i]*c[i];
        
    }
    if(csum>sum)return false;

    for(int i=1;i<=n;i++){
        if(!vis[i]){
            vis[i]=true;
            a[pos]=i;
            if(dfs(pos+1))return true;
            vis[i]=false;
        }
    }
    return false;

}



int main()
{
    cin >> n >> sum;
    ini();
    if(dfs(0)){
        for(int i=0;i<n;i++){
            cout<<a[i]<<" ";
        }
    }
    return 0;
}
```