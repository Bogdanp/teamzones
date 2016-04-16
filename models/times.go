package models

import "time"

// Times are used to extend models with metadata about when they were
// created and last updated.  These are never saved to datastore by
// themselves.
type Times struct {
	CreatedAt time.Time
	UpdatedAt time.Time
}

func (t *Times) initTimes() {
	now := time.Now()

	t.CreatedAt = now
	t.UpdatedAt = now
}

func (t *Times) updateTimes() {
	t.UpdatedAt = time.Now()
}
