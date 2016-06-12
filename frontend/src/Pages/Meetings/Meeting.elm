module Pages.Meetings.Meeting exposing (Msg, Model, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar as CalendarApi exposing (Meeting)
import Components.Loading exposing (loading)
import Html exposing (..)
import Routes exposing (Sitemap(..), MeetingsSitemap(..))
import Task
import Timestamp exposing (Timestamp)
import Util exposing ((?>))


type Msg
    = MeetingError Error
    | MeetingSuccess (Response Meeting)


type alias Model m =
    { m
        | now : Timestamp
        , meetings : Maybe (List Meeting)
        , meeting : Maybe Meeting
    }


init : String -> Model m -> ( Model m, Cmd Msg )
init id model =
    let
        ( meeting, fx ) =
            case lookupMeeting model id of
                Nothing ->
                    ( Nothing
                    , CalendarApi.fetchMeeting id
                        |> Task.perform MeetingError MeetingSuccess
                    )

                meeting ->
                    ( meeting, Cmd.none )
    in
        { model | meeting = meeting } ! [ fx ]


update : Msg -> Model m -> ( Model m, Cmd Msg )
update msg model =
    case msg of
        MeetingError err ->
            model ! [ Routes.navigateTo (MeetingsR (ScheduledMeetingsR ())) ]

        MeetingSuccess { data } ->
            { model | meeting = Just data } ! []


view : Model m -> Html Msg
view { meeting } =
    case meeting of
        Nothing ->
            loading

        Just meeting ->
            div [] []


lookupMeeting : Model m -> String -> Maybe Meeting
lookupMeeting { meetings } id =
    meetings
        ?> []
        |> List.filter (.id >> (==) id)
        |> List.head
