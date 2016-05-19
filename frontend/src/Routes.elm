module Routes exposing (Sitemap(..), IntegrationsSitemap(..), SettingsSitemap(..), match, route)

import Route exposing (..)


type Sitemap
    = DashboardR ()
    | InviteR ()
    | ProfileR String
    | IntegrationsR IntegrationsSitemap
    | SettingsR SettingsSitemap
    | CurrentProfileR ()


homeR =
    DashboardR := static ""


inviteR =
    InviteR := static "invite"


profileR =
    ProfileR := "profile" <//> string


integrationsR =
    "integrations" <//> child IntegrationsR integrationsRouter


settingsR =
    "settings" <//> child SettingsR settingsRouter


currentProfileR =
    CurrentProfileR := static "profile"


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


type IntegrationsSitemap
    = GCalendarR ()


gCalendarR =
    GCalendarR := static "google-calendar"


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


teamR =
    TeamR := static "team"


billingR =
    BillingR := static "billing"


settingsRouter =
    router [ teamR, billingR ]


routeSettings : SettingsSitemap -> String
routeSettings r =
    case r of
        TeamR () ->
            reverse teamR []

        BillingR () ->
            reverse billingR []
