package handlers

import (
	"encoding/json"
	"html/template"
	"net/http"
	"teamzones/forms"
	"teamzones/integrations"
	"teamzones/models"
	"teamzones/utils"
	"time"

	"google.golang.org/appengine"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/taskqueue"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(siteRouter, "home", "/", homeHandler)
	GET(siteRouter, "plans", "/plans/", plansHandler)
	ALL(siteRouter, "sign-up", "/sign-up/:plan/", signUpHandler)
	ALL(siteRouter, "sign-in", "/sign-in/", siteSignInHandler)
	ALL(siteRouter, "find-team", "/find-team/", findTeamHandler)

	GET(
		siteRouter,
		"braintree-token", "/api/bt-token",
		braintreeTokenHandler,
	)
	POST(
		siteRouter,
		"braintree-webhook", "/api/bt-webhooks",
		braintreeWebhookHandler,
	)
}

func homeHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	renderer.HTML(res, http.StatusOK, "index", nil)
}

func plansHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	renderer.HTML(res, http.StatusOK, "plans", integrations.BraintreePlans())
}

type signUpForm struct {
	CompanyName      forms.Field
	CompanySubdomain forms.Field
	FirstName        forms.Field
	LastName         forms.Field
	Email            forms.Field
	Password         forms.Field
	Address1         forms.Field
	Address2         forms.Field
	City             forms.Field
	Region           forms.Field
	PostalCode       forms.Field
	Country          forms.Field
	VATID            forms.Field
	Timezone         forms.Field
}

