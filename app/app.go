package handlers

import (
	"fmt"
	"html/template"
	"io/ioutil"
	"net/http"
	"strings"
	"teamzones/utils"

	"github.com/codegangsta/negroni"
	"github.com/goincremental/negroni-sessions"
	"github.com/goincremental/negroni-sessions/cookiestore"

	"google.golang.org/appengine"

	"gopkg.in/julienschmidt/httprouter.v1"
	"gopkg.in/unrolled/render.v1"
	"gopkg.in/yaml.v2"
)

var (
	metadata = loadMetadata()
	config   = loadConfig()
	renderer = createRenderer()
)

var siteRouter, appRouter = createRouters()

const (
	companyCtxKey = iota
	userCtxKey
)

const (
	uidSessionKey = "uid"
)

// Initializes the router and middleware.
func createRouters() (*httprouter.Router, *httprouter.Router) {
	siteRouter := httprouter.New()
	appRouter := httprouter.New()

	store := cookiestore.New(
		config.Secret.Authentication,
		config.Secret.Encryption,
	)
	site := negroni.New(negroni.Wrap(siteRouter))
	app := negroni.New(
		sessions.Sessions("__", store),
		negroni.HandlerFunc(Subdomain(siteRouter)),
		negroni.HandlerFunc(Auth),
		negroni.HandlerFunc(Access),
		negroni.Wrap(appRouter),
	)

	http.Handle("/", app)
	http.Handle(fmt.Sprintf("%s/", config.Host()), site)
	return siteRouter, appRouter
}

// Initializes the renderer.
func createRenderer() *render.Render {
	funcs := template.FuncMap{
		"asset": func(filename string) string {
			return fmt.Sprintf("/static/%s?v=%s", filename, metadata.Version)
		},

		"route": func(name Route, params ...string) string {
			return ReverseRoute(name).Params(params...).Build()
		},

		"absRoute": func(name Route, params ...string) string {
			return ReverseRoute(name).Params(params...).Absolute().Build()
		},

		"routeSub": func(name Route, subdomain string, params ...string) string {
			return ReverseRoute(name).Subdomain(subdomain).Params(params...).Build()
		},
	}

	return render.New(render.Options{
		Layout: "layout",
		Funcs:  []template.FuncMap{funcs},
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
	Debug bool

	Secret struct {
		Authentication []byte
		Encryption     []byte
	}

	Domain struct {
		Host string
		Port int
	}

	Appspot struct {
		Host string
		Port int
	}

	CloudStorage struct {
		Bucket string
	} `yaml:"cloud_storage"`
}

// Host is the full host name according to the configuration.  The
// port is included if it's not 80 or 443.
func (c *Config) Host() string {
	if c.Domain.Port != 80 && c.Domain.Port != 443 {
		return fmt.Sprintf("%s:%d", c.Domain.Host, c.Domain.Port)
	}

	return c.Domain.Host
}

// AppspotHost is the full host name according to the configuration.  The
// port is included if it's not 80 or 443.
func (c *Config) AppspotHost() string {
	if c.Appspot.Port != 80 && c.Appspot.Port != 443 {
		return fmt.Sprintf("%s:%d", c.Appspot.Host, c.Appspot.Port)
	}

	return c.Appspot.Host
}

// Reads the configuration file for the current environment.
func loadConfig() *Config {
	c := &Config{}
	if strings.Contains(appengine.ServerSoftware(), "Development") {
		utils.LoadYAML("config/local.yaml", c)
	} else {
		utils.LoadYAML(fmt.Sprintf("config/%s.yaml", metadata.Application), c)
	}

	return c
}
