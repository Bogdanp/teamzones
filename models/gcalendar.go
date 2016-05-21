package models

import (
	"teamzones/integrations"

	"golang.org/x/net/context"

	"google.golang.org/appengine/datastore"
)

const (
	calendarDataKind = "GCalendarData"
)

const (
	// GCalendarStatusLoading is the status used while GCalendarData is
	// being processed in the background.
	GCalendarStatusLoading = "loading"
	// GCalendarStatusDone is the status used when GCalendarData is
	// ready for use.
	GCalendarStatusDone = "done"
)

// GCalendarData represents a user's cached Google Calendar information.
type GCalendarData struct {
	Company *datastore.Key `json:"-"`
	User    *datastore.Key `json:"-"`

	Status    string                  `json:"status"`
	DefaultID string                  `json:"defaultId"`
	Calendars []integrations.Calendar `json:"calendars"`

	Times
}

// NewGCalendarData initializes a new GCalendarData struct.
func NewGCalendarData(company *datastore.Key, user *datastore.Key) *GCalendarData {
	data := GCalendarData{
		Company: company,
		User:    user,
		Status:  GCalendarStatusDone,
	}
	data.initTimes()
	return &data
}

// NewGCalendarDataKey creates a new Datastore key with a specific id
// belonging to the given user.
func NewGCalendarDataKey(ctx context.Context, user *datastore.Key, id string) *datastore.Key {
	return datastore.NewKey(ctx, calendarDataKind, id, 0, user)
}

// Load tells datastore how to deserialize GCalendarData.
func (d *GCalendarData) Load(p []datastore.Property) error {
	return datastore.LoadStruct(d, p)
}

// Save tells datastore how to serialize GCalendarData.
func (d *GCalendarData) Save() ([]datastore.Property, error) {
	d.updateTimes()

	return datastore.SaveStruct(d)
}
