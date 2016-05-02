module Components.CurrentUser where

import Html exposing (..)
import Html.Attributes exposing (..)

import Types exposing (User)
import Util exposing (initials, initialsColor)

avatar : User -> Html
avatar user =
  let
    initials' = initials user.name

    avatar' =
      case user.avatar of
        Nothing ->
          a
            [ class "initials", href "", style [ "background" => initialsColor initials' ] ]
            [ text initials' ]

        Just uri ->
          a
            [ href "" ]
            [ img
                [ src uri
                , title user.name
                , alt initials'
                ]
                [ ]
            ]
  in
    div
      [ class "avatar" ]
      [ avatar' ]

view : User -> Html
view user =
  div
    [ class "current-user" ]
    [ avatar user
    , h3 [] [ text user.name ]
    , h6 [] [ text user.timezone ]
    ]

(=>) = (,)
