package integrations

import (
	"errors"
	"fmt"
	"math"
	"strings"
	"teamzones/utils"
	"time"

	// Fixes gocode completion
	braintree "github.com/lionelbarrow/braintree-go"

	"golang.org/x/net/context"

	"google.golang.org/appengine"
	"google.golang.org/appengine/urlfetch"
)

// BraintreePlan represents a subscription plan.
type BraintreePlan struct {
	ID      string
	Label   string
	Price   int
	MPrice  int
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

// BraintreeSubscribe subscribes a new customer in Braintree.
func BraintreeSubscribe(
	ctx context.Context,
	nonce, planID string, vat int,
	subdomain, firstName, lastName, email string,
) (*braintree.Customer, *braintree.Subscription, error) {

	bt := NewBraintreeService(ctx)
	customer, err := bt.Customer().Create(&braintree.Customer{
		FirstName: firstName,
		LastName:  lastName,
		Email:     email,
	})
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

	plan, _ := LookupBraintreePlan(planID)
	subData := braintree.Subscription{
		PlanId:             planID,
		PaymentMethodToken: card.Token,
	}
	if vat != 0 {
		price := int(math.Floor(float64(vat)/100*float64(plan.Price))) + plan.Price
		subData.Price = braintree.NewDecimal(int64(price), 2)
	} else {
		subData.Price = braintree.NewDecimal(int64(plan.Price), 2)
	}

	subscription, err := bt.Subscription().Create(&subData)
	if err != nil {
		return nil, nil, err
	}

	return customer, subscription, nil
}

// BraintreeCancelSubscription cancels a Company's subscription.
func BraintreeCancelSubscription(
	ctx context.Context, subID string,
) (*braintree.Subscription, error) {

	bt := NewBraintreeService(ctx)
	sub, err := bt.Subscription().Cancel(subID)
	if err != nil {
		return nil, err
	}

	return sub, nil
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

// ParseBraintreeDate converts a Braintree date string to a time.Time.
func ParseBraintreeDate(date string) (time.Time, error) {
	t, err := time.Parse("2006-01-02", date)
	if err != nil {
		return time.Time{}, nil
	}

	return t, nil
}

// DollarPrice returns the formatted price of a plan.
func (p *BraintreePlan) DollarPrice() string {
	return fmt.Sprintf("$%d.%02d", p.Price/100, p.Price%100)
}

// DollarMPrice returns the formatted monthly price of a plan.
func (p *BraintreePlan) DollarMPrice() string {
	return fmt.Sprintf("$%d.%02d", p.MPrice/100, p.MPrice%100)
}
