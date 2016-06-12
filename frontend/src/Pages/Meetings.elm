module Pages.Meetings exposing (Msg, Model, init, update, view)

import Api.Calendar exposing (Meeting)
import Components.Notifications exposing (info)
import Components.Page exposing (pageWithTabs)
import Html exposing (Html)
import Html.App as Html
import Pages.Meetings.Meeting as Meeting
import Pages.Meetings.ScheduledMeetings as ScheduledMeetings
import Pages.Meetings.Scheduler as Scheduler
import Routes exposing (Sitemap(..), IntegrationsSitemap(..), MeetingsSitemap(..))
import Timestamp exposing (Timestamp)
import Types exposing (IntegrationStates, User)
import Util exposing ((=>), (?>))


type Msg
    = RouteTo Sitemap
    | ToScheduledMeetings ScheduledMeetings.Msg
    | ToScheduler Scheduler.Msg
    | ToMeeting Meeting.Msg


type alias Context =
    { now : Timestamp
    , fullRoute : Sitemap
    , subRoute : Maybe MeetingsSitemap
    , integrationStates : IntegrationStates
    , currentUser : User
    , teamMembers : List User
    }


type alias Model =
    { now : Timestamp
    , fullRoute : Sitemap
    , subRoute : MeetingsSitemap
    , currentUser : User
    , teamMembers : List User
    , meetings : Maybe (List Meeting)
    , meeting : Maybe Meeting
    , scheduler : Scheduler.Model
    }


init : Context -> ( Model, Cmd Msg )
init ({ now, fullRoute, subRoute, integrationStates, currentUser, teamMembers } as model) =
    let
        ( scheduler, _ ) =
            Scheduler.init model

        model =
            { now = now
            , fullRoute = fullRoute
            , subRoute = subRoute ?> ScheduledMeetingsR ()
            , currentUser = currentUser
            , teamMembers = teamMembers
            , meetings = Nothing
            , meeting = Nothing
            , scheduler = scheduler
            }
    in
        if integrationStates.gCalendar then
            urlUpdate model
        else
            model
                ! [ Routes.navigateTo (IntegrationsR (GCalendarR ()))
                  , info "You must connect your Google Calendar account before you can schedule meetings."
                  ]


urlUpdate : Model -> ( Model, Cmd Msg )
urlUpdate ({ now, fullRoute, subRoute } as model) =
    case subRoute of
        ScheduledMeetingsR () ->
            let
                ( model', meetingsFx ) =
                    ScheduledMeetings.init model
            in
                model' ! [ Cmd.map ToScheduledMeetings meetingsFx ]

        SchedulerR () ->
            let
                ( scheduler, schedulerFx ) =
                    Scheduler.init model
            in
                { model | scheduler = scheduler } ! [ Cmd.map ToScheduler schedulerFx ]

        MeetingR eventId ->
            let
                ( model', meetingFx ) =
                    Meeting.init eventId model
            in
                model' ! [ Cmd.map ToMeeting meetingFx ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ scheduler } as model) =
    case msg of
        RouteTo route ->
            model ! [ Routes.navigateTo route ]

        ToScheduledMeetings msg ->
            let
                ( model', fx ) =
                    ScheduledMeetings.update msg model
            in
                model' ! [ Cmd.map ToScheduledMeetings fx ]

        ToScheduler msg ->
            let
                ( scheduler, fx ) =
                    Scheduler.update msg scheduler
            in
                { model | scheduler = scheduler } ! [ Cmd.map ToScheduler fx ]

        ToMeeting msg ->
            let
                ( model', fx ) =
                    Meeting.update msg model
            in
                model' ! [ Cmd.map ToMeeting fx ]


view : Model -> Html Msg
view ({ fullRoute, subRoute, scheduler } as model) =
    pageWithTabs RouteTo
        fullRoute
        [ MeetingsR (ScheduledMeetingsR ()) => "Meetings"
        , MeetingsR (SchedulerR ()) => "Scheduler"
        ]
        [ case subRoute of
            ScheduledMeetingsR () ->
                ScheduledMeetings.view model
                    |> Html.map ToScheduledMeetings

            SchedulerR () ->
                Scheduler.view scheduler
                    |> Html.map ToScheduler

            MeetingR _ ->
                Meeting.view model
                    |> Html.map ToMeeting
        ]
