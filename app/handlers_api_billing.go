package handlers

import (
	"net/http"
	"teamzones/forms"
	"teamzones/integrations"
	"teamzones/models"

	"github.com/gorilla/context"
	"github.com/lionelbarrow/braintree-go"
	"google.golang.org/appengine"
	"google.golang.org/appengine/log"
	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(
		appRouter,
		currentSubscriptionRoute, "/api/billing/subscriptions/current",
		currentSubscriptionHandler, models.RoleMain,
	)
	DELETE(
		appRouter,
		currentSubscriptionRoute, "/api/billing/subscriptions/current",
		cancelSubscriptionHandler, models.RoleMain,
	)
	POST(
		appRouter,
		updatePlanRoute, "/api/billing/plans",
		updatePlanHandler, models.RoleMain,
	)
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

	renderer.JSON(res, http.StatusOK, map[string]interface{}{
		"plans":      plans,
		"planId":     company.SubscriptionPlanID,
		"status":     company.SubscriptionStatus,
		"validUntil": validUntil,
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

func updatePlanHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var data struct {
		PlanID string `json:"planId"`
	}

	if err := forms.BindJSON(req, &data); err != nil {
		badRequest(res, err.Error())
		return
	}

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	_, err := company.UpdatePlan(ctx, data.PlanID)
	if err != nil {
		log.Errorf(ctx, "failed to update subscription plan for %v: %v", company.Subdomain, err)
		serverError(res)
		return
	}

	res.WriteHeader(http.StatusOK)
}
