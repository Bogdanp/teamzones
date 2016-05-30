package handlers

import (
	"net/http"
	"strconv"
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
	company := models.NewCompany("defn", "defn")
	user, err := models.CreateMainUser(
		ctx, company,
		"Bogdan", "Popa", "bogdan@defn.io", "password", "Europe/Bucharest",
	)
	if err != nil {
		return
	}

	user.Workdays = models.Workdays{
		Monday:    models.Workday{Start: 15, End: 23},
		Tuesday:   models.Workday{Start: 15, End: 23},
		Wednesday: models.Workday{Start: 15, End: 23},
		Thursday:  models.Workday{Start: 15, End: 23},
		Friday:    models.Workday{Start: 13, End: 21},
		Saturday:  models.Workday{Start: 0, End: 0},
		Sunday:    models.Workday{Start: 0, End: 0},
	}
	user.Put(ctx)

	users := []struct {
		FirstName string
		LastName  string
		Email     string
		Timezone  string
	}{
		{"Casey", "Muratori", "casey@mollyrocket.com", "US/Pacific"},
		{"Sorin", "Muntean", "me@sorinmuntean.ro", "Europe/Berlin"},
		{"Dave", "Hayes", "dave@ave81.com", "US/Central"},
		{"Ben", "Demaree", "ben.demaree@ave81.com", "US/Central"},
		{"John", "Watson", "john@defn.io", "Europe/London"},
		{"Simon", "Peyton Jones", "simonpj@microsoft.com", "Europe/London"},
		{"Paul", "Popa", "paul@defn.io", "Europe/Bucharest"},
		{"Radu", "Dan", "radu@fullthrottle.ro", "Europe/Bucharest"},
		{"Andrei", "Baidoc", "baidoc@yahoo.co.uk", "Europe/Bucharest"},
		{"Rob", "Pike", "rob@google.com", "US/Central"},
		{"Gary", "Bernhardt", "support@destroyallsoftware.com", "US/Pacific"},
		{"Mike", "Acton", "me@macton.ninja", "US/Pacific"},
		{"Ryan", "Singer", "ryan@singer.com", "US/Central"},
		{"Joshua", "Stein", "jcs@jcs.org", "US/Central"},
		{"Andrew", "Clarkson", "andrew.clarkson@ave81.com", "US/Central"},
		{"Dave", "Firnstahl", "dave.firnstahl@ave81.com", "US/Central"},
	}

	for i := 0; i < 1; i++ {
		suffix := ""
		if i != 0 {
			suffix = strconv.Itoa(i)
		}

		for _, user := range users {
			models.CreateUser(
				ctx, company.Key(ctx),
				user.FirstName, user.LastName, user.Email+suffix, "password", user.Timezone,
			)
		}
	}
}
