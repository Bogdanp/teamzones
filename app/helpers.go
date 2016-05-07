package handlers

import (
	"encoding/json"
	"log"
	"net/http"
)

func notFound(res http.ResponseWriter) {
	http.Error(res, "not found", http.StatusNotFound)
}

func badRequest(res http.ResponseWriter, errors ...string) {
	data := struct {
		Errors []string `json:"errors"`
	}{Errors: errors}

	res.WriteHeader(http.StatusBadRequest)
	res.Header().Set("content-type", "application/json")

	encoder := json.NewEncoder(res)
	if err := encoder.Encode(&data); err != nil {
		log.Fatalf("badRequest: failed to encode errors: %v", err)
	}
}
