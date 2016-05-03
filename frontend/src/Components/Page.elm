module Components.Page (page) where

import Html exposing (..)
import Html.Attributes exposing (..)

page : String -> List Html -> Html
page title content =
  div
    [ class "page" ]
    [ div [ class "page-header" ] [ h1 [] [ text title ] ]
    , div [ class "page-content" ] content
    ]