func signUpHandler(res http.ResponseWriter, req *http.Request, params httprouter.Params) {
	plan, err := integrations.LookupBraintreePlan(params.ByName("plan"))
	if err != nil {
		notFound(res)
		return
	}

	country := req.Header.Get("X-AppEngine-Country")
	form := signUpForm{
		forms.Field{
			Name:        "company-name",
			Label:       "Team Name",
			Placeholder: "The A-Team",
			Validators:  []forms.Validator{forms.MinLength(3), forms.MaxLength(35)},
		},
		forms.Field{
			Name:        "company-subdomain",
			Label:       "Team Subdomain",
			Placeholder: "ateam",
			Value:       req.FormValue("subdomain"), // ?subdomain=foo
			Validators:  []forms.Validator{forms.MinLength(3), forms.MaxLength(15), forms.Subdomain},
		},
		forms.Field{
			Name:       "first-name",
			Label:      "First Name",
			Validators: []forms.Validator{forms.Name},
		},
		forms.Field{
			Name:       "last-name",
			Label:      "Last Name",
			Validators: []forms.Validator{forms.Name},
		},
		forms.Field{
			Name:       "email",
			Label:      "Email",
			Validators: []forms.Validator{forms.Email},
		},
		forms.Field{
			Name:       "password",
			Label:      "Password",
			Validators: []forms.Validator{forms.MinLength(6)},
		},
		forms.Field{
			Name:       "address-1",
			Label:      "Address 1",
			Validators: []forms.Validator{forms.MaxLength(300)},
		},
		forms.Field{
			Name:       "address-2",
			Label:      "Address 2",
			Optional:   true,
			Validators: []forms.Validator{forms.MaxLength(300)},
		},
		forms.Field{
			Name:       "city",
			Label:      "City",
			Validators: []forms.Validator{forms.MaxLength(35)},
		},
		forms.Field{
			Name:       "region",
			Label:      "State",
			Validators: []forms.Validator{forms.MaxLength(35)},
		},
		forms.Field{
			Name:       "postal-code",
			Label:      "Zip",
			Validators: []forms.Validator{forms.MaxLength(15)},
		},
		forms.Field{
			Name:       "country",
			Label:      "Country",
			Value:      country,
			Values:     forms.CountryValues,
			Validators: []forms.Validator{forms.Country},
		},
		forms.Field{
			Name:     "vat-id",
			Label:    "VAT ID (Optional)",
			Optional: true,
		},
		forms.Field{
			Name:  "timezone",
			Label: "Timezone",
		},
	}

	vatCountries, _ := json.Marshal(utils.VATCountries)
	planJS, _ := json.Marshal(plan)

	data := struct {
		Plan *integrations.BraintreePlan
		Form *signUpForm

		Error        string
		PlanJS       template.JS
		VATCountries template.JS
	}{
		Plan: plan,
		Form: &form,

		Error:        "",
		PlanJS:       template.JS(planJS),
		VATCountries: template.JS(vatCountries),
	}

	if req.Method == http.MethodPost {
		if !forms.Bind(req, &form) {
			renderer.HTML(res, http.StatusBadRequest, "sign-up", data)
			return
		}

		// ZZ is returned by GAE for localhost.
		if country != "ZZ" && country != form.Country.Value {
			form.Country.Errors = []string{"Your selected country does not match your IP address."}
			renderer.HTML(res, http.StatusBadRequest, "sign-up", data)
			return
		}

		ctx := appengine.NewContext(req)
		if form.VATID.Value != "" && !utils.CheckVAT(ctx, form.Country.Value+form.VATID.Value) {
			form.VATID.Errors = []string{"The provided VAT ID is not valid."}
			renderer.HTML(res, http.StatusBadRequest, "sign-up", data)
			return
		}

		nonce := req.PostFormValue("payment_method_nonce")
		if nonce == "" {
			log.Warningf(ctx, "signUpHandler: missing payment method nonce")
			renderer.HTML(res, http.StatusBadRequest, "sign-up", data)
			return
		}

		vat := 0
		if form.VATID.Value == "" {
			vat = utils.LookupVAT(form.Country.Value)
		}

		customer, subscription, err := integrations.BraintreeSubscribe(
			ctx, nonce, plan.ID, vat,
			form.CompanySubdomain.Value,
			form.FirstName.Value,
			form.LastName.Value,
			form.Email.Value,
		)
		if err != nil {
			log.Errorf(ctx, "error while subscribing customer: %v", err)
			data.Error = "We encountered an issue while processing your credit card. You have not been billed."
			renderer.HTML(res, http.StatusBadRequest, "sign-up", data)
			return
		}

		company := models.NewCompany(form.CompanyName.Value, form.CompanySubdomain.Value)

		// Customer-provided
		company.SubscriptionPlanID = plan.ID
		company.SubscriptionFirstName = form.FirstName.Value
		company.SubscriptionLastName = form.LastName.Value
		company.SubscriptionAddress1 = form.Address1.Value
		company.SubscriptionAddress2 = form.Address2.Value
		company.SubscriptionCity = form.City.Value
		company.SubscriptionRegion = form.Region.Value
		company.SubscriptionPostalCode = form.PostalCode.Value
		company.SubscriptionCountry = form.Country.Value
		company.SubscriptionVATID = form.VATID.Value
		company.SubscriptionIP = req.RemoteAddr

		// Braintree-provided
		company.SubscriptionID = subscription.Id
		company.SubscriptionCustomerID = customer.Id

		_, err = models.CreateMainUser(
			ctx,
			company,
			form.FirstName.Value,
			form.LastName.Value,
			form.Email.Value,
			form.Password.Value,
			form.Timezone.Value,
		)

		switch err {
		case nil:
			location := ReverseRoute("team-sign-in").
				Subdomain(form.CompanySubdomain.Value).
				Build()
			http.Redirect(res, req, location, http.StatusTemporaryRedirect)
			return
		case models.ErrSubdomainTaken:
			form.CompanySubdomain.Errors = []string{err.Error()}
			renderer.HTML(res, http.StatusBadRequest, "sign-up", data)
			return
		default:
			panic(err)
		}
	}

	renderer.HTML(res, http.StatusOK, "sign-up", data)
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

		location := ReverseRoute("team-sign-in").
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
	task, err := processBtWebhook.Task(
		req.PostFormValue("bt_signature"),
		req.PostFormValue("bt_payload"),
	)
	if err != nil {
		log.Errorf(ctx, "failed to create processBtWebhook task: %v", err)
		serverError(res)
		return
	}

	// Delay these tasks by 5 minutes to avoid a race condition when
	// creating new accounts.
	task.Delay = 5 * time.Minute
	taskqueue.Add(ctx, task, "braintree")
	res.WriteHeader(http.StatusAccepted)
}
