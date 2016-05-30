module Components.Meetings exposing (Msg, Model, init, update, view)

import Components.Page exposing (page)
import Html exposing (..)


type Msg
    = NoOp


type alias Model =
    {}


init : Model
init =
    {}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []


view : Model -> Html Msg
view model =
    page "Meetings" []
