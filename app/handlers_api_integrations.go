package handlers

import (
	"fmt"
	"net/http"
	"teamzones/forms"
	"teamzones/integrations"
	"teamzones/models"
	"time"

	"github.com/gorilla/context"
	"github.com/qedus/nds"
	"google.golang.org/appengine"
	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	POST(
		appRouter,
		refreshIntegrationRoute, "/api/integrations/refresh",
		refreshIntegrationHandler,
	)
	POST(
		appRouter,
		disconnectIntegrationRoute, "/api/integrations/disconnect",
		disconnectIntegrationHandler,
	)
	GET(
		appRouter,
		gcalendarDataRoute, "/api/integrations/gcalendar/data",
		gcalendarDataHandler,
	)
	POST(
		appRouter,
		scheduleMeetingRoute, "/api/integrations/gcalendar/meetings",
		scheduleMeetingHandler,
	)
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

func scheduleMeetingHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	meeting := models.NewMeeting()
	if err := forms.BindJSON(req, meeting); err != nil {
		badRequest(res, err.Error())
		return
	}

	ctx := appengine.NewContext(req)
	user := context.Get(req, userCtxKey).(*models.User)
	k := models.NewMeetingKey(ctx, user.Key(ctx))
	k, err := nds.Put(ctx, k, meeting)
	if err != nil {
		serverError(res)
		return
	}

	scheduleMeeting.Call(ctx, k)
	res.WriteHeader(http.StatusAccepted)
}
