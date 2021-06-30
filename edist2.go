package main

import (
	"fmt"
	"math"
	"time"
	"io/ioutil"
	"strings"
	"strconv"
)

var (
	X [][]float64
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
		}
	}
}

// 计算欧式距离
func edist(x []float64, y []float64) float64 {
	var sum float64
	sum = 0.0
	for i:=0;i<len(x);i++ {
		sum += (x[i]-y[i])*(x[i]-y[i])
	}
	result := math.Sqrt(sum)

	return result
}


func main(){
	readData()

	fmt.Println("num= ", len(X), "\tdim= ", len(X[0]))

	start := time.Now()

	for i:=0; i<len(X); i++ {
		for j:=0; j<len(X); j++ {
			dist := edist(X[i], X[j])
			//fmt.Printf("%.8f ", dist)
			dist += 1
		}
		//fmt.Println()
	}

	fmt.Printf("dist times: %d\n", len(X)*len(X))

	elapsed := time.Since(start)
	fmt.Printf("[Time taken: %.10fs %v]\n", elapsed.Seconds(), elapsed)
}
