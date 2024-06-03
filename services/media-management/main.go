package main

import (
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
)

func main() {
	fmt.Println("Media Service!")

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "OK")
	})
	count := 0
	http.HandleFunc("/upload", func(w http.ResponseWriter, r *http.Request) {

		if r.Method != http.MethodPost {
			w.WriteHeader(http.StatusMethodNotAllowed)
			fmt.Fprintln(w, "Method Not Allowed")
			return
		}
		fmt.Println("New Upload Request!", count)
		count++

		var maxFileSize int64 = 10 * 1024 * 1024
		if r.ContentLength > maxFileSize {
			fmt.Println("File size exceeds limit")
			w.WriteHeader(http.StatusRequestEntityTooLarge)
			fmt.Fprintln(w, "File size exceeds the limit")
			return
		}

		fmt.Println(r.ContentLength)
		// r.Body = http.MaxBytesReader(w, r.Body, 5*1024*1024) // Limit request size to 5MB

		// Parse the multipart form, with a max memory
		var maxMemory int64 = 5 * 1024 * 1024
		err := r.ParseMultipartForm(maxMemory)
		fmt.Println("----breakpoint 1 -->", err)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, "Error parsing multipart form")
			return
		}
		fmt.Println("----breakpoint 2 -->")
		// Retrieve the file from posted form-data
		file, _, err := r.FormFile("file")
		fmt.Println("file")
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			fmt.Fprintln(w, "Invalid file")
			return
		}
		defer file.Close()

		// Create a temporary file within our temp-images directory that follows
		if _, err := os.Stat("uploads"); os.IsNotExist(err) {
			err := os.Mkdir("uploads", 0755)
			if err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				fmt.Fprintln(w, "Error creating 'uploads' directory")
				return
			}
		}
		tempFile, err := os.CreateTemp("uploads", "upload-*.png")

		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, "Error creating a temporary file")
			return
		}
		defer tempFile.Close()

		// Copy the uploaded file to the destination file
		_, err = io.Copy(tempFile, file)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintln(w, "Error saving the file")
			return
		}

		// Return success message
		fmt.Println("File upload success")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "File uploaded successfully")
	})

	http.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "0.0.3")
	})

	addr := &net.TCPAddr{
		IP:   net.ParseIP("0.0.0.0"),
		Port: 5100,
	}
	err := http.ListenAndServe(addr.String(), nil)
	if err != nil {
		panic("Couldn't start HTTP Server")
	}
}
