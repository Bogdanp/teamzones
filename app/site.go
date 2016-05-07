package handlers

import (
	"net/http"
	"teamzones/forms"
	"teamzones/models"

	"google.golang.org/appengine"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(siteRouter, homeRoute, "/", homeHandler)
	ALL(siteRouter, signUpRoute, "/sign-up/", signUpHandler)
}

func homeHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	renderer.HTML(res, http.StatusOK, "index", nil)
}

func signUpHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	form := struct {
		CompanyName      forms.Field
		CompanySubdomain forms.Field
		Name             forms.Field
		Email            forms.Field
		Password         forms.Field
		Timezone         forms.Field
	}{
		forms.Field{
			Name:       "company-name",
			Label:      "Company name",
			Validators: []forms.Validator{forms.MinLength(3), forms.MaxLength(50)},
		},
		forms.Field{
			Name:       "company-subdomain",
			Label:      "Company subdomain",
			Value:      req.FormValue("subdomain"), // ?subdomain=foo
			Validators: []forms.Validator{forms.MinLength(3), forms.MaxLength(15)},
		},
		forms.Field{
			Name:       "name",
			Label:      "Your name",
			Validators: []forms.Validator{forms.MinLength(2), forms.MaxLength(75)},
		},
		forms.Field{
			Name:       "email",
			Label:      "E-mail address",
			Validators: []forms.Validator{forms.Email, forms.MaxLength(150)},
		},
		forms.Field{
			Name:       "password",
			Label:      "Password",
			Validators: []forms.Validator{forms.MinLength(6)},
		},
		forms.Field{
			Name:       "timezone",
			Label:      "Timezone",
			Validators: []forms.Validator{},
		},
	}

	if req.Method == http.MethodPost {
		if !forms.Bind(req, &form) {
			renderer.HTML(res, http.StatusBadRequest, "sign-up", form)
			return
		}

		ctx := appengine.NewContext(req)
		_, _, err := models.CreateMainUser(
			ctx,
			form.CompanyName.Value,
			form.CompanySubdomain.Value,
			form.Name.Value,
			form.Email.Value,
			form.Password.Value,
			form.Timezone.Value,
		)

		switch err {
		case nil:
			location := ReverseRoute(signInRoute).
				Subdomain(form.CompanySubdomain.Value).
				Build()
			http.Redirect(res, req, location, http.StatusTemporaryRedirect)
			return
		case models.ErrSubdomainTaken:
			form.CompanySubdomain.Errors = []string{err.Error()}
			renderer.HTML(res, http.StatusBadRequest, "sign-up", form)
			return
		default:
			panic(err)
		}
	}

	renderer.HTML(res, http.StatusOK, "sign-up", form)
}
