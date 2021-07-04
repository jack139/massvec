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
	D = 1 // 翻倍，模拟海量数据
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

// 计算欧式距离,  不开根号
func edist(x []float32, y []float32) float32 {
	var sum float32
	sum = 0.0
	for i:=0;i<len(x);i++ {
		sum += (x[i]-y[i])*(x[i]-y[i])
	}
	//result := math.Sqrt(sum)

	return sum
}


func main(){
	var min float32
	var minPos int
	min = 9999999999.0
	minPos = 0

	readData()

	fmt.Println("num= ", N, "\tdim= ", len(X[0]))

	start := time.Now()

	for i:=0; i<N; i++ {
		dist := edist(X[i], X[N])
		//fmt.Printf("%.8f ", dist)
		if dist<min {
			min = dist
			minPos = i
		}
	}
	//fmt.Println()

	fmt.Printf("min= %.8f\tpos=%d\n", min, minPos)

	elapsed := time.Since(start)
	fmt.Printf("[Time taken: %.10fs %v]\n", elapsed.Seconds(), elapsed)
}
