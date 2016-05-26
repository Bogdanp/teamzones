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
	receiptKind = "Receipt"
)

// Receipt represents a successful payment.
type Receipt struct {
	Company *datastore.Key `json:"-"`

	SubscriptionID     string
	SubscriptionPlanID string
	SubscriptionVATID  string

	TransactionID     string
	TransactionAmount int64

	BillingPeriodStart time.Time
	BillingPeriodEnd   time.Time

	Times
}

// NewReceipt creates an empty Receipt, ensuring that its Time
// properties are initialized correctly.
func NewReceipt() *Receipt {
	receipt := Receipt{}
	receipt.initTimes()
	return &receipt
}

// NewReceiptKey creates datastore keys for Receipts.
func NewReceiptKey(ctx context.Context, company *datastore.Key, transID string) *datastore.Key {
	return datastore.NewKey(ctx, receiptKind, transID, 0, company)
}

// CreateReceipt creates a new receipt.
func CreateReceipt(
	ctx context.Context,
	company *Company,
	subscription *braintree.Subscription,
) (*Receipt, error) {

	st, _ := integrations.ParseBraintreeDate(subscription.BillingPeriodStartDate)
	et, _ := integrations.ParseBraintreeDate(subscription.BillingPeriodEndDate)

	// According to BT's docs the most recent transaction should
	// always be at index 0 so this _should_ be safe.
	transaction := subscription.Transactions.Transaction[0]
	companyKey := company.Key(ctx)
	key := NewReceiptKey(ctx, companyKey, transaction.Id)
	receipt := NewReceipt()
	receipt.Company = companyKey
	receipt.SubscriptionID = subscription.Id
	receipt.SubscriptionPlanID = subscription.PlanId
	receipt.SubscriptionVATID = company.SubscriptionVATID
	receipt.TransactionID = transaction.Id
	receipt.TransactionAmount = transaction.Amount.Unscaled
	receipt.BillingPeriodStart = st
	receipt.BillingPeriodEnd = et
	if _, err := nds.Put(ctx, key, receipt); err != nil {
		return nil, err
	}

	return receipt, nil
}

// Load tells datastore how to deserialize Receipts when reading them.
func (r *Receipt) Load(p []datastore.Property) error {
	return datastore.LoadStruct(r, p)
}

// Save tells datastore how to serialize Receipts when storing them.
// This is used to coordinate Receipts' Times.
func (r *Receipt) Save() ([]datastore.Property, error) {
	r.updateTimes()

	return datastore.SaveStruct(r)
}
