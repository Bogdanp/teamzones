package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"strings"
	"teamzones/models"

	"github.com/goincremental/negroni-sessions"
	"github.com/gorilla/context"
	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"
)

// Auth ensures that the user is authenticated before they can access
// a resource.  It also injects the User into the context.
func Auth(res http.ResponseWriter, req *http.Request, next http.HandlerFunc) {
	if req.URL.Path == "/sign-in/" {
		next(res, req)
		return
	}

	session := sessions.GetSession(req)
	email := session.Get(uidSessionKey)
	redirect := func() {
		path := ReverseRoute(signInRoute).
			Query("r", req.URL.String()).
			Build()
		http.Redirect(res, req, path, http.StatusFound)
	}

	if email == nil {
		redirect()
		return
	}

	var user models.User

	company := context.Get(req, companyCtxKey).(*models.Company)
	ctx := appengine.NewContext(req)
	key := models.NewUserKey(ctx, company.Key(ctx), email.(string))
	err := datastore.Get(ctx, key, &user)

	switch err {
	case nil:
		context.Set(req, userCtxKey, &user)
		defer context.Clear(req)
		next(res, req)
	case datastore.ErrNoSuchEntity:
		redirect()
	default:
		panic(err)
	}
}

// Subdomain reads the appropriate Company from datastore based on the
// current subdomain and stores it in the context.  404s if the
// subdomain does not exist.
func Subdomain(res http.ResponseWriter, req *http.Request, next http.HandlerFunc) {
	subdomain, err := parseSubdomain(req.Host)
	if err != nil {
		panic(err)
	}

	var company models.Company

	ctx := appengine.NewContext(req)
	key := models.NewCompanyKey(ctx, subdomain)
	err = datastore.Get(ctx, key, &company)

	switch err {
	case nil:
		context.Set(req, companyCtxKey, &company)
		defer context.Clear(req)
		next(res, req)
	case datastore.ErrNoSuchEntity:
		notFound(res)
	default:
		panic(err)
	}
}

var prefixedHost = fmt.Sprintf(".%s", config.Host())

func parseSubdomain(host string) (string, error) {
	ps := strings.Split(host, prefixedHost)
	if ps[0] == config.Domain.Host {
		return "", errors.New("no subdomain")
	}

	return ps[0], nil
}
