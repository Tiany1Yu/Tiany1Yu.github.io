---
layout: post
read_time: true
show_date: true
title: 语法整理
date: 2026-03-10 22:05:22 +0800
img: 
tags: ["记忆"]
author: uke
---
这文章100%非我手写，主要是为了便于我查找和记忆最近刚开始学习的各类库（）
producted by gemini 3.1pro
---

# 第一部分：Pandas 核心语法全解 (Kaggle: Pandas)
Pandas 是数据科学的基础，它的核心作用就是**“在 Python 里操作 Excel 表格”**。在 Pandas 里，一维数据叫 `Series`（一列），二维数据叫 `DataFrame`（一张表）。

## 1. 创建、读取与写入 (Creating, Reading and Writing)
**场景：** 数据怎么弄进 Python 里？处理完怎么存下来？

```python
import pandas as pd # 永远的第一步：请出 pandas 大神，并给它起个小名叫 pd

# --- 1. 手动创建数据 (常用于自己造测试数据) ---
# 创建一个 DataFrame (数据框/二维表)
# 语法逻辑：pd.DataFrame(字典) -> 字典的键(Key)变成列名，值(Value)变成这一列的数据
df_manual = pd.DataFrame({
    'Yes': [50, 21], 
    'No': [131, 2]
})

# 创建时指定行索引 (index)
df_custom_index = pd.DataFrame({
    'Bob': ['I liked it.', 'It was awful.'], 
    'Sue': ['Pretty good.', 'Bland.']
}, index=['Product A', 'Product B']) # 不写 index 默认是 0, 1, 2...

# 创建一个 Series (序列/一列数据)
s = pd.Series([1, 2, 3, 4, 5], index=['a', 'b', 'c', 'd', 'e'], name='Numbers')

# --- 2. 🌟 读取外部数据 (Kaggle 最常用) ---
# 读取 CSV 文件，并把它存进变量 df 中
# 语法逻辑：pd.read_csv("文件路径")
df = pd.read_csv("../input/titanic/train.csv")

# 读取时，直接把某一列作为行索引 (比如把 ID 列当成行号)
df_wine = pd.read_csv("wine-reviews.csv", index_col=0) 

# --- 3. 检查数据长什么样 ---
# 查看前 5 行 (如果不填数字，默认是 5；想看 10 行就写 df.head(10))
df.head() 
# 查看数据的行数和列数 (注意 shape 不是函数，后面没有括号)
df.shape # 返回结果例如：(1309, 12) 代表 1309行，12列

# --- 4. 保存/写入数据 ---
# 把处理好的数据存成新的 CSV 文件
# index=False 的意思是：不要把行号（0,1,2,3...）也当成一列保存进去
df.to_csv("my_submission.csv", index=False) 
```

## 2. 索引、选择与赋值 (Indexing, Selecting & Assigning)
**场景：** 这张表有 1 万行 50 列，我只想把其中某几行、某几列单独拎出来看。
**💡 避坑指南：** Pandas 有自己独特的定位方式 `iloc` 和 `loc`。
*   `iloc` = **i**ndex **loc**ation (基于**数字位置**找人，就像找“第3排第5列的同学”)
*   `loc` = **loc**ation (基于**标签名字**找人，就像找“叫张三的同学”)

```python
# --- 1. 获取整列数据 ---
# 提取名为 'country' 的列，以下两种写法完全等价：
countries = df.country    # 写法 1 (类似调用属性，列名有空格时不能用)
countries = df['country'] # 写法 2 🌟 (推荐写法，更稳妥)

# --- 2. 基于位置的提取：iloc (纯数字) ---
df.iloc[0]          # 提取第一行的数据 (Python 从 0 开始)
df.iloc[:, 0]       # 提取第一列的数据 (冒号 : 代表“所有行”)
df.iloc[:3, 0]      # 提取第一列的 前 3 行 (第0, 1, 2行)
df.iloc[1:3, 0]     # 提取第一列的 第 1 到 2 行 (注意：1:3 左闭右开，不包含3)
df.iloc[[0, 1, 2], 0] # 提取第一列的 第 0, 1, 2 行 (传入一个列表)
df.iloc[-5:]        # 提取最后 5 行数据

# --- 3. 基于标签的提取：loc (名字) ---
# 提取第一行，但列名为 'country' 的数据
df.loc[0, 'country'] 
# 提取所有行，包含 'taster_name', 'taster_twitter_handle', 'points' 这三列
df.loc[:, ['taster_name', 'taster_twitter_handle', 'points']]

# --- 4. 🌟 条件选择 (Conditional Selection，极度重要) ---
# 找出所有来自 'Italy' 的酒 (此时返回的是一堆 True 和 False)
df.country == 'Italy' 
# 把上面的条件套进 loc 里，就能把来自意大利的行全拿出来！
df.loc[df.country == 'Italy'] 

# 多条件查找：使用 & (并且)，| (或者)
# 找出来自意大利 并且 分数大于等于 90 的酒
df.loc[(df.country == 'Italy') & (df.points >= 90)] # 注意每个条件必须加括号 ()

# 找出来自意大利 或者 来自法国的酒
df.loc[(df.country == 'Italy') | (df.country == 'France')]

# 更优雅的写法：使用 isin (在...里面)
df.loc[df.country.isin(['Italy', 'France'])]

# 找出价格不是空的行 (notnull: 非空；isnull: 是空)
df.loc[df.price.notnull()]

# --- 5. 赋值 (Assigning Data) ---
# 简单粗暴：把某一列的所有值都变成一样
df['critic'] = 'everyone' # 增加一列名为 'critic'，所有的值都是 'everyone'
# 按倒序赋予行号
df['index_backwards'] = range(len(df), 0, -1) 
```

## 3. 统计函数与映射 (Summary Functions and Maps)
**场景：** 我想知道数据的平均值、最大值？我想对某一列的所有数据统一做个数学运算（比如都乘以10）？

```python
# --- 1. 统计函数 ---
# 🌟 describe(): 数据科学家的最爱，一键生成全方位体检报告
# 会显示这列的：数量(count), 平均值(mean), 标准差(std), 最小值(min), 25%分位数, 最大值(max)
df.points.describe() 
df.describe() # 甚至可以对整个表里所有数值型的列直接体检

# 单独获取某一项统计值
df.points.mean() # 平均分
df.points.median() # 中位数
df.country.unique() # 看这列都有哪些不重复的值 (比如一共有多少个国家)
df.country.value_counts() # 🌟 统计每个国家分别出现了多少次 (极度常用)

# --- 2. 数据映射 (Map / Apply) ---
# 场景：你想让某一列的每一个数据，都经过某种处理
# 比如：把所有分数都减去这列的平均分 (计算均值中心化)
review_points_mean = df.points.mean()

# 方法 A：使用 map()，通常用于处理一列 (Series)
# 语法逻辑：列.map(函数)。这里 lambda p: p - mean 是个匿名函数，意思是“给我一个 p，我返回 p 减去均值”
df.points.map(lambda p: p - review_points_mean)

# 方法 B：使用 apply()，通常用于处理整行或整表 (DataFrame)
# axis='columns' 代表把每一行的数据传进去
def remean_points(row):
    row.points = row.points - review_points_mean
    return row

df.apply(remean_points, axis='columns')

# 🌟 Kaggle 捷径：Pandas 支持直接用加减乘除 (向量化操作，比 map/apply 快得多！)
# 上面的逻辑，完全可以直接这么写：
df.points - df.points.mean()
# 拼接两列字符串：
df.country + " - " + df.region_1
```

