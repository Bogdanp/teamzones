module Pages.Meetings.Meeting exposing (Msg, Model, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar as CalendarApi exposing (Meeting)
import Components.Loading exposing (loading)
import Components.Team as Team
import Html exposing (..)
import Html.Attributes exposing (..)
import Routes exposing (Sitemap(..), MeetingsSitemap(..))
import Task
import Timestamp exposing (Timestamp, defaultFormat, from)
import Types exposing (User)
import Util exposing ((?|))


type Msg
    = RouteTo Sitemap
    | MeetingError Error
    | MeetingSuccess (Response Meeting)


type alias Model m =
    { m
        | now : Timestamp
        , teamMembers : List User
        , meetings : Maybe (List Meeting)
        , meeting : Maybe Meeting
    }


init : String -> Model m -> ( Model m, Cmd Msg )
init id model =
    { model | meeting = Nothing }
        ! [ CalendarApi.fetchMeeting id |> Task.perform MeetingError MeetingSuccess ]


update : Msg -> Model m -> ( Model m, Cmd Msg )
update msg model =
    case msg of
        RouteTo route ->
            model ! [ Routes.navigateTo route ]

        MeetingError err ->
            model ! [ Routes.navigateTo <| MeetingsR (ScheduledMeetingsR ()) ]

        MeetingSuccess { data } ->
            { model | meeting = Just data } ! []


view : Model m -> Html Msg
view { now, teamMembers, meeting } =
    case meeting of
        Nothing ->
            loading

        Just meeting ->
            div [ class "meeting" ]
                [ div [ class "column" ]
                    [ h4 [ class "summary" ] [ text <| meeting.summary ?| "No summary" ]
                    , h5 []
                        [ text <| from now meeting.startTime ]
                    , h6 []
                        [ text <| defaultFormat meeting.startTime
                        , text " to "
                        , text <| defaultFormat meeting.endTime
                        ]
                    , p [ class "description" ]
                        [ text <| meeting.description ?| "No description..." ]
                    ]
                , div [ class "column" ]
                    [ h4 [] [ text "Attendees" ]
                    , List.filter (.email >> flip List.member meeting.attendees) teamMembers
                        |> Team.viewList RouteTo now
                    ]
                ]
