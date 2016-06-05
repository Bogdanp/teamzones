package models

import (
	"time"

	"github.com/qedus/nds"

	"golang.org/x/net/context"

	"google.golang.org/appengine/datastore"
)

const (
	meetingKind = "Meeting"
)

// Meeting represents a scheduled Google Calendar event involving
// multiple people.  Meetings are nested under their owners.
type Meeting struct {
	StartTime time.Time `json:"startTime"`
	EndTime   time.Time `json:"endTime"`

	Summary     string   `json:"summary"`
	Description string   `json:"description"`
	Attendees   []string `json:"attendees"`

	EventID string `json:"eventId"`

	Times
}

// NewMeeting creates a new meeting, ensuring its times are correctly
// initialized.
func NewMeeting() *Meeting {
	meeting := Meeting{}
	meeting.initTimes()
	return &meeting
}

// NewMeetingKey creates a new Meeting key belonging to a User.
func NewMeetingKey(ctx context.Context, user *datastore.Key) *datastore.Key {
	return datastore.NewIncompleteKey(ctx, meetingKind, user)
}

// Load tells datastore how to deserialize Meetings when reading them.
func (m *Meeting) Load(p []datastore.Property) error {
	return datastore.LoadStruct(m, p)
}

// Save tells datastore how to serialize Meetings before storing them.
// This is used to keep Meetings' Times up to date.
func (m *Meeting) Save() ([]datastore.Property, error) {
	m.updateTimes()

	return datastore.SaveStruct(m)
}

// Put saves the Meeting to Datastore.
func (m *Meeting) Put(ctx context.Context, k *datastore.Key) (*datastore.Key, error) {
	return nds.Put(ctx, k, m)
}
