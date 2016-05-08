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
	Name    string
	Email   string
	Sent    bool

	Times
}

// NewInvite initializes a new Invite struct.
func NewInvite(companyKey *datastore.Key, name, email string) *Invite {
	invite := Invite{
		Company: companyKey,
		Name:    name,
		Email:   email,
	}
	invite.initTimes()
	return &invite
}

// CreateInvite creates an invite entity in the datastore.  This
// automatically sends out an e-mail invitation on success.
func CreateInvite(
	ctx context.Context,
	companyKey *datastore.Key, name, email string,
) (*Invite, *datastore.Key, error) {

	invite := NewInvite(companyKey, name, email)
	key := datastore.NewIncompleteKey(ctx, inviteKind, companyKey)
	key, err := datastore.Put(ctx, key, invite)
	if err != nil {
		return nil, nil, err
	}

	invite.send(ctx, key.IntID())
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

// DeleteInvite deletes an invite belonging to a Company by its id
func DeleteInvite(
	ctx context.Context,
	companyKey *datastore.Key, inviteID int64,
) error {

	return datastore.Delete(
		ctx,
		datastore.NewKey(ctx, inviteKind, "", inviteID, companyKey),
	)
}

// Send an invite e-mail.
func (invite *Invite) send(ctx context.Context, inviteID int64) {
	// FIXME: Send e-mail (https://sendgrid.com/partners/google)
}
