package integrations

import (
	"log"
	"os"
	"teamzones/utils"
	"testing"

	"golang.org/x/oauth2"
)

var calendarToken *oauth2.Token

func init() {
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
}

func TestCalendarConfig(t *testing.T) {
	if calendarConfig == nil {
		t.Fail()
	}
}

func TestCalendarService(t *testing.T) {
	ctx, done, _ := utils.AEContext()
	defer done()

	service, err := NewCalendarService(ctx, calendarToken)
	if err != nil {
		t.Fatalf("error creating service: %v", err)
	}

	_, err = service.CalendarList.List().Do()
	if err != nil {
		t.Fatalf("error fetching calendars: %v", err)
	}
}

func TestFetchUserCalendars(t *testing.T) {
	ctx, done, _ := utils.AEContext()
	defer done()

	primaryID, calendars, err := FetchUserCalendars(ctx, calendarToken)
	if err != nil {
		t.Fatalf("error fetching calendars: %v", err)
	}

	if primaryID == "" {
		t.Fatalf("must have a primary calendar")
	}

	if len(calendars) < 1 {
		t.Fatalf("must have at least one writable calendar")
	}
}
