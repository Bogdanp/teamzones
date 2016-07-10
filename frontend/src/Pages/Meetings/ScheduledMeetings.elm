module Pages.Meetings.ScheduledMeetings exposing (Msg, Model, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar exposing (Meeting, cancelMeeting, fetchMeetings)
import Components.ConfirmationButton as CB
import Components.Loading exposing (loading)
import Components.Notifications exposing (apiError)
import Dict exposing (Dict)
import Html exposing (Html, br, div, p, text, table, thead, tbody, tr, td)
import Html.App as Html
import Html.Attributes exposing (class, style)
import Routes exposing (Sitemap(..), MeetingsSitemap(..))
import String
import Task
import Timestamp exposing (Timestamp, defaultFormat, from)
import Types exposing (AnchorTo, User)
import Util exposing ((=>), (?|))


type alias CancelButtons =
    Dict String CB.Model


type Msg
    = RouteTo Sitemap
    | MeetingsError Error
    | MeetingsSuccess (Response (List Meeting))
    | ToCancelButton String CB.Msg
    | CancelMeetingError String Error
    | CancelMeetingSuccess String (Response String)


type alias Model m =
    { m
        | now : Timestamp
        , currentUser : User
        , teamMembers : List User
        , cancelButtons : CancelButtons
        , meetings : Maybe (List Meeting)
    }


init : Model m -> ( Model m, Cmd Msg )
init model =
    model ! [ Task.perform MeetingsError MeetingsSuccess fetchMeetings ]


updateButtons : CancelButtons -> String -> CB.Msg -> CancelButtons
updateButtons buttons id msg =
    Dict.map
        (\i b ->
            if i == id then
                CB.update msg b
            else
                b
        )
        buttons


update : Msg -> Model m -> ( Model m, Cmd Msg )
update msg model =
    case msg of
        RouteTo route ->
            model ! [ Routes.navigateTo route ]

        MeetingsError err ->
            model ! apiError err

        MeetingsSuccess response ->
            let
                buttons =
                    List.map (\m -> ( m.id, CB.init "Cancel" )) response.data
                        |> Dict.fromList
            in
                { model
                    | cancelButtons = buttons
                    , meetings = Just response.data
                }
                    ! []

        ToCancelButton id ((CB.ToParent (CB.Confirm)) as msg) ->
            { model | cancelButtons = updateButtons model.cancelButtons id msg }
                ! [ Task.perform (CancelMeetingError id) (CancelMeetingSuccess id) (cancelMeeting id)
                  ]

        ToCancelButton id msg ->
            { model | cancelButtons = updateButtons model.cancelButtons id msg } ! []

        CancelMeetingError id err ->
            model ! apiError err

        CancelMeetingSuccess id _ ->
            let
                meetings =
                    Maybe.map (List.filter (.id >> (/=) id)) model.meetings
            in
                { model | meetings = meetings } ! []


view : Model m -> Html Msg
view model =
    case model.meetings of
        Nothing ->
            loading

        Just ms ->
            meetings model.now model.cancelButtons ms


meetings : Timestamp -> CancelButtons -> List Meeting -> Html Msg
meetings now cancelButtons ms =
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
                            , td [ style [ "width" => "130px" ] ] []
                            ]
                        ]
                    , tbody [] (List.map (meeting now cancelButtons) ms)
                    ]
                , br [] []
                , schedule
                ]


meeting : Timestamp -> CancelButtons -> Meeting -> Html Msg
meeting now cancelButtons { id, summary, description, startTime } =
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
        , td []
            [ case Dict.get id cancelButtons of
                Just button ->
                    CB.view button
                        |> Html.map (ToCancelButton id)

                Nothing ->
                    text ""
            ]
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
