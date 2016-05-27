module Routes
    exposing
        ( Sitemap(..)
        , IntegrationsSitemap(..)
        , SettingsSitemap(..)
        , match
        , route
        , push
        )

import Navigation
import Route exposing (..)


type Sitemap
    = DashboardR ()
    | InviteR ()
    | ProfileR String
    | IntegrationsR IntegrationsSitemap
    | SettingsR SettingsSitemap
    | CurrentProfileR ()
    | NotFoundR


push : Sitemap -> Cmd msg
push =
    Navigation.newUrl << route


homeR : Route Sitemap
homeR =
    DashboardR := static ""


inviteR : Route Sitemap
inviteR =
    InviteR := static "invite"


profileR : Route Sitemap
profileR =
    ProfileR := "profile" <//> string


integrationsR : Route Sitemap
integrationsR =
    "integrations" <//> child IntegrationsR integrationsRouter


settingsR : Route Sitemap
settingsR =
    "settings" <//> child SettingsR settingsRouter


currentProfileR : Route Sitemap
currentProfileR =
    CurrentProfileR := static "profile"


sitemap : Router Sitemap
sitemap =
    router [ homeR, inviteR, profileR, integrationsR, settingsR, currentProfileR ]


match : String -> Sitemap
match =
    Route.match sitemap >> Maybe.withDefault (DashboardR ())


route : Sitemap -> String
route route =
    case route of
        DashboardR () ->
            reverse homeR []

        InviteR () ->
            reverse inviteR []

        ProfileR email ->
            reverse profileR [ email ]

        IntegrationsR r ->
            reverse integrationsR [] ++ routeIntegrations r

        SettingsR r ->
            reverse settingsR [] ++ routeSettings r

        CurrentProfileR () ->
            reverse currentProfileR []

        NotFoundR ->
            Debug.crash "Cannot route to NotFoundR"


type IntegrationsSitemap
    = GCalendarR ()


gCalendarR : Route IntegrationsSitemap
gCalendarR =
    GCalendarR := static "google-calendar"


integrationsRouter : Router IntegrationsSitemap
integrationsRouter =
    router [ gCalendarR ]


routeIntegrations : IntegrationsSitemap -> String
routeIntegrations r =
    case r of
        GCalendarR () ->
            reverse gCalendarR []


type SettingsSitemap
    = TeamR ()
    | BillingR ()


teamR : Route SettingsSitemap
teamR =
    TeamR := static "team"


billingR : Route SettingsSitemap
billingR =
    BillingR := static "billing"


settingsRouter : Router SettingsSitemap
settingsRouter =
    router [ teamR, billingR ]


routeSettings : SettingsSitemap -> String
routeSettings r =
    case r of
        TeamR () ->
            reverse teamR []

        BillingR () ->
            reverse billingR []
