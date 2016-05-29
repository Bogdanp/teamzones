package models

import (
	"teamzones/utils"

	"github.com/lionelbarrow/braintree-go"
	"github.com/qedus/nds"

	"golang.org/x/net/context"

	"google.golang.org/appengine/datastore"
)

const (
	transactionKind = "Transaction"
)

// Transaction represents a successful payment.
type Transaction struct {
	Company *datastore.Key

	SubscriptionID         string
	SubscriptionPlanID     string
	SubscriptionCountry    string
	SubscriptionVATID      string
	SubscriptionVATPercent int

	TransactionID     string
	TransactionAmount int64
	TransactionType   string
	TransactionStatus string

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
