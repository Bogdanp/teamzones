module Components.Profile exposing (Model, view)

import Components.Page exposing (page)
import Html exposing (..)
import Types exposing (User)


type alias Model =
    User


view : User -> Html msg
view user =
    page user.name []
