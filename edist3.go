package main

import (
	"fmt"
	"math"
	"time"
	"io/ioutil"
	"strings"
	"strconv"
)

// go routine 数量, 建议与cpu核数一致
const (
	GONUM = 8
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

func findMin(start int, end int, ch chan string) {
	//fmt.Println("-->", start, end)
	var min1 float64
	min1 = 999999999.0
	for i:=start; i<end; i++ {
		for j:=0; j<len(X); j++ {
			dist := edist(X[i], X[j])
			//fmt.Printf("%.8f ", dist)
			if i!=j && dist<min1 {
				min1 = dist
			}
		}
		//fmt.Println()
	}
	ch<- fmt.Sprintf("%.16f", min1)
}

func main(){
	var min float64
	var seg int
	min = 99999.0
	channel := make([]chan string, GONUM)

	readData()

	fmt.Println("num= ", len(X), "\tdim= ", len(X[0]))


	seg = len(X)/GONUM

	start := time.Now()

	for i:=0;i<GONUM;i++ {
		channel[i] = make(chan string)
		var end int
		if i+1==GONUM { 
			end = len(X) // 对seg计算整除有余数的情况
		} else {
			end = i*seg+seg
		}
		go findMin(i*seg, end, channel[i])
	}

	// 取得返回结果
	for _, rc := range(channel) {
		t := <-rc
		f, _ := strconv.ParseFloat(t, 64)
		if f<min {
			min = f
		}
	}

	fmt.Printf("goroutine: %d\tdist times: %d\tmin= %.8f\n", GONUM, len(X)*len(X), min)

	elapsed := time.Since(start)
	fmt.Printf("[Time taken: %.10fs %v]\n", elapsed.Seconds(), elapsed)
}
