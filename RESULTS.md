## 海量人脸特征检索的研究



### 简介

​		人脸识别的过程一般分为两个步骤：(1) 通过算法模型对待识别的人脸图像进行特征提取，生成特征向量；(2) 在已有的人脸特征库中检索与待识别特征向量最接近的向量，即为识别结果。

​		特征提取的计算耗时基本是固定的，取决于算法模型和计算硬件，通常在CPU环境下耗时1-2秒，GPU环境下100-500毫秒。特征检索的耗时与人脸特征库规模有关。特征检索时的计算量主要是计算两个特征向量之间的欧氏距离，算法复杂度为O(DN^2)，其中D为特征向量的维度，N是特征库特征数量。当N远大于D时，维度对计算量的影响比较小，主要是特征库中特征数量的影响。

​		本测试旨在通过不同方法的欧氏距离计算测试，评估在海量人脸特征库中检索单一人脸特征的可行性、耗时及硬件资源需求。这里“海量数据”的目标暂定为1亿个特征，可以接受的耗时暂定为1-2秒。



### 方法

​		计算测试中，因为特征提取耗时基本固定，暂定为500毫秒。测试主要针对特征检索过程。因为现有模型生成的最大特征向量为2048维，因此在测试过程中使用2048维的特征向量，从程序角度为2048个元素的一维数组。计算测试主要使用4个版本编程进行对比测试：(1)python实现，(2)Go单线程实现，(3)Go多线程实现，(4)CUDA并发C++实现。前3个测试均使用CPU资源，测试(4)使用GPU计算资源。

​		测试硬件资源：CPU资源为AMD R5 1600X，6个核心，可以实现虚拟12核并发；GPU资源为RTX 2070 SUPER，有8GB显示内存。

​		CUDA测试为了提高显存使用效率，使用半精度浮点数（float16）进行，显存使用可以提高一倍，对计算速度没有影响。风险是，当精度减半后，可能出现计算结果误差。



测试过程：

1. 随机生成100万个2048维特征向量，用于计算测试；
2. python版测试，使用numpy库；
3. Go单线程测试；
4. Go多线程测试，使用12个go routine，与CPU核心数相同；
5. CUDA并发测试，使用半精度float16进行测试，块线程数量为256，块数按需。



### 测试结果

| 数据量 | Python       | Go单线程    | Go多线程   | CUDA      |
| ------ | ------------ | ----------- | ---------- | --------- |
| 1万    | n/a          | n/a         | n/a        | 0.798 ms  |
| 10万   | n/a          | n/a         | n/a        | 7.023 ms  |
| 100万  | 11873.225 ms | 1752.153 ms | 226.094 ms | 64.261 ms |



结果讨论

1. python和go单线程在海量特征检索中不实用。
2. go多线程计算时间依赖CPU的核心数量和核心主频有很大关系。如果CPU性能在测试机基础上能提升4倍（226/65=3.48），性能还是可以与CUDA进行竞争的。测试机是普通PC，多路专用PC服务器应该是可以的。
3. CUDA的性能表现比较符合线性规律，可预测1000万数据应该在650ms左右。
4. CUDA计算的限制主要在显存数量。为减少整体计算耗时，数据在初始化时整体拷贝进显存，这样计算耗时即为单纯计算时间。这样做对显存资源占用要求比较高，100万数据使用float16需要4GB显存，如果float32需要8GB显存。
5. CUDA计算时，float16与float32对显存占用影响大，对计算时间影响不大。对结果误差有一定影响，需要对数据集进行评估，对精度进行一定补偿，否则会影响最终检索结果。
6. 按float16精度计算，100万向量数据需要4GB，对比两个GPU显卡的性价比数据如下：

| 显卡        | 显存 | 2048维向量 | 市场价格 | 单位数据价格     | 预估检索速度 |
| ----------- | ---- | ---------- | -------- | ---------------- | ------------ |
| Tesla V100S | 32GB | 800万      | 5万      | 0.625万/百万向量 | 520 ms       |
| RTX 3090    | 24GB | 600万      | 1.8万    | 0.3万/百万向量   | 390 ms       |





### 初步结论



1. 使用CUDA/GPU可以有效提高海量特征检索的速度。使用GPU显卡进行计算时，计算速度不是最大的瓶颈，显卡内存大小会是一个比较明显的制约条件。
2. 如果CPU性能在测试机基础上能提升4倍（226/65=3.48），性能还是可以与CUDA进行竞争的。考虑测试机是普通PC，多路专用PC服务器应该是可以有很大提升的。
3. 考虑1亿特征向量，单次识别1-2秒内，提供如下两个评估方案。**注意：**下述估算是理论计算评估，实际工程实现时会有一定误差。



#### GPU方案

1. 按上述评估计算，实现1亿特征向量检索，大约需要17张RTX3090显卡，平行计算时平均检索速度390ms，加上待测图片的特征向量提取时间（按500ms），一次人脸识别的时间大概需要890ms。
2. 如果使用float32精度计算，显卡数量将增加1倍，为34张卡。



#### CPU方案

1. 假设存在多路PC服务器，能达到4倍测试机的计算性能，则100万特征向量计算时间为57ms (226/4=56.5)，1000万特征计算数据为570ms。
2. 按1的假设和估算，实现1亿特征向量检索，大约需要10台上述多路PC服务器，平行计算时间570ms，加上待测图片的特征向量提取时间（按500ms），一次人脸识别的时间大概需要1070ms。



#### 可继续优化的方向

1. 优化CUDA的kernel算法，提高GPU核心并发度；
2. 使用kNN算法构建ball-tree，降低计算复杂度到O(DN)。

> 上述两个方向都只能优化计算速度，对内存优化没有帮助。