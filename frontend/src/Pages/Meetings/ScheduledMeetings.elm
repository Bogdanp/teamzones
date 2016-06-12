module Pages.Meetings.ScheduledMeetings exposing (Msg, Model, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar exposing (Meeting, fetchMeetings)
import Components.Loading exposing (loading)
import Components.Notifications exposing (apiError)
import Html exposing (Html, br, div, p, text, table, thead, tbody, tr, td)
import Html.Attributes exposing (class, style)
import Routes exposing (Sitemap(..), MeetingsSitemap(..))
import Task
import Timestamp exposing (Timestamp, format, from)
import Types exposing (AnchorTo, User)
import Util exposing ((=>))


type Msg
    = RouteTo Sitemap
    | MeetingsError Error
    | MeetingsSuccess (Response (List Meeting))


type alias Model m =
    { m
        | now : Timestamp
        , currentUser : User
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
            meetings model.now ms


meetings : Timestamp -> List Meeting -> Html Msg
meetings now ms =
    let
        schedule =
            anchorTo (MeetingsR (SchedulerR ())) [ class "button" ] [ text "Schedule a meeting" ]
    in
        if List.isEmpty ms then
            div []
                [ p [] [ text "You don't have any upcoming meetings." ]
                , schedule
                ]
        else
            div []
                [ br [] []
                , table []
                    [ thead []
                        [ tr []
                            [ td [ style [ "width" => "33%" ] ] [ text "When" ]
                            , td [ style [ "width" => "33%" ] ] [ text "Summary" ]
                            , td [ style [ "width" => "33%" ] ] [ text "Description" ]
                            ]
                        ]
                    , tbody [] (List.map (meeting now) ms)
                    ]
                , br [] []
                , schedule
                ]


meeting : Timestamp -> Meeting -> Html Msg
meeting now { id, summary, description, startTime } =
    tr []
        [ td []
            [ anchorTo (MeetingsR (MeetingR id))
                []
                [ text <| format "YYYY-MM-DD HH:mmA" startTime
                , text " ("
                , text <| from now startTime
                , text " from now)"
                ]
            ]
        , td [] [ text summary ]
        , td [] [ text description ]
        ]


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
