module Components.Integrations.GCalendar exposing (Model, Msg, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar as CalendarApi exposing (Calendar, Calendars)
import Components.ConfirmationButton as CB
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.App as Html
import Process
import Task
import Time


type Msg
    = DisconnectError Error
    | DisconnectSuccess (Response String)
    | ToDisconnectButton CB.Msg
    | RefreshError Error
    | RefreshSuccess (Response String)
    | Refresh
    | FetchError Error
    | FetchSuccess (Response Calendars)


type alias Model pmsg =
    { active : Bool
    , calendars : Calendars
    , refreshing : Bool
    , disconnectMsg : pmsg
    , disconnectButton : CB.Model
    }


init : pmsg -> Bool -> ( Model pmsg, Cmd Msg )
init disconnectMsg active =
    { active = active
    , calendars = CalendarApi.empty
    , refreshing = False
    , disconnectMsg = disconnectMsg
    , disconnectButton = CB.init "Disconnect"
    }
        ! [ if active then
                Task.perform FetchError FetchSuccess CalendarApi.fetchAll
            else
                Cmd.none
          ]


update : Msg -> Model pmsg -> ( Model pmsg, Cmd Msg, Maybe pmsg )
update msg ({ disconnectMsg, disconnectButton } as model) =
    case msg of
        DisconnectError error ->
            -- TODO: Handle errors
            ( model, Cmd.none, Nothing )

        DisconnectSuccess _ ->
            ( model, Cmd.none, Just disconnectMsg )

        ToDisconnectButton ((CB.ToParent (CB.Confirm)) as msg) ->
            ( { model
                | active = False
                , disconnectButton = CB.update msg disconnectButton
              }
            , Task.perform DisconnectError DisconnectSuccess CalendarApi.disconnect
            , Nothing
            )

        ToDisconnectButton msg ->
            ( { model | disconnectButton = CB.update msg disconnectButton }, Cmd.none, Nothing )

        RefreshSuccess _ ->
            ( { model | refreshing = False }
            , Task.perform FetchError FetchSuccess CalendarApi.fetchAll
            , Nothing
            )

        RefreshError _ ->
            ( { model | refreshing = False }, Cmd.none, Nothing )

        Refresh ->
            ( { model | refreshing = True }
            , Task.perform RefreshError RefreshSuccess CalendarApi.refresh
            , Nothing
            )

        FetchError _ ->
            -- TODO: Handle errors
            ( model, Cmd.none, Nothing )

        FetchSuccess response ->
            let
                calendars =
                    response.data

                fetchAll =
                    if calendars.status == CalendarApi.Loading then
                        (Process.sleep (1 * Time.second) `Task.andThen` (always CalendarApi.fetchAll))
                            |> Task.perform FetchError FetchSuccess
                    else
                        Cmd.none
            in
                ( { model | calendars = calendars }, fetchAll, Nothing )


view : Model pmsg -> Html Msg
view ({ active } as model) =
    if not active then
        auth model
    else
        connected model


auth : Model pmsg -> Html Msg
auth model =
    div []
        [ p [] [ text "It looks like you haven't authorized your Google Calendar account yet. Click the button below to get started." ]
        , div [ class "input-group" ]
            [ div [ class "input" ]
                [ a
                    [ class "button"
                    , href "/integrations/connect/gcalendar"
                    ]
                    [ text "Connect Account" ]
                ]
            ]
        ]


connected : Model pmsg -> Html Msg
connected { calendars, refreshing, disconnectButton } =
    let
        loading =
            tr [] [ td [ colspan 3 ] [ text "Loading..." ] ]

        calendar c =
            let
                name =
                    Maybe.withDefault "Unnamed calendar" c.summary
            in
                tr []
                    [ td []
                        [ if calendars.defaultId == c.id then
                            strong [] [ text name ]
                          else
                            text name
                        ]
                    , td [] [ text (Maybe.withDefault "" c.timezone) ]
                      -- FIXME: use the user's timezone ^
                    , td [] []
                    ]
    in
        div []
            [ p [] [ text "You have connected your Google Calendar account." ]
            , div [ class "input-group" ]
                [ div [ class "input" ]
                    [ CB.view disconnectButton |> Html.map ToDisconnectButton ]
                ]
            , div [ class "sm-ml" ]
                [ h4 [] [ text "Your calendars" ]
                , table []
                    [ thead []
                        [ tr []
                            [ td [] [ text "Name" ]
                            , td [] [ text "Timezone" ]
                            , td [] []
                            ]
                        ]
                    , if calendars.status == CalendarApi.Loading then
                        tbody [] [ loading ]
                      else
                        tbody [] (List.map calendar calendars.calendars)
                    ]
                , br [] []
                , div [ class "input-group" ]
                    [ div [ class "input" ]
                        [ input
                            [ type' "button"
                            , value "Refresh Calendars"
                            , disabled refreshing
                            , onClick Refresh
                            ]
                            []
                        ]
                    ]
                ]
            ]
