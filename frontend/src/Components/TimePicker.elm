module Components.TimePicker exposing (Msg, Model, init, update, view)

import Components.TimePicker.Time as Time exposing (Period(..), Time)
import Html exposing (Html, div, input)
import Html.Attributes exposing (class, type', value)
import Html.Events exposing (on, targetValue)
import Json.Decode as Json


type Msg
    = Change String


type alias Model =
    { value : String
    , time : Time
    }


init : Time -> Model
init time =
    { value = Time.toString time
    , time = time
    }


update : Msg -> Model -> ( Model, Time )
update msg ({ value, time } as model) =
    case msg of
        Change inputValue ->
            let
                time =
                    case Time.parse inputValue of
                        Nothing ->
                            model.time

                        Just time' ->
                            time'
            in
                ( { model
                    | value = Time.toString time
                    , time = time
                  }
                , time
                )


view : Model -> Html Msg
view model =
    input
        [ class "input timepicker"
        , type' "text"
        , on "change" (Json.map Change targetValue)
        , value model.value
        ]
        []
