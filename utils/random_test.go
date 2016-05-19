package utils

import "testing"

func TestUUID4GeneratesString(t *testing.T) {
	s := UUID4()
	if len(s) != 36 {
		t.Errorf("invalid uuid4: %q", s)
	}
}