## 4. 分组与排序 (Grouping and Sorting)
**场景：** 类似于 Excel 里的“数据透视表”。我想知道“每个国家的最贵葡萄酒是多少钱？”或者“各个性别的平均幸存率是多少？”

```python
# --- 1. 分组分析：groupby ---
# 统计各个国家 (country) 分别有多少款酒
# 语法逻辑：按什么分组 -> 选一列去统计 -> 怎么统计
df.groupby('country').points.count()

# 计算每个国家最便宜的酒 (取 price 列的最小值 min)
df.groupby('country').price.min()

# apply 也能结合 groupby 使用
# 找出每个国家的第一款酒
df.groupby('country').apply(lambda df: df.iloc[0])

# --- 2. 🌟 agg(): 一次性计算多个统计指标 ---
# 计算��个国家酒的长度(数量)、最低分、最高分
df.groupby(['country']).price.agg([len, min, max])

# --- 3. 多重分组 (Multi-Index) ---
# 按 国家 且 按 省份 分组，看最高分
# 结果的行索引会有两层：第一层是国家，第二层是省份
countries_reviewed = df.groupby(['country', 'province']).description.agg([len])

# 遇到多层索引，我们通常用 reset_index() 把它变回普通的扁平表格，方便后续处理
countries_reviewed = countries_reviewed.reset_index()

# --- 4. 排序：sort_values ---
# 把刚刚算出来的数据，按照国家名字的字母顺序排 (默认升序 Ascending)
countries_reviewed.sort_values(by='len')

# 从大到小排 (降序)：加参数 ascending=False
countries_reviewed.sort_values(by='len', ascending=False)

# 多列排序：先按国家名字排，如果国家名字一样，再按数量排
countries_reviewed.sort_values(by=['country', 'len'])

# 按照索引(行号)排序：
countries_reviewed.sort_index()
```

## 5. 数据类型与缺失值 (Data Types and Missing Values)
**场景：** 数据集经常是脏的。有的是数字被存成了文本，有的是格子直接是空的 (NaN)。怎么揪出它们并处理掉？

```python
# --- 1. 数据类型 (Dtypes) ---
# 查看某一列的数据类型 (int64 整数, float64 浮点数, object 文本/字符串)
df.price.dtype
df.dtypes # 查看所有列的数据类型

# 类型转换 (astype)
# 比如把本来是 64位浮点数 的 points 列，硬改成 64位整数
df.points.astype('int64')

# --- 2. 处理缺失值 (Missing Data) ---
# 在 Pandas 里，空值通常显示为 NaN (Not a Number)

# 找出 country 这一列为空值的所有行
df[pd.isnull(df.country)]

# 🌟 填补空值 (fillna)
# 遇到空缺的区域(region_2)，统一填成 'Unknown'
df.region_2.fillna("Unknown")

# 🌟 替换数据 (replace)
# 把数据里所有的 '@kerinokeefe' 替换成 'kerinokeefe'
df.taster_twitter_handle.replace("@kerinokeefe", "kerinokeefe")
```

## 6. 重命名与合并 (Renaming and Combining)
**场景：** 列名太长或有错别字，想改掉。或者有两张表需要拼在一起。

```python
# --- 1. 重命名 (rename) ---
# 改列名：把 'points' 列改名叫 'score' (用字典形式提供对应关系)
df.rename(columns={'points': 'score'})

# 改行名 (改索引名)：把索引 0 和 1 改名叫 'firstEntry' 和 'secondEntry'
df.rename(index={0: 'firstEntry', 1: 'secondEntry'})

# 更改坐标轴名称：
df.rename_axis("wines", axis='rows').rename_axis("fields", axis='columns')

# --- 2. 合并：concat (简单粗暴的上下/左右拼接) ---
# 有两份格式一模一样的表格，把它们上下堆叠起来
# 语法逻辑：pd.concat([表1, 表2])
canadian_youtube = pd.read_csv("../input/youtube-new/CAvideos.csv")
british_youtube = pd.read_csv("../input/youtube-new/GBvideos.csv")
pd.concat([canadian_youtube, british_youtube])

# --- 3. 合并：join (类似于 SQL 里的 Join，按索引拼接不同的列) ---
# 左边的表和右边的表通过共有的行索引(index)拼在一起
left = canadian_youtube.set_index(['title', 'trending_date'])
right = british_youtube.set_index(['title', 'trending_date'])

# lsuffix 和 rsuffix 用于处理两边有同名列的情况
left.join(right, lsuffix='_CAN', rsuffix='_UK')
```

---

# 第二部分：机器学习入门 (Kaggle: Intro to Machine Learning)
这门课带你走完一次**最基础的机器学习全流程**。核心库是 `Scikit-Learn` (简称 `sklearn`)。

在 sklearn 中，不管是哪种算法，都有一个固定的 **“三板斧”语法**：
1. **定义模型** `model = 算法名()`
2. **拟合/训练** `model.fit(X, y)`
3. **预测** `model.predict(X_新数据)`

## 1. 准备数据 (Selecting Data for Modeling)
机器学习要搞清楚两个概念：
*   **`y` (Target / 目标变量)：** 你想预测的东西（比如房价）。习惯上用**小写字母**。
*   **`X` (Features / 特征)：** 你用来进行预测的线索（比如面积、房间数）。习惯上用**大写字母**。

```python
import pandas as pd
melbourne_data = pd.read_csv('melb_data.csv')

# 只要数据里有空值，我们先简单粗暴地全删掉（dropna），否则模型会报错
melbourne_data = melbourne_data.dropna(axis=0)

# --- 1. 选择目标 y ---
y = melbourne_data['Price']

# --- 2. 选择特征 X ---
# 我们把觉得对预测房价有用的列名写成一个列表
melbourne_features = ['Rooms', 'Bathroom', 'Landsize', 'Lattitude', 'Longtitude']
X = melbourne_data[melbourne_features]

# 在丢进模型前，先看一眼我们的特征数据长什么样
X.describe()
X.head()
```

