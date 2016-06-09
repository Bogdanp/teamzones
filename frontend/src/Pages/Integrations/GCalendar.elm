module Pages.Integrations.GCalendar exposing (Model, Msg, init, update, view)

import Api exposing (Error, Response)
import Api.Calendar as CalendarApi exposing (Calendar, Calendars)
import Components.ConfirmationButton as CB
import Components.Loading exposing (loading)
import Components.Notifications exposing (error, info)
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Process
import Task
import Time
import Util exposing ((?>))


type Msg
    = DisconnectError Error
    | DisconnectSuccess (Response String)
    | ToDisconnectButton CB.Msg
    | RefreshError Error
    | RefreshSuccess (Response String)
    | Refresh
    | FetchError Error
    | FetchSuccess (Response Calendars)
    | SetDefault String
    | SetDefaultError Error
    | SetDefaultSuccess (Response Calendars)


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
update msg ({ calendars, disconnectMsg, disconnectButton } as model) =
    case msg of
        DisconnectError _ ->
            ( model
            , error "We encountered an issue while trying to disconnect your integration. Please try again later."
            , Nothing
            )

        DisconnectSuccess _ ->
            ( model
            , info "Your Google Calendar integration has been disconnected."
            , Just disconnectMsg
            )

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
            ( { model | refreshing = False }
            , info "You may only refresh your calendars once every few minutes. Please try again later."
            , Nothing
            )

        Refresh ->
            ( { model | refreshing = True }
            , Task.perform RefreshError RefreshSuccess CalendarApi.refresh
            , Nothing
            )

        FetchError _ ->
            ( model
            , error "We encountered an issue while fetching your calendars. Please try again later."
            , Nothing
            )

        FetchSuccess { data } ->
            let
                fetchAll =
                    if data.status == CalendarApi.Loading then
                        (Process.sleep (1 * Time.second) `Task.andThen` (always CalendarApi.fetchAll))
                            |> Task.perform FetchError FetchSuccess
                    else
                        Cmd.none
            in
                ( { model | calendars = data }, fetchAll, Nothing )

        SetDefault id ->
            ( { model | refreshing = True }
            , CalendarApi.setDefaultCalendar id
                |> Task.perform SetDefaultError SetDefaultSuccess
            , Nothing
            )

        SetDefaultError _ ->
            ( { model | refreshing = False }
            , error "We encountered an issue while updating your calendars. Please try again later."
            , Nothing
            )

        SetDefaultSuccess { data } ->
            ( { model | refreshing = False, calendars = data }, Cmd.none, Nothing )


view : Model pmsg -> Html Msg
view ({ active } as model) =
    if not active then
        auth model
    else
        connected model


auth : Model pmsg -> Html Msg
auth model =
    div []
        [ p [] [ text "It looks like you haven't authorized your Google Calendar account yet. Connect your account to get started." ]
        , div [ class "input-group" ]
            [ div [ class "input-group__input" ]
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
        calendar c =
            let
                default =
                    calendars.defaultId == c.id

                name =
                    c.summary ?> "Unnamed calendar"
            in
                tr []
                    [ td []
                        [ if default then
                            strong [] [ text name ]
                          else
                            text name
                        ]
                    , td [] [ text (c.timezone ?> "-") ]
                    , td []
                        [ if not default then
                            a
                                [ class "button"
                                , onClick (SetDefault c.id)
                                ]
                                [ text "Make default" ]
                          else
                            text ""
                        ]
                    ]
    in
        div []
            [ p [] [ text "You have connected your Google Calendar account." ]
            , div [ class "input-group" ]
                [ div [ class "input-group__input" ]
                    [ CB.view disconnectButton |> Html.map ToDisconnectButton ]
                ]
            , div [ class "sm-ml" ]
                [ h4 [] [ text "Your calendars" ]
                , if calendars.status == CalendarApi.Loading then
                    loading
                  else
                    table [ class "table tall-rows" ]
                        [ thead []
                            [ tr []
                                [ td [] [ text "Name" ]
                                , td [] [ text "Timezone" ]
                                , td [] []
                                ]
                            ]
                        , tbody [] (List.map calendar calendars.calendars)
                        ]
                , br [] []
                , div [ class "input-group" ]
                    [ div [ class "input-group__input" ]
                        [ input
                            [ class "button"
                            , type' "button"
                            , value "Refresh Calendars"
                            , disabled refreshing
                            , onClick Refresh
                            ]
                            []
                        ]
                    ]
                ]
            ]
