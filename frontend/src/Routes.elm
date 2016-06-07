module Routes
    exposing
        ( Sitemap(..)
        , IntegrationsSitemap(..)
        , MeetingsSitemap(..)
        , SettingsSitemap(..)
        , parsePath
        , navigateTo
        , toString
        )

import Navigation exposing (Location)
import Route exposing (..)


type Sitemap
    = DashboardR ()
    | InviteR ()
    | ProfileR String
    | IntegrationsR IntegrationsSitemap
    | MeetingsR MeetingsSitemap
    | SettingsR SettingsSitemap
    | CurrentProfileR ()
    | NotFoundR


parsePath : Location -> Sitemap
parsePath =
    .pathname >> match


navigateTo : Sitemap -> Cmd msg
navigateTo =
    toString >> Navigation.newUrl


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


meetingsR : Route Sitemap
meetingsR =
    "meetings" <//> child MeetingsR meetingsRouter


settingsR : Route Sitemap
settingsR =
    "settings" <//> child SettingsR settingsRouter


currentProfileR : Route Sitemap
currentProfileR =
    CurrentProfileR := static "profile"


sitemap : Router Sitemap
sitemap =
    router [ homeR, inviteR, profileR, integrationsR, meetingsR, settingsR, currentProfileR ]


match : String -> Sitemap
match =
    Route.match sitemap >> Maybe.withDefault NotFoundR


toString : Sitemap -> String
toString route =
    case route of
        DashboardR () ->
            reverse homeR []

        InviteR () ->
            reverse inviteR []

        ProfileR email ->
            reverse profileR [ email ]

        IntegrationsR r ->
            reverse integrationsR [] ++ routeIntegrations r

        MeetingsR r ->
            reverse meetingsR [] ++ routeMeetings r

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


type MeetingsSitemap
    = ScheduledMeetingsR ()
    | SchedulerR ()


scheduledMeetingsR : Route MeetingsSitemap
scheduledMeetingsR =
    ScheduledMeetingsR := static ""


schedulerR : Route MeetingsSitemap
schedulerR =
    SchedulerR := static "scheduler"


meetingsRouter : Router MeetingsSitemap
meetingsRouter =
    router [ scheduledMeetingsR, schedulerR ]


routeMeetings : MeetingsSitemap -> String
routeMeetings r =
    case r of
        ScheduledMeetingsR () ->
            reverse scheduledMeetingsR []

        SchedulerR () ->
            reverse schedulerR []


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
