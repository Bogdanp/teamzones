module Components.CurrentUser where

import Html exposing (..)
import Html.Attributes exposing (..)

import Routes exposing (Sitemap(..))
import Types exposing (User, AnchorTo)
import Util exposing ((=>), initials, initialsColor)

view : AnchorTo -> User -> Html
view anchorTo user =
  div
    [ class "current-user" ]
    [ avatar anchorTo user
    , h3 [] [ text user.name ]
    , h6 [] [ text user.timezone ]
    ]

avatar : AnchorTo -> User -> Html
avatar anchorTo user =
  let
    initials' =
      initials user.name

    avatar' =
      case user.avatar of
        Nothing ->
          anchorTo
            (CurrentProfileR ())
            [ class "initials"
            , style [ "background" => initialsColor initials' ]
            ]
            [ text initials' ]

        Just uri ->
          anchorTo
            (CurrentProfileR ())
            []
            [ img
                [ src uri
                , title user.name
                , alt initials'
                ]
                [ ]
            ]
  in
    div [ class "avatar" ] [ avatar' ]
