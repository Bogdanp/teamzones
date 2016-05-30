package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"teamzones/forms"
	"teamzones/models"
	"time"

	"google.golang.org/appengine"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/memcache"

	"github.com/gorilla/context"
	"github.com/qedus/nds"

	"gopkg.in/julienschmidt/httprouter.v1"
)

const (
	seatsExhaustedMessage = ("You have exhausted your allotted number of " +
		"seats. Please upgrade your account to invite more teammates.")
)

func init() {
	POST(
		appRouter,
		sendInviteRoute, "/api/invites",
		sendInviteHandler, models.RoleMain, models.RoleManager,
	)
	POST(
		appRouter,
		createBulkInviteRoute, "/api/bulk-invites",
		createBulkInviteHandler, models.RoleMain, models.RoleManager,
	)
	DELETE(
		appRouter,
		deleteUserRoute, "/api/users/:email",
		deleteUserHandler,
	)
}

func sendInviteHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var data struct {
		FirstName string `json:"firstName" validate:"MinLength:3,MaxLength:50"`
		LastName  string `json:"lastName" validate:"MinLength:3,MaxLength:50"`
		Email     string `json:"email" validate:"Email"`
	}

	if err := forms.BindJSON(req, &data); err != nil {
		badRequest(res, err.Error())
		return
	}

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	if company.SeatsLeft(ctx) <= 0 {
		badRequest(res, seatsExhaustedMessage)
		return
	}

	inviteUser.Call(ctx, company.Key(ctx), data.FirstName, data.LastName, data.Email)
	res.WriteHeader(http.StatusCreated)
}

type bulkInviteResponse struct {
	URI string  `json:"uri"`
	TTL float64 `json:"ttl"`
}

func createBulkInviteHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var inviteIDStr string
	var invite *models.Invite

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	if company.SeatsLeft(ctx) <= 0 {
		badRequest(res, seatsExhaustedMessage)
		return
	}

	companyKey := company.Key(ctx)
	cacheKey := fmt.Sprintf("bulk-invites:%d", companyKey.IntID())
	inviteData, err := memcache.Get(ctx, cacheKey)
	if err == nil {
		inviteIDStr = string(inviteData.Value)
		inviteID, _ := strconv.ParseInt(inviteIDStr, 10, 64)
		invite, _ = models.GetInvite(ctx, companyKey, inviteID)
	} else {
		inviteData, inviteKey, err := models.CreateBulkInvite(ctx, companyKey)
		if err != nil {
			log.Errorf(ctx, "failed to create invite: %v", err)
			serverError(res)
			return
		}

		invite = inviteData // janky af
		inviteIDStr = strconv.FormatInt(inviteKey.IntID(), 10)
		memcache.Set(ctx, &memcache.Item{
			Key:        cacheKey,
			Value:      []byte(inviteIDStr),
			Expiration: models.BulkInviteTTL - 600,
		})
	}

	location := ReverseRoute(teamSignUpRoute).
		Param("invite", inviteIDStr).
		Subdomain(company.Subdomain).
		Build()

	renderer.JSON(res, http.StatusCreated, bulkInviteResponse{
		URI: location,
		TTL: invite.CreatedAt.Add(models.BulkInviteTTL).Sub(time.Now()).Seconds(),
	})
}

func deleteUserHandler(res http.ResponseWriter, req *http.Request, params httprouter.Params) {
	user := context.Get(req, userCtxKey).(*models.User)
	email := params.ByName("email")
	if user.Role == models.RoleUser || user.Email == email {
		forbidden(res)
		return
	}

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	user, err := models.GetUser(ctx, company.Key(ctx), email)
	if err != nil || user.Role == models.RoleMain {
		notFound(res)
		return
	}

	if err := nds.Delete(ctx, user.Key(ctx)); err != nil {
		serverError(res)
		return
	}

	res.WriteHeader(http.StatusNoContent)
}
