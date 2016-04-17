package handlers

import "testing"

func TestBuilderStaticParsing(t *testing.T) {
	b := newBuilder("/hello")
	if b.Build() != "/hello" {
		t.Error("bad parse")
	}
}

func TestBuilderDynamicParsing(t *testing.T) {
	b := newBuilder("/hello/:a/b/c/:d/e/f/g")
	if b.Param("a", "a").Param("d", "d").Build() != "/hello/a/b/c/d/e/f/g" {
		t.Error("bad build")
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
	if b.Subdomain("test").Build() != "test.teamzones.io/sign-in" {
		t.Error("bad subdomain")
	}
}

func TestBuildersAreSafe(t *testing.T) {
	sitemap["foo"] = newBuilder("/foo")
	b1 := ReverseRoute("foo").Query("a", "hello")
	b2 := ReverseRoute("foo").Query("a", "goodbye")
	if b1.Build() == b2.Build() {
		t.Error("builders are not safe")
	}
}
