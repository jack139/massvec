# -*- coding: utf-8 -*-

from datetime import datetime
import numpy as np

with open("vector.data") as f:
    data = f.readlines()

X = []

for i in data:
    X.append(np.array([float(x) for x in i.split(",")]))

print("num= ", len(X), "\tdim= ", len(X[0]))

# Euclidean 欧几里得距离

start_time = datetime.now()

for i in range(len(X)):
    for j in range(len(X)):
        dist2 = np.sqrt(np.sum(np.square(X[i]-X[j])))
        #print("%.8f"%dist2, end=" ")
    #print()

print("dist times: %d"%(len(X)*len(X)))
print('[Time taken: {!s}]'.format(datetime.now() - start_time))

