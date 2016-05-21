package handlers

import (
	"teamzones/integrations"
	"teamzones/models"

	"golang.org/x/net/context"
	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/delay"
	"google.golang.org/appengine/log"
)

var refreshGCalendar = delay.Func(
	"refresh-gcalendar",
	func(ctx context.Context, tokenKey *datastore.Key) {
		var token models.OAuth2Token
		if err := datastore.Get(ctx, tokenKey, &token); err != nil {
			log.Errorf(ctx, "Token not found: %v", err)
			return
		}

		type calendarsResult struct {
			primaryID string
			calendars []integrations.Calendar
			err       error
		}

		c := make(chan calendarsResult)
		go func() {
			primaryID, calendars, err := integrations.FetchUserCalendars(ctx, &token.Token)
			c <- calendarsResult{primaryID, calendars, err}
		}()

		var user models.User
		userKey := token.User
		if err := datastore.Get(ctx, userKey, &user); err != nil {
			panic(err)
		}

		calendarData := models.NewGCalendarData(user.Company, userKey)
		if user.GCalendarData == nil {
			user.GCalendarData = models.NewGCalendarDataKey(ctx, token.User, user.Email)
		} else if err := datastore.Get(ctx, user.GCalendarData, calendarData); err != nil {
			panic(err)
		}

		res := <-c
		if res.err != nil {
			panic(res.err)
		}

		if calendarData.DefaultID == "" {
			calendarData.DefaultID = res.primaryID
		}

		calendarData.Status = models.GCalendarStatusDone
		calendarData.Calendars = res.calendars
		err := datastore.RunInTransaction(ctx, func(ctx context.Context) error {
			_, err := datastore.PutMulti(
				ctx,
				[]*datastore.Key{userKey, user.GCalendarData},
				[]interface{}{&user, calendarData},
			)
			return err
		}, nil)
		if err != nil {
			panic(err)
		}
	},
)
