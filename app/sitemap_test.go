package handlers

import "testing"

const aRoute = iota

func TestBuilderStaticParsing(t *testing.T) {
	b := newBuilder("/hello")
	if b.Build() != "/hello" {
		t.Error("bad parse")
	}
}

func TestBuilding(t *testing.T) {
	cases := []struct {
		builder  RouteBuilder
		expected string
	}{
		{newBuilder("/sign-up/:invite").Param("invite", "12312312312"), "/sign-up/12312312312"},
		{newBuilder("/hello/:a/b/c/:d/e/f/g").Param("a", "a").Param("d", "d"), "/hello/a/b/c/d/e/f/g"},
		{newBuilder("/hello/:a/b/c/:d/e/f/g").Param("a", "a").Param("d", "d").Subdomain("test"), "http://test.teamzones.io/hello/a/b/c/d/e/f/g"},
		{newBuilder("/oauth-callback").Query("code", "abc").Query("state", "def").Query("error", ""), "/oauth-callback?code=abc&state=def&error="},
		{newBuilder("/sign-in").Query("return", "http://foo.teamzones.io"), "/sign-in?return=http%3A%2F%2Ffoo.teamzones.io"},
		{newBuilder("/sign-in").Subdomain("test"), "http://test.teamzones.io/sign-in"},
	}

	for _, test := range cases {
		value := test.builder.Build()
		if value != test.expected {
			t.Errorf("bad build, expected %q got %q for builder %v", test.expected, value, test.builder)
		}
	}
}

func TestBuilderPanicsIfMissingParams(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Error("did not panic")
		}
	}()

	newBuilder("/:a").Build()
}

func TestBuildersAreSafe(t *testing.T) {
	sitemap[aRoute] = newBuilder("/foo")
	b1 := ReverseRoute(aRoute).Query("a", "hello")
	b2 := ReverseRoute(aRoute).Query("a", "goodbye")
	if b1.Build() == b2.Build() {
		t.Error("builders are not safe")
	}
}
