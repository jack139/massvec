# -*- coding: utf-8 -*-

from datetime import datetime
import numpy as np

dim = 2048
n = 1000 # 100 000 000

ff = open('vector.data', 'w')

for x in range(n):
	x = np.random.random(dim)
	xs = ','.join(['%.16f'%i for i in x.tolist()])+'\n'
	ff.write(xs)

ff.close()
