package handlers

import (
	"net/http"
	"teamzones/forms"
	"teamzones/models"

	"google.golang.org/appengine"

	"github.com/goincremental/negroni-sessions"
	"github.com/gorilla/context"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(appRouter, dashboardRoute, "/", dashboard)
	ALL(appRouter, teamSignUpRoute, "/sign-up/", teamSignUp)
	ALL(appRouter, signInRoute, "/sign-in/", signIn)
	GET(appRouter, signOutRoute, "/sign-out/", signOut)
}

func dashboard(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var users []models.User

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	if _, err := models.FindUsers(company.Key(ctx)).GetAll(ctx, &users); err != nil {
		panic(err)
	}

	renderer.HTML(res, http.StatusOK, "dashboard", users)
}

func teamSignUp(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
}

type signInForm struct {
	Email    forms.Field
	Password forms.Field
}

func signIn(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
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

func signOut(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	session := sessions.GetSession(req)
	session.Delete(uidSessionKey)
	http.Redirect(res, req, ReverseSimple(signInRoute), http.StatusFound)
}
