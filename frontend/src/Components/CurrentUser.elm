module Components.CurrentUser where

import Html exposing (..)
import Html.Attributes exposing (..)

import Types exposing (User)
import Util exposing (initials)

avatar : User -> Html
avatar user =
  div
    [ class "avatar" ]
    [ img [ src <| Maybe.withDefault "/static/images/default-avatar.png" user.avatar
          , title user.name
          , alt <| initials user.name
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
