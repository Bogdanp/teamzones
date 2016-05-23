package handlers

import (
	"net/http"
	"teamzones/forms"
	"teamzones/integrations"
	"teamzones/models"

	"google.golang.org/appengine"
	"google.golang.org/appengine/log"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(siteRouter, homeRoute, "/", homeHandler)
	GET(siteRouter, plansRoute, "/plans/", plansHandler)
	ALL(siteRouter, signUpRoute, "/sign-up/:plan/", signUpHandler)
	ALL(siteRouter, siteSignInRoute, "/sign-in/", siteSignInHandler)
	ALL(siteRouter, findTeamRoute, "/find-team/", findTeamHandler)

	GET(siteRouter, btTokenRoute, "/api/bt-token", braintreeTokenHandler)
	POST(siteRouter, btWebhookRoute, "/api/bt-webhooks", braintreeWebhookHandler)
}

func homeHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	renderer.HTML(res, http.StatusOK, "index", nil)
}

func plansHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	renderer.HTML(res, http.StatusOK, "plans", integrations.BraintreePlans())
}

func signUpHandler(res http.ResponseWriter, req *http.Request, params httprouter.Params) {
	plan, err := integrations.LookupBraintreePlan(params.ByName("plan"))
	if err != nil {
		notFound(res)
		return
	}

	country := req.Header.Get("X-AppEngine-Country")
	form := struct {
		CompanyName      forms.Field
		CompanySubdomain forms.Field
		Name             forms.Field
		Email            forms.Field
		Password         forms.Field
		Country          forms.Field
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
			Name:       "country",
			Label:      "Country",
			Value:      country,
			Values:     forms.CountryValues(),
			Validators: []forms.Validator{forms.Country},
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

		if country != "ZZ" && country != form.Country.Value {
			form.Country.Errors = []string{"Your selected country must match your IP address."}
			renderer.HTML(res, http.StatusBadRequest, "sign-up", form)
			return
		}

		nonce := req.PostFormValue("payment_method_nonce")
		if nonce == "" {
			renderer.HTML(res, http.StatusBadRequest, "sign-up", form)
			return
		}

		ctx := appengine.NewContext(req)
		customer, subscription, err := integrations.BraintreeSubscribe(
			ctx, nonce, plan.ID,
			form.CompanySubdomain.Value, form.Name.Value, form.Email.Value,
		)
		if err != nil {
			// FIXME: Display an error
			log.Errorf(ctx, "error while subscribing customer: %v", err)
			renderer.HTML(res, http.StatusBadRequest, "sign-up", form)
			return
		}

		_, _, err = models.CreateMainUser(
			ctx,

			form.CompanyName.Value,
			form.CompanySubdomain.Value,

			plan.ID,
			customer.Id,
			subscription.Id,

			// Remote address and Country are required for VAT purposes
			req.RemoteAddr,
			form.Country.Value,

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

func siteSignInHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	form := struct {
		Subdomain forms.Field
	}{
		forms.Field{
			Name:       "subdomain",
			Label:      "Subdomain",
			Validators: []forms.Validator{forms.MinLength(3), forms.MaxLength(15)},
		},
	}

	if req.Method == http.MethodPost {
		if !forms.Bind(req, &form) {
			renderer.HTML(res, http.StatusBadRequest, "site-sign-in", form)
			return
		}

		ctx := appengine.NewContext(req)
		company, err := models.GetCompany(ctx, form.Subdomain.Value)
		if err != nil {
			form.Subdomain.Errors = []string{"We couldn't find your team."}
			renderer.HTML(res, http.StatusOK, "site-sign-in", form)
			return
		}

		location := ReverseRoute(signInRoute).
			Subdomain(company.Subdomain).
			Build()

		http.Redirect(res, req, location, http.StatusFound)
		return
	}

	renderer.HTML(res, http.StatusOK, "site-sign-in", form)
}

func findTeamHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
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
			renderer.HTML(res, http.StatusBadRequest, "find-team", form)
			return
		}

		// FIXME: Send out notifications
		renderer.HTML(res, http.StatusOK, "find-team-success", nil)
		return
	}

	renderer.HTML(res, http.StatusOK, "find-team", form)
}

func braintreeTokenHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	ctx := appengine.NewContext(req)
	t, err := integrations.NewBraintreeService(ctx).ClientToken().Generate()
	if err != nil {
		log.Errorf(ctx, "failed to generate client token: %v", err)
		serverError(res)
		return
	}

	renderer.JSON(res, http.StatusOK, t)
}

func braintreeWebhookHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	ctx := appengine.NewContext(req)
	processBtWebhook.Call(ctx, req.PostFormValue("bt_signature"), req.PostFormValue("bt_payload"))
	res.WriteHeader(http.StatusAccepted)
}
