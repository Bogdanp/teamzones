package handlers

import (
	"encoding/json"
	"html/template"
	"net/http"
	"strconv"
	"teamzones/forms"
	"teamzones/models"

	"google.golang.org/appengine"

	"github.com/goincremental/negroni-sessions"
	"github.com/gorilla/context"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(appRouter, dashboardRoute, "/", dashboardHandler)
	GET(appRouter, inviteRoute, "/invite", dashboardHandler)
	GET(appRouter, settingsRoute, "/settings", dashboardHandler)
	ALL(appRouter, teamSignUpRoute, "/sign-up/:invite", teamSignUpHandler)
	ALL(appRouter, signInRoute, "/sign-in/", signInHandler)
	GET(appRouter, signOutRoute, "/sign-out/", signOutHandler)
}

func dashboardHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var users []models.User

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	if _, err := models.FindUsers(company.Key(ctx)).GetAll(ctx, &users); err != nil {
		panic(err)
	}

	user := context.Get(req, userCtxKey).(*models.User)
	data, err := json.Marshal(struct {
		Company *models.Company `json:"company"`
		User    *models.User    `json:"user"`
		Team    []models.User   `json:"team"`
	}{
		Company: company,
		User:    user,
		Team:    users,
	})
	if err != nil {
		panic(err)
	}

	renderer.HTML(res, http.StatusOK, "dashboard", template.JS(data))
}

func teamSignUpHandler(res http.ResponseWriter, req *http.Request, ps httprouter.Params) {
	company := context.Get(req, companyCtxKey).(*models.Company)
	inviteID, err := strconv.ParseInt(ps.ByName("invite"), 10, 64)
	if err != nil {
		notFound(res)
		return
	}

	ctx := appengine.NewContext(req)
	_, err = models.GetInvite(ctx, company.Key(ctx), inviteID)
	if err != nil {
		notFound(res)
		return
	}

	// FIXME: Implement team signup.
}

type signInForm struct {
	Email    forms.Field
	Password forms.Field
}

func signInHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	company := context.Get(req, companyCtxKey).(*models.Company)
	form := signInForm{
		forms.Field{
			Name:       "email",
			Label:      "E-mail address",
			Validators: []forms.Validator{forms.Email},
		},
		forms.Field{
			Name:  "password",
			Label: "Password",
		},
	}

	templateCtx := struct {
		Company *models.Company
		Form    *signInForm
	}{company, &form}

	if req.Method == http.MethodPost {
		if !forms.Bind(req, &form) {
			renderer.HTML(res, http.StatusBadRequest, "sign-in", templateCtx)
			return
		}

		ctx := appengine.NewContext(req)
		user, err := models.Authenticate(
			ctx,
			models.NewCompanyKey(ctx, company.Subdomain),
			form.Email.Value,
			form.Password.Value,
		)

		switch err {
		case nil:
			session := sessions.GetSession(req)
			session.Set(uidSessionKey, user.Email)
			path := req.FormValue("r")
			if path == "" {
				path = "/"
			}

			http.Redirect(res, req, path, http.StatusFound)
			return
		case models.ErrInvalidCredentials:
			renderer.HTML(res, http.StatusBadRequest, "sign-in", templateCtx)
			return
		default:
			panic(err)
		}
	}

	renderer.HTML(res, http.StatusOK, "sign-in", templateCtx)
}

func signOutHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	session := sessions.GetSession(req)
	session.Delete(uidSessionKey)
	http.Redirect(res, req, ReverseSimple(signInRoute), http.StatusFound)
}
