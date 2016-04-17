package handlers

import (
	"bytes"
	"fmt"
	"net/http"
	"net/url"
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
	path      string
	subdomain string
	absolute  bool
	params    map[string]string
	query     map[string][]string
	segments  []segment
}

// Param sets a parameter on the RouteBuilder.  Parameters are not
// checked for existance.
func (b RouteBuilder) Param(name, value string) RouteBuilder {
	if b.params == nil {
		b.params = make(map[string]string)
	}

	b.params[name] = value
	return b
}

// Query sets a list of query string parameters on the RouterBuilder.
func (b RouteBuilder) Query(name string, value ...string) RouteBuilder {
	if b.query == nil {
		b.query = make(map[string][]string)
	}

	b.query[name] = value
	return b
}

// Subdomain sets the subdomain on the RouteBuilder.
func (b RouteBuilder) Subdomain(subdomain string) RouteBuilder {
	b.subdomain = subdomain
	b.absolute = true
	return b
}

// Absolute sets the absolute flag on RouteBuilder to true.
func (b RouteBuilder) Absolute() RouteBuilder {
	b.absolute = true
	return b
}

// Build converts the RouteBuilder to a URI.  Panics if there are
// missing parameters.
func (b RouteBuilder) Build() string {
	var buffer bytes.Buffer

	// add the subdomain and the domain
	if b.absolute {
		if b.subdomain != "" {
			buffer.WriteString(b.subdomain + "." + config.Host())
		} else {
			buffer.WriteString(config.Host())
		}
	}

	// add the path
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

	// add the query string
	if len(b.query) > 0 {
		buffer.WriteString("?")

		for param, values := range b.query {
			for i, value := range values {
				buffer.WriteString(fmt.Sprintf("%s=%s", param, url.QueryEscape(value)))

				if i < len(values)-1 {
					buffer.WriteString("&")
				}
			}
		}
	}

	return buffer.String()
}

func newBuilder(path string) RouteBuilder {
	segments := []segment{}
	subpath := path

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

	return RouteBuilder{
		path:      path,
		subdomain: "",
		absolute:  false,
		params:    nil,
		query:     nil,
		segments:  segments,
	}
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
