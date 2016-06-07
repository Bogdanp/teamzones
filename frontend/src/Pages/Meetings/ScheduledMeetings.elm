module Pages.Meetings.ScheduledMeetings exposing (Msg, Model, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar exposing (Meeting, fetchMeetings)
import Components.Loading exposing (loading)
import Components.Notifications exposing (apiError)
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Routes exposing (Sitemap(..), MeetingsSitemap(..))
import Task
import Types exposing (AnchorTo, User)
import Util


type Msg
    = RouteTo Sitemap
    | MeetingsError Error
    | MeetingsSuccess (Response (List Meeting))


type alias Model m =
    { m
        | currentUser : User
        , teamMembers : List User
        , meetings : Maybe (List Meeting)
    }


init : Model m -> ( Model m, Cmd Msg )
init model =
    model ! [ Task.perform MeetingsError MeetingsSuccess fetchMeetings ]


update : Msg -> Model m -> ( Model m, Cmd Msg )
update msg model =
    case msg of
        RouteTo route ->
            model ! [ Routes.navigateTo route ]

        MeetingsError err ->
            model ! apiError err

        MeetingsSuccess response ->
            { model | meetings = Just response.data } ! []


view : Model m -> Html Msg
view model =
    case model.meetings of
        Nothing ->
            loading

        Just ms ->
            meetings ms


meetings : List Meeting -> Html Msg
meetings meetings =
    if List.isEmpty meetings then
        div []
            [ p [] [ text "You don't have any upcoming meetings." ]
            , anchorTo (MeetingsR (SchedulerR ())) [ class "button" ] [ text "Schedule a meeting" ]
            ]
    else
        div [] []


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
