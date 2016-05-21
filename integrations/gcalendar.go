package integrations

import (
	"io/ioutil"

	"github.com/pkg/errors"

	"google.golang.org/api/calendar/v3"

	"golang.org/x/net/context"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

var calendarConfig = loadDefaultCalendarConfig()

func loadCalendarConfigFromFile(filename string) *oauth2.Config {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		panic(err)
	}

	config, err := google.ConfigFromJSON(data, calendar.CalendarScope)
	if err != nil {
		panic(err)
	}

	return config
}

func loadDefaultCalendarConfig() *oauth2.Config {
	return loadCalendarConfigFromFile("credentials/calendar.json")
}

// SetCalendarRedirectURL should be called to update the OAuth2
// redirect URL on app initialization.
func SetCalendarRedirectURL(URL string) {
	calendarConfig.RedirectURL = URL
}

// NewCalendarService instantiates a new Google Calendar client and returns it.
func NewCalendarService(ctx context.Context, token *oauth2.Token) (*calendar.Service, error) {
	client := calendarConfig.Client(ctx, token)
	service, err := calendar.New(client)
	if err != nil {
		return nil, errors.Wrap(err, "failed to create calendar service")
	}

	return service, nil
}

// GetCalendarAuthURL returns an OAuth2 authorization URL.
func GetCalendarAuthURL(state string) string {
	return calendarConfig.AuthCodeURL(state, oauth2.AccessTypeOffline, oauth2.ApprovalForce)
}

// ExchangeCalendarCode exchanges an authorization code for a Token.
func ExchangeCalendarCode(ctx context.Context, code string) (*oauth2.Token, error) {
	return calendarConfig.Exchange(ctx, code)
}

// Calendar represents a user's Google Calendar data.
type Calendar struct {
	ID       string `json:"id"`
	Summary  string `json:"summary,omitempty"`
	Timezone string `json:"timezone,omitempty"`
}

// FetchUserCalendars returns all of the visible Google Calendars that
// a specific user can write to.
func FetchUserCalendars(ctx context.Context, token *oauth2.Token) ([]Calendar, error) {
	service, err := NewCalendarService(ctx, token)
	if err != nil {
		return nil, err
	}

	calendarList, err := service.CalendarList.List().Do()
	if err != nil {
		return nil, err
	}

	var calendars []Calendar
	for _, cal := range calendarList.Items {
		if cal.Hidden || cal.Deleted || cal.Id == "" || !(cal.AccessRole == "writer" || cal.AccessRole == "owner") {
			continue
		}

		summary := cal.Summary
		if cal.SummaryOverride != "" {
			summary = cal.SummaryOverride
		}

		calendars = append(calendars, Calendar{
			ID:       cal.Id,
			Summary:  summary,
			Timezone: cal.TimeZone,
		})
	}

	return calendars, nil
}
