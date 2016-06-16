package forms

import (
	"net/http"
	"strings"
	"testing"
)

func TestBindJSON(t *testing.T) {
	t.Parallel()

	var data struct {
		Name  string `json:"name" validate:"MinLength:3,MaxLength:50"`
		Email string `json:"email" validate:"Email"`
	}

	cases := []struct {
		input string
		pass  bool
	}{
		{`{"name":"Bogdan Popa","email":"bogdan@defn.io"}`, true},
		{`{"name":"Bo","email":"bogdan@defn.io"}`, false},
		{`{"name":"Bogdan","email":"bogdan"}`, false},
		{`{"name":"","email":""}`, false},
	}

	for i, test := range cases {
		req, err := http.NewRequest("GET", "http://example.com", strings.NewReader(test.input))
		if err != nil {
			t.Fatal(err)
		}

		err = BindJSON(req, &data)
		if test.pass && err != nil {
			t.Fatalf("expected test %d %q to pass but it failed: %v", i, test.input, err)
		} else if !test.pass && err == nil {
			t.Fatalf("expected test %d %q to fail but it passed", i, test.input)
		}
	}
}

func TestSubdomainValidator(t *testing.T) {
	t.Parallel()

	cases := []struct {
		Value string
		Valid bool
	}{
		{"admin", false},
		{"example", true},
		{"ABC", true},
		{"foo0123", true},
		{"λ", false},
	}

	for _, test := range cases {
		err := Subdomain(test.Value)
		if err != nil && test.Valid {
			t.Fatalf("expected %q to pass but it failed: %v", test.Value, err)
		}
	}
}
