package handlers

import (
	"teamzones/integrations"
	"teamzones/models"

	"github.com/lionelbarrow/braintree-go"
	"github.com/qedus/nds"

	"golang.org/x/net/context"
	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/delay"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/mail"
)

var processBtWebhook = delay.Func(
	"process-braintree-webhook",
	func(ctx context.Context, btSignature, btPayload string) {
		bt := integrations.NewBraintreeService(ctx)
		n, err := bt.WebhookNotification().Parse(btSignature, btPayload)
		if err != nil {
			log.Errorf(ctx, "Failed to parse Braintree webhook: %v", err)
			return
		}

		sub := n.Subject.Subscription
		if sub == nil {
			log.Errorf(ctx, "Notification does not have a Subscription: %v", n.Kind)
			return
		}

		company, err := models.GetCompanyBySubID(ctx, sub.Id)
		if err != nil {
			log.Errorf(ctx, "Failed to retrieve company: %v", err)
			return
		}

		switch n.Kind {
		case braintree.SubscriptionCanceledWebhook:
			if err := company.CancelSubscription(ctx, sub); err != nil {
				panic(err)
			}

		case braintree.SubscriptionWentPastDueWebhook:
			// TODO: Notify the user that their subscription is past due.
			if err := company.MarkSubscriptionPastDue(ctx, sub); err != nil {
				panic(err)
			}

		case braintree.SubscriptionChargedSuccessfullyWebhook:
			if err := company.MarkSubscriptionActive(ctx, sub); err != nil {
				panic(err)
			}
		}
	},
)

var refreshGCalendar = delay.Func(
	"refresh-gcalendar",
	func(ctx context.Context, tokenKey *datastore.Key) {
		var token models.OAuth2Token
		if err := nds.Get(ctx, tokenKey, &token); err != nil {
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
		if err := nds.Get(ctx, userKey, &user); err != nil {
			panic(err)
		}

		calendarData := models.NewGCalendarData(user.Company, userKey)
		if user.GCalendarData == nil {
			user.GCalendarData = models.NewGCalendarDataKey(ctx, token.User, user.Email)
		} else if err := nds.Get(ctx, user.GCalendarData, calendarData); err != nil {
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
		err := nds.RunInTransaction(ctx, func(ctx context.Context) error {
			_, err := nds.PutMulti(
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

var sendMail = delay.Func(
	"send-mail",
	func(ctx context.Context, message mail.Message) {
		mail.Send(ctx, &message)
	},
)
