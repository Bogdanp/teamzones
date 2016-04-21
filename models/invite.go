package models

import (
	"golang.org/x/net/context"
	"google.golang.org/appengine/datastore"
)

const (
	inviteKind = "Invite"
)

// Invite represents an individual invitation that is sent out to a
// User via e-mail.  Invites allow said users to join teams.
type Invite struct {
	Company *datastore.Key
	Email   string

	Times
}

// NewInvite initializes a new Invite struct.
func NewInvite(companyKey *datastore.Key, email string) *Invite {
	invite := Invite{
		Company: companyKey,
		Email:   email,
	}
	invite.initTimes()
	return &invite
}

// CreateInvite creates an invite entity in the datastore.
func CreateInvite(
	ctx context.Context,
	companyKey *datastore.Key, email string,
) (*Invite, *datastore.Key, error) {

	invite := NewInvite(companyKey, email)
	key := datastore.NewIncompleteKey(ctx, inviteKind, companyKey)
	key, err := datastore.Put(ctx, key, invite)
	if err != nil {
		return nil, nil, err
	}

	return invite, key, nil
}

// GetInvite gets an invite belonging to a Company by its id.
func GetInvite(
	ctx context.Context,
	companyKey *datastore.Key, inviteID int64,
) (*Invite, error) {

	invite := Invite{}
	inviteKey := datastore.NewKey(ctx, inviteKind, "", inviteID, companyKey)
	if err := datastore.Get(ctx, inviteKey, &invite); err != nil {
		return nil, err
	}

	return &invite, nil
}