## 2. 你的第一个机器学习模型 (Your First ML Model)
我们使用**决策树 (Decision Tree)**，它就像是一个不断在做“如果...那么...”判断的流程图。

```python
from sklearn.tree import DecisionTreeRegressor

# 1. 定义模型：指定模型类型
# random_state=1 的作用是“固定随机种子”。
# 机器学习里有很多随机初始化的过程，固定这个数字能保证你每次跑出的结果一模一样，方便查错。
melbourne_model = DecisionTreeRegressor(random_state=1)

# 2. 拟合/训练模型：把线索(X)和答案(y)都喂给它，让它找规律
melbourne_model.fit(X, y)

# 3. 预测：给它新的线索，让它猜答案
# 这里我们只是拿训练集前5行测试一下它能不能跑通
print("我们正在为以下5套房子做预测：")
print(X.head())
print("预测结果如下：")
print(melbourne_model.predict(X.head()))
```

## 3. 模型验证 (Model Validation)
**场景：** 刚才我们拿平时练习的题（训练集）去考模型，它当然会做。要想知道它到底聪不聪明，必须得拿没见过的卷子（验证集）来考它！

```python
# 引入“平均绝对误差”工具 (Mean Absolute Error, MAE)
# MAE = |真实值 - 预测值| 的平均。比如预测房价和真实房价平均差了多少钱。
from sklearn.metrics import mean_absolute_error
# 引入“切分数据”的工具
from sklearn.model_selection import train_test_split

# --- 1. 切分数据集 ---
# train_test_split 会把数据洗牌后，按比例(默认3:1)切成两份。
# 分别得到：训练特征, 验证特征, 训练答案, 验证答案
train_X, val_X, train_y, val_y = train_test_split(X, y, random_state=0)

# --- 2. 重新用训练集训练模型 ---
melbourne_model = DecisionTreeRegressor()
melbourne_model.fit(train_X, train_y) # 此时只喂给它训练卷子

# --- 3. 用验证集进行预测 ---
val_predictions = melbourne_model.predict(val_X) # 考它验证卷子上的题

# --- 4. 判卷打分 ---
# 对比模型猜的答案(val_predictions)和真实答案(val_y)
print(mean_absolute_error(val_y, val_predictions)) 
```

## 4. 欠拟合与过拟合 (Underfitting and Overfitting)
**场景：** 
*   **过拟合 (Overfitting)：** 模型死记硬背了训练集，连异常的噪点都背下来了，遇到新题完全不会做（树太深，叶子太多）。
*   **欠拟合 (Underfitting)：** 模型根本没学会，找出来的规律太简单（树太浅，只有两三片叶子）。
在 sklearn 中，控制树深浅的参数是 `max_leaf_nodes`（最大叶子节点数）。

```python
# 我们写一个小函数，专门用来对比不同 max_leaf_nodes 的 MAE 误差得分
def get_mae(max_leaf_nodes, train_X, val_X, train_y, val_y):
    # 用指定的叶子数量建树
    model = DecisionTreeRegressor(max_leaf_nodes=max_leaf_nodes, random_state=0)
    model.fit(train_X, train_y)
    preds_val = model.predict(val_X)
    mae = mean_absolute_error(val_y, preds_val)
    return mae

# 测试不同的树深度：5叶, 50叶, 500叶, 5000叶
# 我们要找出哪种叶子数量下的 mae 最小！
for max_leaf_nodes in [5, 50, 500, 5000]:
    my_mae = get_mae(max_leaf_nodes, train_X, val_X, train_y, val_y)
    print("Max leaf nodes: %d  \t\t Mean Absolute Error:  %d" % (max_leaf_nodes, my_mae))

# 结论通常是中间某个数字最好（比如50），5就是欠拟合，5000就是过拟合。
```

## 5. 随机森林 (Random Forests)
**场景：** 决策树有一个大缺点——它很不稳定。随机森林通过“集思广益”解决了这个问题：建很多棵不同的小决策树，然后大家投票决定预测结果。
**💡 重点：** 在 Kaggle 中，随机森林通常是默认起手式，因为它的默认参数效果就很好了！

```python
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error

# 语法和决策树一模一样！只是名字换了。
forest_model = RandomForestRegressor(random_state=1) # 1. 定义模型
forest_model.fit(train_X, train_y)                   # 2. 训练模型
melb_preds = forest_model.predict(val_X)             # 3. 预测结果

print(mean_absolute_error(val_y, melb_preds))        # 4. 评估结果 (你会发现比单棵决策树低多了！)
```

---

# 第三部分：机器学习进阶 (Kaggle: Intermediate Machine Learning)
真实世界的数据是很残酷的：充满了缺失值、文本符号。如果不做处理，模型一跑就崩溃。这门课教你**如何科学地把“脏数据”洗成机器学习喜欢的“纯数字矩阵”**。

## 1. 缺失值处理 (Missing Values)
当发现特征中有空值 (NaN) 时的三种策略。

```python
# 策略 1：简单粗暴地扔掉有缺失值的“列” (Drop Columns)
# 虽然会丢失信息，但最简单。
# 获取有缺失值的列名
cols_with_missing = [col for col in X_train.columns if X_train[col].isnull().any()]
# 删掉这些列 (注意，训练集删了，验证集也必须删同样的列，保持对齐！)
reduced_X_train = X_train.drop(cols_with_missing, axis=1) # axis=1 代表删除列
reduced_X_valid = X_valid.drop(cols_with_missing, axis=1)

# ---------------------------------------------
# 策略 2：🌟 插补法 (Imputation) 
# 用这一列的平均值、中位数去填补空洞。这是最常用的方法！
from sklearn.impute import SimpleImputer

# 定义插补器，默认策略就是算平均值 (mean)
my_imputer = SimpleImputer()

# ⚠️ 非常重要的语法坑：
# 对于训练集，我们需要让插补器去“找规律”(fit)并且“执行转换”(transform)，所以用 fit_transform
imputed_X_train = pd.DataFrame(my_imputer.fit_transform(X_train))
# 对于验证集/测试集，我们直接用刚才学到的平均值去“执行转换”，千万不能再让它找新规律了！所以只用 transform
imputed_X_valid = pd.DataFrame(my_imputer.transform(X_valid))

# 填补后，原来的列名会丢失（变成0,1,2列），把它重新贴回去
imputed_X_train.columns = X_train.columns
imputed_X_valid.columns = X_valid.columns

# ---------------------------------------------
# 策略 3：扩展插补法 (An Extension to Imputation)
# 填补了平均值，但为了告诉模型“这里原本是空的，是我填的”，我们再额外加一列布尔值(True/False)标记
X_train_plus = X_train.copy()
for col in cols_with_missing:
    X_train_plus[col + '_was_missing'] = X_train_plus[col].isnull()
# 标记完之后，再按策略 2 进行填补即可。
```

