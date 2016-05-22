package integrations

import (
	"errors"
	"strings"
	"teamzones/utils"

	"github.com/lionelbarrow/braintree-go"
	"golang.org/x/net/context"

	"google.golang.org/appengine"
	"google.golang.org/appengine/urlfetch"
)

// BraintreePlan represents a subscription plan.
type BraintreePlan struct {
	ID      string
	Label   string
	Price   int
	Cycle   string
	Members int
}

// BraintreeConfiguration represents the data necessary to communicate
// with the Braintree API.
type BraintreeConfiguration struct {
	Environment braintree.Environment
	MerchantID  string `yaml:"merchant_id"`
	PublicKey   string `yaml:"public_key"`
	PrivateKey  string `yaml:"private_key"`

	Plans []BraintreePlan
}

var (
	// ErrPlanNotFound is the error that is returned when a
	// subscription plan cannot be found in the global configuration.
	ErrPlanNotFound = errors.New("unknown subscription plan")
)

var braintreeConfig = loadBraintreeConfig()

func loadBraintreeConfig() *BraintreeConfiguration {
	var filename string
	if strings.Contains(appengine.ServerSoftware(), "Development") {
		filename = "credentials/braintree_sandbox.yaml"
	} else {
		filename = "credentials/braintree_production.yaml"
	}

	c := &BraintreeConfiguration{}
	utils.LoadYAML(filename, c)
	utils.LoadYAML("data/plans.yaml", c)
	return c
}

// NewBraintreeService returns a new Braintree API client.
func NewBraintreeService(ctx context.Context) *braintree.Braintree {
	bt := braintree.New(
		braintreeConfig.Environment,
		braintreeConfig.MerchantID,
		braintreeConfig.PublicKey,
		braintreeConfig.PrivateKey,
	)
	bt.HttpClient = urlfetch.Client(ctx)
	return bt
}

// BraintreeSubscribe creates subscribes a new customer in Braintree.
func BraintreeSubscribe(
	ctx context.Context,
	nonce, planID, subdomain, name, email string,
) (*braintree.Customer, *braintree.Subscription, error) {

	bt := NewBraintreeService(ctx)
	customer, err := bt.Customer().Create(&braintree.Customer{})
	if err != nil {
		return nil, nil, err
	}

	card, err := bt.CreditCard().Create(&braintree.CreditCard{
		CustomerId:         customer.Id,
		PaymentMethodNonce: nonce,
		Options: &braintree.CreditCardOptions{
			VerifyCard: true,
		},
	})
	if err != nil {
		return nil, nil, err
	}

	subscription, err := bt.Subscription().Create(&braintree.Subscription{
		PlanId:             planID,
		PaymentMethodToken: card.Token,
	})
	if err != nil {
		return nil, nil, err
	}

	return customer, subscription, nil
}

// BraintreePlans returns the list of defined subscription plans.
func BraintreePlans() []BraintreePlan {
	return braintreeConfig.Plans
}

// LookupBraintreePlan looks up plans by their ID.
func LookupBraintreePlan(planID string) (*BraintreePlan, error) {
	for _, plan := range braintreeConfig.Plans {
		if plan.ID == planID {
			return &plan, nil
		}
	}

	return nil, ErrPlanNotFound
}
