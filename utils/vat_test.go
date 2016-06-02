package utils

import "testing"

func TestCheckVAT(t *testing.T) {
	ctx, done, _ := AEContext()
	defer done()

	cases := []struct {
		VATID string
		Valid bool
	}{
		{"a", false},
		{"RO    ", false},
		{"AT0000", false},
		{"RO1234", false},
		{"DE146269081", true},
	}

	for _, test := range cases {
		r := CheckVAT(ctx, test.VATID)
		if r != test.Valid {
			t.Fatalf("%v is %v, expected %v", test.VATID, r, test.Valid)
		}
	}
}