## 2. 处理分类变量 (Categorical Variables)
机器学习无法理解 "Red" 或者 "Honda" 这种文本字符串。我们需要把文本转成数字。

```python
# 找到数据类型为 'object' (即文本)的分类列
s = (X_train.dtypes == 'object')
object_cols = list(s[s].index)

# ---------------------------------------------
# 策略 1：序号编码 (Ordinal Encoding)
# 把不同的文本按顺序编成 1,2,3...
# 适用于：有明显大小/顺序关系的词，比如 "差", "良", "优" -> 1, 2, 3
from sklearn.preprocessing import OrdinalEncoder

label_X_train = X_train.copy()
label_X_valid = X_valid.copy()

ordinal_encoder = OrdinalEncoder()
label_X_train[object_cols] = ordinal_encoder.fit_transform(X_train[object_cols])
label_X_valid[object_cols] = ordinal_encoder.transform(X_valid[object_cols])

# ---------------------------------------------
# 策略 2：🌟 独热编码 (One-Hot Encoding)
# 创建新的列，用 0 和 1 表示是否拥有该属性。
# 比如一列是颜色（红/黄/蓝），会变成三列（是否红：1/0，是否黄：1/0，是否蓝：1/0）
# 适用于：没有顺序大小之分的词，比如 "猫", "狗", "鸟"。
from sklearn.preprocessing import OneHotEncoder

# handle_unknown='ignore': 验证集遇到没见过的词，直接全标为0，不会报错退出
# sparse_output=False: 要求输出一个完整的普通矩阵
OH_encoder = OneHotEncoder(handle_unknown='ignore', sparse_output=False)

# 返回的是 numpy 矩阵
OH_cols_train = pd.DataFrame(OH_encoder.fit_transform(X_train[object_cols]))
OH_cols_valid = pd.DataFrame(OH_encoder.transform(X_valid[object_cols]))

# 重新把由于转换丢掉的索引贴回去
OH_cols_train.index = X_train.index
OH_cols_valid.index = X_valid.index

# 把之前不需要转换的数字特征(num_X_train) 和 刚转化好的独热特征(OH_cols_train) 拼合在一起
# pd.concat 再次出场！
# OH_X_train = pd.concat([num_X_train, OH_cols_train], axis=1)
```

## 3. 🌟 数据流水线 (Pipelines) - 强烈推荐！
**场景：** 你会发现前面处理缺失值和分类变量的代码又长又臭。一旦数据分了训练集、验证集、测试集，你就要反反复复写 `fit_transform` 和 `transform`。
**流水线的作用：** 把“数据清洗”和“模型训练”打包成一根管子。丢进去脏数据，管子那头直接吐出预测结果！这是专业数据科学家的标志。

```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error

# 假设此时有数值特征(numerical_cols)和分类特征(categorical_cols)

# ================================
# 第一步：定义预处理步骤 (Preprocessing)
# ================================
# 数值型数据的处理：填补缺失值 (常数填补)
numerical_transformer = SimpleImputer(strategy='constant')

# 分类型数据的处理：也是一个流水线！先填补缺失值(最频繁出现的值)，再进行独热编码
categorical_transformer = Pipeline(steps=[
    ('imputer', SimpleImputer(strategy='most_frequent')),
    ('onehot', OneHotEncoder(handle_unknown='ignore'))
])

# 把这俩预处理步骤组合起来 (ColumnTransformer)
# 意思：当数据流过来时，数值列交给 numerical_transformer 处理，分类列交给 categorical_transformer 处理
preprocessor = ColumnTransformer(
    transformers=[
        ('num', numerical_transformer, numerical_cols),
        ('cat', categorical_transformer, categorical_cols)
    ])

# ================================
# 第二步：定义模型 (Define the Model)
# ================================
model = RandomForestRegressor(n_estimators=100, random_state=0)

# ================================
# 第三步：组装超级大管子 (Create Pipeline)
# ================================
my_pipeline = Pipeline(steps=[('preprocessor', preprocessor),
                              ('model', model)
                             ])

# ================================
# 见证奇迹的时刻
# ================================
# 直接把脏的、混杂着文本和空缺的 X_train 喂给流水线！
my_pipeline.fit(X_train, y_train) 

# 直接把脏的 X_valid 喂给它，它会自动先清洗，然后预测！
preds = my_pipeline.predict(X_valid)

score = mean_absolute_error(y_valid, preds)
print('MAE:', score)
```

## 4. 交叉验证 (Cross-Validation)
**场景：** 数据集太小，如果只切分一次训练集和验证集（比如拿20%出来验证），验证集可能碰巧包含的都是很简单/很难的数据，得分骗了你。
**做法：** 把数据切成 5 份。跑 5 次模型。每次拿其中 1 份当考卷，其余 4 份当教材。最后把 5 次考试的成绩平均一下。这就叫 5折交叉验证（5-Fold CV）。

```python
from sklearn.model_selection import cross_val_score
from sklearn.pipeline import Pipeline
# 我们直接复用上面的 my_pipeline! （这就是为什么一定要学流水线）

# cross_val_score 函数直接搞定：
# cv=5: 折数为 5 折
# scoring: 评估标准。注意 sklearn 中很多评分规定“越大越好”，由于误差是越小越好，
# 所以它使用“负的 MAE (neg_mean_absolute_error)”。出来的分数是负数。
scores = -1 * cross_val_score(my_pipeline, X, y,
                              cv=5,
                              scoring='neg_mean_absolute_error')

print("MAE scores:\n", scores)             # 会打印出 5 个误差分数
print("Average MAE score (across experiments):")
print(scores.mean())                       # 取平均，这才是模型真实可靠的水平
```

## 5. 终极杀器：XGBoost 梯度提升树
**场景：** 随机森林是“集思广益”，而 XGBoost（梯度提升树）是**“错题本纠正法”**。它会建一棵树，然后看哪里预测错了��建第二棵树专门纠正第一棵树的错误，循环往复。它是 Kaggle 比赛结构化数据绝对的王者。

