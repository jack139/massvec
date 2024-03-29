## 向量计算测试


### 12核32G PC
> Go语言版本使用 float32 计算结果

```
processor	: 11
vendor_id	: AuthenticAMD
cpu family	: 23
model		: 1
model name	: AMD Ryzen 5 1600X Six-Core Processor
stepping	: 1
microcode	: 0x8001129
cpu MHz		: 3600.000
cache size	: 512 KB
```

```
$ python3 edist2.py 
num=  1000 	dim=  2048
dist times: 1000000
[Time taken: 0:00:11.873225]

$ go run edist2.go 
num=  1000000 	dim=  2048
min= 309.78689575	pos=8730
[Time taken: 1.7521530800s 1.75215308s]

$ go run edist3.go 
num=  1000000 	dim=  2048
goroutine: 12	min= 309.78689575
[Time taken: 0.2260935900s 226.09359ms]
```


### RTX 2070 SUPER
> float16 半精度计算结果

```
$ ./edistCUDA
num= 10000	dim= 2048
grid size: 40	block size: 256
min= 29696.00000000	pos= 5472
[ time taken: 0.797504ms 0.162752ms ]

$ ./edistCUDA
num= 100000	dim= 2048
grid size: 391	block size: 256
min= 29696.00000000	pos= 5472
[ time taken: 7.022944ms 1.170176ms ]

$ ./edistCUDA
num= 1000000	dim= 2048
grid size: 3907	block size: 256
min= 29696.00000000	pos= 5472
[ time taken: 64.260994ms 12.235360ms ]
```
