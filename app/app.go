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
	// Site
	homeRoute = iota
	plansRoute
	btTokenRoute
	signUpRoute
	siteSignInRoute
	findTeamRoute

	// Integrations
	initiateOAuthRoute
	gcalendarOAuthRoute
	gcalendarOAuthTeamRoute

	// Application
	dashboardRoute
	currentProfileRoute
	inviteRoute
	profileRoute
	integrationsGCalRoute
	settingsTeamRoute
	settingsBillingRoute
	teamSignUpRoute
	signInRoute
	signOutRoute
	recoverPasswordRoute
	resetPasswordRoute

	// API
	locationRoute
	sendInviteRoute
	createBulkInviteRoute
	updateProfileRoute
	avatarUploadRoute
	deleteAvatarRoute
	deleteUserRoute
	refreshIntegrationRoute
	disconnectIntegrationRoute
	gcalendarDataRoute

	// Tools
	provisionRoute
)

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

	store := cookiestore.New([]byte(config.Secret))
	site := negroni.New(negroni.Wrap(siteRouter))
	app := negroni.New(
		sessions.Sessions("session", store),
		negroni.HandlerFunc(Subdomain),
		negroni.HandlerFunc(Auth),
		negroni.Wrap(appRouter),
	)

	http.Handle("/", app)
	http.Handle(fmt.Sprintf("%s/", config.Host()), site)
	return siteRouter, appRouter
}

// Initializes the renderer.
func createRenderer() *render.Render {
	funcs := template.FuncMap{
		"version": func() string {
			return metadata.Version
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
	Debug  bool
	Secret string
	Domain struct {
		Host string
		Port int
	}

	CloudStorage struct {
		Bucket string
	} `yaml:"cloud_storage"`

	Plans []Plan
}

// Host is the full host name according to the configuration.  The
// port is included if it's not 80 or 443.
func (c *Config) Host() string {
	if c.Domain.Port != 80 && c.Domain.Port != 443 {
		return fmt.Sprintf("%s:%d", c.Domain.Host, c.Domain.Port)
	}

	return c.Domain.Host
}

// Reads the configuration file for the current environment.
func loadConfig() *Config {
	var filename string
	if strings.Contains(appengine.ServerSoftware(), "Development") {
		filename = "config/local.yaml"
	} else {
		filename = fmt.Sprintf("config/%s.yaml", metadata.Application)
	}

	config := &Config{}
	utils.LoadYAML(filename, config)
	utils.LoadYAML("config/plans.yaml", config)
	return config
}
