package main

import (
	"fmt"
	//"math"
	"time"
	"io/ioutil"
	"strings"
	"strconv"
)

const (
	D = 100 // 翻倍，模拟海量数据
)

var (
	X [][]float64
	min float64
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
		X = append(X, make([]float64, 0))
		for _,fs := range xx {
			f, _ := strconv.ParseFloat(fs, 64)
			X[N+i] = append(X[N+i], f)
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

// 计算欧式距离,  不开根号
func edist(x []float64, y []float64) float64 {
	var sum float64
	sum = 0.0
	for i:=0;i<len(x);i++ {
		sum += (x[i]-y[i])*(x[i]-y[i])
	}
	//result := math.Sqrt(sum)

	return sum
}


func main(){
	min = 9999999999.0

	readData()

	fmt.Println("num= ", N, "\tdim= ", len(X[0]))

	start := time.Now()

	for i:=0; i<N; i++ {
		dist := edist(X[i], X[N])
		//fmt.Printf("%.8f ", dist)
		if dist<min {
			min = dist
		}
	}
	//fmt.Println()

	fmt.Printf("min= %.8f\n", min)

	elapsed := time.Since(start)
	fmt.Printf("[Time taken: %.10fs %v]\n", elapsed.Seconds(), elapsed)
}