```python
# XGBoost 不属于 sklearn，它是一个独立的牛逼库
from xgboost import XGBRegressor

# 1. 基础版调用
my_model = XGBRegressor()
my_model.fit(X_train, y_train)
predictions = my_model.predict(X_valid)

# 2. 🌟 进阶调参版 (这是你拿高分的关键)
my_model = XGBRegressor(
    n_estimators=1000, # 要建多少棵树 (循环多少次)。数值大一点(100-1000)
    learning_rate=0.05, # 学习率：每次纠正错误的步子跨多大。越小越精细，但需要配更大的 n_estimators
    n_jobs=4 # 利用电脑的几个CPU核心来算，4代表四核，能加快运行速度
)

# 早期停止机制 (early_stopping_rounds)
# 防止跑1000棵树跑到过拟合：如果在验证集上连续 5 次(5棵树)误差都没有降低，就立刻停止训练！
my_model.fit(X_train, y_train, 
             early_stopping_rounds=5, 
             eval_set=[(X_valid, y_valid)], # 必须告诉它拿什么数据当考卷来看有没有降低误差
             verbose=False)                 # 不要把每棵树的过程都打印出来吵我眼睛

predictions = my_model.predict(X_valid)
```

## 6. 数据泄露 (Data Leakage)
*（这里没有需要记忆的语法，但是概念极其重要）*
**场景：** 你训练模型时考了 100 分，一上线到真实环境就崩溃。为什么？因为**考题提前泄露到了训练资料里**。
**常见泄漏：** 
我们要预测“这个人会不会得肺炎”。你在用作特征的表格 `X` 里，包含了一列叫“是否吃过治肺炎的抗生素”。
在真实世界里，他一定是先得了肺炎，医生才会给他开药吃。但如果你的模型看到了他“吃了治肺炎的药”，它就直接断定“这个人有肺炎”。
这就属于把 **预测发生时间点之后的信息 (Target Leakage)** 泄露进去了。
**对策：** 在训练前，仔细排查所有的特征（列），把那些只有在“预测目标发生之后”才会产生的数据剔除掉！

---
### 结语与复习建议

看完了不要焦虑！**数据科学就是乐高积木。**
你在 Kaggle 写代码的时候，流程永远是这几步：
1. `pd.read_csv` (引入数据)
2. `dropna`, `SimpleImputer`, `OneHotEncoder` (洗干净数据)
3. `X` 和 `y`, `train_test_split` (分切特征和目标)
4. `model = RandomForestRegressor()` 或 `XGBRegressor()` (请出模型)
5. `model.fit(X, y)` (训练)
6. `model.predict()` 和 `mean_absolute_error()` (预测和评分)

这三门课程（**数据可视化、特征工程、SQL基础**）是让你从“初级调包侠”进阶为“Kaggle 竞赛高手”的必经之路。

你提到希望有极度详细（上万字级别）的拆解。受限于单次回答的字数上限，我为你提炼了**最核心、最浓缩、最能直接复制粘贴使用的“千字纯干货”**。这不仅是一份代码速查表，更是一份**思维导图**。

请记住我们的原则：**不要背单词，理解它的“业务场景”，然后复制粘贴！**

---

# 🎨 第一部分：数据可视化 (Data Visualization)
*使用的核心武器：`Seaborn` (建立在 Matplotlib 之上的高级画图库)*

**核心心法：** 画图不是为了好看，而是为了**“找规律”**和**“看异常”**。Kaggle 把画图分为三大场景：**趋势 (Trends)、关系 (Relationships)、分布 (Distributions)**。

### 0. 每次画图前的“起手式”
```python
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# 把图表的默认尺寸设大一点，宽16，高6，免得挤在一起看不清
plt.figure(figsize=(16,6)) 

# 设定图表的整体风格，"darkgrid" 是带灰色网格的背景，看起来最专业
sns.set_style("darkgrid") 
```

### 1. 📈 场景一：看“趋势” (Trends) -> 折线图
**业务场景：** 随着**时间**推移，数据是怎么变化的？比如：Spotify 上某首歌每天的播放量、比特币每天的价格。

```python
# 读取时间序列数据（注意：要把日期那一列设为行索引 index_col，并解析日期 parse_dates）
spotify_data = pd.read_csv("spotify.csv", index_col="Date", parse_dates=True)

# 语法逻辑：sns.lineplot(data=你的表格)
# 它会自动把行索引（日期）作为 X 轴，把表格里的数值作为 Y 轴
sns.lineplot(data=spotify_data)

# 如果你只想画其中一列（比如只看 Shape of You 这首歌）
sns.lineplot(data=spotify_data['Shape of You'], label="Shape of You")
sns.lineplot(data=spotify_data['Despacito'], label="Despacito")

# 加上标题
plt.title("Daily Global Streams of Popular Songs")
```

### 2. 📊 场景二：看“关系” (Relationships) -> 条形图、热力图、散点图
**业务场景：** 两个不同的变量之间有什么关系？比如：不同平台的游戏评分对比（条形图）；抽烟和肺癌有没有关系（散点图）。

**条形图 (Bar Chart)：适合分类数据对比**
```python
# 语法逻辑：x轴放类别，y轴放数值
# 比如看不同游戏平台 (Platform) 的平均赛车游戏得分 (Racing)
sns.barplot(x=ign_data.index, y=ign_data['Racing'])

# 因为平台名字可能很长，横着放会重叠，所以把图转个90度
plt.xticks(rotation=90)
```

**热力图 (Heatmap)：适合看一张二维大表的“颜色深浅”**
```python
# 经常用来代替枯燥的数字表格。颜色越深代表数值越大。
# annot=True 的意思是：把具体的数字也写在颜色方块上面
sns.heatmap(data=ign_data, annot=True)
```

**散点图 (Scatter Plot)：适合看两个连续数字特征的关系**
```python
# 比如：BMI指数 (x) 和 医疗费用 (y) 的关系
sns.scatterplot(x=insurance_data['bmi'], y=insurance_data['charges'])

# 🌟 进阶：回归线散点图 (Regression Plot)
# 不仅画散点，还顺便帮你用 AI 拟合一条直线，一眼看出正相关还是负相关
sns.regplot(x=insurance_data['bmi'], y=insurance_data['charges'])

# 🌟 杀手锏：带颜色的散点图 (Color-coded Scatter Plot)
# 加一个参数 `hue` (色调)
# 比如：不仅看 BMI 和费用的关系，还要把抽烟的人标成红色，不抽烟的标成蓝色！
sns.scatterplot(x=insurance_data['bmi'], y=insurance_data['charges'], hue=insurance_data['smoker'])

# 终极形态：两条回归线
# 直接用 lmplot，它会给抽烟和不抽烟的人各画一条趋势线！
sns.lmplot(x="bmi", y="charges", hue="smoker", data=insurance_data)
```

### 3. 📉 场景三：看“分布” (Distributions) -> 直方图、密度图
**业务场景：** 这个数据集中在哪一块？有没有极端值？比如：这家医院大部分乳腺癌肿瘤是多大？

**直方图 (Histogram)：把数据切成一个个小区间数个数**
```python
# 看看良性肿瘤 (B) 的面积分布
# a 意思是你的数据序列，kde=False 表示不画平滑曲线
sns.histplot(cancer_b_data['Area (mean)'])
```

