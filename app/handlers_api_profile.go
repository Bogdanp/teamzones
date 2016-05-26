package handlers

import (
	"fmt"
	"net/http"
	"teamzones/forms"
	"teamzones/integrations"
	"teamzones/models"
	"time"

	"github.com/gorilla/context"
	"google.golang.org/appengine"
	"google.golang.org/appengine/blobstore"
	"google.golang.org/appengine/image"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/memcache"
	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(
		appRouter,
		locationRoute, "/api/location",
		locationHandler,
	)
	POST(
		appRouter,
		updateProfileRoute, "/api/profile",
		updateProfileHandler,
	)
	ALL(
		appRouter,
		avatarUploadRoute, "/api/upload",
		avatarUploadHandler,
	)
	DELETE(
		appRouter,
		deleteAvatarRoute, "/api/avatar",
		deleteAvatarHandler,
	)
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
