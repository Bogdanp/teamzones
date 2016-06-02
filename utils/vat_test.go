package utils

import (
	"net/http"
	"testing"

	"google.golang.org/appengine"
	"google.golang.org/appengine/aetest"
)

func TestCheckVAT(t *testing.T) {
	// aetest.NewContext doesn't seem to satisfy urlfetch
	inst, _ := aetest.NewInstance(nil)
	defer inst.Close()
	req, _ := inst.NewRequest(http.MethodGet, "/", nil)
	ctx := appengine.NewContext(req)

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
