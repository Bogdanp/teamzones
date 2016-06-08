module Components.Duration exposing (Msg, Duration, Model, init, update, view, parseDuration)

import Combine exposing (Parser, choice, end, maybe, optional, regex, string)
import Combine.Infix exposing ((<$>), (<*>), (<*), (*>))
import Combine.Num exposing (int)
import Html exposing (..)
import Html.Attributes exposing (class, type', value)
import Html.Events exposing (on, targetValue)
import Json.Decode as Json


type Msg
    = Change String


type alias Duration =
    Float


type alias Model =
    { duration : Duration }


init : Duration -> Model
init d =
    { duration = d }


update : Msg -> Model -> ( Model, Duration )
update msg model =
    case msg of
        Change value ->
            let
                duration =
                    parseDuration value |> Maybe.withDefault model.duration
            in
                ( { model | duration = duration }, duration )


view : Model -> Html Msg
view { duration } =
    input
        [ class "input duration"
        , type' "text"
        , on "change" (Json.map Change targetValue)
        , value <| toString duration
        ]
        []


toString : Duration -> String
toString millis =
    let
        seconds =
            floor <| millis / 1000

        hours =
            seconds // 3600

        minutes =
            seconds `rem` 3600 // 60
    in
        Basics.toString hours ++ "h:" ++ Basics.toString minutes ++ "m"


posInt : Parser Int
posInt =
    abs <$> int


ws : Parser String
ws =
    regex " *"


hour : Parser Int
hour =
    ws *> posInt <* maybe (string "h") <* maybe (string ":")


minute : Parser Int
minute =
    ws *> posInt <* maybe (string "m")


duration : Parser Duration
duration =
    let
        toMillis h m =
            (toFloat h * 3600 + toFloat m * 60) * 1000
    in
        choice
            [ toMillis <$> hour <*> optional 0 minute <* end
            , toMillis 0 <$> minute <* end
            , flip toMillis 0 <$> hour <* end
            ]


parseDuration : String -> Maybe Duration
parseDuration =
    Combine.parse duration >> fst >> Result.toMaybe
