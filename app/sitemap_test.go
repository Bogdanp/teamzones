package handlers

import "testing"

const aRoute = iota

func TestBuilderStaticParsing(t *testing.T) {
	b := newBuilder("/hello")
	if b.Build() != "/hello" {
		t.Error("bad parse")
	}
}

func TestBuilderDynamicParsing(t *testing.T) {
	cases := map[string]RouteBuilder{
		"/hello/a/b/c/d/e/f/g":                         newBuilder("/hello/:a/b/c/:d/e/f/g").Param("a", "a").Param("d", "d"),
		"/sign-up/12312312312":                         newBuilder("/sign-up/:invite").Param("invite", "12312312312"),
		"http://test.teamzones.io/hello/a/b/c/d/e/f/g": newBuilder("/hello/:a/b/c/:d/e/f/g").Param("a", "a").Param("d", "d").Subdomain("test"),
	}

	for expected, builder := range cases {
		value := builder.Build()
		if value != expected {
			t.Errorf("bad build, expected %q got %q for builder %q", expected, value, builder)
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

func TestBuildingQueryStrings(t *testing.T) {
	b := newBuilder("/sign-in")
	r := "/sign-in?return=http%3A%2F%2Ffoo.teamzones.io"
	if b.Query("return", "http://foo.teamzones.io").Build() != r {
		t.Error("bad query string")
	}
}

func TestBuildingSubdomains(t *testing.T) {
	b := newBuilder("/sign-in")
	r := b.Subdomain("test").Build()
	if r != "http://test.teamzones.io/sign-in" {
		t.Errorf("bad subdomain: %s", r)
	}
}

func TestBuildersAreSafe(t *testing.T) {
	sitemap[aRoute] = newBuilder("/foo")
	b1 := ReverseRoute(aRoute).Query("a", "hello")
	b2 := ReverseRoute(aRoute).Query("a", "goodbye")
	if b1.Build() == b2.Build() {
		t.Error("builders are not safe")
	}
}
