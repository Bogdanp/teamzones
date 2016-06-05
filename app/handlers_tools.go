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
		"Peter", "Parker", "bogdan@defn.io", "password", "Europe/Bucharest",
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
		{"Richard", "Parker", "richard.parker@defn.io", "US/Pacific"},
		{"Ben", "Parker", "ben.parker@defn.io", "Europe/Berlin"},
		{"May", "Reilly", "may.reilly@defn.io", "US/Central"},
		{"Mary Jane", "Watson", "mary.jane.watson@defn.io", "US/Central"},
		{"Jessica", "Drew", "jessica.drew@defn.io", "Europe/London"},
		{"Gwen", "Stacy", "gwen.stacy@defn.io", "Europe/London"},
		{"Felicia", "Hardy", "felicia.hardy@defn.io", "Europe/Bucharest"},
		{"Carol", "Danvers", "carol.danvers@defn.io", "Europe/Bucharest"},
		{"Curt", "Connors", "curt.connors@defn.io", "Europe/Bucharest"},
		{"Maxwell", "Dillon", "maxwell.dillon@defn.io", "US/Central"},
		{"Richard", "Fisk", "richard.fisk@defn.io", "US/Pacific"},
		{"Eddie", "Brock", "eddie.brock@defn.io", "US/Pacific"},
		{"Cletus", "Kasady", "cletus.kasady@defn.io", "US/Central"},
		{"Norman", "Osborn", "norman.osborn@defn.io", "US/Central"},
		{"Harry", "Osborn", "harry.osborn@defn.io", "US/Central"},
		{"Mac", "Gragan", "mac.gragan@defn.io", "US/Central"},
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
