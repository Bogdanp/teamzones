module Components.Integrations.GCalendar exposing (Model, Msg, init, update, view)

import Api exposing (Errors, postPlain)
import Components.ConfirmationButton as CB
import HttpBuilder
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as Html
import Json.Encode
import Util exposing ((=>))


type Msg
    = DisconnectError (HttpBuilder.Error Errors)
    | DisconnectSuccess (HttpBuilder.Response String)
    | ToDisconnectButton CB.Msg


type alias Model pmsg =
    { active : Bool
    , disconnectMsg : pmsg
    , disconnectButton : CB.Model
    }


init : pmsg -> Bool -> ( Model pmsg, Cmd Msg )
init disconnectMsg active =
    { active = active
    , disconnectMsg = disconnectMsg
    , disconnectButton = CB.init "Disconnect"
    }
        ! []


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
            , Cmd.batch [ disconnect ]
            , Nothing
            )

        ToDisconnectButton msg ->
            ( { model | disconnectButton = CB.update msg disconnectButton }, Cmd.none, Nothing )


view : Model pmsg -> Html Msg
view ({ active } as model) =
    if not active then
        authView model
    else
        connectedView model


authView : Model pmsg -> Html Msg
authView model =
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


connectedView : Model pmsg -> Html Msg
connectedView { disconnectButton } =
    div []
        [ p [] [ text "You have connected your Google Calendar account." ]
        , div [ class "input-group" ]
            [ div [ class "input" ] [ CB.view disconnectButton |> Html.map ToDisconnectButton ]
            ]
        ]


integrationPayload : Json.Encode.Value
integrationPayload =
    Json.Encode.object [ "integration" => Json.Encode.string "gcalendar" ]


disconnect : Cmd Msg
disconnect =
    postPlain DisconnectError DisconnectSuccess integrationPayload "integrations/disconnect"
