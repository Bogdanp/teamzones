package handlers

import (
	"net/http"
	"teamzones/models"

	"google.golang.org/appengine"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(siteRouter, provisionRoute, "/_tools/provision", provisionHandler)
}

func provisionHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	if !config.Debug {
		notFound(res)
		return
	}

	ctx := appengine.NewContext(req)
	company, _, err := models.CreateMainUser(
		ctx, "defn", "defn",
		"Bogdan Popa", "bogdan@defn.io", "password", "Europe/Bucharest",
	)
	if err != nil {
		return
	}

	users := []struct {
		Name     string
		Email    string
		Password string
		Timezone string
	}{
		{"Casey Muratori", "casey@mollyrocket.com", "password", "US/Pacific"},
		{"Sorin Muntean", "me@sorinmuntean.ro", "password", "Europe/Berlin"},
		{"Dave Hayes", "dave@ave81.com", "password", "US/Central"},
		{"John Watson", "john@defn.io", "password", "Europe/London"},
		{"Simon Peyton Jones", "simonpj@microsoft.com", "password", "Europe/London"},
		{"Paul Popa", "paul@defn.io", "password", "Europe/Bucharest"},
		{"Radu Dan", "radu@fullthrottle.ro", "password", "Europe/Bucharest"},
		{"Rob Pike", "rob@google.com", "password", "US/Central"},
	}

	for _, user := range users {
		models.CreateUser(
			ctx, company.Key(ctx),
			user.Name, user.Email, user.Password, user.Timezone,
		)
	}
}
