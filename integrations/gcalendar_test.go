package integrations

import (
	"encoding/json"
	"log"
	"os"
	"testing"

	"google.golang.org/api/calendar/v3"

	"golang.org/x/net/context"
	"golang.org/x/oauth2"
)

var calendarToken *oauth2.Token

func init() {
	fixture := "fixtures/gcalendar_token.json"
	f, err := os.Open(fixture)
	if err != nil {
		log.Fatalf("Fixture not found: %v", err)
	}

	calendarToken = &oauth2.Token{}
	err = json.NewDecoder(f).Decode(calendarToken)
	if err != nil {
		log.Fatalf("Failed to read fixture: %v", err)
	}

	defer f.Close()
}

func TestCalendarConfig(t *testing.T) {
	if calendarConfig == nil {
		t.Fail()
	}
}

func TestCalendarService(t *testing.T) {
	ctx := context.TODO()
	service, err := NewCalendarService(ctx, calendarToken)
	if err != nil {
		t.Fail()
	}

	listService := calendar.NewCalendarListService(service)
	_, err = listService.List().Do()
	if err != nil {
		t.Fail()
	}
}
