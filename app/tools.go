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
	company, user, err := models.CreateMainUser(
		ctx, "defn", "defn",
		"Bogdan Popa", "bogdan@defn.io", "password", "Europe/Bucharest",
	)
	if err != nil {
		return
	}

	user.Workdays = models.Workdays{
		models.Workday{Start: 15, End: 23},
		models.Workday{Start: 15, End: 23},
		models.Workday{Start: 15, End: 23},
		models.Workday{Start: 15, End: 23},
		models.Workday{Start: 13, End: 21},
		models.Workday{Start: 0, End: 0},
		models.Workday{Start: 0, End: 0},
	}
	user.Put(ctx)

	users := []struct {
		Name     string
		Email    string
		Timezone string
	}{
		{"Casey Muratori", "casey@mollyrocket.com", "US/Pacific"},
		{"Sorin Muntean", "me@sorinmuntean.ro", "Europe/Berlin"},
		{"Dave Hayes", "dave@ave81.com", "US/Central"},
		{"Ben Demaree", "ben.demaree@ave81.com", "US/Central"},
		{"John Watson", "john@defn.io", "Europe/London"},
		{"Simon Peyton Jones", "simonpj@microsoft.com", "Europe/London"},
		{"Paul Popa", "paul@defn.io", "Europe/Bucharest"},
		{"Radu Dan", "radu@fullthrottle.ro", "Europe/Bucharest"},
		{"Andrei Baidoc", "baidoc@yahoo.co.uk", "Europe/Bucharest"},
		{"Rob Pike", "rob@google.com", "US/Central"},
		{"Gary Bernhardt", "support@destroyallsoftware.com", "US/Pacific"},
		{"Mike Acton", "me@macton.ninja", "US/Pacific"},
		{"Ryan Singer", "ryan@singer.com", "US/Central"},
		{"Joshua Stein", "jcs@jcs.org", "US/Central"},
		{"Andrew Clarkson", "andrew.clarkson@ave81.com", "US/Central"},
		{"Dave Firnstahl", "dave.firnstahl@ave81.com", "US/Central"},
	}

	for _, user := range users {
		models.CreateUser(
			ctx, company.Key(ctx),
			user.Name, user.Email, "password", user.Timezone,
		)
	}
}