package main

import (
	"fmt"
	"math"
	"time"
)

var (
	x = []float64{0.97006349, 0.5127459, 0.44315555, 0.09636233, 0.6790125, 0.80202988, 0.94640137, 0.38441741, 0.01713934, 0.72238491}
	y = []float64{0.34731419, 0.15514822, 0.6681165, 0.52882095, 0.01684999, 0.2326016, 0.72043829, 0.43343879, 0.36280994, 0.67440929}
)

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
	fmt.Println(x)
	fmt.Println(y)
	start := time.Now()
	dist := edist(x, y)
	elapsed := time.Since(start)
	fmt.Println("dist= ", dist)
	fmt.Printf("[Time taken: %.10fs %v]\n", elapsed.Seconds(), elapsed)
}