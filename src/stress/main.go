package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os/exec"
	"strconv"

	"github.com/gorilla/mux"
)

func main() {
    r := mux.NewRouter()

    // /v1/stress 경로에 대한 POST 핸들러를 등록합니다.
    r.HandleFunc("/v1/stress", StressHandler).Methods("POST")

    // /healthcheck 경로에 대한 GET 핸들러를 등록하여 기본 상태 확인 엔드포인트를 만듭니다.
    r.HandleFunc("/healthcheck", HealthCheckHandler).Methods("GET")

    // 서버를 8080 포트에서 실행합니다.
    http.Handle("/", r)
    log.Fatal(http.ListenAndServe(":8080", nil))
}

func StressHandler(w http.ResponseWriter, r *http.Request) {
    // 요청 바디에서 CPU 개수를 읽어옵니다.
    body, err := ioutil.ReadAll(r.Body)
    if err != nil {
        http.Error(w, fmt.Sprintf("Failed to read request body: %s", err.Error()), http.StatusBadRequest)
        return
    }

    cpuCount, err := strconv.Atoi(string(body))
    if err != nil {
        http.Error(w, "Invalid CPU count in request body", http.StatusBadRequest)
        return
    }

    // "stress" 명령어를 실행합니다.
    cmd := exec.Command("stress", "-c", strconv.Itoa(cpuCount), "-i", "--timeout", "300s")
    err = cmd.Run()
    if err != nil {
        http.Error(w, fmt.Sprintf("Failed to run stress command: %s", err.Error()), http.StatusInternalServerError)
        return
    }

    // 성공적으로 실행되면 200 OK를 반환합니다.
    w.WriteHeader(http.StatusOK)
    fmt.Fprintf(w, "stress 명령어가 %d개의 CPU로 실행되었습니다.", cpuCount)
}

func HealthCheckHandler(w http.ResponseWriter, r *http.Request) {
    // 기본적인 상태 확인 응답을 반환합니다.
    w.WriteHeader(http.StatusOK)
    fmt.Fprintf(w, "서비스가 정상 상태입니다.")
}
