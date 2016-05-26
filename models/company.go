package models

import (
	"teamzones/integrations"
	"time"

	"github.com/lionelbarrow/braintree-go"
	"github.com/qedus/nds"
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

	// Customer-provided
	SubscriptionPlanID     string `json:"-"`
	SubscriptionFirstName  string `json:"-"`
	SubscriptionLastName   string `json:"-"`
	SubscriptionAddress1   string `json:"-"`
	SubscriptionAddress2   string `json:"-"`
	SubscriptionCity       string `json:"-"`
	SubscriptionRegion     string `json:"-"` // or state
	SubscriptionPostalCode string `json:"-"` // or zip
	SubscriptionCountry    string `json:"-"` // necessary for VAT
	SubscriptionVATID      string `json:"-"` // VAT not charged if provided
	SubscriptionIP         string `json:"-"` // necessary for VAT

	// Braintree-provided
	SubscriptionID         string    `json:"-"`
	SubscriptionCustomerID string    `json:"-"`
	SubscriptionStatus     string    `json:"-"` // never Expired or Unrecognized
	SubscriptionValidUntil time.Time `json:"-"` // used when subscription status is canceled or past due

	Times
}

// NewCompany creates an empty Company, ensuring that its Time
// properties are initialized correctly.
func NewCompany(name, subdomain string) *Company {
	company := Company{
		Name:               name,
		Subdomain:          subdomain,
		SubscriptionPlanID: "free",
		SubscriptionStatus: braintree.SubscriptionStatusPending,
	}
	company.initTimes()
	return &company
}

// NewCompanyKey creates datastore keys for companies.
func NewCompanyKey(ctx context.Context, subdomain string) *datastore.Key {
	return datastore.NewKey(ctx, companyKind, subdomain, 0, nil)
}

// GetCompany returns a company by its subdomain.
func GetCompany(ctx context.Context, subdomain string) (*Company, error) {
	var company Company
	if err := nds.Get(ctx, NewCompanyKey(ctx, subdomain), &company); err != nil {
		return nil, err
	}

	return &company, nil
}

// GetCompanyBySubID searches for a Company by its subscription id.
func GetCompanyBySubID(ctx context.Context, subID string) (*Company, error) {
	var company Company

	_, err := datastore.
		NewQuery(companyKind).
		Filter("SubscriptionID=", subID).
		Run(ctx).
		Next(&company)
	if err != nil {
		return nil, err
	}

	return &company, nil
}

// GetCompanySize returns the number of members a given Company has.
func GetCompanySize(ctx context.Context, company *datastore.Key) (int, error) {
	return datastore.NewQuery(userKind).
		Ancestor(company).
		Count(ctx)

}

// CancelSubscription marks the Company's subscription as canceled.
func (c *Company) CancelSubscription(ctx context.Context, sub *braintree.Subscription) error {

	t, err := integrations.ParseBraintreeDate(sub.BillingPeriodEndDate)
	if err != nil {
		return err
	}

	return nds.RunInTransaction(ctx, func(ctx context.Context) error {
		company, err := GetCompany(ctx, c.Subdomain)
		if err != nil {
			return err
		}

		company.SubscriptionStatus = braintree.SubscriptionStatusCanceled
		company.SubscriptionValidUntil = t
		_, err = company.Put(ctx)
		return err
	}, nil)
}

// MarkSubscriptionPastDue marks the Company's subscription as being past due.
func (c *Company) MarkSubscriptionPastDue(ctx context.Context, sub *braintree.Subscription) error {

	t, err := integrations.ParseBraintreeDate(sub.BillingPeriodEndDate)
	if err != nil {
		return err
	}

	return nds.RunInTransaction(ctx, func(ctx context.Context) error {
		company, err := GetCompany(ctx, c.Subdomain)
		if err != nil {
			return err
		}

		company.SubscriptionStatus = braintree.SubscriptionStatusPastDue
		company.SubscriptionValidUntil = t
		_, err = company.Put(ctx)
		return err
	}, nil)
}

// MarkSubscriptionActive marks the Company's subscription as being
// active.
func (c *Company) MarkSubscriptionActive(ctx context.Context, sub *braintree.Subscription) error {

	t, err := integrations.ParseBraintreeDate(sub.BillingPeriodEndDate)
	if err != nil {
		return err
	}

	return nds.RunInTransaction(ctx, func(ctx context.Context) error {
		company, err := GetCompany(ctx, c.Subdomain)
		if err != nil {
			return err
		}

		company.SubscriptionStatus = braintree.SubscriptionStatusActive
		company.SubscriptionValidUntil = t
		_, err = company.Put(ctx)
		return err
	}, nil)
}

// ValidPlans returns a slice of plans that are valid for the Company given its size.
func (c *Company) ValidPlans(ctx context.Context) ([]integrations.BraintreePlan, error) {
	var plans []integrations.BraintreePlan

	p, err := integrations.LookupBraintreePlan(c.SubscriptionPlanID)
	if err != nil {
		return plans, err
	}

	ps := integrations.BraintreePlans()
	teamSize, err := GetCompanySize(ctx, c.Key(ctx))
	if err != nil {
		return plans, err
	}

	for _, plan := range ps {
		if plan.ID != "free" && p.Cycle == plan.Cycle && plan.Members >= teamSize {
			plans = append(plans, plan)
		}
	}

	return plans, nil
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

// Put saves the Company to Datastore.
func (c *Company) Put(ctx context.Context) (*datastore.Key, error) {
	return nds.Put(ctx, c.Key(ctx), c)
}
