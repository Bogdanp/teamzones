package integrations

import (
	"strings"
	"teamzones/utils"

	"github.com/lionelbarrow/braintree-go"
	"golang.org/x/net/context"

	"google.golang.org/appengine"
	"google.golang.org/appengine/urlfetch"
)

// BraintreeConfiguration represents the data necessary to communicate
// with the Braintree API.
type BraintreeConfiguration struct {
	Environment braintree.Environment
	MerchantID  string `yaml:"merchant_id"`
	PublicKey   string `yaml:"public_key"`
	PrivateKey  string `yaml:"private_key"`
}

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
	return c
}

// NewBraintreeService returns a new Braintree API client.
func NewBraintreeService(ctx context.Context) *braintree.Braintree {
	c := braintree.New(
		braintreeConfig.Environment,
		braintreeConfig.MerchantID,
		braintreeConfig.PublicKey,
		braintreeConfig.PrivateKey,
	)
	c.HttpClient = urlfetch.Client(ctx)
	return c
}
