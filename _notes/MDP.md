---
layout: post
read_time: true
show_date: true
title: "MDP"
date: 2026-05-27 12:09:52 +0800
last_modified_at: 2026-05-27 12:09:52 +0800
img: "notes/20260527-MDP/cover_MDP.png"
tags: [强化学习]
author: "uke"
---
## 1.前言
MDP在[[MAB]]的基础上，加入了与环境的交互：
1.环境不再是一成不变的，而是具有state的变化
2.action具有改变环境的能力

本文依旧参照《动手学强化学习》，大致分为这几个板块：

前言、马尔可夫过程、MDP的数学推导，最后会有一些自己对这些公式的理解

## 2.马尔可夫过程

我们将已知历史信息$(s_1,\dots,s_t)$的下一个时间步为$s_{t+1}$的概率记为$P(s_{t+1}\mid s_1,\dots,s_t)$

当$P(s_{t+1}\mid s_1,\dots,s_t)=P(s_{t+1}\mid s_t)$时,我们称一个随机过程具有马尔可夫性质

## 3.MDP的数学推导
我们按照$MP \to MRP \to MDP$的顺序来进行推导

### 3.1 MP
我们一般使用元组$\langle \mathcal{S},\mathcal{P} \rangle$来描述MP，其中$S$是有限数量的状态集合，$P$是状态转移矩阵

