---
layout: post
read_time: true
show_date: true
title: "REINFORCE&ACTOR_CRITIC"
date: 2026-06-15 16:09:46 +0800
last_modified_at: 2026-06-15 16:09:46 +0800
img: ""
tags: [强化学习]
author: "uke"
---
先前我们所涉及的所有算法，都是针对价值函数进行迭代，而策略方面往往仅局限于$\epsilon-\text{贪婪算法}$，几乎不进行更新
我们先介绍基于策略的经典算法：REINFORCE，也就是策略梯度算法
## 1.REINFORCE
我们严格定义一下该算法
首先，我们记轨迹为：
$$\tau=(s_0,a_0,r_0,s_1,a_1,r_1,\cdots)$$
记轨迹概率为,其中T是与环境可能交互的最大步数：
$$\rho_\theta(\tau)=\rho_0(s_0)\prod_{t=0}^T\pi_\theta(a_t\mid s_t) P(s_{t+1}\mid s_t,a_t)$$
环境转移概率,初始概率分布与策略无关，因此
$$\nabla_\theta \log{\rho_\theta(\tau)}=\sum_{t=0}^T\nabla_\theta \log{\pi_\theta(a_t\mid s_t)}$$
优化目标为：
$$J(\theta)=\mathbb{E}_{\tau \sim \rho_\theta}[R(\tau)]=\sum_\tau R(\tau)\rho_\theta(\tau)$$
故，
$$\begin{align}
\nabla_\theta J(\theta)=&\sum_\tau R(\tau)\nabla_\theta\rho_\theta(\tau)\text{（这是因为在$\tau$确定的情况下，$R(\tau)$与$\theta$无关）}\nonumber \\
=&\sum_\tau R(\tau)\rho_\theta(\tau)\nabla_\theta log{\rho_\theta(\tau)}\nonumber \\
=&\mathbb{E}_{\tau \sim \rho_\theta}[R(\tau)\nabla_\theta log{\rho_\theta(\tau)}]\nonumber \\
=&\mathbb{E}_{\tau \sim \rho_\theta}[\sum_{t=0}^T R(\tau)\nabla_\theta log{\pi_\theta(a_t\mid s_t)}]\nonumber \\
\end{align}$$

我们记录这里的$R(\tau)$为$\psi_t$，故有：
$$\nabla_\theta J(\theta)=\mathbb{E}_{\tau \sim \rho_\theta}[\sum_{t=0}^T \psi_t(\tau)\nabla_\theta log{\pi_\theta(a_t\mid s_t)}]$$
我们不加证明的给出$\psi_t$的六种取值：
$$
\begin{align}
\psi_t &= \sum_{t'=0}^T\gamma^{t'}r_{t'} \tag{1} \\
\psi_t &= \sum_{t'=t}^T\gamma^{t'-t}r_{t'} \tag{2} \\
\psi_t &= \sum_{t'=t}^T\gamma^{t'-t}r_{t'}-b(s_t) \tag{3} \\
\psi_t &= Q^{\pi_\theta}(s_t,a_t) \tag{4} \\
\psi_t &= A^{\pi_\theta}(s_t,a_t) \tag{5} \\
\psi_t &= r_t+\gamma V^{\pi_\theta}(s_{t+1})-V^{\pi_\theta}(s_t) \tag{6}
\end{align}
$$
（1）的方差非常大，一条轨迹可以影响此轨迹所有节点的策略，而事实上$a_t$不可能影响已发生的奖励，会有非常大的噪声，需要采样大量数据才可以收敛
（2）依旧无偏差，方差比（1）要小很多
（3）加入了baseline，一般取$V^\pi(s)$,baseline的引入不增加偏差，故依旧无偏，一个好的baseline可以降低方差
（4）（5）（6）从（4）开始，摆脱了MC更新，减小了方差，可以一个时间步一更新而非一个采样序列一更新，但是同时，一般来说Q，A，V都未知，需要引入2.的critic来学习
（4）到（5）到（6），通常方差逐渐减小，但是偏差逐渐增大，对critic精确性的依赖逐步加深，其中（5）应用于大量经典算法（如PPO等）
## 2.ACTOR-CRITIC
actor和critic分别为两个神经网络，其中：
- Actor 要做的是与环境交互，并在 Critic 价值函数的指导下用策略梯度学习一个更好的策略。
- Critic 要做的是通过 Actor 与环境交互收集的数据学习一个价值函数，这个价值函数会用于判断在当前状态什么动作是好的，什么动作不是好的，进而帮助 Actor 进行策略更新。
critic有很多种更新方式，如（3）中可以采用MC更新，（4）（5）（6）可以使用TD更新，TD(n)以及一些后续会提到的更新方式等
## 3.实践
后续更新