**核密度估计图 (KDE Plot)：平滑版的直方图，像一座座小山**
```python
# 只要曲线，不要一根根的柱子。shade=True 把山底下的面积涂上颜色
sns.kdeplot(data=cancer_b_data['Area (mean)'], fill=True)

# 🌟 多组数据对比分布 (非常常用！)
# 在同一张图上，对比良性(B)和恶性(M)肿瘤的大小分布
sns.kdeplot(data=cancer_b_data['Area (mean)'], fill=True, label="Benign (良性)")
sns.kdeplot(data=cancer_m_data['Area (mean)'], fill=True, label="Malignant (恶性)")
plt.legend() # 显示右上角的标签图例
```

---

# 🛠️ 第二部分：特征工程 (Feature Engineering)
*这是拉开 Kaggle 选手差距的最核心课程。如果说模型是“厨房里的锅”，那特征就是“食材”。烂食材绝对炒不出好菜（Garbage in, Garbage out）。特征工程就是**“切配、腌制食材”**的过程。*

### 1. 互信息 (Mutual Information, MI)
**场景：** 数据集里有 80 多个列（特征），到底哪些列对预测房价最有用？我不能盲猜，需要用数学来打分。
**逻辑：** 互信息就像是衡量两个变量“八卦关联度”的指标。MI 分数越高，说明这个特征对预测目标越有用。

```python
from sklearn.feature_selection import mutual_info_regression

# 这是一个固定的模板函数，直接复制保存即可！
def make_mi_scores(X, y):
    # 先把特征里的文本(object)转成模型勉强能看懂的数字序号，因为 MI 计算需要数字
    X = X.copy()
    for colname in X.select_dtypes(["object", "category"]):
        X[colname], _ = X[colname].factorize()
    
    # 获取所有的离散特征(整数类型)，告诉算法哪些是分类变量
    discrete_features = [pd.api.types.is_integer_dtype(t) for t in X.dtypes]
    
    # 🌟 核心计算代码：计算 X 里所有列和 y 的互信息分数
    mi_scores = mutual_info_regression(X, y, discrete_features=discrete_features, random_state=0)
    
    # 把分数整理成好看的 Pandas 表格，并从大到小排序
    mi_scores = pd.Series(mi_scores, name="MI Scores", index=X.columns)
    mi_scores = mi_scores.sort_values(ascending=False)
    return mi_scores

# 运行并打印分数
mi_scores = make_mi_scores(X, y)
print(mi_scores.head()) 
```

### 2. 创建新特征 (Creating Features)
**场景：** 现有的列不够用。比如有“地上建筑面积”和“地下室面积”，其实模型更想知道“总面积”。我们要人工帮它算出来。

```python
# 1. 数学变换 (Mathematical Transforms)
# 比例/比率：比如 楼层高度 / 楼层面积
autos["stroke_ratio"] = autos.stroke / autos.bore
# 对数变换：当某个金额差距极大（比如有的房子10万，有的1000万），取对数可以让数据分布更正常
import numpy as np
accidents["LogWindSpeed"] = accidents.WindSpeed.apply(np.log1p)

# 2. 计数 (Counts)
# 统计一辆车上有多少个表明“它很危险”的配置
roadway_features = ["Amenity", "Bump", "Crossing", "GiveWay", "Junction", "NoExit"]
# 语法：选中这些列 -> 沿着横向(axis=1)求和(sum)
accidents["RoadwayFeatures"] = accidents[roadway_features].sum(axis=1)

# 3. 拆解特征 (Building-Up and Breaking-Down)
# 拆解文本：从 "1-2-2023" 里拆出年份和月份
# 拆解字符串特征极度重要，比如从名字里拆出 Title (Mr, Mrs, Miss)
customer["Type"] = customer["Policy"].str.split(" ", expand=True)[0]
```

### 3. K-Means 聚类 (Clustering)
**场景：** 用“无监督学习”来创造特征。比如预测加州的房价，我们可以根据经纬度，用聚类算法把地理位置分成 6 个“商圈/板块”。这个“板块编号”就是一个超级强大的新特征！

```python
from sklearn.cluster import KMeans

# 挑出你想用来聚类的列 (比如经度和纬度)
features = ["Longitude", "Latitude"]
X_cluster = df[features]

# 定义聚类算法：分成 6 类 (n_clusters=6)
kmeans = KMeans(n_clusters=6, random_state=0)

# 训练并直接输出每一行属于哪个类！把结果作为新的一列加到原表里
df["Cluster"] = kmeans.fit_predict(X_cluster)

# 现在，原本单纯的经纬度，变成了很有商业意义的 "板块 0", "板块 1" ...
```

### 4. 主成分分析 (PCA)
**场景：** 数据集里有 10 个描述车身尺寸的特征（长、宽、高、轴距...），它们高度重合。PCA 可以把这 10 个特征浓缩成 2 个“主成分”（比如 PC1代表“车体大小”，PC2代表“底盘运动性”）。

```python
from sklearn.decomposition import PCA

# 取出需要降维/浓缩的特征
features = ["wheel-base", "length", "width", "height", "curb-weight"]
X_pca = df[features]

# 数据标准化极其重要！做 PCA 前必须把数据缩放到同一个尺度 (不然数值大的列会霸占结果)
X_scaled = (X_pca - X_pca.mean(axis=0)) / X_pca.std(axis=0)

# 定义 PCA，提取所有的主成分
pca = PCA()
X_components = pca.fit_transform(X_scaled)

# 把算出来的矩阵变成好读的 DataFrame，列名叫 PC1, PC2...
component_names = [f"PC{i+1}" for i in range(X_components.shape[1])]
X_pca_df = pd.DataFrame(X_components, columns=component_names)

# PCA 最核心的是看懂 "Loadings"（成分载荷）
# 它告诉你 PC1 到底是由哪些原始特征组成的
loadings = pd.DataFrame(pca.components_.T, columns=component_names, index=X_pca.columns)
print(loadings)
```

---

# 🗄️ 第三部分：SQL 基础 (Intro to SQL)
*Kaggle 中的 SQL 课程非常特殊。它不是在普通的数据库里查，而是教你用 Python 调用 Google 的大数据平台 **BigQuery**。你可以把它当成用 SQL 语言去操作几百 GB 的超大云端 CSV。*

**核心心法：** 无论多复杂的 SQL，永远跑不出这个骨架：`SELECT (拿什么) FROM (从哪拿) WHERE (条件) GROUP BY (分组) ORDER BY (排序)`。

