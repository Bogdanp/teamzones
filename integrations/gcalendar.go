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
