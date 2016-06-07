module Pages.Meetings.Scheduler exposing (Msg, Model, init, update, view)

import Html exposing (Html, div)


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
    div [] []
