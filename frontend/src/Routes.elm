module Routes exposing (Sitemap(..), SettingsMap(..), match, route)

import Route exposing (..)


type SettingsMap
    = TeamR ()
    | BillingR ()


teamR =
    TeamR := static "team"


billingR =
    BillingR := static "billing"


settingsRouter =
    router [ teamR, billingR ]


routeSettings : SettingsMap -> String
routeSettings r =
    case r of
        TeamR () ->
            reverse teamR []

        BillingR () ->
            reverse billingR []


type Sitemap
    = DashboardR ()
    | InviteR ()
    | SettingsR SettingsMap
    | CurrentProfileR ()


homeR =
    DashboardR := static ""


inviteR =
    InviteR := static "invite"


settingsR =
    "settings" <//> child SettingsR settingsRouter


currentProfileR =
    CurrentProfileR := static "profile"


sitemap =
    router [ homeR, inviteR, settingsR, currentProfileR ]


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

        SettingsR r ->
            reverse settingsR [] ++ routeSettings r

        CurrentProfileR () ->
            reverse currentProfileR []
