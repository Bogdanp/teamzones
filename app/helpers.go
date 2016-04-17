package handlers

import "net/http"

// Helper for returning 404s.
func notFound(res http.ResponseWriter) {
	http.Error(res, "not found", http.StatusNotFound)
}
