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
	min float64
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
	min = 9999999999.0

	readData()

	fmt.Println("num= ", len(X), "\tdim= ", len(X[0]))

	start := time.Now()

	for i:=0; i<len(X); i++ {
		for j:=0; j<len(X); j++ {
			dist := edist(X[i], X[j])
			//fmt.Printf("%.8f ", dist)
			if i!=j && dist<min {
				min = dist
			}
		}
		//fmt.Println()
	}

	fmt.Printf("dist times: %d\tmin= %.8f\n", len(X)*len(X), min)

	elapsed := time.Since(start)
	fmt.Printf("[Time taken: %.10fs %v]\n", elapsed.Seconds(), elapsed)
}
