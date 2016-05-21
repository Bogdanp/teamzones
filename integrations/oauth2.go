package integrations

import (
	"bytes"
	"encoding/json"
	"io"

	"github.com/pkg/errors"
	"golang.org/x/oauth2"
)

// TokenToJSON converts and OAuth2 Token instance to a JSON bytestring.
func TokenToJSON(token *oauth2.Token) ([]byte, error) {
	var buf bytes.Buffer

	err := json.NewEncoder(&buf).Encode(token)
	if err != nil {
		return nil, errors.Wrap(err, "failed to encode oauth2 token")
	}

	return buf.Bytes(), nil
}

// TokenFromJSON converts a Reader of JSON to an OAuth2 Token.
func TokenFromJSON(buf io.Reader) (*oauth2.Token, error) {
	token := &oauth2.Token{}
	err := json.NewDecoder(buf).Decode(&token)
	if err != nil {
		return nil, errors.Wrap(err, "failed to decode oauth2 token from json")
	}

	return token, nil
}
