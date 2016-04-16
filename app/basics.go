package handlers

import (
	"net/http"
	"teamzones/forms"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	router.GET("/", home)
	router.GET("/sign-up", signUp)
	router.POST("/sign-up", signUp)
}

func home(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	renderer.HTML(res, http.StatusOK, "index", nil)
}

func signUp(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	form := struct {
		CompanyName      forms.Field
		CompanySubdomain forms.Field
		Email            forms.Field
		Password         forms.Field
	}{
		forms.Field{
			Name:       "company-name",
			Label:      "Company name",
			Validators: []forms.Validator{forms.MinLength(3), forms.MaxLength(50)},
		},
		forms.Field{
			Name:       "company-subdomain",
			Label:      "Company subdomain",
			Validators: []forms.Validator{forms.MinLength(3), forms.MaxLength(15)},
		},
		forms.Field{
			Name:       "email",
			Label:      "E-mail address",
			Validators: []forms.Validator{forms.Email},
		},
		forms.Field{
			Name:       "password",
			Label:      "Password",
			Validators: []forms.Validator{forms.MinLength(6)},
		},
	}

	if req.Method == http.MethodPost {
		if !forms.Bind(req, &form) {
			renderer.HTML(res, http.StatusBadRequest, "sign-up", form)
			return
		}
	}

	renderer.HTML(res, http.StatusOK, "sign-up", form)
}
