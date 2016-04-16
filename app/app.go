package handlers

import (
	"io/ioutil"
	"net/http"

	"gopkg.in/codegangsta/negroni.v0"
	"gopkg.in/julienschmidt/httprouter.v1"
	"gopkg.in/unrolled/render.v1"
	"gopkg.in/yaml.v2"
)

var (
	metadata = loadMetadata()
	config   = loadConfig()
	router   = createRouter()
	renderer = createRenderer()
)

// Initializes the router and middleware.
func createRouter() *httprouter.Router {
	router := httprouter.New()
	middleware := negroni.New()
	middleware.UseHandler(router)
	http.Handle("/", middleware)
	return router
}

// Initializes the renderer.
func createRenderer() *render.Render {
	return render.New(render.Options{
		Layout: "layout",
	})
}

// Metadata contains information read from app.yaml.
type Metadata struct {
	Application string
	Version     string
}

// Reads the app.yaml file into a Metadata struct so that its
// information can be used at runtime.  This is useful for
// generating media URIs and similar stuff.
func loadMetadata() *Metadata {
	var m Metadata

	data, err := ioutil.ReadFile("app.yaml")
	if err != nil {
		panic(err)
	}

	if err := yaml.Unmarshal(data, &m); err != nil {
		panic(err)
	}

	return &m
}

// Config contains information read from environment-specific
// configuration files.
type Config struct {
}

// Reads the configuration file for the current environment.
func loadConfig() *Config {
	return &Config{}
}
