package handlers

import (
	"bytes"
	"fmt"
	"net/http"
	"strings"

	"gopkg.in/julienschmidt/httprouter.v1"
)

var sitemap = make(map[interface{}]RouteBuilder)

const (
	segmentStatic  = iota
	segmentDynamic = iota
)

type segmentKind int
type segment struct {
	kind  segmentKind
	value string // for dynamic segments this is the param name
}

// RouteBuilder is used to build routes in a reasonably-safe manner.
type RouteBuilder struct {
	path     string
	params   map[string]string
	segments []segment
}

// Param sets a parameter on the RouteBuilder.  Parameters are not
// checked for existance.
func (b RouteBuilder) Param(name, value string) RouteBuilder {
	b.params[name] = value
	return b
}

// Build converts the RouteBuilder to a URI.  Panics if there are
// missing parameters.
func (b RouteBuilder) Build() string {
	var buffer bytes.Buffer

	for _, segment := range b.segments {
		switch segment.kind {
		case segmentStatic:
			buffer.WriteString(segment.value)
		case segmentDynamic:
			param, found := b.params[segment.value]
			if !found {
				panic(fmt.Sprintf("sitemap: parameter %q not set on builder", segment.value))
			}

			buffer.WriteString(param)
		}
	}

	return buffer.String()
}

func newBuilder(path string) RouteBuilder {
	params := make(map[string]string)
	subpath := path
	segments := []segment{}

	for {
		i := strings.Index(subpath, ":")
		if i == -1 {
			segments = append(segments, segment{segmentStatic, subpath})
			break
		}

		prefix := subpath[:i]
		subpath = subpath[i+1:]

		i = strings.Index(subpath, "/")
		if i == -1 {
			segments = append(segments, segment{segmentDynamic, subpath})
			break
		}

		name := subpath[:i]
		subpath = subpath[i:]
		segments = append(
			segments,
			segment{segmentStatic, prefix},
			segment{segmentDynamic, name},
		)
	}

	return RouteBuilder{path, params, segments}
}

func register(
	router *httprouter.Router,
	name interface{}, path string, handler httprouter.Handle, methods ...string,
) {

	sitemap[name] = newBuilder(path)

	for _, method := range methods {
		router.Handle(method, path, handler)
	}
}

// GET creates an HTTP GET route handler.
func GET(router *httprouter.Router, name interface{}, path string, handler httprouter.Handle) {
	register(router, name, path, handler, http.MethodGet)
}

// POST creates an HTTP POST route handler.
func POST(router *httprouter.Router, name interface{}, path string, handler httprouter.Handle) {
	register(router, name, path, handler, http.MethodPost)
}

// ALL creates an HTTP GET and POST route handler.
func ALL(router *httprouter.Router, name interface{}, path string, handler httprouter.Handle) {
	register(router, name, path, handler, http.MethodGet, http.MethodPost)
}

// ReverseRoute looks up routes by name and returns RouteBuilders for
// them.  The builders can be used in turn to generate full-fledged
// URIs.
func ReverseRoute(name interface{}) RouteBuilder {
	builder, found := sitemap[name]
	if !found {
		panic(fmt.Sprintf("sitemap: route %q does not exist", name))
	}

	return builder
}

// ReverseSimple looks up routes by name and returns their paths.
// This is not safe to use with paths that contain dynamic parameters,
// use ReverseRoute for those.
func ReverseSimple(name interface{}) string {
	return ReverseRoute(name).path
}
