package main

import (
	"fmt"
	//"math"
	"time"
	"io/ioutil"
	"strings"
	"strconv"
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
		if len(X)<i+1 { // 添加一个新向量
			X = append(X, make([]float64, 0))
		}
		for _,fs := range xx {
			f, _ := strconv.ParseFloat(fs, 64)
			X[i] = append(X[i], f)
			//fmt.Printf("%.8f ", f)
		}
		//fmt.Println()
	}

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
		fmt.Printf("%.8f ", dist)
		if dist<min {
			min = dist
		}
	}
	fmt.Println()

	fmt.Printf("dist times: %d\tmin= %.8f\n", N, min)

	elapsed := time.Since(start)
	fmt.Printf("[Time taken: %.10fs %v]\n", elapsed.Seconds(), elapsed)
}
