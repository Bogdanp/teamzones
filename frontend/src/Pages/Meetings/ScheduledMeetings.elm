module Pages.Meetings.ScheduledMeetings exposing (Msg, Model, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar exposing (Meeting, fetchMeetings)
import Components.Loading exposing (loading)
import Components.Notifications exposing (apiError)
import Html exposing (Html, br, div, p, text, table, thead, tbody, tr, td)
import Html.Attributes exposing (class, style)
import Routes exposing (Sitemap(..), MeetingsSitemap(..))
import String
import Task
import Timestamp exposing (Timestamp, defaultFormat, from)
import Types exposing (AnchorTo, User)
import Util exposing ((=>), (?|))


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
                            [ td [ style [ "width" => "25%" ] ] [ text "When" ]
                            , td [ style [ "width" => "25%" ] ] [ text "Summary" ]
                            , td [ style [] ] [ text "Description" ]
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
                [ text <| defaultFormat startTime
                , text " ("
                , text <| from now startTime
                , text ")"
                ]
            ]
        , td [] [ text <| trim 20 summary ?| "No summary" ]
        , td [] [ text <| trim 75 description ?| "No description" ]
        ]


trim : Int -> String -> String
trim n s =
    if String.length s > n then
        String.toList s
            |> List.take n
            |> String.fromList
            |> flip (++) "..."
    else
        s


anchorTo : AnchorTo Msg
anchorTo =
    Util.anchorTo RouteTo
