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
