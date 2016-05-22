package models

import (
	"errors"
	"time"

	"github.com/qedus/nds"

	"golang.org/x/net/context"
	"google.golang.org/appengine/datastore"
)

var (
	// ErrInviteExpired is returned when attempting to retrieve a Bulk
	// invite that has expired.
	ErrInviteExpired = errors.New("Bulk invite has expired.")
)

const (
	// BulkInviteTTL is the maximum amount of time that a bulk invite can be valid for.
	BulkInviteTTL = 2 * time.Hour

	inviteKind = "Invite"
)

// Invite represents an individual invitation that is sent out to a
// User via e-mail.  Invites allow said users to join teams.
type Invite struct {
	Company *datastore.Key
	Name    string
	Email   string
	Sent    bool
	Bulk    bool

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

// NewBulkInvite initializes an Invite struct that can be used to
// invite multiple team members.
func NewBulkInvite(companyKey *datastore.Key) *Invite {
	invite := Invite{
		Company: companyKey,
		Bulk:    true,
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
	key, err := nds.Put(ctx, key, invite)
	if err != nil {
		return nil, nil, err
	}

	invite.send(ctx, key.IntID())
	return invite, key, nil
}

// CreateBulkInvite creates a bulk invite entity in the datastore.
func CreateBulkInvite(
	ctx context.Context,
	companyKey *datastore.Key,
) (*Invite, *datastore.Key, error) {

	invite := NewBulkInvite(companyKey)
	key := datastore.NewIncompleteKey(ctx, inviteKind, companyKey)
	key, err := nds.Put(ctx, key, invite)
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
	if err := nds.Get(ctx, inviteKey, &invite); err != nil {
		return nil, err
	}

	if invite.Bulk && time.Now().Sub(invite.CreatedAt) >= BulkInviteTTL {
		return nil, ErrInviteExpired
	}

	return &invite, nil
}

// DeleteInvite deletes an invite belonging to a Company by its id
func DeleteInvite(
	ctx context.Context,
	companyKey *datastore.Key, inviteID int64,
) error {

	return nds.Delete(
		ctx,
		datastore.NewKey(ctx, inviteKind, "", inviteID, companyKey),
	)
}

func (invite *Invite) send(ctx context.Context, inviteID int64) {
	// FIXME: Send e-mail (https://sendgrid.com/partners/google)
}
