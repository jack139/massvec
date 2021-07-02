# -*- coding: utf-8 -*-

from datetime import datetime
import numpy as np

with open("vector.data") as f:
    data = f.readlines()

X = []
minimal = 99999999999

for i in data:
    X.append(np.array([float(x) for x in i.split(",")]))

N = len(X)-1

print("num= ", N, "\tdim= ", len(X[0]))

# Euclidean 欧几里得距离

start_time = datetime.now()

for i in range(N):
    #dist2 = np.sqrt(np.sum(np.square(X[i]-X[j])))
    dist2 = np.sum(np.square(X[i]-X[N])) # 不开根号
    if dist2<minimal:
        minimal = dist2
    print("%.8f"%dist2, end=" ")
print()

print("dist times: %d\tmin= %.8f"%(len(X)*len(X), minimal))
print('[Time taken: {!s}]'.format(datetime.now() - start_time))

