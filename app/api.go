package handlers

import (
	"fmt"
	"net/http"
	"teamzones/models"
	"teamzones/utils"
	"time"

	"google.golang.org/appengine"
	"google.golang.org/appengine/memcache"

	"github.com/gorilla/context"

	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	GET(appRouter, locationRoute, "/api/v1/location", location)
}

type locationResponse struct {
	Country  string `json:"country"`
	Region   string `json:"region"`
	City     string `json:"city"`
	Timezone []byte `json:"timezone"`
}

func location(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var timezoneID []byte

	ctx := appengine.NewContext(req)
	user := context.Get(req, userCtxKey).(*models.User)
	cacheKey := fmt.Sprintf("timezone:%s", user.Email)
	timezone, err := memcache.Get(ctx, cacheKey)

	if err == nil {
		timezoneID = timezone.Value
	} else {
		location := req.Header.Get("X-AppEngine-CityLatLong")
		if location != "" {
			timezoneID = []byte(<-utils.GetTimezone(ctx, location))
			memcache.Set(ctx, &memcache.Item{
				Key:        cacheKey,
				Value:      timezoneID,
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
