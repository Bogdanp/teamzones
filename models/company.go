package models

import "google.golang.org/appengine/datastore"

type Profile struct {
	Logo           string
	Phone          string
	Fax            string
	AddressStreet1 string
	AddressStreet2 string
	City           string
	State          string
	ZipCode        string
	Country        string
}

type Company struct {
	Name      string
	Subdomain string

	Profile
	Times
}

func NewCompany() *Company {
	company := Company{}
	company.initTimes()
	return &company
}

func (c *Company) Load(p []datastore.Property) error {
	return datastore.LoadStruct(c, p)
}

func (c *Company) Save() ([]datastore.Property, error) {
	c.updateTimes()

	return datastore.SaveStruct(c)
}
