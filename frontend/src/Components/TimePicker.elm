module Components.TimePicker exposing (Msg, Model, init, initWithMin, initWithValue, update, view)

import Components.TimePicker.Time as Time exposing (Period(..), Time)
import Html exposing (Html, div, input)
import Html.Attributes exposing (class, type', value)
import Html.Events exposing (on, targetValue)
import Json.Decode as Json
import Util exposing ((?>))


type Msg
    = Change String


type alias Model =
    { value : Maybe String
    , time : Maybe Time
    , min : Maybe Time
    }


init : Model
init =
    { value = Nothing
    , time = Nothing
    , min = Nothing
    }


initWithValue : String -> Model
initWithValue value =
    { init
        | value = Just value
        , time = Time.parse value
    }


initWithMin : Time -> Time -> Model
initWithMin min value =
    { init
        | value = Just <| Time.toString value
        , time =
            Just
                <| if Time.compare value min == GT then
                    value
                   else
                    min
        , min = Just min
    }


update : Msg -> Model -> ( Model, Maybe Time )
update msg ({ value, time } as model) =
    case msg of
        Change inputValue ->
            let
                time =
                    case ( Time.parse inputValue, model.min ) of
                        ( Nothing, _ ) ->
                            model.time

                        ( Just time, Just min ) ->
                            if Time.compare time min == GT then
                                Just time
                            else
                                Just min

                        ( time, _ ) ->
                            time
            in
                ( { model | value = Maybe.map Time.toString time, time = time }, time )


view : Model -> Html Msg
view model =
    input
        [ class "timepicker"
        , type' "text"
        , on "change" (Json.map Change targetValue)
        , value (model.value ?> "")
        ]
        []
