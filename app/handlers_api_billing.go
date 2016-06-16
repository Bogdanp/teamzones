package handlers

import (
	"net/http"
	"teamzones/forms"
	"teamzones/integrations"
	"teamzones/models"
	"teamzones/utils"

	"github.com/gorilla/context"
	"github.com/lionelbarrow/braintree-go"
	"google.golang.org/appengine"
	"google.golang.org/appengine/log"
	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(
		appRouter,
		"billing-get-subscription", "/api/billing/subscriptions/current",
		currentSubscriptionHandler, models.RoleMain,
	)
	DELETE(
		appRouter,
		"billing-delete-subscription", "/api/billing/subscriptions/current",
		cancelSubscriptionHandler, models.RoleMain,
	)
	POST(
		appRouter,
		"billing-update-vat-id", "/api/billing/vat-id",
		updateVATIDHandler, models.RoleMain,
	)
	POST(
		appRouter,
		"billing-update-plan", "/api/billing/plans",
		updatePlanHandler, models.RoleMain,
	)
	GET(
		appRouter,
		"billing-invoices", "/api/billing/invoices",
		invoiceListHandler, models.RoleMain,
	)
	GET(
		appRouter,
		"billing-invoice", "/api/billing/invoices/:id",
		invoiceHandler, models.RoleMain,
	)
}

type subscriptionResponse struct {
	NeedVAT    bool                         `json:"needVat"`
	VAT        int                          `json:"vat"`
	VATID      string                       `json:"vatId"`
	Plans      []integrations.BraintreePlan `json:"plans"`
	PlanID     string                       `json:"planId"`
	Status     string                       `json:"status"`
	ValidUntil int64                        `json:"validUntil"`
}

func currentSubscriptionHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	company := context.Get(req, companyCtxKey).(*models.Company)
	var validUntil int64
	if company.SubscriptionStatus != braintree.SubscriptionStatusPending {
		validUntil = company.SubscriptionValidUntil.Unix()
	}

	ctx := appengine.NewContext(req)
	plans, err := company.ValidPlans(ctx)
	if err != nil {
		log.Errorf(ctx, "error fetching valid plans: %v", err)
		serverError(res)
		return
	}

	vat := company.LookupVAT()
	renderer.JSON(res, http.StatusOK, subscriptionResponse{
		NeedVAT:    vat != 0 && company.SubscriptionVATID == "",
		VAT:        vat,
		VATID:      company.SubscriptionVATID,
		Plans:      plans,
		PlanID:     company.SubscriptionPlanID,
		Status:     company.SubscriptionStatus,
		ValidUntil: validUntil,
	})
}

func cancelSubscriptionHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	sub, err := integrations.BraintreeCancelSubscription(ctx, company.SubscriptionID)
	if err != nil {
		log.Errorf(ctx, "failed to cancel subscription for %v: %v", company.Subdomain, err)
		serverError(res)
		return
	}

	err = company.CancelSubscription(ctx, sub)
	if err != nil {
		log.Errorf(ctx, "failed to cancel subscription: %v", err)
		serverError(res)
		return
	}

	res.WriteHeader(http.StatusOK)
}

func updateVATIDHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var data struct {
		VATID string `json:"vatId"`
	}

	if err := forms.BindJSON(req, &data); err != nil {
		badRequest(res, err.Error())
		return
	}

	ctx := appengine.NewContext(req)
	if data.VATID != "" && !utils.CheckVAT(ctx, data.VATID) {
		badRequest(res, "invalid VAT id")
		return
	}

	company := context.Get(req, companyCtxKey).(*models.Company)
	company.SubscriptionVATID = data.VATID
	company.Put(ctx)

	_, err := company.UpdatePlan(ctx, company.SubscriptionPlanID)
	if err != nil {
		log.Errorf(ctx, "failed to update vat for %v: %v", company.Subdomain, err)
		serverError(res)
		return
	}

	res.WriteHeader(http.StatusOK)
}

func updatePlanHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var data struct {
		PlanID string `json:"planId"`
	}

	if err := forms.BindJSON(req, &data); err != nil {
		badRequest(res, err.Error())
		return
	}

	var err error
	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	if company.SubscriptionStatus == braintree.SubscriptionStatusCanceled {
		_, err = company.Resubscribe(ctx, data.PlanID)
	} else {
		_, err = company.UpdatePlan(ctx, data.PlanID)
	}

	if err != nil {
		log.Errorf(ctx, "failed to update subscription plan for %v: %v", company.Subdomain, err)
		serverError(res)
		return
	}

	res.WriteHeader(http.StatusOK)
}

type invoiceResponse struct {
	ID string `json:"id"`

	models.Transaction
}

func invoiceListHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var invoices []invoiceResponse

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	keys, err := models.FindInvoices(company.Key(ctx)).GetAll(ctx, &invoices)
	if err != nil {
		log.Errorf(ctx, "failed to find invoices: %v", err)
		serverError(res)
		return
	}

	for i, k := range keys {
		invoices[i].ID = k.StringID()
	}

	renderer.JSON(res, http.StatusOK, invoices)
}

func invoiceHandler(res http.ResponseWriter, req *http.Request, params httprouter.Params) {
	id := params.ByName("id")
	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	invoice, err := models.GetInvoice(ctx, company.Key(ctx), id)
	if err != nil {
		notFound(res)
		return
	}

	renderer.JSON(res, http.StatusOK, invoiceResponse{id, *invoice})
}
