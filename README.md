## 向量计算测试


### 8核8G i5笔记本

```
processor	: 7
vendor_id	: GenuineIntel
cpu family	: 6
model		: 142
model name	: Intel(R) Core(TM) i5-8265U CPU @ 1.60GHz
stepping	: 12
microcode	: 0xb2
cpu MHz		: 3759.463
cache size	: 6144 KB
```

```
$ python3 edist2.py 
num=  1000 	dim=  2048
dist times: 1000000
[Time taken: 0:00:11.873225]

$ go run edist2.go 
num=  1000 	dim=  2048
dist times: 1000000
[Time taken: 2.3769506390s 2.376950639s]
```

### 4核16G Xeon服务器

```
processor	: 3
vendor_id	: GenuineIntel
cpu family	: 6
model		: 85
model name	: Intel(R) Xeon(R) Platinum 8269CY CPU @ 2.50GHz
stepping	: 7
microcode	: 0x1
cpu MHz		: 2499.998
cache size	: 36608 KB
```

```
# python3 edist2.py 
num=  1000 	dim=  2048
dist times: 1000000
[Time taken: 0:00:11.105829]

# ./edist2 
num=  1000 	dim=  2048
dist times: 1000000
[Time taken: 2.8235832940s 2.823583294s]
```