### 1. 接入 BigQuery 数据库
```python
# 导入 Google 云端大数据库的 API
from google.cloud import bigquery

# 创建一个客户端（相当于打开数据库连接软件）
client = bigquery.Client()

# 找到名叫 "hacker_news" 的公开数据库
dataset_ref = client.dataset("hacker_news", project="bigquery-public-data")

# 获取并查看这个数据库的���息
dataset = client.get_dataset(dataset_ref)
tables = list(client.list_tables(dataset))
for table in tables:
    print(table.table_id) # 打印里面所有表的名字，比如 "full", "comments"
```

### 2. 最核心的查询：SELECT, FROM, WHERE
**业务场景：** 帮我从 `full` 表里，找出所有类型是 "job" 的记录，只要它们的 `title` (标题) 和 `text` (内容)。

```python
# 在 Python 里，SQL 语句其实就是一个长长的字符串 (用三个引号包起来可以换行)
query = """
        SELECT title, text
        FROM `bigquery-public-data.hacker_news.full`
        WHERE type = "job"
        """

# 🌟 安全第一：查询大数据是要扣钱的！Kaggle 教了一个绝招防止查询过大
# 设置最大计算量为 1 GB。如果你写的 SQL 需要扫超过 1GB 的数据，它会直接报错阻止你。
safe_config = bigquery.QueryJobConfig(maximum_bytes_billed=10**9)

# 真正去云端执行查询
query_job = client.query(query, job_config=safe_config)

# 把查到的结果下载下来，直接转成你最熟悉的 Pandas DataFrame！
# 后面你想怎么分析就怎么分析！
jobs_df = query_job.to_dataframe()
```

### 3. 分组统计：GROUP BY, HAVING, COUNT()
**业务场景：** 统计 hacker_news 上每天有多少篇帖子。只要那些发帖量超过 1000 的日子。

```python
query = """
        SELECT `by` AS author, COUNT(id) AS NumPosts
        FROM `bigquery-public-data.hacker_news.full`
        GROUP BY `by`                  -- 按作者分组
        HAVING COUNT(id) > 1000        -- HAVING 是在分组后进行过滤
        ORDER BY NumPosts DESC         -- ORDER BY: 按帖子数量排序，DESC 表示降序(从大到小)
        """
# 注意：在 SQL 里，把列名重命名叫 AS。
# COUNT(id) 意思是数一数这个组里有多少个 ID。
```

### 4. 拆解日期：EXTRACT
**业务场景：** 表里的日期往往精确到秒（2023-05-12 14:22:11）。我只想统计“每个星期的第几天 (Day of Week)”发生的事故最多。

```python
query = """
        SELECT EXTRACT(DAYOFWEEK FROM timestamp_of_crash) AS day_of_week, 
               COUNT(consecutive_number) AS num_accidents
        FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
        GROUP BY day_of_week
        ORDER BY num_accidents DESC
        """
# EXTRACT(DAYOFWEEK FROM ...) 能够直接把一长串时间戳，扣成数字 1-7 (星期天到星期六)。
# 其他常用：EXTRACT(YEAR FROM...), EXTRACT(MONTH FROM...)
```

### 5. 多表联合：JOIN
**业务场景：** 有两张表。一张表记录了用户的 ID 和姓名 (`users` 表)；另一张表记录了每个回帖的 ID、内容和作者的用户 ID (`comments` 表)。我想把它们拼起来，看具体是谁发了什么。

```python
# INNER JOIN 就像两张表的联姻。ON 后面写联姻的条件（两边共有的身份证号）。
query = """
        SELECT u.name, c.text
        FROM `bigquery-public-data.hacker_news.users` AS u
        INNER JOIN `bigquery-public-data.hacker_news.comments` AS c
            ON u.id = c.author
        """
# 逻辑拆解：
# 1. 给长长的表名起了短别名：users 叫 u，comments 叫 c
# 2. 从 u 里面拿 name，从 c 里面拿 text
# 3. 拼接条件：u 表的 id 必须等于 c 表的 author 字段
```
完全理解！为了让你彻底拥有一个**“Kaggle 字典级别的外脑”**，我将为你进行**深度扩充**。

在真实的 Kaggle 竞赛中，初学者往往在基础语法上没问题，但在遇到**“高阶图表定制”、“复杂特征构造”**和**“嵌套 SQL 查询”**时会瞬间卡壳。

下面我为你补充这三门课中**最容易遗忘、但也最能拉开分数差距的“高阶进阶语法与实战技巧”**。请将这些代码块一并存入你的速查手册！

---

# 🎨 深度扩充一：数据可视化 (Data Visualization) - 高阶掌控

在 Kaggle 的中后期，你不再只是画单张图，而是需要把好几个图拼在一起对比，或者处理密密麻麻重叠在一起的百万级数据点。

### 1. 多图拼接：子图绘制 (Subplots)
**业务场景：** 领导或评委不想看 5 张分开的图，他们希望在一个面板里看到“不同年龄段”和“不同性别”的消费分布，方便左右对比。

```python name=data_viz_subplots.py
import matplotlib.pyplot as plt
import seaborn as sns

# 创建一个大画板 (Figure) 和多个子画板 (Axes)
# nrows=1, ncols=2 意思是：1 行 2 列（共2张小图）
# figsize=(14, 6) 控制整个大画板的尺寸
fig, axes = plt.subplots(nrows=1, ncols=2, figsize=(14, 6))

# 在第一张小图 (axes[0]) 上画直方图
sns.histplot(data=df['Age'], ax=axes[0])
axes[0].set_title("Age Distribution") # 给第一张小图加标题

# 在第二张小图 (axes[1]) 上画散点图
sns.scatterplot(x=df['Age'], y=df['Income'], hue=df['Gender'], ax=axes[1])
axes[1].set_title("Age vs Income") # 给第二张小图加标题

# 自动调整间距，防止两张图的字撞在一起
plt.tight_layout()
plt.show()
```

### 2. 🌟 分面网格：FacetGrid (Kaggle 大神最爱)
**业务场景：** 数据里有 10 个不同的城市，你想给每个城市都画一张房价的直方图。手动写 10 次太傻了，FacetGrid 可以一键生成照片墙！

```python name=data_viz_facetgrid.py
# 步骤 1：按照 'City' (城市) 把画板切分成多个小格子
# col="City" 意思是每个城市占一列，col_wrap=3 意思是每行最多放 3 张图就换行
g = sns.FacetGrid(df, col="City", col_wrap=3, height=4)

# 步骤 2：把你想画的图“映射 (map)”到这些小格子里
# 这里我们要在每个格子里画 'Price' 的直方图 (histplot)
g.map(sns.histplot, "Price")

# 加一个总标题 (y=1.05 把标题往上抬一点，免得挡住图)
g.fig.suptitle("House Prices by City", y=1.05)
```

---

# 🛠️ 深度扩充二：特征工程 (Feature Engineering) - 夺冠秘籍

