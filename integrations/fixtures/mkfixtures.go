package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"google.golang.org/api/calendar/v3"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

var calendarConfig = loadCalendarConfig()

func loadCalendarConfig() *oauth2.Config {
	data, err := ioutil.ReadFile("../credentials/calendar_offline.json")
	if err != nil {
		panic(err)
	}

	config, err := google.ConfigFromJSON(data, calendar.CalendarScope)
	if err != nil {
		panic(err)
	}

	return config
}

func calendarTokenFromWeb(config *oauth2.Config) *oauth2.Token {
	authURL := config.AuthCodeURL("state-token", oauth2.AccessTypeOffline)
	fmt.Printf("Go to the following link in your browser then type the authorization code: \n%v\n", authURL)

	var code string
	if _, err := fmt.Scan(&code); err != nil {
		log.Fatalf("Unable to read authorization code %v", err)
	}

	tok, err := config.Exchange(oauth2.NoContext, code)
	if err != nil {
		log.Fatalf("Unable to retrieve token from web %v", err)
	}
	return tok
}

func main() {
	calendarToken := calendarTokenFromWeb(calendarConfig)
	f, err := os.Create("gcalendar_token.json")
	if err != nil {
		log.Fatalf("Cannot create fixture %v", err)
	}

	err = json.NewEncoder(f).Encode(calendarToken)
	if err != nil {
		log.Fatalf("Failed to encode fixture %v", err)
	}

	defer f.Close()
}
