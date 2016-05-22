package handlers

import "errors"

// Plan represents a subscription plan.
type Plan struct {
	ID      string
	Label   string
	Price   int
	Cycle   string
	Members int
}

var (
	// ErrPlanNotFound is the error that is returned when a
	// subscription plan cannot be found in the global configuration.
	ErrPlanNotFound = errors.New("unknown subscription plan")
)

func lookupPlan(planID string) (*Plan, error) {
	for _, plan := range config.Plans {
		if plan.ID == planID {
			return &plan, nil
		}
	}

	return nil, ErrPlanNotFound
}