假设共有$n$个离散的状态,此时：
$$\mathcal S=\{s_1,\dots,s_n\}$$
$$\mathbf P=\begin{pmatrix}\
P(s_1\mid s_1)&\cdots &P(s_n\mid s_1)\\
\vdots & \ddots & \vdots\\
P(s_n\mid s_1) & \cdots & P(s_n\mid s_n)
\end{pmatrix}$$
### 3.2 MRP
我们在MP的基础上加上奖励函数$r$与折扣因子$\gamma$,那我们就得到了MRP
一般由四元组$\langle \mathcal S,\mathbf P, r, \gamma  \rangle$来定义，其中
$r$为奖励函数，$r(s)$指在$s$状态下获得奖励的期望，
$\gamma$为折扣因子，引入它可以确保价值收敛，范围为$[0,1)$，可以通过调整使之更关注长期/短期利益
#### 3.2.1 回报
我们定义从第$t$时间步开始的所有奖励的衰减之和定义为回报$G_t(return)$
$$G_t=R_t+\gamma R_{t+1} +\gamma^2 R_{t+2}+\dots =\sum_{k=0}^\infty \gamma^k R_{t+k}$$
其中，$R_t$表示$t$时间步时获得的奖励
#### 3.2.2 价值函数
我们把一个时间步的回报的期望定义为价值
所有状态的价值组成了价值函数，（输入为某个state，输出为某个价值），定义为
$$V(s)=\mathbb{E}[G_t\mid S_t=s]$$
而，
$$\begin{align*}
V(s)&=\mathbb{E}[G_t\mid S_t=s]\\
&=\mathbb{E}[R_t+\gamma R_{t+1}+ \gamma^2 R_{t+2} + \dots \mid S_t=s]\\
&=\mathbb{E}[R_t+\gamma(R_{t+1}+\gamma R_{t+2})+\dots \mid S_t=s]\\
&=\mathbb{E}[R_t+\gamma V(S_{t+1}) \mid S_t=s]
\end{align*}$$
故我们可以得到：
$$V(s)=r(s)+\gamma \sum_{s' \in S} P(s' \mid s)V(s')$$
这就是大名鼎鼎的贝尔曼方程
我们整理所有共$t$个状态，组成列向量
得到矩阵形式的贝尔曼方程：
$$\mathbf{V}=\mathbf R + \gamma \mathbf P \mathbf V$$
$$\begin{bmatrix}V(s_1)\\
V(s_2)\\
\vdots\\
V(s_t)\end{bmatrix}
=
\begin{bmatrix}r(s_1)\\
r(s_2)\\
\vdots\\
r(s_t)\end{bmatrix}
+
\gamma
\begin{bmatrix}
P(s_1\mid s_1)&P(s_2\mid s_1)&\cdots&P(s_t\mid s_1)\\
P(s_1\mid s_2)&P(s_2\mid s_2)&\cdots&P(s_t\mid s_2)\\
\vdots&\vdots&\ddots&\vdots\\
P(s_1\mid s_1)&P(s_2\mid s_1)&\cdots&P(s_t\mid s_1)\\
\end{bmatrix}
\begin{bmatrix}V(s_1)\\
V(s_2)\\
\vdots\\
V(s_t)\end{bmatrix}$$
故移项解得：
$$\mathbf V= (\mathbf I - \gamma \mathbf P)^{-1}\mathbf R$$
### 3.3 MDP
总算推进到了MDP

MP与MRP都没有“动作”“策略”的参与，本质上是一个自己运行，无干预的系统
如果有一个外界的“刺激”可以改变这个随机过程（加入智能体的"动作"），就得到了MDP
我们可以把MDP记为一个五元组:
$$\langle \mathcal S,\mathcal A,\mathbf P, r, \gamma  \rangle$$
其中$\mathcal A$为动作集合

在这种情况下，我们不把$\mathbf P$记作一个概率分布矩阵，而是记作一个状态转移函数，原因有二：
1）记作概率分布矩阵不可行，因为引入了不同的动作，而每一个动作都具有自己的概率分布矩阵，故只能记作一个三阶张量
2）状态集合非有限时，仍可以记作状态转移函数，说明状态转移函数更为普遍

agent与环境相互交互的过程大致如下：
![MDP.png](/assets/img/notes/20260527-MDP/MDP.png)
#### 3.3.1 策略（policy）
智能体的**策略**（Policy）通常用字母$\pi$表示。策略$\pi(a\mid s)=P(A_t=a\mid S_t=s)$是一个函数，表示在输入状态情况下采取动作的概率。

在 MDP 中，由于马尔可夫性质的存在，策略只需要与当前状态有关，不需要考虑历史状态。

#### 3.3.2 状态价值函数$V^{\pi}(s)$
与MRP定义类似，状态价值函数被定义为基于策略$\pi$的回报的期望，定义为：
$$V^{\pi}(s)=\mathbb{E}_{\pi}[G_t\mid S_t=s]$$
#### 3.3.3 动作价值函数$Q^{\pi}(s,a)$
与MRP不同的是，我们额外定义一个基于$\pi$的函数，定义为:
$$Q^{\pi}(s,a)=\mathbb{E}_{\pi}[G_t\mid S_t=s,A_t=a]$$
状态价值函数和动作价值函数之间的联系：
$$V^{\pi}(s)=\sum_{a \in A} \pi(a\mid s)Q^{\pi}(s,a)$$
其意义是显然的，不过多解释

当然，还有Q的计算式：
$$Q^{\pi}(s,a)=r(s,a)+\gamma\sum _{s' \in S}P(s'\mid s ,a)V^{\pi}(s')$$
#### 3.3.4 贝尔曼期望方程
$$\begin{align}
V^{\pi}(s)&=\mathbb{E}[R(s)+\gamma V^{\pi}(S_{t+1} \mid S_t=s)]\nonumber \\
&=\sum_{a \in A}\pi(a \mid s)\left(r(s,a)+\gamma\sum_{s' \in S} P(s' \mid s,a) V^{\pi}(s') \right)
\end{align}$$

$$\begin{align}
Q^{\pi}(s,a)&=\mathbb{E}[R(s,a)+\gamma Q^{\pi}(S_{t+1},A_{t+1} \mid S_t=s,A_t=a)] \nonumber \\
&=r(s,a)+\gamma \sum_{s' \in S} P(s'\mid s,a)\sum_{a'\in A}\pi(a'\mid s)Q^{\pi}(s',a')\\
\end{align}
$$
### 3.4蒙特卡洛方法
MC,简单的一种取样方法，即将随机取样的平均值当作期望的近似，即为：
$$V^{\pi}(s)=\mathbb{E}[G_t \mid S_t=s] \approx \frac{\sum_{i=1}^{N}G_t^{(i)}}{N}$$
我们依旧可以使用[[MAB]]中的增量更新的方法
### 3.5 占用度量
如果我们用$P^{\pi}_t(s)$来定义采取策略$\pi$,在$t$时刻，状态为$s$的概率，并且定义$v_0(s)$为初始概率分布
那么，我们可以定义一个策略的状态访问分布为：
$$\mathcal{v}^{\pi}(s)=(1-\gamma)\sum_{t=0}^{\infty}\gamma^{t}P_t^{\pi}(s)$$
其中，$1-\gamma$为归一化参数，目的是使得状态访问分布相加为1
类似的，我们还可以定义策略的占用度量：
$$\rho^{\pi}(s,a)=(1-\gamma)\sum_{t=0}^{\infty}\gamma^tP_t^\pi(s)\pi(a\mid s)$$
### 3.6 最优策略
我们定义$\pi>\pi'$当且仅当$\forall s\in S,V^{\pi}(s)\ge V^{\pi'}(s)$
于是在有限状态和动作集合的 MDP 中，至少存在一个策略比其他所有策略都好或者至少存在一个策略不差于其他所有策略，这个策略就是**最优策略**（optimal policy）。最优策略可能有很多个，我们都将其表示为$\pi^*(s)$。
由此，我们可以定义最优状态价值函数$V^*(s)$与最优动作价值函数$Q^*(s,a)$
$$V^*(s)=\max_\pi V^\pi(s),\forall s \in S$$
$$Q^*(s,a)=\max_\pi Q^\pi(s,a),\forall s \in S,\forall a \in A$$
为了使Q最大，我们要使得之后的每个选择都选择最优价值，即：
$$Q^*(s,a)=r(s,a)+\gamma \sum_{s' \in S}P(s' \mid s,a)V^*(s')=r(s,a)+\gamma \sum_{s' \in S}P(s' \mid s,a)\max_{a' \in A}Q^*(s',a')$$
同样的，最优的状态价值出自最优的动作，即：
$$V^*(s)=\max_{a \in A}Q^*(s,a)=\max_{a\in A}\left(r(s,a)+\gamma\sum_{s' \in S} P(s' \mid s,a) V^*(s') \right)$$
我们把
$$Q^*(s,a)=r(s,a)+\gamma \sum_{s' \in S}P(s' \mid s,a)\max_{a' \in A}Q^*(s',a')$$
与
$$V^*(s)=\max_{a\in A}\left(r(s,a)+\gamma\sum_{s' \in S} P(s' \mid s,a) V*(s') \right)$$
称作贝尔曼最优方程

## 4.一些总结
虽然全程手打公式很痛苦，公式也很复杂，但是实际上全然是为了严谨定义所以显的复杂，实际上，在策略确定时（假设已经最优），即为
$$V(s)=r(s)+\gamma V(s')$$
其中，s'是在策略$\pi$下，当前状态为$s$的可能下一状态
考虑简单的01背包问题，其贝尔曼最优方程即为：

$$F(i,c)=\max_{a\in{0,1},\ aw_i\le c} \left[a v_i+F(i-1,c-aw_i)\right]$$
化成类似定义的形式：
$$V^*(i, c) = \max_{a \in \{0, 1\}} \left\{ a \cdot v_i + 1 \cdot \sum_{s'} 1 \cdot V^*(s') \right\}$$
也就是取$\gamma=1$（收益无衰减），且策略均为确定性策略的结果

从特殊到一般，MDP提供了描述所有相关事务的一种工具，并深刻的揭示，定义了价值，比DP等层次更高

