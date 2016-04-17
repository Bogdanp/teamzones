package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"strings"
	"teamzones/models"

	"github.com/gorilla/context"
	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"
)

var prefixedHost = fmt.Sprintf(".%s", config.Domain.Host)

func subdomainMiddleware(res http.ResponseWriter, req *http.Request, next http.HandlerFunc) {
	var company models.Company

	subdomain, err := parseSubdomain(req.Host)
	if err != nil {
		next(res, req)
		return
	}

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

func parseSubdomain(host string) (string, error) {
	// remove the port
	port := strings.Index(host, ":")
	if port != -1 {
		host = host[:port]
	}

	// split on .hostname
	ps := strings.Split(host, prefixedHost)
	if ps[0] == config.Domain.Host {
		return "", errors.New("no subdomain")
	}

	return ps[0], nil
}
