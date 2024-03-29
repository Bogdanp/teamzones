package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"teamzones/integrations"
	"teamzones/models"

	"golang.org/x/net/context"

	gcontext "github.com/gorilla/context"
	"github.com/qedus/nds"

	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(
		appRouter,
		"integrations-connect", "/integrations/connect/:integration",
		initiateOAuthHandler,
	)
	GET(
		siteRouter,
		"integrations-gcalendar-callback", "/integrations/gcalendar/oauth2-callback",
		gcalendarOAuthHandler,
	)
	GET(
		appRouter,
		"integrations-gcalendar-callback-team", "/integrations/gcalendar/oauth2-callback",
		gcalendarOAuthTeamHandler,
	)

	// Hook up the Google Calendar OAuth2 URL.
	integrations.SetCalendarRedirectURL(
		ReverseRoute("integrations-gcalendar-callback").Absolute().Build(),
	)
}

func initiateOAuthHandler(res http.ResponseWriter, req *http.Request, params httprouter.Params) {
	var redirectURL string

	integration := params.ByName("integration")
	switch integration {
	case models.OAuth2GCalendar:
		ctx := appengine.NewContext(req)
		user := gcontext.Get(req, userCtxKey).(*models.User)
		company := gcontext.Get(req, companyCtxKey).(*models.Company)
		key, _, err := models.CreateOAuth2Token(
			ctx, company.Key(ctx), user.Key(ctx), integration,
		)
		if err != nil {
			log.Errorf(ctx, "failed to create oauth2 token: %v", err)
			serverError(res)
			return
		}

		state := fmt.Sprintf("%s,%d", company.Subdomain, key.IntID())
		redirectURL = integrations.GetCalendarAuthURL(state)
	default:
		notFound(res)
		return
	}

	http.Redirect(res, req, redirectURL, http.StatusFound)
}

// User hits this with state=SUBDOMAIN,EMAIL at which point they get
// redirected to the TeamHandler with state=EMAIL where we'll have
// access to their session.
func gcalendarOAuthHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	state := req.FormValue("state")
	segments := strings.SplitN(state, ",", 2)
	if len(segments) <= 1 {
		notFound(res)
		return
	}

	location := ReverseRoute("integrations-gcalendar-callback-team").
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
		nds.Delete(ctx, tokenKey)
		return
	}

	tok, err := integrations.ExchangeCalendarCode(ctx, req.FormValue("code"))
	if err != nil {
		// TODO: Tell the user their shit's fucked
		nds.Delete(ctx, tokenKey)
		return
	}

	err = nds.RunInTransaction(ctx, func(ctx context.Context) error {
		token.Token = *tok
		user.GCalendarToken = tokenKey

		_, err := nds.PutMulti(
			ctx,
			[]*datastore.Key{tokenKey, userKey},
			[]interface{}{token, user},
		)

		return err
	}, nil)
	if err != nil {
		// TODO: Tell the user their shit's fucked
		nds.Delete(ctx, tokenKey)
		return
	}

	location := ReverseRoute("integrations-calendar").Build()
	http.Redirect(res, req, location, http.StatusFound)
}
