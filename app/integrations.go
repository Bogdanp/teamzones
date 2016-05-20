package handlers

import (
	"net/http"
	"strconv"
	"strings"
	"teamzones/integrations"
	"teamzones/models"

	"golang.org/x/net/context"

	gcontext "github.com/gorilla/context"

	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"

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
	ctx := appengine.NewContext(req)
	user := gcontext.Get(req, userCtxKey).(*models.User)
	userKey := user.Key(ctx)
	tokID, err := strconv.ParseInt(req.FormValue("state"), 10, 64)
	if err != nil {
		notFound(res)
		return
	}

	tokenKey, token, err := models.GetOAuth2Token(ctx, userKey, tokID)
	if err != nil {
		notFound(res)
		return
	}

	errCode := req.FormValue("error")
	if errCode != "" {
		// TODO: Tell the user their shit's fucked
		go datastore.Delete(ctx, tokenKey)
		return
	}

	tok, err := integrations.ExchangeCalendarCode(ctx, req.FormValue("code"))
	if err != nil {
		// TODO: Tell the user their shit's fucked
		go datastore.Delete(ctx, tokenKey)
		return
	}

	err = datastore.RunInTransaction(ctx, func(ctx context.Context) error {
		token.Token = *tok
		user.GCalendarToken = tokenKey

		_, err := datastore.PutMulti(
			ctx,
			[]*datastore.Key{tokenKey, userKey},
			[]interface{}{token, user},
		)

		return err
	}, nil)
	if err != nil {
		// TODO: Tell the user their shit's fucked
		go datastore.Delete(ctx, tokenKey)
		return
	}

	location := ReverseRoute(integrationsGCalRoute).Build()
	http.Redirect(res, req, location, http.StatusFound)
}
