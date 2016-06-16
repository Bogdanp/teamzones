package models

import (
	"errors"
	"teamzones/utils"

	"github.com/lionelbarrow/braintree-go"
	"github.com/qedus/nds"

	"golang.org/x/net/context"

	"google.golang.org/appengine/datastore"
)

var (
	// ErrTransactionNotInvoice is returned when a requested
	// transaction is not an invoice.
	ErrTransactionNotInvoice = errors.New("transaction is not an invoice")
)

const (
	transactionKind          = "Transaction"
	transactionInvoiceStatus = "settled"
)

// Transaction represents a successful payment.
type Transaction struct {
	Company *datastore.Key `json:"-"`

	SubscriptionID         string `json:"subscriptionId"`
	SubscriptionPlanID     string `json:"subscriptionPlanId"`
	SubscriptionCountry    string `json:"subscriptionCountry"`
	SubscriptionVATID      string `json:"subscriptionVatId"`
	SubscriptionVATPercent int    `json:"subscriptionVatPercent"`

	TransactionID     string `json:"transactionId"`
	TransactionAmount int64  `json:"transactionAmount"`
	TransactionType   string `json:"transactionType"`
	TransactionStatus string `json:"transactionStatus"`

	Times
}

// SyncTransactions synchronizes transactions off of a Subscription object.
func SyncTransactions(
	ctx context.Context,
	company *Company,
	subscription *braintree.Subscription,
) error {

	companyKey := company.Key(ctx)

	// TODO: Add 6-month cutoff.
	for _, btTransaction := range subscription.Transactions.Transaction {
		var transaction Transaction

		key := datastore.NewKey(ctx, transactionKind, btTransaction.Id, 0, companyKey)
		if err := nds.Get(ctx, key, &transaction); err == datastore.ErrNoSuchEntity {
			transaction.Company = companyKey
			transaction.SubscriptionID = subscription.Id
			transaction.SubscriptionPlanID = subscription.PlanId
			transaction.SubscriptionCountry = company.SubscriptionCountry
			transaction.SubscriptionVATID = company.SubscriptionVATID
			if company.SubscriptionVATID == "" {
				transaction.SubscriptionVATPercent = utils.LookupVAT(company.SubscriptionCountry)
			}
		}

		transaction.TransactionID = btTransaction.Id
		transaction.TransactionType = btTransaction.Type
		transaction.TransactionStatus = btTransaction.Status
		transaction.TransactionAmount = btTransaction.Amount.Unscaled

		transaction.CreatedAt = *btTransaction.CreatedAt
		transaction.UpdatedAt = *btTransaction.UpdatedAt
		if _, err := nds.Put(ctx, key, &transaction); err != nil {
			return err
		}
	}

	return nil
}

// FindInvoices returns a query that finds all settled transactions belonging to a company.
func FindInvoices(company *datastore.Key) *datastore.Query {
	return datastore.NewQuery(transactionKind).
		Ancestor(company).
		Filter("TransactionType=", "sale").
		Filter("TransactionStatus=", transactionInvoiceStatus).
		Order("-CreatedAt")
}

// GetInvoice gets an invoice by id.
func GetInvoice(ctx context.Context, company *datastore.Key, id string) (*Transaction, error) {
	t := &Transaction{}
	err := nds.Get(ctx, datastore.NewKey(ctx, transactionKind, id, 0, company), t)
	if err != nil {
		return nil, err
	}

	if !t.isInvoice() {
		return nil, ErrTransactionNotInvoice
	}

	return t, nil
}

func (t *Transaction) isInvoice() bool {
	return t.TransactionType == "sale" && t.TransactionStatus == transactionInvoiceStatus
}