如果说之前的 PCA 和聚类是标准动作，那么接下来的**目标编码 (Target Encoding)** 就是 Kaggle 比赛结构化数据中经常用来冲刺前 1% 的绝招。

### 1. 🌟 目标编码 (Target Encoding)
**业务场景：** 假设你有一个特征叫 `Zipcode`（邮编），里面有 5000 个不同的邮编。
*   如果用“独热编码 (One-Hot)”，会多出 5000 列，内存直接爆炸，模型也会崩溃。
*   如果用“序号编码 (Ordinal)”，邮编 10001 和 10002 并没有大小之分，模型会被误导。
*   **绝招：** 用**“这个邮编里的历史平均房价”**来代替这个邮编！比如 10001 邮编的房子历史平均卖 500 万，就把所有 10001 替换成 500 万。这就叫目标编码。

```python name=feature_engineering_target_encode.py
import pandas as pd
# category_encoders 是一个专门做特征编码的神器库
from category_encoders import MEstimateEncoder

# 准备好类别特征 X_encode 和 目标变量 y
X_encode = df.select_dtypes(["object", "category"])
y = df['Price']

# 定义目标编码器
# m=5 是一种平滑机制 (Smoothing)：如果某个偏僻邮编历史上只卖过 1 套房，恰好是 1 个亿的豪宅，
# 直接用 1 亿代替这个邮编就太绝对了。m 参数会引入全局平均值来“中和”这种极端情况。
encoder = MEstimateEncoder(cols=X_encode.columns, m=5.0)

# 拟合并且转换
# ⚠️ 极度危险的坑 (Data Leakage)：
# 绝对不能把验证集的数据也混在一起算平均值！否则等于提前泄露了验证集的答案。
# 正确做法：只用训练集 (train) 来 fit，然后分别 transform 训练集和验证集。
X_train_encoded = encoder.fit_transform(X_train_encode, y_train)
X_valid_encoded = encoder.transform(X_valid_encode)
```

### 2. 异常值处理 (Outlier Treatment)
**业务场景：** 预测人的身高，绝大部分在 1.5 - 1.9 米，但数据录入错误，出现了一个 18 米的人。不处理的话，线性模型会被这个 18 米的人严重带偏。

```python name=feature_engineering_outliers.py
import numpy as np

# 策略 1：盖帽法 (Clipping/Winsorization)
# 把所有大于 99% 分位数的数据，强制压平到 99% 的数值；小于 1% 的强制拔高到 1% 的数值。
# 比如身高最高只算到 2.1米，再高的统统算 2.1米。
lower_bound = df['Height'].quantile(0.01)
upper_bound = df['Height'].quantile(0.99)

# np.clip 会把超出上下限的值自动截断
df['Height_Clipped'] = np.clip(df['Height'], lower_bound, upper_bound)

# 策略 2：对数转换 (Log Transformation) -> 专治“长尾分布”
# 比如收入数据，大部分人月薪 1 万，少部分人月薪 1 个亿。画图出来尾巴拖得很长。
# 用 np.log1p (即 log(x+1)) 转换后，1 万和 1 亿的差距在模型眼里就没那么夸张了，分布会变得更像正态分布。
df['Income_Log'] = np.log1p(df['Income'])
```

---

# 🗄️ 深度扩充三：SQL 基础与进阶 (Intro to & Advanced SQL)

Kaggle 的 SQL 课程后半段（Advanced SQL）是很多非计算机专业同学的噩梦。主要是因为代码变得很长，涉及了 **CTE（公共表表达式）** 和 **窗口函数（Window Functions）**。

### 1. 🌟 化繁为简的神器：CTE (WITH 语句)
**业务场景：** 你要先计算每个用户的总订单量，然后再从这些人里挑出总订单量大于 10 的，最后再算这些 VIP 用户的平均消费。如果全写在一坨 SQL 里，括号套括号会让人疯掉。
**逻辑：** `WITH` 语句的作用就是**“打草稿”**。先把第一步的中间结果存成一张“虚拟草稿表”，然后再在草稿表上查。

```sql name=advanced_sql_cte.sql
# 我们用 WITH 定义一张草稿表，叫 UserOrders 草稿
query_with_cte = """
    WITH UserOrders AS (
        -- 这是草稿 1 的内容：统计每个用户的订单总数和总花费
        SELECT 
            user_id, 
            COUNT(order_id) AS total_orders,
            SUM(spend) AS total_spend
        FROM `bigquery-public-data.store.orders`
        GROUP BY user_id
    )
    
    -- 下面才是真正的正式查询！我们可以直接把 UserOrders 当成真实的表来用！
    SELECT 
        user_id, 
        total_spend / total_orders AS avg_spend_per_order
    FROM UserOrders
    WHERE total_orders > 10
    ORDER BY avg_spend_per_order DESC
"""
```

### 2. 高维打击：窗口函数 (Window Functions - OVER & PARTITION BY)
**业务场景：** 我们有一张员工薪水表。我想在每一行数据的后面，额外加一列，显示**“这个员工所在的部门，平均薪水是多少”**。
*   如果用 `GROUP BY`，所有员工的明细行就全消失了，只剩下部门汇总的几行。
*   **逻辑：** 窗口函数允许你在**不改变原有行数**的情况下，进行分组统计！就像是打开一个小窗口，看一眼这个组的数据算个平均，然后把结果写在这一行旁边。

```sql name=advanced_sql_window.sql
query_window = """
    SELECT 
        employee_name,
        department,
        salary,
        -- 🌟 窗口函数来啦！
        -- 计算平均工资 (AVG)
        -- OVER 告诉它这是一个窗口操作
        -- PARTITION BY department 意思是：只在当前这个部门的“小窗口”里算平均
        AVG(salary) OVER (PARTITION BY department) AS dept_avg_salary,
        
        -- 进阶用法：部门内薪水排名！
        -- 在部门内 (PARTITION BY department)，按薪水从高到低 (ORDER BY salary DESC) 给每个人排个名次
        RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
        
    FROM `my_company.hr.salaries`
"""
```
*这个语法在 Kaggle 分析时序数据（比如计算“过�� 7 天的滚动平均销量”）时极度常用。*

### 3. 数据重组：UNION ALL (上下堆叠)
**业务场景：** 你有两张表结构完全一样的表，比如一张叫 `2022_sales`，一张叫 `2023_sales`。你需要把它们像叠汉堡一样上下叠起来变成一张大表。

```sql name=advanced_sql_union.sql
query_union = """
    -- 拿出 2022 年的数据
    SELECT date, product_id, revenue
    FROM `store.sales_2022`
    
    UNION ALL  -- 上下暴力拼接的胶水！
    
    -- 拿出 2023 年的数据
    SELECT date, product_id, revenue
    FROM `store.sales_2023`
"""
```

