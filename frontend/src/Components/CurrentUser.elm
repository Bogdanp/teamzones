module Components.CurrentUser where

import Html exposing (..)
import Html.Attributes exposing (..)

import Types exposing (User)

avatar : User -> Html
avatar user =
  div
    [ class "avatar" ]
    [ img [ src user.avatar
          , title user.name
          , alt "Avatar"
          ] []
    ]

view : User -> Html
view user =
  div
    [ class "current-user" ]
    [ avatar user
    , h3 [] [ text user.name ]
    , h6 [] [ text user.timezone ]
    ]
