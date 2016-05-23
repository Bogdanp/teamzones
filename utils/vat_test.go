package utils

import (
	"testing"

	"golang.org/x/net/context"
)

func TestCheckVAT(t *testing.T) {
	tests := []struct {
		VATID string
		Valid bool
	}{
		{"a", false},
		{"RO1234", false},
	}

	for _, test := range tests {
		r := CheckVAT(context.Background(), test.VATID)
		if r != test.Valid {
			t.Fatalf("%v is %v, expected %v", test.VATID, r, test.Valid)
		}
	}
}
