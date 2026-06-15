
我们简单介绍三种算法，并附上代码实践
## 1 TD
我们给出下面的式子：
$$\begin{align}
V_\pi(s)
&=\mathbb{E}_\pi[G_t\mid S_t=s]\nonumber \\
&=\mathbb{E}_\pi[r_i+\gamma G_{t+1} \mid S_t=s] \nonumber \\
&=\mathbb{E}_\pi[r_t+\gamma V_\pi(S_{t+1})\mid S_t=s]

\end{align}$$
最后一个等号是因为全期望公式
回顾[[MDP]]中的蒙特卡洛算法，我们需要采样完一整条路径，再采用上式的第一行进行增量更新，形式类似：
$$V_\pi(S_t)\leftarrow V_\pi(S_t)+\alpha[G_t-V_\pi(S_t)]$$
其中，$\alpha=\frac{1}{N(s)}$或最好至少有$\sum\alpha\to\infty$且$\sum\alpha^2<\infty$
采样一条路径耗时长，方差大，我们可以采用第三行来进行增量更新，也就是：
$$V_\pi(S_t)\leftarrow V_\pi(S_t)+\alpha[r_t+\gamma V_\pi(S_{t+1})-V(S_t)]$$
这便是强化学习中的TD方法
我们发现，这大大降低了随机性，也就降低了方差，但同时，自举式的更新导致这是一种有偏估计（在离线策略或函数逼近时将不一定能收敛到全局最优）
## 2 SARSA
我们尝试使用类似策略迭代的方式来解决这个问题
我们已经可以使用TD进行策略评估，那我们该如何进行策略提升呢？
那么可以有：
$$Q(s_t,a_t)\leftarrow Q(s_t,a_t)+\alpha [r_t+\gamma Q(s_{t+1},a_{t+1})-Q(s_t,a_t)]$$
然后每次更新选择$arg\max_a Q(s,a)$即可
但是，这样做存在问题，也就是如何平衡探索与利用？
我们是采样更新，而非像DP那样挑选每个动作，也许有一些动作从来没更新
于是，我们定义
$$
\pi(a\mid s)=
\begin{cases}
\frac{\epsilon}{\lvert A \rvert}+1-\epsilon,& \text{if }a=arg\max_a Q(s,a)\\
\frac{\epsilon}{\lvert A \rvert},& \text{else}
\end{cases}
$$
![[sarsa.png]]
这个算法与s，a，r，以及s',a'有关，因此得名sarsa
## 3 多步 Sarsa
$$Q(s_t,a_t)\leftarrow Q(s_t,a_t)+\alpha [r_t+\gamma Q(s_{t+1},a_{t+1})+\gamma^2Q(s_{t+2},a_{t+2})+\cdots+\gamma^nQ(s_{t+2},a_{t+2})-Q(s_t,a_t)]$$

这便是n步sarsa算法的更新方式，可以在一定程度上中和这种自举的算法的偏差
## 4 Q-learning
$$Q(s_t,a_t)\leftarrow Q(s_t,a_t)+\alpha [r_t+\gamma\max_a Q(s_{t+1},a)-Q(s_t,a_t)]$$
这是一种离线策略算法，直接估计的是贝尔曼最优方程
## 5 Dyna-Q
之前介绍的都是无模型的算法，也就是不对环境进行建模的算法，而Dyna-Q会进行Q-planning
![[Dyna-Q.png]]
![[Dyna-Q流程图.png]]这里的M也就是模型
书中的算法是执行在确定性环境中，那么M就是一个简单的记忆模型，而非推测模型
Dyna-Q好在哪里？
每一次采样，通过Q-planning可以生成n个假采样并更新数据，更新效率极高，在取样困难等场景非常管用
## 6 代码实践
（日后更新）