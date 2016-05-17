module Components.Settings exposing (Model, Msg, init, update, view)

import Components.Page exposing (page)
import Html exposing (..)
import Routes exposing (SettingsMap(..))


type Msg
    = Submit


type alias Model =
    { route : SettingsMap
    }


init : Model
init =
    { route = TeamR ()
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Submit ->
            model ! []


view : Model -> Html msg
view ({ route } as model) =
    page "Settings"
        []
