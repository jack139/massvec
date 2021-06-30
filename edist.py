# -*- coding: utf-8 -*-

from datetime import datetime
import numpy as np

#x = np.random.random(10)
#y = np.random.random(10)

x = np.array([0.97006349, 0.5127459, 0.44315555, 0.09636233, 0.6790125, 0.80202988, 0.94640137, 0.38441741, 0.01713934, 0.72238491])
y = np.array([0.34731419, 0.15514822, 0.6681165, 0.52882095, 0.01684999, 0.2326016, 0.72043829, 0.43343879, 0.36280994, 0.67440929])

print('x',x)
print('y',y)

# Euclidean 欧几里得距离

# solution1
start_time = datetime.now()
dist1 = np.linalg.norm(x-y)
print('[Time taken: {!s}]'.format(datetime.now() - start_time))
print('dist1',dist1)

# solution2
start_time = datetime.now()
dist2 = np.sqrt(np.sum(np.square(x-y)))
print('[Time taken: {!s}]'.format(datetime.now() - start_time))
print('dist2',dist2)
