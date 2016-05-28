package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"strings"
	"teamzones/models"

	"github.com/goincremental/negroni-sessions"
	"github.com/gorilla/context"
	"github.com/qedus/nds"
	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"
)

var (
	guestPaths = []string{
		"/sign-in",
		"/sign-up",
		"/recover-password",
		"/reset-password",
	}

	billingPaths = []string{
		"/api/billing",
		"/settings/billing",
	}
)

func isSubpath(path string, paths []string) bool {
	for _, p := range paths {
		if strings.HasPrefix(path, p) {
			return true
		}
	}

	return false
}

// Access restricts access to paths based on their ACL and on the
// current Company's billing status.  The ACLs only apply to static
// paths!
func Access(res http.ResponseWriter, req *http.Request, next http.HandlerFunc) {
	user := context.Get(req, userCtxKey).(*models.User)
	company := context.Get(req, companyCtxKey).(*models.Company)
	if company.Suspended() {
		if user.Role != models.RoleMain {
			ctx := appengine.NewContext(req)
			main := company.LookupMainUser(ctx)
			renderer.HTML(res, http.StatusOK, "suspended", main)
			return
		}

		if !isSubpath(req.URL.Path, billingPaths) {
			http.Redirect(res, req, ReverseSimple(settingsBillingRoute), http.StatusFound)
			return
		}
	}

	if roles, ok := sitemapACL[req.URL.Path]; ok {
		for _, role := range roles {
			if role == user.Role {
				next(res, req)
				return
			}
		}

		forbidden(res)
		return
	}

	next(res, req)
}

func redirectAuth(res http.ResponseWriter, req *http.Request, r string) {
	path := ReverseRoute(signInRoute).
		Query("r", r).
		Build()
	http.Redirect(res, req, path, http.StatusFound)
}

// Auth ensures that the user is authenticated before they can access
// a resource.  It also injects the User into the context.
func Auth(res http.ResponseWriter, req *http.Request, next http.HandlerFunc) {
	isGuestPath := isSubpath(req.URL.Path, guestPaths)
	session := sessions.GetSession(req)
	email := session.Get(uidSessionKey)

	if email == nil {
		if isGuestPath {
			next(res, req)
			return
		}

		redirectAuth(res, req, req.URL.String())
		return
	} else if isGuestPath {
		http.Redirect(res, req, "/", http.StatusFound)
		return
	}

	var user models.User

	company := context.Get(req, companyCtxKey).(*models.Company)
	ctx := appengine.NewContext(req)
	key := models.NewUserKey(ctx, company.Key(ctx), email.(string))
	err := nds.Get(ctx, key, &user)

	switch err {
	case nil:
		context.Set(req, userCtxKey, &user)
		defer context.Clear(req)
		next(res, req)
	case datastore.ErrNoSuchEntity:
		redirectAuth(res, req, req.URL.String())
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
	err = nds.Get(ctx, key, &company)

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
