module Components.Integrations.GCalendar exposing (Model, Msg, init, update, view)

import Api exposing (Errors, postJson, postPlain)
import Components.ConfirmationButton as CB
import HttpBuilder
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.App as Html
import Json.Decode as Json exposing ((:=))
import Json.Encode
import Util exposing ((=>))


type Msg
    = AuthURLError (HttpBuilder.Error Errors)
    | AuthURLSuccess (HttpBuilder.Response String)
    | DisconnectError (HttpBuilder.Error Errors)
    | DisconnectSuccess (HttpBuilder.Response String)
    | ToDisconnectButton CB.Msg


type alias Model pmsg =
    { active : Bool
    , authUrl : Maybe String
    , disconnectMsg : pmsg
    , disconnectButton : CB.Model
    }


init : pmsg -> Bool -> ( Model pmsg, Cmd Msg )
init disconnectMsg active =
    { active = active
    , authUrl = Nothing
    , disconnectMsg = disconnectMsg
    , disconnectButton = CB.init "Disconnect"
    }
        ! [ if not active then
                requestAuthUrl
            else
                Cmd.none
          ]


update : Msg -> Model pmsg -> ( Model pmsg, Cmd Msg, Maybe pmsg )
update msg ({ disconnectMsg, disconnectButton } as model) =
    case msg of
        AuthURLError _ ->
            -- TODO: Limit attempts
            ( model, requestAuthUrl, Nothing )

        AuthURLSuccess response ->
            ( { model | authUrl = Just response.data }, Cmd.none, Nothing )

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
            , Cmd.batch [ disconnect, requestAuthUrl ]
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
authView { authUrl } =
    let
        ( uri, disabled ) =
            case authUrl of
                Nothing ->
                    ( "javascript:;", True )

                Just uri ->
                    ( uri, False )
    in
        div []
            [ p [] [ text "It looks like you haven't authorized your Google Calendar account yet. Click the button below to get started." ]
            , div [ class "input-group" ]
                [ div [ class "input" ]
                    [ a
                        [ classList
                            [ "button" => True
                            , "disabled" => disabled
                            ]
                        , href uri
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


requestAuthUrl : Cmd Msg
requestAuthUrl =
    let
        dec =
            "redirectUrl" := Json.string
    in
        postJson AuthURLError AuthURLSuccess integrationPayload dec "integrations/authorize"


disconnect : Cmd Msg
disconnect =
    postPlain DisconnectError DisconnectSuccess integrationPayload "integrations/disconnect"
