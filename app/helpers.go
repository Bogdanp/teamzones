package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"teamzones/models"
	"time"

	gcontext "github.com/gorilla/context"

	"google.golang.org/appengine/memcache"

	"golang.org/x/net/context"
)

func hasRole(res http.ResponseWriter, req *http.Request, roles ...string) bool {
	user := gcontext.Get(req, userCtxKey).(*models.User)
	for _, r := range roles {
		if user.Role == r {
			return true
		}
	}

	forbidden(res)
	return false
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
