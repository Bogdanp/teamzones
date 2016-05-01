package models

import (
	"golang.org/x/net/context"
	"google.golang.org/appengine/datastore"
)

const (
	companyKind = "Company"
)

// Company is a way to group users in an organization.
type Company struct {
	Name      string `json:"name"`
	Subdomain string `json:"-"`

	Times
}

// NewCompany creates an empty Company, ensuring that its Time
// properties are initialized correctly.
func NewCompany() *Company {
	company := Company{}
	company.initTimes()
	return &company
}

// NewCompanyKey creates datastore keys for companies.
func NewCompanyKey(ctx context.Context, subdomain string) *datastore.Key {
	return datastore.NewKey(ctx, companyKind, subdomain, 0, nil)
}

// Key is a helper function for building a Company's key.
func (c *Company) Key(ctx context.Context) *datastore.Key {
	return NewCompanyKey(ctx, c.Subdomain)
}

// Load tells datastore how to deserialize Companies when reading them.
func (c *Company) Load(p []datastore.Property) error {
	return datastore.LoadStruct(c, p)
}

// Save tells datastore how to serialize Companies when storing them.
// This is used to coordinate Companies' Times.
func (c *Company) Save() ([]datastore.Property, error) {
	c.updateTimes()

	return datastore.SaveStruct(c)
}
