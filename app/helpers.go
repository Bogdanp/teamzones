package handlers

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"google.golang.org/appengine/memcache"

	"golang.org/x/net/context"
)

// Render a template from the _emails directory.
func renderEmail(buf *bytes.Buffer, template string, data interface{}) string {
	if err := renderer.TemplateLookup("_emails/"+template).Execute(buf, data); err != nil {
		panic(err)
	}

	defer buf.Reset()
	return buf.String()
}

// Optimistically "lock" around a key in memcache.  Returns true when
// execution should halt and false otherwise.
func throttle(ctx context.Context, key string, duration time.Duration) bool {
	_, err := memcache.Get(ctx, key)
	if err == nil {
		return true
	}

	memcache.Set(ctx, &memcache.Item{
		Key:        key,
		Value:      []byte{},
		Expiration: duration,
	})
	return false
}

func notFound(res http.ResponseWriter) {
	http.Error(res, "not found", http.StatusNotFound)
}

func forbidden(res http.ResponseWriter) {
	http.Error(res, "forbidden", http.StatusForbidden)
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

func serverError(res http.ResponseWriter) {
	http.Error(res, "Internal server error", http.StatusInternalServerError)
}
