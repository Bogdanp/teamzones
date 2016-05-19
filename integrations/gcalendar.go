package integrations

import (
	"bytes"
	"encoding/json"
	"io"
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

// TokenToJSON converts and OAuth2 Token instance to a JSON bytestring.
func TokenToJSON(token *oauth2.Token) ([]byte, error) {
	var buf bytes.Buffer

	err := json.NewEncoder(&buf).Encode(token)
	if err != nil {
		return nil, errors.Wrap(err, "failed to encode oauth2 token")
	}

	return buf.Bytes(), nil
}

// TokenFromJSON converts a Reader of JSON to an OAuth2 Token.
func TokenFromJSON(buf io.Reader) (*oauth2.Token, error) {
	token := &oauth2.Token{}
	err := json.NewDecoder(buf).Decode(&token)
	if err != nil {
		return nil, errors.Wrap(err, "failed to decode oauth2 token from json")
	}

	return token, nil
}
