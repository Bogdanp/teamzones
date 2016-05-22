package handlers

import (
	"encoding/json"
	"html/template"
	"net/http"
	"strconv"
	"teamzones/forms"
	"teamzones/models"

	"google.golang.org/appengine"
	"google.golang.org/appengine/log"

	"github.com/goincremental/negroni-sessions"
	"github.com/gorilla/context"
	"github.com/qedus/nds"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(appRouter, dashboardRoute, "/", dashboardHandler)
	GET(appRouter, inviteRoute, "/invite", dashboardHandler)
	GET(appRouter, profileRoute, "/profile/:email", dashboardHandler)
	GET(appRouter, integrationsGCalRoute, "/integrations/google-calendar", dashboardHandler)
	GET(appRouter, settingsTeamRoute, "/settings/team", dashboardHandler)
	GET(appRouter, settingsBillingRoute, "/settings/billing", dashboardHandler)
	GET(appRouter, currentProfileRoute, "/profile", dashboardHandler)
	ALL(appRouter, teamSignUpRoute, "/sign-up/:invite", teamSignUpHandler)
	ALL(appRouter, signInRoute, "/sign-in/", signInHandler)
	GET(appRouter, signOutRoute, "/sign-out/", signOutHandler)
	ALL(appRouter, recoverPasswordRoute, "/recover-password/", recoverPasswordHandler)
	ALL(appRouter, resetPasswordRoute, "/reset-password/:token", resetPasswordHandler)
}

type integrationsPayload struct {
	GCalendar bool `json:"gCalendar"`
}

type dashboardPayload struct {
	Company *models.Company `json:"company"`
	User    *models.User    `json:"user"`
	Team    []models.User   `json:"team"`

	Integrations integrationsPayload `json:"integrationStates"`
}

func dashboardHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var users []models.User

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	if _, err := models.FindUsers(company.Key(ctx)).GetAll(ctx, &users); err != nil {
		panic(err)
	}

	user := context.Get(req, userCtxKey).(*models.User)
	data, err := json.Marshal(dashboardPayload{
		Company: company,
		User:    user,
		Team:    users,
		Integrations: integrationsPayload{
			GCalendar: user.GCalendarToken != nil,
		},
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
	companyKey := company.Key(ctx)
	invite, err := models.GetInvite(ctx, companyKey, inviteID)
	if err != nil {
		notFound(res)
		return
	}

	form := struct {
		Name     forms.Field
		Email    forms.Field
		Password forms.Field
		Timezone forms.Field
	}{
		forms.Field{
			Name:       "name",
			Label:      "Your name",
			Value:      invite.Name,
			Validators: []forms.Validator{forms.MinLength(2), forms.MaxLength(75)},
		},
		forms.Field{
			Name:       "email",
			Label:      "E-mail address",
			Value:      invite.Email,
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
			renderer.HTML(res, http.StatusBadRequest, "team-sign-up", form)
			return
		}

		ctx := appengine.NewContext(req)
		_, err := models.CreateUser(
			ctx,
			companyKey,
			form.Name.Value,
			form.Email.Value,
			form.Password.Value,
			form.Timezone.Value,
		)

		switch err {
		case nil:
			if !invite.Bulk {
				models.DeleteInvite(ctx, companyKey, inviteID)
			}

			location := ReverseRoute(signInRoute).
				Subdomain(company.Subdomain).
				Build()
			http.Redirect(res, req, location, http.StatusTemporaryRedirect)
			return
		case models.ErrUserExists:
			form.Email.Errors = []string{err.Error()}
			renderer.HTML(res, http.StatusBadRequest, "team-sign-up", form)
			return
		default:
			log.Criticalf(ctx, "failed to create uesr: %v", err)
		}

	}

	renderer.HTML(res, http.StatusOK, "team-sign-up", form)
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

func recoverPasswordHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	form := struct {
		Email forms.Field
	}{
		forms.Field{
			Name:       "email",
			Label:      "Email",
			Validators: []forms.Validator{forms.Email},
		},
	}

	if req.Method == http.MethodPost {
		if !forms.Bind(req, &form) {
			renderer.HTML(res, http.StatusBadRequest, "recover-password", form)
			return
		}

		ctx := appengine.NewContext(req)
		company := context.Get(req, companyCtxKey).(*models.Company)
		companyKey := company.Key(ctx)
		user, err := models.GetUser(ctx, companyKey, form.Email.Value)
		if err == nil {
			_, _, err := models.CreateRecoveryToken(ctx, companyKey, user.Key(ctx))
			if err != nil {
				panic(err)
			}
		}

		renderer.HTML(res, http.StatusOK, "recover-password-success", nil)
		return
	}

	renderer.HTML(res, http.StatusOK, "recover-password", form)
}

func resetPasswordHandler(res http.ResponseWriter, req *http.Request, params httprouter.Params) {
	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	companyKey := company.Key(ctx)
	tokenID := params.ByName("token")
	token, err := models.GetRecoveryToken(ctx, companyKey, tokenID)
	if err != nil {
		notFound(res)
		return
	}

	var user models.User
	if err := nds.Get(ctx, token.User, &user); err != nil {
		notFound(res)
		return
	}

	form := struct {
		Password forms.Field
	}{
		forms.Field{
			Name:       "password",
			Label:      "Password",
			Validators: []forms.Validator{forms.MinLength(6)},
		},
	}

	if req.Method == http.MethodPost {
		if !forms.Bind(req, &form) {
			renderer.HTML(res, http.StatusBadRequest, "reset-password", form)
			return
		}

		user.SetPassword(form.Password.Value)
		if _, err := user.Put(ctx); err != nil {
			panic(err)
		}

		nds.Delete(ctx, models.NewRecoveryTokenKey(ctx, companyKey, tokenID))
		location := ReverseRoute(signInRoute).Build()
		http.Redirect(res, req, location, http.StatusFound)
		return
	}

	renderer.HTML(res, http.StatusOK, "reset-password", form)
}
