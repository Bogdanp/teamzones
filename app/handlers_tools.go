package handlers

import (
	"net/http"
	"teamzones/integrations"
	"teamzones/models"

	"github.com/qedus/nds"

	"google.golang.org/appengine"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(siteRouter, "tools-provision", "/_tools/provision", provisionHandler)
}

func provisionHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	ctx := appengine.NewContext(req)
	company := models.NewCompany("demo", "demo")
	user, err := models.CreateMainUser(
		ctx, company,
		"Peter", "Parker", "peter.parker@example.com", "password", "Europe/Bucharest",
	)
	if err == models.ErrSubdomainTaken {
		user = company.LookupMainUser(ctx)
	} else if err != nil {
		panic(err)
	}

	companyKey := company.Key(ctx)
	token, _, err := models.CreateOAuth2Token(
		ctx, companyKey, user.Key(ctx), "gcalendar",
	)
	if err != nil {
		panic(err)
	}

	cData := models.NewGCalendarData(company.Key(ctx), user.Key(ctx))
	cData.DefaultID = "default"
	cData.Calendars = []integrations.Calendar{
		{"default", "Default", "Europe/Bucharest"},
	}
	cDataKey := models.NewGCalendarDataKey(ctx, user.Key(ctx), "default")
	if _, err := nds.Put(ctx, cDataKey, cData); err != nil {
		panic(err)
	}

	workdays := models.Workdays{
		Monday:    models.Workday{Start: 9, End: 17},
		Tuesday:   models.Workday{Start: 9, End: 17},
		Wednesday: models.Workday{Start: 9, End: 17},
		Thursday:  models.Workday{Start: 9, End: 17},
		Friday:    models.Workday{Start: 9, End: 17},
		Saturday:  models.Workday{Start: 9, End: 17},
		Sunday:    models.Workday{Start: 9, End: 17},
	}

	user.GCalendarToken = token
	user.GCalendarData = cDataKey
	user.Workdays = workdays
	user.Put(ctx)

	users := []struct {
		FirstName string
		LastName  string
		Email     string
		Timezone  string
	}{
		{"Richard", "Parker", "richard.parker@example.com", "US/Pacific"},
		{"Ben", "Parker", "ben.parker@example.com", "Europe/Berlin"},
		{"May", "Reilly", "may.reilly@example.com", "US/Central"},
		{"Mary Jane", "Watson", "mary.jane.watson@example.com", "US/Central"},
		{"Jessica", "Drew", "jessica.drew@example.com", "Europe/London"},
		{"Gwen", "Stacy", "gwen.stacy@example.com", "Europe/London"},
		{"Felicia", "Hardy", "felicia.hardy@example.com", "Europe/Bucharest"},
		{"Carol", "Danvers", "carol.danvers@example.com", "Europe/Bucharest"},
		{"Curt", "Connors", "curt.connors@example.com", "Europe/Bucharest"},
		{"Maxwell", "Dillon", "maxwell.dillon@example.com", "US/Central"},
		{"Richard", "Fisk", "richard.fisk@example.com", "US/Pacific"},
		{"Eddie", "Brock", "eddie.brock@example.com", "US/Pacific"},
		{"Cletus", "Kasady", "cletus.kasady@example.com", "US/Central"},
		{"Norman", "Osborn", "norman.osborn@example.com", "US/Central"},
		{"Harry", "Osborn", "harry.osborn@example.com", "US/Central"},
		{"Mac", "Gragan", "mac.gragan@example.com", "US/Central"},
	}

	for _, user := range users {
		u := models.NewUser()
		u.Company = companyKey
		u.FirstName = user.FirstName
		u.LastName = user.LastName
		u.Email = user.Email
		u.Timezone = user.Timezone
		u.Workdays = workdays
		u.SetPassword("password")
		u.Put(ctx)
	}

	meetings, err := models.FindUpcomingMeetings(user.Key(ctx)).KeysOnly().GetAll(ctx, nil)
	if err != nil {
		panic(err)
	}

	if err := nds.DeleteMulti(ctx, meetings); err != nil {
		panic(err)
	}
}
