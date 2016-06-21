package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"teamzones/forms"
	"teamzones/integrations"
	"teamzones/models"
	"time"

	"github.com/gorilla/context"
	"github.com/qedus/nds"
	"google.golang.org/appengine"
	"google.golang.org/appengine/log"
	"gopkg.in/julienschmidt/httprouter.v1"
)

func init() {
	POST(
		appRouter,
		"integrations-refresh", "/api/integrations/refresh",
		refreshIntegrationHandler,
	)
	POST(
		appRouter,
		"integrations-disconnect", "/api/integrations/disconnect",
		disconnectIntegrationHandler,
	)
	GET(
		appRouter,
		"integrations-calendar-data", "/api/integrations/gcalendar/data",
		gcalendarDataHandler,
	)
	POST(
		appRouter,
		"integrations-calendar-schedule", "/api/integrations/gcalendar/meetings",
		scheduleMeetingHandler,
	)
	GET(
		appRouter,
		"integrations-calendar-meetings", "/api/integrations/gcalendar/meetings",
		meetingListHandler,
	)
	GET(
		appRouter,
		"integrations-calendar-meeting", "/api/integrations/gcalendar/meetings/:id",
		meetingDetailsHandler,
	)
	PATCH(
		appRouter,
		"integrations-calendar-set-default", "/api/integrations/gcalendar/meetings",
		setDefaultCalendarHandler,
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

type meetingResponse struct {
	ID string `json:"id"`

	models.Meeting
}

func scheduleMeetingHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	meeting := models.NewMeeting()
	if err := forms.BindJSON(req, meeting); err != nil {
		badRequest(res, err.Error())
		return
	}

	ctx := appengine.NewContext(req)
	company := context.Get(req, companyCtxKey).(*models.Company)
	user := context.Get(req, userCtxKey).(*models.User)
	k := models.NewMeetingKey(ctx, user.Key(ctx))
	k, err := nds.Put(ctx, k, meeting)
	if err != nil {
		serverError(res)
		return
	}

	if !company.IsDemo() {
		scheduleMeeting.Call(ctx, k)
	}

	sid := strconv.FormatInt(k.IntID(), 10)
	renderer.JSON(res, http.StatusOK, meetingResponse{sid, *meeting})
}

func meetingListHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var meetings []meetingResponse

	ctx := appengine.NewContext(req)
	user := context.Get(req, userCtxKey).(*models.User)
	keys, err := models.FindUpcomingMeetings(user.Key(ctx)).GetAll(ctx, &meetings)
	if err != nil {
		log.Errorf(ctx, "failed to retrieve upcoming meetings: %v", err)
		serverError(res)
		return
	}

	for i, k := range keys {
		meetings[i].ID = strconv.FormatInt(k.IntID(), 10)
	}

	renderer.JSON(res, http.StatusOK, meetings)
}

func meetingDetailsHandler(res http.ResponseWriter, req *http.Request, params httprouter.Params) {
	ctx := appengine.NewContext(req)
	user := context.Get(req, userCtxKey).(*models.User)

	sid := params.ByName("id")
	id, err := strconv.ParseInt(sid, 10, 64)
	if err != nil {
		notFound(res)
		return
	}

	meeting := meetingResponse{ID: sid}
	if err := models.GetMeetingByID(ctx, user.Key(ctx), id, &meeting); err != nil {
		notFound(res)
		return
	}

	renderer.JSON(res, http.StatusOK, meeting)
}

func setDefaultCalendarHandler(res http.ResponseWriter, req *http.Request, _ httprouter.Params) {
	var calendarData models.GCalendarData
	var data struct {
		CalendarID string `json:"calendarId"`
	}

	if err := forms.BindJSON(req, &data); err != nil {
		badRequest(res, err.Error())
		return
	}

	ctx := appengine.NewContext(req)
	user := context.Get(req, userCtxKey).(*models.User)
	if err := nds.Get(ctx, user.GCalendarData, &calendarData); err != nil {
		log.Errorf(ctx, "failed to get calendar data: %v", err)
		serverError(res)
		return
	}

	found := false
	for _, c := range calendarData.Calendars {
		if c.ID == data.CalendarID {
			found = true
			break
		}
	}

	if !found {
		badRequest(res, "invalid calendarId")
		return
	}

	calendarData.DefaultID = data.CalendarID
	if _, err := nds.Put(ctx, user.GCalendarData, &calendarData); err != nil {
		log.Errorf(ctx, "failed to save calendar data: %v", err)
		serverError(res)
		return
	}

	renderer.JSON(res, http.StatusOK, calendarData)
}
