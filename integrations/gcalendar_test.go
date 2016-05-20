package integrations

import (
	"flag"
	"log"
	"os"
	"testing"

	"golang.org/x/net/context"
	"golang.org/x/oauth2"
)

var calendarToken *oauth2.Token

func TestCalendarConfig(t *testing.T) {
	if calendarConfig == nil {
		t.Fail()
	}
}

func TestCalendarService(t *testing.T) {
	ctx := context.Background()
	service, err := NewCalendarService(ctx, calendarToken)
	if err != nil {
		t.Fail()
	}

	_, err = service.CalendarList.List().Do()
	if err != nil {
		t.Fatalf("error fetching calendars: %v", err)
	}
}

func TestMain(m *testing.M) {
	flag.Parse()

	// Load the offline config
	calendarConfig = loadCalendarConfigFromFile("credentials/calendar_offline.json")

	// Load the token
	fixture := "fixtures/gcalendar_token.json"
	f, err := os.Open(fixture)
	if err != nil {
		log.Fatalf("Fixture not found: %v", err)
	}
	defer f.Close()

	calendarToken, err = TokenFromJSON(f)
	if err != nil {
		log.Fatalf("Failed to read fixture: %v", err)
	}

	// Run the tests
	res := m.Run()

	// Re-save the token
	of, err := os.Create(fixture)
	if err != nil {
		log.Fatalf("Failed to recreate fixture: %v", err)
	}
	defer of.Close()

	json, err := TokenToJSON(calendarToken)
	if err != nil {
		log.Fatalf("Failed to convert token to JSON: %v", err)
	}
	of.Write(json)

	os.Exit(res)
}
