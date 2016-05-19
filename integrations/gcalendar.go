package integrations

import (
	"io/ioutil"

	"github.com/pkg/errors"

	"google.golang.org/api/calendar/v3"

	"golang.org/x/net/context"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

var calendarConfig = loadCalendarConfig()

func loadCalendarConfig() *oauth2.Config {
	data, err := ioutil.ReadFile("credentials/calendar.json")
	if err != nil {
		panic(err)
	}

	config, err := google.ConfigFromJSON(data, calendar.CalendarScope)
	if err != nil {
		panic(err)
	}

	return config
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
