package utils

import (
	"github.com/pkg/errors"

	"google.golang.org/appengine/urlfetch"

	"golang.org/x/net/context"

	"googlemaps.github.io/maps"
)

// GetTimezone uses the Google Maps API to retrieve the timezone ID
// for a given latitude and longitude pair (comma-separated floats).
func GetTimezone(ctx context.Context, location string) (string, error) {
	client, err := maps.NewClient(
		maps.WithHTTPClient(urlfetch.Client(ctx)),
		maps.WithAPIKey("AIzaSyANTHWnaqELwSaHNTMLSqpAPk3LHA10gws"),
	)
	if err != nil {
		return "", errors.Wrap(err, "failed to create maps client")
	}

	ll, err := maps.ParseLatLng(location)
	if err != nil {
		return "", errors.Wrapf(err, "failed to parse location %q", location)
	}

	result, err := client.Timezone(context.Background(), &maps.TimezoneRequest{
		Location: &ll,
	})
	if err != nil {
		return "", errors.Wrap(err, "failed to retrieve timezone")
	}

	return result.TimeZoneID, nil
}
