package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"teamzones/forms"
	"teamzones/integrations"
	"teamzones/models"
	"time"

	"google.golang.org/appengine"
	"google.golang.org/appengine/blobstore"
	"google.golang.org/appengine/image"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/memcache"

	"github.com/gorilla/context"
	"github.com/lionelbarrow/braintree-go"
	"github.com/qedus/nds"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	// User management
	POST(appRouter, sendInviteRoute, "/api/invites", sendInviteHandler)
	POST(appRouter, createBulkInviteRoute, "/api/bulk-invites", createBulkInviteHandler)
	DELETE(appRouter, deleteUserRoute, "/api/users/:email", deleteUserHandler)

	// Profile
	GET(appRouter, locationRoute, "/api/location", locationHandler)
	POST(appRouter, updateProfileRoute, "/api/profile", updateProfileHandler)
	ALL(appRouter, avatarUploadRoute, "/api/upload", avatarUploadHandler)
	DELETE(appRouter, deleteAvatarRoute, "/api/avatar", deleteAvatarHandler)

	// Integrations
	POST(appRouter, refreshIntegrationRoute, "/api/integrations/refresh", refreshIntegrationHandler)
	POST(appRouter, disconnectIntegrationRoute, "/api/integrations/disconnect", disconnectIntegrationHandler)
	GET(appRouter, gcalendarDataRoute, "/api/integrations/gcalendar/data", gcalendarDataHandler)

	// Billing
	GET(appRouter, currentSubscriptionRoute, "/api/billing/subscriptions/current", currentSubscriptionHandler)
	DELETE(appRouter, currentSubscriptionRoute, "/api/billing/subscriptions/current", cancelSubscriptionHandler)
}

type locationResponse struct {
	Country  string `json:"country"`
	Region   string `json:"region"`
	City     string `json:"city"`
	Timezone string `json:"timezone"`
}

func locationHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var timezoneID string

	ctx := appengine.NewContext(req)
	user := context.Get(req, userCtxKey).(*models.User)
	cacheKey := fmt.Sprintf("timezone:%s", user.Email)
	timezone, err := memcache.Get(ctx, cacheKey)

	if err == nil {
		timezoneID = string(timezone.Value)
	} else {
		location := req.Header.Get("X-AppEngine-CityLatLong")
		if location != "" {
			timezoneID, err := integrations.GetTimezone(ctx, location)
			if err != nil {
				panic(err)
			}

			memcache.Set(ctx, &memcache.Item{
				Key:        cacheKey,
				Value:      []byte(timezoneID),
				Expiration: 8 * time.Hour,
			})
		}
	}

	renderer.JSON(res, http.StatusOK, locationResponse{
		Country:  req.Header.Get("X-AppEngine-Country"),
		Region:   req.Header.Get("X-AppEngine-Region"),
		City:     req.Header.Get("X-AppEngine-City"),
		Timezone: timezoneID,
	})
}

func sendInviteHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	user := context.Get(req, userCtxKey).(*models.User)
	if user.Role == models.RoleUser {
		forbidden(res)
		return
	}

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
	companyKey := company.Key(ctx)
	_, err := models.GetUser(ctx, companyKey, data.Email)
	if err == nil {
		log.Infof(ctx, "user %q is already a member, skipping invite", data.Email)
		return
	}

	_, _, err = models.CreateInvite(
		ctx, companyKey,
		data.FirstName, data.LastName, data.Email,
	)
	if err != nil {
		log.Errorf(ctx, "failed to create invite: %v", err)
		serverError(res)
		return
	}

	// TODO: Send email invite
	res.WriteHeader(http.StatusCreated)
}

type bulkInviteResponse struct {
	URI string  `json:"uri"`
	TTL float64 `json:"ttl"`
}

func createBulkInviteHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	user := context.Get(req, userCtxKey).(*models.User)
	if user.Role == models.RoleUser {
		http.Error(res, "forbidden", http.StatusForbidden)
		return
	}

	var inviteIDStr string
	var invite *models.Invite

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
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

func avatarUploadHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	ctx := appengine.NewContext(req)

	if req.Method == http.MethodPost {
		redirect := func() {
			http.Redirect(res, req, ReverseSimple(currentProfileRoute), http.StatusFound)
		}

		blobs, _, err := blobstore.ParseUpload(req)
		if err != nil {
			log.Errorf(ctx, "failed to upload file: %v", err)
			redirect()
			return
		}

		file := blobs["avatar-file"]
		if len(file) == 0 {
			redirect()
			return
		}

		avatar := file[0]
		imageURL, err := image.ServingURL(ctx, avatar.BlobKey, &image.ServingURLOptions{
			Size: 500,
			Crop: true,
		})
		if err != nil {
			redirect()
			return
		}

		smImageURL, err := image.ServingURL(ctx, avatar.BlobKey, &image.ServingURLOptions{
			Size: 100,
			Crop: true,
		})
		if err != nil {
			redirect()
			return
		}

		user := context.Get(req, userCtxKey).(*models.User)
		user.Avatar = imageURL.String()
		user.AvatarSm = smImageURL.String()
		user.AvatarFile = avatar.BlobKey
		user.Put(ctx)

		redirect()
		return
	}

	location := ReverseSimple(avatarUploadRoute)
	uri, err := blobstore.UploadURL(ctx, location, &blobstore.UploadURLOptions{
		MaxUploadBytesPerBlob: 1024 * 1024 * 8,

		StorageBucket: fmt.Sprintf("%s/avatars", config.CloudStorage.Bucket),
	})
	if err != nil {
		log.Errorf(ctx, "failed to create upload url: %v", err)
		serverError(res)
		return
	}

	renderer.JSON(res, http.StatusOK, struct {
		URI string `json:"uri"`
	}{
		URI: uri.String(),
	})
}

func deleteAvatarHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	ctx := appengine.NewContext(req)
	user := context.Get(req, userCtxKey).(*models.User)
	user.Avatar = ""
	user.Put(ctx)

	res.WriteHeader(http.StatusNoContent)
}

func updateProfileHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var data struct {
		FirstName string          `json:"firstName" validate:"MinLength:3,MaxLength:50"`
		LastName  string          `json:"lastName" validate:"MinLength:3,MaxLength:50"`
		Timezone  string          `json:"timezone"`
		Workdays  models.Workdays `json:"workdays"`
	}

	if err := forms.BindJSON(req, &data); err != nil {
		badRequest(res, err.Error())
		return
	}

	ctx := appengine.NewContext(req)
	user := context.Get(req, userCtxKey).(*models.User)
	user.FirstName = data.FirstName
	user.Timezone = data.Timezone
	user.Workdays = data.Workdays
	user.Put(ctx)

	res.WriteHeader(http.StatusNoContent)
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

func refreshIntegrationHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var data struct {
		Integration string `json:"integration"`
	}

	if err := forms.BindJSON(req, &data); err != nil {
		badRequest(res, err.Error())
		return
	}

	switch data.Integration {
	case models.OAuth2GCalendar:
		ctx := appengine.NewContext(req)
		user := context.Get(req, userCtxKey).(*models.User)
		if user.GCalendarToken == nil {
			badRequest(res, "integration disconnected")
			return
		}

		throttlingKey := fmt.Sprintf("refresh-calendar:%s", user.Email)
		if throttle(ctx, throttlingKey, 5*time.Minute) {
			badRequest(res, "throttled")
			return
		}

		if user.GCalendarData != nil {
			var data models.GCalendarData
			if err := nds.Get(ctx, user.GCalendarData, &data); err != nil {
				serverError(res)
				return
			}

			data.Status = models.GCalendarStatusLoading
			if _, err := nds.Put(ctx, user.GCalendarData, &data); err != nil {
				serverError(res)
				return
			}
		}

		refreshGCalendar.Call(ctx, user.GCalendarToken)
		res.WriteHeader(http.StatusAccepted)
		return
	default:
		badRequest(res, "invalid integration")
		return
	}
}

func disconnectIntegrationHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var data struct {
		Integration string `json:"integration"`
	}

	if err := forms.BindJSON(req, &data); err != nil {
		badRequest(res, err.Error())
		return
	}

	switch data.Integration {
	case models.OAuth2GCalendar:
		ctx := appengine.NewContext(req)
		user := context.Get(req, userCtxKey).(*models.User)
		if user.GCalendarToken == nil {
			badRequest(res, "integration disconnected")
			return
		}

		nds.Delete(ctx, user.GCalendarToken)
		user.GCalendarToken = nil
		user.Put(ctx)
		res.WriteHeader(http.StatusNoContent)
		return
	default:
		badRequest(res, "invalid integration")
		return
	}
}

func gcalendarDataHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	data := models.GCalendarData{
		Status:    models.GCalendarStatusLoading,
		Calendars: []integrations.Calendar{},
	}

	user := context.Get(req, userCtxKey).(*models.User)
	if user.GCalendarToken != nil {
		ctx := appengine.NewContext(req)
		if user.GCalendarData == nil {
			refreshGCalendar.Call(ctx, user.GCalendarToken)
		} else if err := nds.Get(ctx, user.GCalendarData, &data); err != nil {
			serverError(res)
			return
		}
	}

	renderer.JSON(res, http.StatusOK, data)
}

func currentSubscriptionHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	if !hasRole(res, req, models.RoleMain) {
		return
	}

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
	if !hasRole(res, req, models.RoleMain) {
		return
	}

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
