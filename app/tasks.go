package handlers

import (
	"bytes"
	"fmt"
	"strconv"
	"teamzones/integrations"
	"teamzones/models"

	"github.com/lionelbarrow/braintree-go"
	"github.com/qedus/nds"

	"golang.org/x/net/context"
	"google.golang.org/appengine/channel"
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
			if err := models.SyncTransactions(ctx, company, sub); err != nil {
				panic(err)
			}

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
	func(ctx context.Context, to, subject, txtMsg, htmlMsg string) {
		log.Debugf(ctx, "Sending email to %q with subject %q and message %q...", to, subject, txtMsg)
		mail.Send(ctx, &mail.Message{
			To:       []string{to},
			Sender:   "Teamzones.io <support@teamzones.io>",
			Subject:  subject,
			Body:     txtMsg,
			HTMLBody: htmlMsg,
		})
	},
)

var inviteUser = delay.Func(
	"invite-user",
	func(ctx context.Context, companyKey *datastore.Key, firstName, lastName, email string) {
		var company models.Company
		if err := datastore.Get(ctx, companyKey, &company); err != nil {
			log.Warningf(ctx, "company %v not found", companyKey)
			return
		}

		_, err := models.GetUser(ctx, companyKey, email)
		if err == nil {
			log.Infof(ctx, "user %q is already a member, skipping invite", email)
			return
		}

		key, _, err := models.CreateInvite(ctx, companyKey, firstName, lastName, email)
		if err != nil {
			panic(err)
		}

		location := ReverseRoute("team-sign-up").
			Param("invite", strconv.FormatInt(key.IntID(), 10)).
			Subdomain(company.Subdomain).
			Build()

		data := struct {
			Company  *models.Company
			Main     *models.User
			Location string
		}{
			Company:  &company,
			Main:     company.LookupMainUser(ctx),
			Location: location,
		}

		var buf bytes.Buffer
		subject := fmt.Sprintf("You have been invited to join the Teamzones team for %q!", company.Name)
		txtMsg := renderEmail(&buf, "invite.txt", data)
		htmlMsg := renderEmail(&buf, "invite.html", data)
		sendMail.Call(ctx, email, subject, txtMsg, htmlMsg)
	},
)

var createRecoveryToken = delay.Func(
	"create-recovery-token",
	func(ctx context.Context, companyKey *datastore.Key, email string) {
		var company models.Company
		if err := datastore.Get(ctx, companyKey, &company); err != nil {
			log.Warningf(ctx, "company %v not found", companyKey)
			return
		}

		user, err := models.GetUser(ctx, companyKey, email)
		if err != nil {
			log.Errorf(ctx, "failed to get user: %v", err)
			return
		}

		key, _, err := models.CreateRecoveryToken(ctx, companyKey, user.Key(ctx))
		if err != nil {
			panic(err)
		}

		location := ReverseRoute("team-reset-password").
			Param("token", key.StringID()).
			Subdomain(company.Subdomain).
			Build()

		data := struct {
			Company  *models.Company
			User     *models.User
			Location string
		}{
			Company:  &company,
			User:     user,
			Location: location,
		}

		var buf bytes.Buffer
		subject := "Change your Teamzones password"
		txtMsg := renderEmail(&buf, "recover-password.txt", data)
		htmlMsg := renderEmail(&buf, "recover-password.html", data)
		sendMail.Call(ctx, email, subject, txtMsg, htmlMsg)
	},
)

var scheduleMeeting = delay.Func(
	"schedule-meeting",
	func(ctx context.Context, k *datastore.Key) {
		var meeting models.Meeting
		var user models.User
		var token models.OAuth2Token
		var calendars models.GCalendarData

		_ = nds.Get(ctx, k, &meeting)
		_ = nds.Get(ctx, k.Parent(), &user)
		_ = nds.Get(ctx, user.GCalendarToken, &token)
		_ = nds.Get(ctx, user.GCalendarData, &calendars)

		event, err := integrations.ScheduleMeeting(
			ctx, &token.Token, calendars.DefaultID,
			meeting.StartTime, meeting.EndTime,
			meeting.Summary, meeting.Description, meeting.Attendees,
		)
		if err != nil {
			panic(err)
		}

		meeting.EventID = event.Id
		meeting.Put(ctx, k)
	},
)

var notifyMemberAdded = delay.Func(
	"notify-member-added",
	func(ctx context.Context, compKey, userKey *datastore.Key) {
		var company models.Company
		var users []models.User
		var user models.User

		_ = nds.Get(ctx, compKey, &company)
		_ = nds.Get(ctx, userKey, &user)
		if _, err := models.FindUsers(compKey).GetAll(ctx, &users); err != nil {
			panic(err)
		}

		for _, u := range users {
			if u.Email != userKey.StringID() {
				channel.SendJSON(ctx, u.ChannelKey(), map[string]interface{}{
					"kind":  "MemberAdded",
					"value": user,
				})
			}
		}
	},
)
