---
title: "luoguP1111修复公路"
date: 2026-09-01T19:52:05+08:00
author: farmer3-c
tags:
- Algorithm programming problem
mathjax: true
draft: false
---

# [P1111 修复公路](https://www.luogu.com.cn/problem/P1111)

## 我理解的题目意思

这是一个图论问题，给出N个点(x,y)、M个双向边及边权t。若无法生成连通图则输出-1，若可以连通则给出连通时最大边权的最小值。

$$1≤x,y≤N≤10^3，1≤M,t≤10^5。$$

## 解题思路

使用并查集进行点的合并查找，维护s:并查集数组，初始化并查集，每个节点指向自己,合并操作:
```
void together(int *b, int a, int *s) {
    if (s[*b] == *b) { // b没有祖先时
        s[*b] = a;     // 令a为b的父亲
    } else {
        together(&s[*b], a, s); // 否则继续找b的祖先
    }
}
```

a为要成为父节点的节点，b为要合并的节点，一直找直到b没有祖先即指向自己的节点，令a为b的父亲。

查找操作：
```
int findfather(int *s, int x) {
    if (x != s[x]) { // 不是最老祖先
        s[x] = findfather(s, s[x]); // 路径压缩，直接指向最老祖先
    }
    return s[x]; // 返回最老祖先
}
```

即查找最老祖先并返回，加一个路径压缩，查找到后直接指向最老祖先。

使用Kruskal算法生成最小树，先对边按边权排序，然后遍历所有边，检查两个顶点是否属于同一集合，否则合并两个集合，更新最大边权。

同时记录已连接的边数，用于判断是否连通。

代码：
```
#include <iostream>
#include <vector>
#include <unordered_map>
#include <algorithm>
#include <cstring>
#include <set>
using namespace std;




// 全局变量
int N, M, ans; // N:村庄数, M:道路数, ans:最小树中的最大通路时间

// 图的边结构
struct E {
    int a;    // 顶点a
    int b;    // 顶点b
    int t;    // 修复时间
};

// 快速排序函数（对边按权重从小到大排序）
void SORT(E *e, int left, int right) {
    if (left >= right) return;
    
    int i = left, j = right;
    E pivot = e[left];
    
    while (i < j) {
        while (i < j && e[j].t >= pivot.t) j--;
        if (i < j) e[i++] = e[j];
        while (i < j && e[i].t <= pivot.t) i++;
        if (i < j) e[j--] = e[i];
    }
    e[i] = pivot;
    
    SORT(e, left, i - 1);
    SORT(e, i + 1, right);
}

// 并查集的合并操作
// b:要合并的节点, a:要成为父节点的节点, s:并查集数组
void together(int *b, int a, int *s) {
    if (s[*b] == *b) { // b没有祖先时
        s[*b] = a;     // 令a为b的父亲
    } else {
        together(&s[*b], a, s); // 否则继续找b的祖先
    }
}

// 并查集的查找操作（路径压缩）
int findfather(int *s, int x) {
    if (x != s[x]) { // 不是最老祖先
        s[x] = findfather(s, s[x]); // 路径压缩，直接指向最老祖先
    }
    return s[x]; // 返回最老祖先
}

// Kruskal算法生成最小树
int TREE(E *e, int *s) {
    int i, total = 0;
    
    // 对边按权重从小到大排序
    SORT(e, 1, M);
    
    // 遍历所有边
    for (i = 1; i <= M; i++) {
        // 检查两个顶点是否属于同一集合
        if (findfather(s, e[i].a) != findfather(s, e[i].b)) {
            // 合并两个集合
            together(&s[e[i].a], s[e[i].b], s);
            total++;           // 记录已连接的边数
            ans = e[i].t;      // 更新最大边权（因为边已排序，最后加入的就是最大的）
        }
    }
    
    return total;
}

int main() {
    int i;
    int s[100010];
    E e[100010];
    
    // 输入村庄数和道路数
    cin >> N >> M;
    
    // 初始化并查集，每个节点指向自己
    for (i = 1; i <= N; i++) {
        s[i] = i;
    }
    
    // 输入每条道路的信息
    for (i = 1; i <= M; i++) {
        cin >> e[i].a >> e[i].b >> e[i].t;
    }
    
    // 生成最小树，并返回边数
    int c = TREE(e, s);
    
    // 判断是否所有村庄都连通
    if (c != N - 1) { // N个节点的树需要N-1条边
        ans = -1;     // 无法连通所有村庄
    }
    
    // 输出结果
    cout << ans << endl;
    
    return 0;
}
```

* 参考
[Euler_Pursuer](https://www.luogu.com.cn/article/ktlovmgx)

