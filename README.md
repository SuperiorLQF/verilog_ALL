# <font color=red>verilog_ALL</font>
```
git config --global http.proxy "127.0.0.1:7890"
```
这里收集了verilog入门的基本知识和练习

***
## 多位比较器的实现：
发现仅仅根据Gi,Ei,Ai,Bi就可以得到Go,Eo和Lo，因此加入了改进（省略了Lo，仅仅在最后再输出Lo）。一位比较器只比较**大于**或者**等于**，以这样的比较器串联成多位比较器。
***