package handlers

import (
	"log"
	"net/http"
	"teamzones/forms"
	"teamzones/models"

	"google.golang.org/appengine"

	"github.com/gorilla/context"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	ALL(appRouter, signInRoute, "/sign-in", signIn)
}

type signInForm struct {
	Email    forms.Field
	Password forms.Field
}

func signIn(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	company, found := context.GetOk(req, companyCtxKey)
	if !found {
		notFound(res)
		return
	}

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
	}{company.(*models.Company), &form}

	if req.Method == http.MethodPost {
		if !forms.Bind(req, &form) {
			renderer.HTML(res, http.StatusBadRequest, "sign-in", templateCtx)
			return
		}

		c := company.(*models.Company)
		ctx := appengine.NewContext(req)
		user, err := models.Authenticate(
			ctx,
			models.NewCompanyKey(ctx, c.Subdomain),
			form.Email.Value,
			form.Password.Value,
		)

		switch err {
		case nil:
			log.Println(user)
		case models.ErrInvalidCredentials:
			renderer.HTML(res, http.StatusBadRequest, "sign-in", templateCtx)
			return
		default:
			panic(err)
		}
	}

	renderer.HTML(res, http.StatusOK, "sign-in", templateCtx)
}
