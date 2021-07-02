# -*- coding: utf-8 -*-

from datetime import datetime
import numpy as np

dim = 10
n = 10 # 100 000 000

ff = open('vector.data', 'w')

# 多生成1个，用最后1个与其他进行比较计算
for x in range(n+1):
	x = np.random.random(dim)
	xs = ','.join(['%.16f'%i for i in x.tolist()])+'\n'
	ff.write(xs)

ff.close()
