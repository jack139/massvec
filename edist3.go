package main

import (
	"fmt"
	//"math"
	"time"
	"io/ioutil"
	"strings"
	"strconv"
)

// go routine 数量, 建议与cpu核数一致
const (
	GONUM = 12
	D = 100 // 翻倍，模拟海量数据
)

var (
	X [][]float32
	N int
)

// 从文件载入测试数据
func readData(){
	b, err := ioutil.ReadFile("vector.data") 
	if err != nil {
		fmt.Print(err)
	}
	s := string(b)
	lines := strings.Split(s, "\n")

	//fmt.Println(len(lines), len(lines[0]))

	for i:=0;i<len(lines);i++ {
		if len(lines[i])==0 { continue } // 过滤掉空行
		xx := strings.Split(lines[i], ",")
		X = append(X, make([]float32, 0))
		for _,fs := range xx {
			f, _ := strconv.ParseFloat(fs, 32)
			X[N+i] = append(X[N+i], float32(f))
			//fmt.Printf("%.8f ", f)
		}
		//fmt.Println()
	}

	N = len(X)-1
	test := X[N] // 保存测试向量（最后一个）
	X = X[:N] // 删除最后一个

	for d:=1;d<D;d++ { // 复制 D-1 次
		X = append(X, X[:N]...)
	}

	X = append(X, test) // 追加测试向量

	N = len(X)-1
}

// 计算欧式距离, 不开根号
func edist(x []float32, y []float32) float32 {
	var sum float32
	sum = 0.0
	for i:=0;i<len(x);i++ {
		sum += (x[i]-y[i])*(x[i]-y[i])
	}
	//result := math.Sqrt(sum)

	return sum
}

// 用X中最后1个向量做测试
func findMin(start int, end int, ch chan string) {
	//fmt.Println("-->", start, end)
	var min1 float32
	min1 = 999999999.0
	for i:=start; i<end; i++ {
		dist := edist(X[i], X[N])
		//fmt.Printf("%.8f ", dist)
		if dist<min1 {
			min1 = dist
		}
	}
	//fmt.Println()

	ch<- fmt.Sprintf("%.16f", min1)
}

func main(){
	var min float32
	var seg int
	min = 99999.0
	channel := make([]chan string, GONUM)

	readData()

	fmt.Println("num= ", N, "\tdim= ", len(X[0]))


	seg = N/GONUM

	start := time.Now()

	for i:=0;i<GONUM;i++ {
		channel[i] = make(chan string)
		var end int
		if i+1==GONUM { 
			end = N // 对seg计算整除有余数的情况
		} else {
			end = i*seg+seg
		}
		go findMin(i*seg, end, channel[i])
	}

	// 取得返回结果
	for _, rc := range(channel) {
		t := <-rc
		f, _ := strconv.ParseFloat(t, 32)
		if float32(f)<min {
			min = float32(f)
		}
	}

	fmt.Printf("goroutine: %d\tmin= %.8f\n", GONUM, min)

	elapsed := time.Since(start)
	fmt.Printf("[Time taken: %.10fs %v]\n", elapsed.Seconds(), elapsed)
}
