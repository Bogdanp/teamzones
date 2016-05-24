package utils

import (
	"testing"

	"golang.org/x/net/context"
)

func TestCheckVAT(t *testing.T) {
	// TODO: Add passing case
	cases := []struct {
		VATID string
		Valid bool
	}{
		{"a", false},
		{"RO    ", false},
		{"AT0000", false},
		{"RO1234", false},
	}

	for _, test := range cases {
		r := CheckVAT(context.Background(), test.VATID)
		if r != test.Valid {
			t.Fatalf("%v is %v, expected %v", test.VATID, r, test.Valid)
		}
	}
}
