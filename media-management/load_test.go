package main

import (
	"bytes"
	"fmt"
	"math/rand"
	"mime/multipart"
	"net/http"
	"testing"
	"time"

	vegeta "github.com/tsenart/vegeta/lib"
)

func TestUploadRouteLoad(t *testing.T) {
	rate := vegeta.Rate{Freq: 10, Per: time.Second} // 10 requests per second
	duration := 1 * time.Second                     // test duration
	targeter := vegeta.NewStaticTargeter(vegeta.Target{
		Method: "POST",
		URL:    "http://127.0.0.1:5100/upload",
		Body:   createMultipartFormData(),
		Header: http.Header{"Content-Type": []string{fmt.Sprintf("multipart/form-data; boundary=%s", "boundary123")}},
	})
	attacker := vegeta.NewAttacker()

	var metrics vegeta.Metrics
	for res := range attacker.Attack(targeter, rate, duration, "Upload Test") {
		metrics.Add(res)
	}
	metrics.Close()

	fmt.Printf("99th percentile: %s\n", metrics.Latencies.P99)
	fmt.Printf("Mean Latency: %s\n", metrics.Latencies.Mean)
	fmt.Printf("Max: %s\n", metrics.Latencies.Max)
	fmt.Printf("Success: %.2f%%\n", metrics.Success*100)

}

func createMultipartFormData() []byte {
	fmt.Println("Fn called")
	var b bytes.Buffer
	w := multipart.NewWriter(&b)
	w.SetBoundary("boundary123")
	fw, err := w.CreateFormFile("file", "test.png")
	if err != nil {
		panic(err)
	}
	desiredSize := rand.Intn(1*1024*1024) + 1*1024*1024 // Random value greater than 1 MB

	fileContent := make([]byte, desiredSize)
	_, err = fw.Write(fileContent) // simulate file content
	if err != nil {
		panic(err)
	}
	w.Close()
	return b.Bytes()
}
