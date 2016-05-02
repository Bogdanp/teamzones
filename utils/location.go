package utils

import (
	"log"

	"google.golang.org/appengine/urlfetch"

	"golang.org/x/net/context"

	"googlemaps.github.io/maps"
)

// GetTimezone uses the Google Maps API to retrieve the timezone ID
// for a given latitude and longitude pair (comma-separated floats).
func GetTimezone(ctx context.Context, location string) chan string {
	client, err := maps.NewClient(
		maps.WithHTTPClient(urlfetch.Client(ctx)),
		maps.WithAPIKey("AIzaSyANTHWnaqELwSaHNTMLSqpAPk3LHA10gws"),
	)
	if err != nil {
		log.Fatalf("GetTimezone failed to create maps client: %s", err)
	}

	timezoneID := make(chan string)
	go func() {
		ll, err := maps.ParseLatLng(location)
		if err != nil {
			log.Fatalf("GetTimezone failed to parse location %q: %s", location, err)
		}

		result, err := client.Timezone(context.Background(), &maps.TimezoneRequest{
			Location: &ll,
		})
		if err != nil {
			log.Fatalf("GetTimezone failed to retrieve timezone: %s", err)
		}

		timezoneID <- result.TimeZoneID
		close(timezoneID)
	}()

	return timezoneID
}
