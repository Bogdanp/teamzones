module Components.Integrations.GCalendar exposing (Model, Msg, init, update, view)

import Api exposing (Errors, postJson)
import HttpBuilder
import Html exposing (..)
import Json.Decode as Json exposing ((:=))
import Json.Encode
import Util exposing ((=>))


type Msg
    = AuthURLError (HttpBuilder.Error Errors)
    | AuthURLSuccess (HttpBuilder.Response String)


type alias Model =
    { authUrl : Maybe String }


init : ( Model, Cmd Msg )
init =
    { authUrl = Nothing } ! [ requestAuthUrl ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AuthURLError _ ->
            model ! [ requestAuthUrl ]

        AuthURLSuccess response ->
            let
                _ =
                    Debug.log "uri" response.data
            in
                { model | authUrl = Just response.data } ! []


view : Model -> Html Msg
view model =
    div [] []


requestAuthUrl : Cmd Msg
requestAuthUrl =
    let
        payload =
            Json.Encode.object [ "integration" => Json.Encode.string "gcalendar" ]

        dec =
            "redirectUrl" := Json.string
    in
        postJson AuthURLError AuthURLSuccess payload dec "integrations/authorize"
