module Components.CurrentUser where

import Html exposing (..)
import Html.Attributes exposing (..)

import Types exposing (User)

view : User -> Html
view user =
  div
    [ class "current-user" ]
    [ h1 [] [ text user.name ]
    , h2 [] [ text user.timezone ]
    ]
