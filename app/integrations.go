package handlers

import (
	"log"
	"net/http"
	"strings"
	"teamzones/integrations"
	"teamzones/models"

	"google.golang.org/appengine"

	"github.com/gorilla/context"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(siteRouter, gcalendarOAuthRoute, "/integrations/gcalendar/oauth2-callback", gcalendarOAuthHandler)
	GET(appRouter, gcalendarOAuthTeamRoute, "/integrations/gcalendar/oauth2-callback", gcalendarOAuthTeamHandler)

	// Hook up the Google Calendar OAuth2 URL.
	integrations.SetCalendarRedirectURL(ReverseRoute(gcalendarOAuthRoute).Absolute().Build())
}

// User hits this with state=SUBDOMAIN,EMAIL at which point they get
// redirected to the TeamHandler with state=EMAIL where we'll have
// access to their session.
func gcalendarOAuthHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	state := req.FormValue("state")
	segments := strings.Split(state, ",")
	if len(segments) <= 1 {
		notFound(res)
		return
	}

	location := ReverseRoute(gcalendarOAuthTeamRoute).
		Subdomain(segments[0]).
		Query("state", segments[1]).
		Query("code", req.FormValue("code")).
		Query("error", req.FormValue("error")).
		Build()

	http.Redirect(res, req, location, http.StatusFound)
}

func gcalendarOAuthTeamHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	user := context.Get(req, userCtxKey).(*models.User)
	email := req.FormValue("state")
	if user.Email != email {
		notFound(res)
		return
	}

	error := req.FormValue("error")
	if error != "" {
		// TODO: Tell the user their shit's fucked
		return
	}

	ctx := appengine.NewContext(req)
	token, err := integrations.ExchangeCalendarCode(ctx, req.FormValue("code"))
	if err != nil {
		// TODO: Tell the user their shit's fucked
		return
	}

	// TODO: Store the token
	log.Println(token)
}
