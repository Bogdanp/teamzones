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


type alias Model =
    { active : Bool
    , authUrl : Maybe String
    , disconnectButton : CB.Model
    }


init : Bool -> ( Model, Cmd Msg )
init active =
    { active = active
    , authUrl = Nothing
    , disconnectButton = CB.init "Disconnect"
    }
        ! [ if not active then
                requestAuthUrl
            else
                Cmd.none
          ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ disconnectButton } as model) =
    case msg of
        AuthURLError _ ->
            -- TODO: Limit attempts
            model ! [ requestAuthUrl ]

        AuthURLSuccess response ->
            { model | authUrl = Just response.data } ! []

        DisconnectError error ->
            -- TODO: Handle errors
            model ! []

        DisconnectSuccess _ ->
            model ! []

        ToDisconnectButton ((CB.ToParent (CB.Confirm)) as msg) ->
            { model
                | active = False
                , disconnectButton = CB.update msg disconnectButton
            }
                ! [ disconnect, requestAuthUrl ]

        ToDisconnectButton msg ->
            { model | disconnectButton = CB.update msg disconnectButton } ! []


view : Model -> Html Msg
view ({ active } as model) =
    if not active then
        authView model
    else
        connectedView model


authView : Model -> Html Msg
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


connectedView : Model -> Html Msg
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
