package models

import (
	"github.com/qedus/nds"
	"golang.org/x/net/context"
	"golang.org/x/oauth2"
	"google.golang.org/appengine/datastore"
)

const (
	oauth2TokenKind = "OAuth2Token"
)

const (
	// OAuth2GCalendar is the type of OAuth2Token used for the
	// GCalendar integration.
	OAuth2GCalendar = "gcalendar"
)

// OAuth2Token is a Datastore wrapper around an oauth2.Token value.
type OAuth2Token struct {
	Company *datastore.Key
	User    *datastore.Key

	Kind  string
	Token oauth2.Token

	Times
}

// NewOAuth2Token initializes a new OAuth2Token struct.
func NewOAuth2Token(company, user *datastore.Key, kind string) *OAuth2Token {
	tok := &OAuth2Token{
		Company: company,
		User:    user,
		Kind:    kind,
	}
	tok.initTimes()

	return tok
}

// NewOAuth2TokenKey returns a new incomplete key for an OAuth2Token
// belonging to the given user.
func NewOAuth2TokenKey(ctx context.Context, user *datastore.Key) *datastore.Key {
	return datastore.NewIncompleteKey(ctx, oauth2TokenKind, user)
}

// CreateOAuth2Token stores and returns a new OAuth2Token.
func CreateOAuth2Token(
	ctx context.Context,
	company, user *datastore.Key, kind string,
) (*datastore.Key, *OAuth2Token, error) {

	tok := NewOAuth2Token(company, user, kind)
	key := NewOAuth2TokenKey(ctx, user)
	key, err := nds.Put(ctx, key, tok)
	if err != nil {
		return nil, nil, err
	}

	return key, tok, nil
}

// GetOAuth2Token retrieves an OAuth2Token by its id.
func GetOAuth2Token(
	ctx context.Context,
	user *datastore.Key, tokID int64,
) (*datastore.Key, *OAuth2Token, error) {
	var tok OAuth2Token

	key := datastore.NewKey(ctx, oauth2TokenKind, "", tokID, user)
	if err := nds.Get(ctx, key, &tok); err != nil {
		return nil, nil, err
	}

	return key, &tok, nil
}
